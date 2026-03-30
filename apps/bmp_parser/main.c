/* Verified BMP Parser — real-world driver
 *
 * Usage: bmp_parser <file.bmp>
 *
 * Parses a BMP file header using verified code. Every byte access
 * is proven safe by Z3 — no buffer overread possible.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#define main forge_main_unused
#include "bmp.c"
#undef main

int main(int argc, char **argv) {
    printf("=== Forge Verified BMP Parser ===\n\n");

    uint64_t *buf = NULL;
    size_t buf_len = 0;

    if (argc > 1) {
        /* Read actual BMP file */
        FILE *fp = fopen(argv[1], "rb");
        if (!fp) { fprintf(stderr, "Cannot open %s\n", argv[1]); return 1; }
        fseek(fp, 0, SEEK_END);
        long fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        buf_len = (size_t)fsize;
        buf = (uint64_t *)malloc(buf_len * sizeof(uint64_t));
        if (!buf) { fprintf(stderr, "Out of memory\n"); fclose(fp); return 1; }
        for (size_t i = 0; i < buf_len; i++) {
            int byte = fgetc(fp);
            buf[i] = (byte == EOF) ? 0 : (uint64_t)byte;
        }
        fclose(fp);
        printf("File: %s (%zu bytes)\n\n", argv[1], buf_len);
    } else {
        /* Generate a minimal valid 2x2 BMP for testing */
        printf("No file specified — using built-in 2x2 test BMP\n\n");
        buf_len = 70;  /* 54-byte header + 16 bytes pixel data (2x2, 24-bit, padded) */
        buf = (uint64_t *)calloc(buf_len, sizeof(uint64_t));

        /* BMP file header (14 bytes) */
        buf[0] = 66; buf[1] = 77;          /* 'B', 'M' */
        buf[2] = 70; buf[3] = 0; buf[4] = 0; buf[5] = 0;  /* file size = 70 */
        buf[6] = 0; buf[7] = 0; buf[8] = 0; buf[9] = 0;   /* reserved */
        buf[10] = 54; buf[11] = 0; buf[12] = 0; buf[13] = 0; /* pixel offset = 54 */

        /* DIB header (40 bytes, BITMAPINFOHEADER) */
        buf[14] = 40; buf[15] = 0; buf[16] = 0; buf[17] = 0; /* header size = 40 */
        buf[18] = 2; buf[19] = 0; buf[20] = 0; buf[21] = 0;  /* width = 2 */
        buf[22] = 2; buf[23] = 0; buf[24] = 0; buf[25] = 0;  /* height = 2 */
        buf[26] = 1; buf[27] = 0;                              /* planes = 1 */
        buf[28] = 24; buf[29] = 0;                             /* bits per pixel = 24 */
        /* rest is zeros (no compression, etc.) */

        /* Pixel data: 2x2, 24-bit, each row padded to 4-byte boundary */
        /* Row 0 (bottom): red, green + 2 pad bytes */
        buf[54] = 0; buf[55] = 0; buf[56] = 255;    /* pixel(0,0): red */
        buf[57] = 0; buf[58] = 255; buf[59] = 0;    /* pixel(1,0): green */
        buf[60] = 0; buf[61] = 0;                    /* padding */
        /* Row 1 (top): blue, white + 2 pad bytes */
        buf[62] = 255; buf[63] = 0; buf[64] = 0;    /* pixel(0,1): blue */
        buf[65] = 255; buf[66] = 255; buf[67] = 255; /* pixel(1,1): white */
        buf[68] = 0; buf[69] = 0;                    /* padding */
    }

    forge_span_u64_t bmp_span = { buf, buf_len };

    /* Validate header */
    __forge_tuple_u64_u64_u64_u64_u64_t result = validate_bmp_header(bmp_span, buf_len);
    uint64_t err = result._0;
    uint64_t width = result._1;
    uint64_t height = result._2;

    if (err != 0) {
        const char *msgs[] = { "OK", "too small", "bad magic", "bad offset", "bad dimensions" };
        printf("INVALID BMP: %s (error %lu)\n", err < 5 ? msgs[err] : "unknown",
               (unsigned long)err);
    } else {
        printf("Valid BMP header:\n");
        printf("  Dimensions: %lux%lu\n", (unsigned long)width, (unsigned long)height);
        printf("  Pixel offset: %lu\n", (unsigned long)read_u32_le(bmp_span, 10));
        printf("  File size: %lu bytes\n", (unsigned long)read_u32_le(bmp_span, 2));
        printf("  Bits/pixel: %lu\n", (unsigned long)read_u16_le(bmp_span, 28));

        /* Extract corner pixels if we can */
        uint64_t pixel_offset = read_u32_le(bmp_span, 10);
        if (width > 0 && height > 0) {
            __forge_tuple_u64_u64_u64_t px = extract_pixel(bmp_span, buf_len,
                pixel_offset, 0, 0, width);
            printf("  Pixel(0,0): R=%lu G=%lu B=%lu\n",
                   (unsigned long)px._0, (unsigned long)px._1, (unsigned long)px._2);
        }
    }

    printf("\nAll parsing performed by verified code — zero buffer overread risk.\n");
    free(buf);
    return 0;
}
