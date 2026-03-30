/* Verified Ring Buffer IPC — real-world driver
 *
 * Demonstrates a producer-consumer message queue.
 * All queue operations are proven safe by Z3.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#define main forge_main_unused
#include "ringbuf.c"
#undef main

int main(void) {
    printf("=== Forge Verified Ring Buffer IPC ===\n\n");

    /* Create a ring buffer with capacity 64 */
    uint64_t buffer[64];
    int cap = 64;
    forge_span_u64_t buf_span = { buffer, cap };

    ring_init(buf_span, cap);

    uint64_t head = 0, tail = 0, count = 0;

    printf("--- Producer: writing messages ---\n");

    /* Message 1: "HELLO" as bytes */
    uint64_t msg1[] = { 'H', 'E', 'L', 'L', 'O' };
    forge_span_u64_t m1 = { msg1, 5 };
    __forge_tuple_u64_u64_t w1 = ring_write(buf_span, cap, tail, count, m1, 5);
    tail = w1._0; count = w1._1;
    printf("  Wrote 'HELLO' (5 bytes), count=%lu, tail=%lu\n",
           (unsigned long)count, (unsigned long)tail);

    /* Message 2: "WORLD" */
    uint64_t msg2[] = { 'W', 'O', 'R', 'L', 'D' };
    forge_span_u64_t m2 = { msg2, 5 };
    __forge_tuple_u64_u64_t w2 = ring_write(buf_span, cap, tail, count, m2, 5);
    tail = w2._0; count = w2._1;
    printf("  Wrote 'WORLD' (5 bytes), count=%lu, tail=%lu\n",
           (unsigned long)count, (unsigned long)tail);

    /* Message 3: sequence 0-19 */
    uint64_t msg3[20];
    for (int i = 0; i < 20; i++) msg3[i] = (uint64_t)i;
    forge_span_u64_t m3 = { msg3, 20 };
    __forge_tuple_u64_u64_t w3 = ring_write(buf_span, cap, tail, count, m3, 20);
    tail = w3._0; count = w3._1;
    printf("  Wrote sequence 0-19 (20 bytes), count=%lu, tail=%lu\n",
           (unsigned long)count, (unsigned long)tail);

    uint64_t avail = ring_available(cap, count);
    printf("  Available space: %lu / %d\n\n", (unsigned long)avail, cap);

    /* Consumer: read messages */
    printf("--- Consumer: reading messages ---\n");

    uint64_t out_buf[64];
    forge_span_u64_t out_span = { out_buf, 64 };

    /* Read 5 bytes (should get "HELLO") */
    __forge_tuple_u64_u64_u64_t r1 = ring_read(buf_span, cap, head, count, out_span, 5);
    head = r1._0; count = r1._1;
    printf("  Read %lu bytes: '", (unsigned long)r1._2);
    for (uint64_t i = 0; i < r1._2; i++) printf("%c", (char)out_buf[i]);
    printf("', count=%lu\n", (unsigned long)count);

    /* Read 5 bytes (should get "WORLD") */
    __forge_tuple_u64_u64_u64_t r2 = ring_read(buf_span, cap, head, count, out_span, 5);
    head = r2._0; count = r2._1;
    printf("  Read %lu bytes: '", (unsigned long)r2._2);
    for (uint64_t i = 0; i < r2._2; i++) printf("%c", (char)out_buf[i]);
    printf("', count=%lu\n", (unsigned long)count);

    /* Read 20 bytes (should get sequence) */
    __forge_tuple_u64_u64_u64_t r3 = ring_read(buf_span, cap, head, count, out_span, 20);
    head = r3._0; count = r3._1;
    printf("  Read %lu bytes: [", (unsigned long)r3._2);
    for (uint64_t i = 0; i < r3._2 && i < 10; i++)
        printf("%lu%s", (unsigned long)out_buf[i], i < r3._2-1 && i < 9 ? "," : "");
    if (r3._2 > 10) printf(",...");
    printf("], count=%lu\n", (unsigned long)count);

    /* Test wrap-around: fill most of the buffer, read some, write more */
    printf("\n--- Wrap-around test ---\n");
    uint64_t fill_data[50];
    for (int i = 0; i < 50; i++) fill_data[i] = (uint64_t)(i + 100);
    forge_span_u64_t fill_span = { fill_data, 50 };

    __forge_tuple_u64_u64_t w4 = ring_write(buf_span, cap, tail, count, fill_span, 50);
    tail = w4._0; count = w4._1;
    printf("  Wrote 50 bytes, count=%lu, tail=%lu\n",
           (unsigned long)count, (unsigned long)tail);

    __forge_tuple_u64_u64_u64_t r4 = ring_read(buf_span, cap, head, count, out_span, 30);
    head = r4._0; count = r4._1;
    printf("  Read 30 bytes, count=%lu, head=%lu\n",
           (unsigned long)count, (unsigned long)head);

    /* Write across the boundary */
    uint64_t wrap_data[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE };
    forge_span_u64_t wrap_span = { wrap_data, 6 };
    __forge_tuple_u64_u64_t w5 = ring_write(buf_span, cap, tail, count, wrap_span, 6);
    tail = w5._0; count = w5._1;
    printf("  Wrote 6 bytes across boundary, count=%lu, tail=%lu\n",
           (unsigned long)count, (unsigned long)tail);

    printf("\nAll IPC operations performed by verified code — zero buffer overflow risk.\n");
    return 0;
}
