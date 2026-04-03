#!/usr/bin/env python3
"""
forge_pipeline.py — Forge → OpenCUDA → OpenPTXas → cubin

Full open-source GPU compilation pipeline, no nvcc/ptxas required.

Usage:
    python forge_pipeline.py <input.fg> [--run] [--verbose]

Steps:
    1. forge cuda input.fg          → input.cu  (Forge: prove + emit CUDA C)
    2. OpenCUDA parse+optimize+emit → input.ptx (Python CUDA C → PTX)
    3. OpenPTXas compile_ptx_source → input.cubin per kernel
    4. (optional) Run cubin on GPU via CUDA driver API
"""

import argparse
import ctypes
import subprocess
import sys
from pathlib import Path

# ── Path setup ──────────────────────────────────────────────────────────────
_HERE = Path(__file__).resolve().parent          # forge/scripts/
_FORGE_ROOT = _HERE.parent                        # forge/
_OPENCUDA   = _FORGE_ROOT.parent / 'opencuda'
_OPENPTXAS  = _FORGE_ROOT.parent / 'openptxas'

for p in (_OPENCUDA, _OPENPTXAS):
    if str(p) not in sys.path:
        sys.path.insert(0, str(p))

# ── Forge compiler (WSL path) ────────────────────────────────────────────────
_FORGE_EXE_WIN = str(_FORGE_ROOT / '_build' / 'default' / 'bin' / 'main.exe')
_FORGE_EXE_WSL = _FORGE_EXE_WIN.replace('C:\\', '/mnt/c/').replace('\\', '/')


def _win_to_wsl(path: Path) -> str:
    s = str(path.resolve())
    return s.replace('C:\\', '/mnt/c/').replace('\\', '/')


def forge_cuda(fg_path: Path, verbose: bool = False) -> Path:
    """Run `forge cuda input.fg` via WSL and return the emitted .cu path."""
    cu_path = fg_path.with_suffix('.cu')
    wsl_fg  = _win_to_wsl(fg_path)
    cmd = [
        'wsl.exe', '-e', 'bash', '-c',
        f'export PATH=/root/.opam/default/bin:/usr/bin:/bin; '
        f'{_FORGE_EXE_WSL} cuda {wsl_fg}'
    ]
    if verbose:
        print(f'[forge] running: forge cuda {fg_path.name}')
    result = subprocess.run(cmd, capture_output=not verbose, text=True)
    if result.returncode != 0:
        if not verbose:
            print(result.stdout, end='')
            print(result.stderr, end='', file=sys.stderr)
        raise RuntimeError(f'forge cuda failed (exit {result.returncode})')
    if verbose:
        print(result.stdout, end='')
    if not cu_path.exists():
        raise RuntimeError(f'forge cuda did not emit {cu_path}')
    return cu_path


def opencuda_compile(cu_path: Path, verbose: bool = False) -> dict[str, str]:
    """Parse + optimize + emit PTX via OpenCUDA. Returns {kernel_name: ptx}."""
    from opencuda.frontend.parser import parse
    from opencuda.ir.optimize import optimize
    from opencuda.codegen.emit import ir_to_ptx

    src = cu_path.read_text()
    if verbose:
        print(f'[opencuda] parsing {cu_path.name}...')
    mod = parse(src)
    if verbose:
        print(f'[opencuda] {len(mod.kernels)} kernel(s): '
              f'{", ".join(k.name for k in mod.kernels)}')
    optimize(mod)
    ptx_map = ir_to_ptx(mod)
    if verbose:
        for name, ptx in ptx_map.items():
            print(f'[opencuda] {name}: {ptx.count(chr(10))} PTX lines')
    return ptx_map


def openptxas_assemble(ptx_map: dict[str, str],
                       out_dir: Path,
                       verbose: bool = False) -> dict[str, Path]:
    """Assemble PTX via OpenPTXas. Returns {kernel_name: cubin_path}."""
    from sass.pipeline import compile_ptx_source

    cubin_paths = {}
    for name, ptx in ptx_map.items():
        if verbose:
            print(f'[openptxas] assembling {name}...')
        cubins = compile_ptx_source(ptx, verbose=False)
        kbytes = cubins.get(name)
        if kbytes is None and cubins:
            kbytes = next(iter(cubins.values()))
        if kbytes is None:
            raise RuntimeError(f'OpenPTXas produced no cubin for kernel {name}')
        out_path = out_dir / f'{name}.cubin'
        out_path.write_bytes(kbytes)
        if verbose:
            print(f'[openptxas] {name}: {len(kbytes)} bytes → {out_path.name}')
        cubin_paths[name] = out_path
    return cubin_paths


# ── GPU execution ─────────────────────────────────────────────────────────────

def _check(err, msg='CUDA error'):
    if err != 0:
        raise RuntimeError(f'{msg}: error code {err}')


def run_on_gpu(cubin_path: Path, kernel_name: str,
               args: list, grid: tuple, block: tuple,
               verbose: bool = False) -> None:
    """
    Load a cubin and launch kernel_name with the given args.

    args: list of ctypes values (pointers passed by reference, scalars by value)
    grid/block: (x, y, z) tuples
    """
    cuda = ctypes.CDLL('nvcuda.dll')

    dev = ctypes.c_int()
    _check(cuda.cuInit(0), 'cuInit')
    _check(cuda.cuDeviceGet(ctypes.byref(dev), 0), 'cuDeviceGet')

    name_buf = ctypes.create_string_buffer(256)
    cuda.cuDeviceGetName(name_buf, 256, dev)
    if verbose:
        print(f'[gpu] device: {name_buf.value.decode()}')

    ctx = ctypes.c_void_p()
    _check(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, dev), 'cuCtxCreate')

    mod = ctypes.c_void_p()
    _check(cuda.cuModuleLoad(ctypes.byref(mod),
                             str(cubin_path).encode()), 'cuModuleLoad')

    func = ctypes.c_void_p()
    _check(cuda.cuModuleGetFunction(ctypes.byref(func), mod,
                                    kernel_name.encode()), 'cuModuleGetFunction')

    # Build kernelParams: array of pointers to each argument
    kp_array = (ctypes.c_void_p * len(args))(
        *[ctypes.cast(ctypes.byref(a), ctypes.c_void_p) for a in args]
    )

    _check(cuda.cuLaunchKernel(
        func,
        grid[0], grid[1], grid[2],
        block[0], block[1], block[2],
        0, ctypes.c_void_p(0),
        kp_array, ctypes.c_void_p(0),
    ), 'cuLaunchKernel')

    _check(cuda.cuCtxSynchronize(), 'cuCtxSynchronize')

    if verbose:
        print(f'[gpu] {kernel_name} launched and synced OK')

    cuda.cuCtxDestroy_v2(ctx)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='Forge → OpenCUDA → OpenPTXas end-to-end GPU pipeline')
    parser.add_argument('input', help='Forge source file (.fg)')
    parser.add_argument('--run', action='store_true',
                        help='Run the first kernel on GPU after assembly')
    parser.add_argument('--verbose', '-v', action='store_true')
    parser.add_argument('--keep-cu', action='store_true',
                        help='Keep intermediate .cu file')
    args = parser.parse_args()

    fg_path = Path(args.input).resolve()
    if not fg_path.exists():
        print(f'error: {fg_path} not found', file=sys.stderr)
        sys.exit(1)

    print(f'{"=" * 60}')
    print(f' FORGE END-TO-END PIPELINE')
    print(f'{"=" * 60}')
    print(f' Input:      {fg_path.name}')
    print(f' Toolchain:  Forge + OpenCUDA + OpenPTXas (no nvcc)')
    print(f'{"=" * 60}')

    # Step 1: Forge → CUDA C
    print('\n[1/3] Forge: prove obligations + emit CUDA C')
    cu_path = forge_cuda(fg_path, verbose=args.verbose)
    print(f'      → {cu_path.name}')

    # Step 2: OpenCUDA → PTX
    print('\n[2/3] OpenCUDA: CUDA C → PTX')
    ptx_map = opencuda_compile(cu_path, verbose=args.verbose)
    kernels = list(ptx_map.keys())
    print(f'      → {len(kernels)} kernel(s): {", ".join(kernels)}')

    # Optionally write .ptx files
    for kname, ptx in ptx_map.items():
        ptx_path = fg_path.with_name(f'{fg_path.stem}_{kname}.ptx')
        ptx_path.write_text(ptx)
        if args.verbose:
            print(f'      → wrote {ptx_path.name}')

    # Step 3: OpenPTXas → cubin
    print('\n[3/3] OpenPTXas: PTX → SM_120 cubin')
    cubin_paths = openptxas_assemble(ptx_map, fg_path.parent, verbose=args.verbose)
    for kname, cp in cubin_paths.items():
        print(f'      → {cp.name} ({cp.stat().st_size} bytes)')

    if not args.keep_cu:
        cu_path.unlink(missing_ok=True)

    print(f'\n{"=" * 60}')
    print(' PIPELINE COMPLETE')
    print(f'{"=" * 60}')
    print(' Forge proofs:   discharged by Z3')
    print(' PTX compiler:   OpenCUDA (pure Python)')
    print(' PTX assembler:  OpenPTXas (pure Python)')
    print(' NVIDIA tooling: NOT USED')
    print(f'{"=" * 60}')

    if args.run:
        print('\n[run] launching first kernel on GPU...')
        # Basic smoke test: not fully general, just verifies the cubin loads
        kname = kernels[0]
        cp = cubin_paths[kname]
        try:
            import numpy as np
            N = 256
            a = np.arange(N, dtype=np.float32)
            b = np.arange(N, dtype=np.float32) * 2.0
            out = np.zeros(N, dtype=np.float32)
            cuda = ctypes.CDLL('nvcuda.dll')
            _check(cuda.cuInit(0))
            dev = ctypes.c_int()
            _check(cuda.cuDeviceGet(ctypes.byref(dev), 0))
            ctx = ctypes.c_void_p()
            _check(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, dev))
            mod = ctypes.c_void_p()
            _check(cuda.cuModuleLoad(ctypes.byref(mod), str(cp).encode()))
            func = ctypes.c_void_p()
            _check(cuda.cuModuleGetFunction(ctypes.byref(func), mod, kname.encode()))
            print(f'[run] kernel {kname!r} loaded successfully from cubin')
            print('[run] (full launch test requires kernel-specific args; '
                  'use forge_e2e_run.py for vector_add)')
            cuda.cuCtxDestroy_v2(ctx)
        except Exception as e:
            print(f'[run] GPU load test: {e}')


if __name__ == '__main__':
    main()
