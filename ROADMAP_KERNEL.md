# Forge Kernel Readiness Roadmap

## Goal
Enable Forge to write verified kernel modules: packet filters, crypto drivers,
filesystem parsers, memory allocators, and USB/Bluetooth protocol handlers.

## Gap Analysis

### Tier 1 — Required for any kernel work (blocking)

| Feature | Status | AST | Parser | Typecheck | Codegen | Est. |
|---------|--------|-----|--------|-----------|---------|------|
| Function pointers | Partial | TFn ✓ | Partial | Partial | Partial | Medium |
| Raw pointers + arithmetic | Partial | TRaw ✓ | Minimal | No | emit T* ✓ | Medium |
| Volatile types | No | No | No | No | No | Small |
| Bitfields | No | No | No | No | No | Medium |
| Union types | No | No | No | No | No | Medium |
| Extern C declarations | Partial | ✓ | ✓ | ✓ | ✓ | Done-ish |

### Tier 2 — Required for serious kernel modules

| Feature | Status | Notes |
|---------|--------|-------|
| Inline assembly | No | `asm!("...", in/out/clobber)` → `__asm__ volatile` |
| Packed structs | No | `#[repr(packed)]` → `__attribute__((packed))` |
| Computed gotos | No | Low priority — only used in interpreter loops |
| setjmp/longjmp | No | Low priority — only used in error handling |
| VLAs | No | Use spans instead |

### Tier 3 — Nice to have

| Feature | Notes |
|---------|-------|
| Macro system | Hygienic macros or const generics cover most cases |
| Container-of pattern | Could be a built-in: `container_of!(ptr, Type, field)` |
| Kernel module boilerplate | `#[module]` attribute → generates `module_init`/`module_exit` |

## Implementation Plan

### Phase 1: Function pointers (enables callbacks, vtables)
- Parser: `fn(u64, u64) -> u64` as a type
- Typecheck: allow `f(args)` where `f: fn(T) -> U`
- Codegen: emit `typedef U (*fn_name_t)(T1, T2);` for each unique fn type
- Proof: function pointer calls are unchecked (extern) — user provides specs

### Phase 2: Raw pointer operations (enables allocators, DMA)
- `raw_null<T>()` → `(T*)NULL`
- `raw_offset(ptr, n)` → `ptr + n`
- `raw_read(ptr)` → `*ptr` (requires `ptr != null` precondition)
- `raw_write(ptr, val)` → `*ptr = val`
- `raw_cast<U>(ptr)` → `(U*)ptr` (unsafe, logged)
- All raw ops generate proof obligations for non-null

### Phase 3: Volatile + bitfields (enables device drivers)
- `volatile<T>` type → `volatile T` in C
- `volatile_read(ptr)` / `volatile_write(ptr, val)` → direct access
- `struct Foo { x: u8 @ 3, y: u8 @ 5 }` → C bitfields

### Phase 4: Union types (enables protocol parsing)
- `union Packet { tcp: TcpHeader, udp: UdpHeader, raw: [u8; 64] }`
- Tag-checked access in safe mode, unchecked in `raw {}` blocks
- Codegen: direct C union

### Phase 5: Inline assembly (enables crypto, atomics)
- `asm!("mov {}, {}", out(reg) result, in(reg) input)`
- Codegen: `__asm__ volatile ("mov %0, %1" : "=r"(result) : "r"(input))`
- No proof obligations on asm blocks — trust the programmer
