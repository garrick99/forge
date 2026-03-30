/* Verified Password Hasher — real-world driver
 *
 * Usage: password_hasher <password> [iterations]
 *
 * Hashes a password using verified iterative mixing.
 * Every array access in the core is proven safe by Z3.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#define main forge_main_unused
#include "hasher.c"
#undef main

int main(int argc, char **argv) {
    const char *password = argc > 1 ? argv[1] : "correcthorsebatterystaple";
    int iterations = argc > 2 ? atoi(argv[2]) : 10000;
    if (iterations < 1) iterations = 1;

    printf("=== Forge Verified Password Hasher ===\n");
    printf("Password:   \"%s\"\n", password);
    printf("Iterations: %d\n", iterations);

    /* Convert password to u64 array */
    int pw_len = (int)strlen(password);
    uint64_t pw_buf[256];
    for (int i = 0; i < pw_len && i < 256; i++)
        pw_buf[i] = (uint64_t)(unsigned char)password[i];

    /* Fixed salt */
    uint64_t salt[] = {0x5A, 0xA5, 0x0F, 0xF0, 0x3C, 0xC3, 0x69, 0x96,
                       0x55, 0xAA, 0x33, 0xCC, 0x0F, 0xF0, 0x5A, 0xA5};
    int salt_len = 16;

    /* Output buffer (32 bytes) */
    uint64_t output[32];
    int out_len = 32;

    forge_span_u64_t pw_span = { pw_buf, pw_len < 256 ? pw_len : 256 };
    forge_span_u64_t salt_span = { salt, salt_len };
    forge_span_u64_t out_span = { output, out_len };

    pbkdf_iterate(pw_span, pw_span.len, salt_span, salt_span.len,
                  out_span, out_len, (uint64_t)iterations);

    printf("Hash:       ");
    for (int i = 0; i < out_len; i++)
        printf("%02lx", (unsigned long)output[i]);
    printf("\n");
    printf("\nAll %d iterations executed in verified code — zero buffer overflow risk.\n",
           iterations);
    return 0;
}
