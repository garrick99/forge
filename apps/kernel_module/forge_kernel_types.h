/*
 * forge_kernel_types.h — Adapts Forge-generated C for kernel space
 *
 * Forge's codegen emits #include <stdint.h> and uses uint64_t, _Bool, etc.
 * Kernel modules must use <linux/types.h> instead. This header intercepts
 * the userspace includes and maps types to kernel equivalents.
 */

#ifndef FORGE_KERNEL_TYPES_H
#define FORGE_KERNEL_TYPES_H

/* Block ALL userspace headers — redirect to kernel equivalents.
   These must be defined BEFORE filter_core.c is included. */
#include <linux/types.h>
#include <linux/string.h>

/* Prevent filter_core.c from pulling in userspace headers */
#define stdint_h     /* blocks some compilers */
#define stdbool_h
#define stdlib_h

/* Map Forge codegen types to kernel types */
#ifndef uint64_t
typedef u64 uint64_t;
#endif
#ifndef uint32_t
typedef u32 uint32_t;
#endif
#ifndef uint16_t
typedef u16 uint16_t;
#endif
#ifndef uint8_t
typedef u8  uint8_t;
#endif
#ifndef int64_t
typedef s64 int64_t;
#endif
#ifndef int32_t
typedef s32 int32_t;
#endif
typedef unsigned long uintptr_t;

/* Kernel already defines bool — just ensure _Bool works */
#ifndef _Bool
#define _Bool bool
#endif

/* Forge uses stdlib for nothing in kernel context — stub out */
#define malloc(x)  NULL
#define free(x)    do {} while(0)

#endif /* FORGE_KERNEL_TYPES_H */
