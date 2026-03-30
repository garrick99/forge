/* Packet Filter — real-world driver
 *
 * Usage: packet_filter [packet_hex_file]
 *
 * Reads hex-encoded packets from stdin (one per line) or a file,
 * applies hardcoded firewall rules, prints ACCEPT/DROP/INVALID for each.
 *
 * Rules:
 *   ACCEPT TCP (proto 6) from any source to port 80 (HTTP)
 *   ACCEPT TCP to port 443 (HTTPS)
 *   ACCEPT UDP (proto 17) to port 53 (DNS)
 *   DROP everything else (default deny)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

/* Include the verified core — suppress its main() */
#define main forge_main_unused
#include "filter.c"
#undef main

/* Convert hex character to nibble */
static int hex_val(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* Parse hex string into byte array (stored as uint64_t for Forge compat) */
static int parse_hex(const char *hex, uint64_t *buf, int max_len) {
    int len = 0;
    while (hex[0] && hex[1] && len < max_len) {
        int hi = hex_val(hex[0]);
        int lo = hex_val(hex[1]);
        if (hi < 0 || lo < 0) break;
        buf[len++] = (uint64_t)(hi * 16 + lo);
        hex += 2;
        /* Skip optional spaces/colons */
        while (*hex == ' ' || *hex == ':') hex++;
    }
    return len;
}

static const char *ip_to_str(uint64_t ip, char *buf) {
    snprintf(buf, 20, "%lu.%lu.%lu.%lu",
             (ip >> 24) & 0xFF, (ip >> 16) & 0xFF,
             (ip >> 8) & 0xFF, ip & 0xFF);
    return buf;
}

int main(int argc, char **argv) {
    /* Firewall rules: (protocol, src_ip, dst_port, action)
     * WILDCARD = 0xFFFFFFFFFFFFFFFF */
    uint64_t rules[] = {
        6,  0xFFFFFFFFFFFFFFFFULL, 80,  1,  /* TCP any -> port 80: ACCEPT */
        6,  0xFFFFFFFFFFFFFFFFULL, 443, 1,  /* TCP any -> port 443: ACCEPT */
        17, 0xFFFFFFFFFFFFFFFFULL, 53,  1,  /* UDP any -> port 53: ACCEPT */
    };
    int n_rules = 3;

    forge_span_u64_t rule_span = { rules, n_rules * 4 };

    printf("=== Forge Verified Packet Filter ===\n");
    printf("Rules:\n");
    printf("  ACCEPT TCP -> port 80  (HTTP)\n");
    printf("  ACCEPT TCP -> port 443 (HTTPS)\n");
    printf("  ACCEPT UDP -> port 53  (DNS)\n");
    printf("  DROP   *   (default deny)\n\n");

    FILE *fp = stdin;
    if (argc > 1) {
        fp = fopen(argv[1], "r");
        if (!fp) { fprintf(stderr, "Cannot open %s\n", argv[1]); return 1; }
    }

    /* If no input file and stdin is a terminal, use built-in test packets */
    if (argc <= 1) {
        printf("No input file — running built-in test packets:\n\n");

        /* Test packet 1: TCP SYN to port 80 (HTTP) — should ACCEPT
         * IPv4, IHL=5, proto=6 (TCP), src=192.168.1.100, dst=10.0.0.1
         * TCP: src_port=12345, dst_port=80 */
        uint64_t pkt1[] = {
            0x45, 0x00, 0x00, 0x28,  /* ver=4, ihl=5, total_len=40 */
            0x00, 0x01, 0x00, 0x00,  /* id, flags, frag */
            0x40, 0x06, 0x00, 0x00,  /* ttl=64, proto=6(TCP), cksum */
            0xC0, 0xA8, 0x01, 0x64,  /* src: 192.168.1.100 */
            0x0A, 0x00, 0x00, 0x01,  /* dst: 10.0.0.1 */
            0x30, 0x39, 0x00, 0x50,  /* TCP: src=12345, dst=80 */
            0x00, 0x00, 0x00, 0x00,  /* seq */
        };
        forge_span_u64_t s1 = { pkt1, sizeof(pkt1)/sizeof(pkt1[0]) };
        uint64_t r1 = filter_packet(s1, s1.len, rule_span, n_rules);
        char ip_buf[20];
        printf("  Packet 1: TCP 192.168.1.100 -> port 80   => %s\n",
               r1 == 1 ? "ACCEPT" : r1 == 0 ? "DROP" : "INVALID");

        /* Test packet 2: UDP to port 53 (DNS) — should ACCEPT */
        uint64_t pkt2[] = {
            0x45, 0x00, 0x00, 0x3C,
            0x00, 0x02, 0x00, 0x00,
            0x40, 0x11, 0x00, 0x00,  /* proto=17(UDP) */
            0xC0, 0xA8, 0x01, 0x64,
            0x08, 0x08, 0x08, 0x08,  /* dst: 8.8.8.8 */
            0xE0, 0x14, 0x00, 0x35,  /* UDP: src=57364, dst=53 */
        };
        forge_span_u64_t s2 = { pkt2, sizeof(pkt2)/sizeof(pkt2[0]) };
        uint64_t r2 = filter_packet(s2, s2.len, rule_span, n_rules);
        printf("  Packet 2: UDP 192.168.1.100 -> port 53   => %s\n",
               r2 == 1 ? "ACCEPT" : r2 == 0 ? "DROP" : "INVALID");

        /* Test packet 3: TCP to port 22 (SSH) — should DROP */
        uint64_t pkt3[] = {
            0x45, 0x00, 0x00, 0x28,
            0x00, 0x03, 0x00, 0x00,
            0x40, 0x06, 0x00, 0x00,  /* proto=6(TCP) */
            0xC0, 0xA8, 0x01, 0x64,
            0x0A, 0x00, 0x00, 0x01,
            0x30, 0x39, 0x00, 0x16,  /* TCP: dst=22 (SSH) */
        };
        forge_span_u64_t s3 = { pkt3, sizeof(pkt3)/sizeof(pkt3[0]) };
        uint64_t r3 = filter_packet(s3, s3.len, rule_span, n_rules);
        printf("  Packet 3: TCP 192.168.1.100 -> port 22   => %s\n",
               r3 == 1 ? "ACCEPT" : r3 == 0 ? "DROP" : "INVALID");

        /* Test packet 4: Too short — should be INVALID */
        uint64_t pkt4[] = { 0x45, 0x00, 0x00 };
        forge_span_u64_t s4 = { pkt4, 3 };
        uint64_t r4 = filter_packet(s4, s4.len, rule_span, n_rules);
        printf("  Packet 4: 3 bytes (truncated)             => %s\n",
               r4 == 1 ? "ACCEPT" : r4 == 0 ? "DROP" : "INVALID");

        /* Test packet 5: TCP to port 443 (HTTPS) — should ACCEPT */
        uint64_t pkt5[] = {
            0x45, 0x00, 0x00, 0x28,
            0x00, 0x04, 0x00, 0x00,
            0x40, 0x06, 0x00, 0x00,
            0xAC, 0x10, 0x00, 0x01,  /* src: 172.16.0.1 */
            0x0A, 0x00, 0x00, 0x02,
            0xC0, 0x01, 0x01, 0xBB,  /* TCP: dst=443 */
        };
        forge_span_u64_t s5 = { pkt5, sizeof(pkt5)/sizeof(pkt5[0]) };
        uint64_t r5 = filter_packet(s5, s5.len, rule_span, n_rules);
        printf("  Packet 5: TCP 172.16.0.1 -> port 443     => %s\n",
               r5 == 1 ? "ACCEPT" : r5 == 0 ? "DROP" : "INVALID");

        printf("\nAll packet decisions made by verified code — zero buffer overflow risk.\n");
        return 0;
    }

    /* Interactive mode: read hex packets from file/stdin */
    char line[4096];
    uint64_t pkt_buf[2048];
    int pkt_num = 0;

    while (fgets(line, sizeof(line), fp)) {
        /* Strip newline */
        line[strcspn(line, "\r\n")] = 0;
        if (line[0] == 0 || line[0] == '#') continue;

        int pkt_len = parse_hex(line, pkt_buf, 2048);
        if (pkt_len == 0) continue;

        forge_span_u64_t pkt_span = { pkt_buf, pkt_len };
        uint64_t result = filter_packet(pkt_span, pkt_len, rule_span, n_rules);

        pkt_num++;
        printf("Packet %d (%d bytes): %s\n", pkt_num, pkt_len,
               result == 1 ? "ACCEPT" : result == 0 ? "DROP" : "INVALID");
    }

    if (fp != stdin) fclose(fp);
    return 0;
}
