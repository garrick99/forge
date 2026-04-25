"""Forge ML kernel inventory — proof / assume / instruction count table.

Walks the 112X-113X demos (the f32 ML kernel arc starting at FORGE70) and
records, per kernel:

  - SMT proof obligations discharged (from `forge build` output)
  - assumes (from the assume audit)
  - PTX line count (excluding blank lines and comments)
  - generated CUDA C line count

Emits `benchmarks/forge_ml_inventory.md` with a Markdown table.

Lightweight on purpose — no GPU, no nvcc, no runtime measurement.  This is
the proof-and-emission story for the Forge-native ML kernel suite.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

FORGE_ROOT = Path(__file__).resolve().parent.parent
DEMOS_DIR = FORGE_ROOT / "demos"

# Forge's main.exe is a Linux ELF binary built under WSL; invoke through wsl.
FORGE_WSL_PATH = "/mnt/c/Users/kraken/forge"
FORGE_BIN_WSL = f"{FORGE_WSL_PATH}/_build/default/bin/main.exe"

# ML arc: 1120 onward (FORGE70 first f32 demo).
DEMO_GLOB = sorted(DEMOS_DIR.glob("11[2-9]?_forge_*.fg"))


def run_forge_build(fg_path: Path) -> str:
    rel = fg_path.relative_to(FORGE_ROOT).as_posix()
    cmd = ["wsl", "bash", "-c",
           f"cd {FORGE_WSL_PATH} && {FORGE_BIN_WSL} build {rel}"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout + result.stderr


_PROOF_RE = re.compile(
    r"proof summary: (\d+) total, (\d+) SMT, (\d+) guided, (\d+) manual, (\d+) failed"
)
_ASSUME_RE = re.compile(r"assume audit: (\d+) assumption")


def parse_build(text: str) -> tuple[int, int]:
    proofs = 0
    assumes = 0
    m = _PROOF_RE.search(text)
    if m:
        proofs = int(m.group(1))
    m = _ASSUME_RE.search(text)
    if m:
        assumes = int(m.group(1))
    elif "assume audit: 0 assumptions" in text:
        assumes = 0
    return proofs, assumes


def count_significant_lines(path: Path) -> int:
    if not path.exists():
        return 0
    n = 0
    for line in path.read_text(errors="ignore").splitlines():
        s = line.strip()
        if not s or s.startswith("//") or s.startswith("/*") or s.startswith("*"):
            continue
        n += 1
    return n


def main() -> int:
    rows = []
    for fg in DEMO_GLOB:
        name = fg.stem
        out = run_forge_build(fg)
        proofs, assumes = parse_build(out)
        ptx_lines = count_significant_lines(fg.with_suffix(".ptx"))
        cu_lines = count_significant_lines(fg.with_suffix(".cu"))
        rows.append((name, proofs, assumes, cu_lines, ptx_lines))
        print(f"{name:42s}  proofs={proofs:3d}  assumes={assumes}  "
              f"cu_lines={cu_lines:4d}  ptx_lines={ptx_lines:4d}")

    md_path = FORGE_ROOT / "benchmarks" / "forge_ml_inventory.md"
    with md_path.open("w") as f:
        f.write("# Forge ML kernel inventory\n\n")
        f.write("Proof / assume / emission counts for the f32 ML kernel arc "
                "(1120-1135), Forge-native demos shipped FORGE70 onward.\n\n")
        f.write("| demo | proofs | assumes | CUDA C lines | PTX lines |\n")
        f.write("|------|-------:|--------:|-------------:|----------:|\n")
        for name, proofs, assumes, cu, ptx in rows:
            f.write(f"| `{name}` | {proofs} | {assumes} | {cu} | {ptx} |\n")
        total_p = sum(r[1] for r in rows)
        total_a = sum(r[2] for r in rows)
        f.write(f"| **total** | **{total_p}** | **{total_a}** | | |\n")

    print()
    print(f"Wrote {md_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
