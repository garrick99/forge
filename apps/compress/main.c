/* Forge Verified Compression Utility
 *
 * Usage:
 *   compress                        — run built-in demo
 *   compress -c <input> <output>    — compress file
 *   compress -d <input> <output>    — decompress file
 *
 * The compression/decompression core is proven memory-safe by Z3.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#define main forge_main_unused
#include "compress.c"
#undef main

#define WINDOW_SIZE 4096
#define MIN_MATCH   3
#define MAX_MATCH   258

static void run_demo(void) {
    printf("=== Forge Verified Compression Utility ===\n\n");

    /* Test data: repetitive text compresses well */
    const char *test_str =
        "ABCABCABCABCABCABCABCABC"
        "the quick brown fox jumps over the lazy dog "
        "the quick brown fox jumps over the lazy dog "
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "0123456789012345678901234567890123456789"
        "ABCABCABCABCABCABCABCABC";

    int input_len = (int)strlen(test_str);
    uint64_t *input = (uint64_t *)malloc(input_len * sizeof(uint64_t));
    for (int i = 0; i < input_len; i++)
        input[i] = (uint64_t)(unsigned char)test_str[i];

    printf("Input:  %d bytes\n", input_len);
    printf("  \"%.*s...\"\n\n", input_len > 60 ? 60 : input_len, test_str);

    /* Compress */
    int out_cap = input_len * 3;  /* worst case: all literals */
    uint64_t *compressed = (uint64_t *)calloc(out_cap, sizeof(uint64_t));

    forge_span_u64_t in_span = { input, input_len };
    forge_span_u64_t comp_span = { compressed, out_cap };

    uint64_t comp_len = compress(in_span, input_len, comp_span, out_cap,
                                 WINDOW_SIZE, MIN_MATCH, MAX_MATCH);

    /* Count token types */
    forge_span_u64_t comp_view = { compressed, comp_len };
    __forge_tuple_u64_u64_t stats = count_tokens(comp_view, comp_len);
    uint64_t comp_size = compressed_size(comp_view, comp_len);

    printf("Compressed: %lu tokens (%lu words)\n",
           (unsigned long)(stats._0 + stats._1), (unsigned long)comp_len);
    printf("  Literals:    %lu\n", (unsigned long)stats._0);
    printf("  References:  %lu\n", (unsigned long)stats._1);
    printf("  Effective:   %lu bytes (%.1f%% of original)\n",
           (unsigned long)comp_size,
           input_len > 0 ? (100.0 * comp_size / input_len) : 0.0);

    /* Decompress and verify roundtrip */
    uint64_t *decompressed = (uint64_t *)calloc(input_len + 100, sizeof(uint64_t));
    forge_span_u64_t decomp_span = { decompressed, input_len + 100 };

    uint64_t decomp_len = decompress(comp_view, comp_len,
                                      decomp_span, input_len + 100);

    printf("\nDecompressed: %lu bytes\n", (unsigned long)decomp_len);

    /* Verify roundtrip */
    int match = 1;
    if (decomp_len != (uint64_t)input_len) {
        match = 0;
        printf("  LENGTH MISMATCH: got %lu, expected %d\n",
               (unsigned long)decomp_len, input_len);
    } else {
        for (int i = 0; i < input_len; i++) {
            if (decompressed[i] != input[i]) {
                match = 0;
                printf("  MISMATCH at byte %d: got %lu, expected %lu\n",
                       i, (unsigned long)decompressed[i], (unsigned long)input[i]);
                break;
            }
        }
    }

    if (match) {
        printf("  Roundtrip: PERFECT MATCH ✓\n");
    } else {
        printf("  Roundtrip: FAILED ✗\n");
    }

    /* Print some compressed tokens for inspection */
    printf("\nFirst 10 tokens:\n");
    uint64_t ti = 0;
    int shown = 0;
    while (ti < comp_len && shown < 10) {
        if (compressed[ti] == 0 && ti + 1 < comp_len) {
            printf("  LIT '%c'\n", (char)compressed[ti + 1]);
            ti += 2;
        } else if (compressed[ti] == 1 && ti + 2 < comp_len) {
            printf("  REF offset=%lu length=%lu\n",
                   (unsigned long)compressed[ti + 1],
                   (unsigned long)compressed[ti + 2]);
            ti += 3;
        } else {
            break;
        }
        shown++;
    }

    printf("\nAll compression performed by verified code — zero buffer overflow risk.\n");

    free(input);
    free(compressed);
    free(decompressed);
}

static void compress_file(const char *inpath, const char *outpath) {
    FILE *fin = fopen(inpath, "rb");
    if (!fin) { fprintf(stderr, "Cannot open %s\n", inpath); exit(1); }
    fseek(fin, 0, SEEK_END);
    long fsize = ftell(fin);
    fseek(fin, 0, SEEK_SET);

    uint64_t *input = (uint64_t *)malloc(fsize * sizeof(uint64_t));
    for (long i = 0; i < fsize; i++) {
        int b = fgetc(fin);
        input[i] = (b == EOF) ? 0 : (uint64_t)b;
    }
    fclose(fin);

    long out_cap = fsize * 3;
    uint64_t *output = (uint64_t *)calloc(out_cap, sizeof(uint64_t));

    forge_span_u64_t in_span = { input, fsize };
    forge_span_u64_t out_span = { output, out_cap };

    uint64_t comp_len = compress(in_span, fsize, out_span, out_cap,
                                  WINDOW_SIZE, MIN_MATCH, MAX_MATCH);

    FILE *fout = fopen(outpath, "wb");
    if (!fout) { fprintf(stderr, "Cannot write %s\n", outpath); exit(1); }
    /* Write token stream as raw uint64_t values */
    fwrite(&fsize, sizeof(long), 1, fout);
    fwrite(&comp_len, sizeof(uint64_t), 1, fout);
    for (uint64_t i = 0; i < comp_len; i++) {
        uint8_t b = (uint8_t)(output[i] & 0xFF);
        uint64_t val = output[i];
        fwrite(&val, sizeof(uint64_t), 1, fout);
    }
    fclose(fout);

    forge_span_u64_t cv = { output, comp_len };
    __forge_tuple_u64_u64_t st = count_tokens(cv, comp_len);

    printf("Compressed %s → %s\n", inpath, outpath);
    printf("  Input:  %ld bytes\n", fsize);
    printf("  Output: %lu tokens (%lu literals, %lu refs)\n",
           (unsigned long)(st._0 + st._1),
           (unsigned long)st._0, (unsigned long)st._1);

    free(input);
    free(output);
}

static void decompress_file(const char *inpath, const char *outpath) {
    FILE *fin = fopen(inpath, "rb");
    if (!fin) { fprintf(stderr, "Cannot open %s\n", inpath); exit(1); }

    long orig_size;
    uint64_t comp_len;
    fread(&orig_size, sizeof(long), 1, fin);
    fread(&comp_len, sizeof(uint64_t), 1, fin);

    uint64_t *tokens = (uint64_t *)malloc(comp_len * sizeof(uint64_t));
    for (uint64_t i = 0; i < comp_len; i++)
        fread(&tokens[i], sizeof(uint64_t), 1, fin);
    fclose(fin);

    uint64_t *output = (uint64_t *)calloc(orig_size + 100, sizeof(uint64_t));
    forge_span_u64_t tok_span = { tokens, comp_len };
    forge_span_u64_t out_span = { output, orig_size + 100 };

    uint64_t decomp_len = decompress(tok_span, comp_len, out_span, orig_size + 100);

    FILE *fout = fopen(outpath, "wb");
    if (!fout) { fprintf(stderr, "Cannot write %s\n", outpath); exit(1); }
    for (uint64_t i = 0; i < decomp_len; i++)
        fputc((int)(output[i] & 0xFF), fout);
    fclose(fout);

    printf("Decompressed %s → %s (%lu bytes)\n", inpath, outpath,
           (unsigned long)decomp_len);

    free(tokens);
    free(output);
}

int main(int argc, char **argv) {
    if (argc >= 4 && strcmp(argv[1], "-c") == 0) {
        compress_file(argv[2], argv[3]);
    } else if (argc >= 4 && strcmp(argv[1], "-d") == 0) {
        decompress_file(argv[2], argv[3]);
    } else {
        run_demo();
    }
    return 0;
}
