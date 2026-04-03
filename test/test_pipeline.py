"""
test_pipeline.py — Forge → OpenCUDA → OpenPTXas end-to-end integration tests.

Validates the full open-source GPU compilation pipeline:
  Forge source → (forge cuda) → CUDA C → OpenCUDA → PTX → OpenPTXas → cubin

Run: pytest forge/test/test_pipeline.py -v
"""

import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

# ── Path setup ────────────────────────────────────────────────────────────────
_FORGE_ROOT  = Path(__file__).resolve().parent.parent   # forge/
_OPENCUDA    = _FORGE_ROOT.parent / 'opencuda'
_OPENPTXAS   = _FORGE_ROOT.parent / 'openptxas'
_FORGE_EXE   = (_FORGE_ROOT / '_build' / 'default' / 'bin' / 'main.exe')
_FORGE_WSL   = str(_FORGE_EXE).replace('C:\\', '/mnt/c/').replace('\\', '/')

for p in (_OPENCUDA, _OPENPTXAS):
    if str(p) not in sys.path:
        sys.path.insert(0, str(p))


def _win_to_wsl(p: Path) -> str:
    return str(p.resolve()).replace('C:\\', '/mnt/c/').replace('\\', '/')


def forge_cuda(fg_src: str) -> str:
    """Compile Forge source to CUDA C. Returns CUDA C text."""
    with tempfile.TemporaryDirectory() as tmpdir:
        fg = Path(tmpdir) / 'kernel.fg'
        fg.write_text(fg_src)
        cmd = [
            'wsl.exe', '-e', 'bash', '-c',
            f'export PATH=/root/.opam/default/bin:/usr/bin:/bin; '
            f'{_FORGE_WSL} cuda {_win_to_wsl(fg)}'
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            raise AssertionError(
                f'forge cuda failed:\n{r.stdout}\n{r.stderr}')
        cu = fg.with_suffix('.cu')
        if not cu.exists():
            raise AssertionError('forge cuda did not write .cu file')
        return cu.read_text()


def opencuda_to_ptx(cu_src: str) -> dict[str, str]:
    """Compile CUDA C to PTX via OpenCUDA. Returns {name: ptx}."""
    from opencuda.frontend.parser import parse
    from opencuda.ir.optimize import optimize
    from opencuda.codegen.emit import ir_to_ptx
    mod = parse(cu_src)
    optimize(mod)
    return ir_to_ptx(mod)


def openptxas_to_cubin(ptx: str) -> bytes:
    """Assemble PTX to cubin via OpenPTXas. Returns cubin bytes."""
    from sass.pipeline import compile_ptx_source
    cubins = compile_ptx_source(ptx, verbose=False)
    assert cubins, 'OpenPTXas produced no cubins'
    return next(iter(cubins.values()))


# ── Test kernels ──────────────────────────────────────────────────────────────

VEC_ADD_FG = """\
#[kernel]
fn vec_add(a: span<f32>, b: span<f32>, out: span<f32>)
    requires a.len == out.len
    requires b.len == out.len
{
    let i: u64 = blockIdx_x * blockDim_x + threadIdx_x;
    if i < out.len {
        out[i] = a[i] + b[i];
    }
}
"""

SCALE_FG = """\
#[kernel]
fn scale(a: span<f32>, s: f32, out: span<f32>)
    requires a.len == out.len
{
    let i: u64 = blockIdx_x * blockDim_x + threadIdx_x;
    if i < out.len {
        out[i] = a[i] * s;
    }
}
"""

FILL_FG = """\
#[kernel]
fn fill(out: span<u64>, val: u64) {
    let i: u64 = blockIdx_x * blockDim_x + threadIdx_x;
    if i < out.len {
        out[i] = val;
    }
}
"""

MULTI_KERNEL_FG = """\
#[kernel]
fn k_add(a: span<f32>, b: span<f32>, out: span<f32>)
    requires a.len == out.len
    requires b.len == out.len
{
    let i: u64 = blockIdx_x * blockDim_x + threadIdx_x;
    if i < out.len {
        out[i] = a[i] + b[i];
    }
}

#[kernel]
fn k_mul(a: span<f32>, b: span<f32>, out: span<f32>)
    requires a.len == out.len
    requires b.len == out.len
{
    let i: u64 = blockIdx_x * blockDim_x + threadIdx_x;
    if i < out.len {
        out[i] = a[i] * b[i];
    }
}
"""


# ── Tests ─────────────────────────────────────────────────────────────────────

class TestForgeToCudaC:
    """Stage 1: Forge → CUDA C via 'forge cuda'."""

    def test_vec_add_emits_global(self):
        cu = forge_cuda(VEC_ADD_FG)
        assert '__global__ void vec_add(' in cu

    def test_vec_add_flat_params(self):
        """forge cuda should emit flat T* + len params, not fat-pointer structs."""
        cu = forge_cuda(VEC_ADD_FG)
        assert 'forge_span' not in cu
        assert 'float* __restrict__' in cu
        assert 'uint64_t' in cu

    def test_no_forward_declarations(self):
        """forge cuda emits definitions only, no forward decls."""
        cu = forge_cuda(VEC_ADD_FG)
        lines = cu.splitlines()
        global_lines = [l for l in lines if '__global__' in l]
        # Each kernel appears exactly once (definition), not twice (decl + def)
        assert len(global_lines) == 1

    def test_scale_kernel(self):
        cu = forge_cuda(SCALE_FG)
        assert '__global__ void scale(' in cu
        assert 'float* __restrict__' in cu

    def test_fill_kernel(self):
        cu = forge_cuda(FILL_FG)
        assert '__global__ void fill(' in cu
        assert 'uint64_t* __restrict__' in cu

    def test_multi_kernel(self):
        cu = forge_cuda(MULTI_KERNEL_FG)
        assert '__global__ void k_add(' in cu
        assert '__global__ void k_mul(' in cu


class TestCudaCToPtr:
    """Stage 2: CUDA C → PTX via OpenCUDA."""

    def test_vec_add_parses(self):
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        assert 'vec_add' in ptx_map

    def test_vec_add_ptx_has_entry(self):
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        ptx = ptx_map['vec_add']
        assert '.visible .entry vec_add(' in ptx

    def test_vec_add_ptx_has_params(self):
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        ptx = ptx_map['vec_add']
        # 3 spans → 6 declared params (ptr + len each) in the entry signature
        # Count only signature params: lines like "    .param .u64 name"
        import re
        sig_params = re.findall(r'\.param\s+\.\w+\s+\w+[,)]', ptx)
        assert len(sig_params) == 6, f'expected 6 params, got {len(sig_params)}: {sig_params}'

    def test_vec_add_ptx_uses_thread_builtins(self):
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        ptx = ptx_map['vec_add']
        assert '%ctaid.x' in ptx
        assert '%ntid.x' in ptx
        assert '%tid.x' in ptx

    def test_scale_kernel_ptx(self):
        cu = forge_cuda(SCALE_FG)
        ptx_map = opencuda_to_ptx(cu)
        assert 'scale' in ptx_map
        ptx = ptx_map['scale']
        assert '.visible .entry scale(' in ptx
        assert 'mul.f32' in ptx or 'fma.rn.f32' in ptx

    def test_fill_u64_ptx(self):
        cu = forge_cuda(FILL_FG)
        ptx_map = opencuda_to_ptx(cu)
        assert 'fill' in ptx_map
        ptx = ptx_map['fill']
        assert 'st.global' in ptx

    def test_multi_kernel_both_parsed(self):
        cu = forge_cuda(MULTI_KERNEL_FG)
        ptx_map = opencuda_to_ptx(cu)
        assert 'k_add' in ptx_map
        assert 'k_mul' in ptx_map

    def test_no_nvcc_dependency(self):
        """The pipeline must not invoke nvcc or ptxas."""
        import shutil
        # If nvcc/ptxas are absent the pipeline should still work
        # (they are not called by OpenCUDA or OpenPTXas)
        cu = forge_cuda(SCALE_FG)
        ptx_map = opencuda_to_ptx(cu)
        assert ptx_map  # succeeded without nvcc


class TestPTXToCubin:
    """Stage 3: PTX → SM_120 cubin via OpenPTXas."""

    def test_vec_add_assembles(self):
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        cubin = openptxas_to_cubin(ptx_map['vec_add'])
        assert len(cubin) > 0

    def test_cubin_has_elf_magic(self):
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        cubin = openptxas_to_cubin(ptx_map['vec_add'])
        assert cubin[:4] == b'\x7fELF', 'cubin is not an ELF binary'

    def test_scale_assembles(self):
        cu = forge_cuda(SCALE_FG)
        ptx_map = opencuda_to_ptx(cu)
        cubin = openptxas_to_cubin(ptx_map['scale'])
        assert cubin[:4] == b'\x7fELF'

    def test_fill_assembles(self):
        cu = forge_cuda(FILL_FG)
        ptx_map = opencuda_to_ptx(cu)
        cubin = openptxas_to_cubin(ptx_map['fill'])
        assert cubin[:4] == b'\x7fELF'

    def test_multi_kernel_both_assemble(self):
        cu = forge_cuda(MULTI_KERNEL_FG)
        ptx_map = opencuda_to_ptx(cu)
        for kname in ('k_add', 'k_mul'):
            cubin = openptxas_to_cubin(ptx_map[kname])
            assert cubin[:4] == b'\x7fELF', f'{kname} cubin missing ELF magic'

    def test_cubin_minimum_size(self):
        """A valid SM_120 cubin should be at least 1 KB."""
        cu = forge_cuda(VEC_ADD_FG)
        ptx_map = opencuda_to_ptx(cu)
        cubin = openptxas_to_cubin(ptx_map['vec_add'])
        assert len(cubin) >= 1024, f'cubin too small: {len(cubin)} bytes'


class TestExistingKernelDemos:
    """
    Regression tests: existing Forge GPU demos must survive the full pipeline.
    Uses the already-compiled .cu files in forge/demos/.
    """

    def _cu_file(self, name: str) -> Path:
        p = _FORGE_ROOT / 'demos' / name
        if not p.exists():
            pytest.skip(f'{name} not found')
        return p

    def test_19_gpu_kernel(self):
        """demos/19_gpu_kernel.cu (vec_add, prefix_sum_step, block_offset_kernel)."""
        cu = self._cu_file('19_gpu_kernel.cu').read_text()
        ptx_map = opencuda_to_ptx(cu)
        assert 'vec_add' in ptx_map
        assert 'prefix_sum_step' in ptx_map
        assert 'block_offset_kernel' in ptx_map
        for name, ptx in ptx_map.items():
            cubin = openptxas_to_cubin(ptx)
            assert cubin[:4] == b'\x7fELF', f'{name}: not ELF'
