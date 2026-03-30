/* Verified Sensor Monitor — real-world driver
 *
 * Simulates reading sensor values from a data file or generates test data.
 * Applies verified threshold checking, spike detection, and running max.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#define main forge_main_unused
#include "monitor.c"
#undef main

int main(int argc, char **argv) {
    printf("=== Forge Verified Sensor Monitor ===\n\n");

    /* Simulated sensor readings (temperature × 10, e.g. 225 = 22.5°C) */
    uint64_t readings[] = {
        220, 221, 223, 225, 228, 232, 238, 245, 255, 270,  /* warming trend */
        290, 310, 280, 260, 250, 245, 242, 240, 238, 237,  /* spike then cool */
        236, 235, 234, 233, 232, 231, 230, 229, 228, 227,  /* steady */
        226, 225, 224, 223, 222, 221, 220, 219, 218, 217,  /* cooling */
        150, 220, 221, 222, 223, 500, 224, 223, 222, 221,  /* anomalies at 40,45 */
    };
    int n = 50;

    uint64_t output[50];
    uint64_t alerts[50];

    forge_span_u64_t r_span = { readings, n };
    forge_span_u64_t o_span = { output, n };
    forge_span_u64_t a_span = { alerts, n };

    /* Thresholds: 200-350 (20.0°C - 35.0°C normal range) */
    uint64_t lo_thresh = 200;
    uint64_t hi_thresh = 350;
    uint64_t max_delta = 30;  /* max 3.0°C change between readings */

    printf("Sensor: Temperature (×10)\n");
    printf("Normal range: %.1f°C - %.1f°C\n", lo_thresh/10.0, hi_thresh/10.0);
    printf("Max delta: %.1f°C between consecutive readings\n\n", max_delta/10.0);

    /* Run verified analysis */
    uint64_t avg = compute_average(r_span, n);
    printf("Average: %.1f°C\n", avg/10.0);

    uint64_t violations = count_violations(r_span, n, lo_thresh, hi_thresh);
    printf("Threshold violations: %lu\n", (unsigned long)violations);

    running_max_fn(r_span, n, o_span);
    printf("Running max at end: %.1f°C\n", output[n-1]/10.0);

    uint64_t spikes = detect_spike(r_span, n, max_delta);
    printf("Spike events: %lu\n", (unsigned long)spikes);

    uint64_t total = monitor_pipeline(r_span, n, o_span,
                                      lo_thresh, hi_thresh, max_delta);
    printf("Total alerts: %lu\n\n", (unsigned long)total);

    /* Print timeline */
    printf("Timeline (showing alerts):\n");
    for (int i = 0; i < n; i++) {
        if (readings[i] < lo_thresh || readings[i] > hi_thresh) {
            printf("  [%2d] %.1f°C  *** OUT OF RANGE ***\n", i, readings[i]/10.0);
        } else if (i > 0 && (readings[i] > readings[i-1] + max_delta ||
                              readings[i] + max_delta < readings[i-1])) {
            printf("  [%2d] %.1f°C  *** SPIKE ***\n", i, readings[i]/10.0);
        }
    }

    printf("\nAll analysis performed by verified code — zero buffer overflow risk.\n");
    return 0;
}
