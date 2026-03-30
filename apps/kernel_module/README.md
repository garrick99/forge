# Forge Verified Netfilter Module

A Linux kernel packet filter where **every array access is mathematically proven safe**.

## What this is

A real Linux kernel module (`.ko`) that hooks into netfilter's `NF_INET_PRE_ROUTING` chain. Every packet passes through Forge-verified code before reaching the network stack.

**92 proof obligations. 0 assumptions. 0 buffer overflow risk.**

## Architecture

```
┌──────────────────────────────────────────────┐
│                 Linux Kernel                  │
│                                              │
│  NIC → skb → ┌─────────────────────────┐    │
│              │  forge_netfilter.ko      │    │
│              │                         │    │
│              │  sk_buff → u64 span    │    │
│              │         ↓              │    │
│              │  ┌─────────────────┐   │    │
│              │  │ filter_core.c   │   │    │
│              │  │ (FORGE VERIFIED)│   │    │
│              │  │ 92 proofs ✓     │   │    │
│              │  └────────┬────────┘   │    │
│              │           ↓            │    │
│              │  NF_ACCEPT / NF_DROP   │    │
│              └─────────────────────────┘    │
│                       ↓                      │
│              TCP/IP stack (if accepted)       │
└──────────────────────────────────────────────┘
```

## Proven guarantees

The Forge compiler proves, via Z3 SMT solver, that the filter core:

1. **Never reads out of bounds** — every `pkt[i]` access has `i < pkt_len` proven
2. **Rule matching is safe** — every `rules[base + k]` has `base + k < rules.len` proven
3. **Conntrack state is valid** — `conn_state_transition` ensures `result < 6`
4. **Verdict is bounded** — `filter_packet` ensures `result <= 1` (DROP or ACCEPT)

These are not runtime checks. They are compile-time mathematical proofs. The generated C has **zero** bounds checks because they were **proven unnecessary**.

## Default rules

| Protocol | Port | Action |
|----------|------|--------|
| TCP | 22 (SSH) | ACCEPT |
| TCP | 80 (HTTP) | ACCEPT |
| TCP | 443 (HTTPS) | ACCEPT |
| UDP | 53 (DNS) | ACCEPT |
| UDP | 67-68 (DHCP) | ACCEPT |
| ICMP | * | ACCEPT |
| * | * | **DROP** (default deny) |

## Build & Run

```bash
# Prerequisites
sudo apt install linux-headers-$(uname -r)

# Build the kernel module
make

# Load
sudo insmod forge_netfilter.ko
dmesg | grep forge

# Test (from another machine)
ping <this-machine>       # should work (ICMP allowed)
curl <this-machine>:80    # should work (HTTP allowed)
nc <this-machine> 12345   # should be dropped (not in rules)

# Check stats
dmesg | grep forge

# Unload
sudo rmmod forge_netfilter
```

## Regenerate verified core

If you modify `filter_core.fg`:

```bash
# Requires Forge compiler
make verify

# This runs:
#   forge build filter_core.fg
# Which:
#   1. Parses the Forge source
#   2. Generates 92 proof obligations
#   3. Sends each to Z3 for verification
#   4. Only emits filter_core.c if ALL pass
#   5. Refuses to compile if any proof fails
```

## Files

| File | What |
|------|------|
| `filter_core.fg` | Forge source — the verified core (parsing, rules, conntrack) |
| `filter_core.c` | Generated C — proven correct, do not edit |
| `forge_netfilter.c` | Kernel wrapper — hooks, sk_buff adapter, init/exit |
| `Makefile` | Kbuild makefile |

## CVEs this prevents

By construction (no runtime check needed):

- **CWE-120** Buffer overflow — every access proven in bounds
- **CWE-125** Out-of-bounds read — every packet byte access proven safe
- **CWE-131** Incorrect buffer size — length validated before any field access
- **CWE-787** Out-of-bounds write — conntrack writes proven within table
- **CWE-805** Buffer access with incorrect length — header length checked first

## License

The Forge-generated core (`filter_core.c`) carries no license restrictions.
The kernel wrapper (`forge_netfilter.c`) is GPL (required for kernel modules).
