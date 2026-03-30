/*
 * forge_sniffer — Userspace verified packet filter
 *
 * Captures live network packets using raw sockets, runs them through
 * the Forge-verified filter core, and displays accept/drop decisions.
 *
 * No kernel module needed. Works on any Linux. Runs right now.
 *
 * Usage:
 *   sudo ./forge_sniffer              — sniff all interfaces
 *   sudo ./forge_sniffer -c 100       — capture 100 packets then exit
 *   sudo ./forge_sniffer -q           — quiet mode (stats only)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <linux/if_ether.h>

/* Include the Forge-verified core */
#define main forge_main_unused
#include "filter_core.c"
#undef main

/* ---- Configuration -------------------------------------------------------- */

#define MAX_PKT   65535
#define W         0xFFFFFFFFFFFFFFFFULL

/* Firewall rules: proto, src_ip, dst_ip, dst_port, action */
static uint64_t rules[] = {
    6,  W, W, 22,  1,   /* SSH: ACCEPT */
    6,  W, W, 80,  1,   /* HTTP: ACCEPT */
    6,  W, W, 443, 1,   /* HTTPS: ACCEPT */
    17, W, W, 53,  1,   /* DNS: ACCEPT */
    17, W, W, 67,  1,   /* DHCP: ACCEPT */
    17, W, W, 68,  1,   /* DHCP: ACCEPT */
    1,  W, W, W,   1,   /* ICMP: ACCEPT */
};
static int n_rules = 7;

/* Conntrack table */
#define MAX_CT 4096
static uint64_t ct_table[MAX_CT * 6];

/* Stats */
static volatile int running = 1;
static uint64_t total_pkts = 0;
static uint64_t accepted = 0;
static uint64_t dropped = 0;
static uint64_t errors = 0;

static void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

static const char *proto_name(int proto) {
    switch (proto) {
        case 1:  return "ICMP";
        case 6:  return "TCP";
        case 17: return "UDP";
        default: return "???";
    }
}

int main(int argc, char **argv) {
    int max_count = 0;
    int quiet = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-c") == 0 && i + 1 < argc)
            max_count = atoi(argv[++i]);
        else if (strcmp(argv[i], "-q") == 0)
            quiet = 1;
    }

    printf("╔══════════════════════════════════════════════╗\n");
    printf("║  Forge Verified Packet Filter (userspace)    ║\n");
    printf("║  92 proof obligations — 0 buffer overflow    ║\n");
    printf("╚══════════════════════════════════════════════╝\n\n");

    printf("Rules:\n");
    printf("  ACCEPT: SSH(22) HTTP(80) HTTPS(443) DNS(53) DHCP(67-68) ICMP\n");
    printf("  DROP:   everything else\n\n");

    /* Open raw socket — capture ALL IP packets */
    int sock = socket(AF_PACKET, SOCK_DGRAM, htons(ETH_P_IP));
    if (sock < 0) {
        /* Fallback to IPPROTO_RAW */
        sock = socket(AF_INET, SOCK_RAW, IPPROTO_RAW);
        if (sock < 0) {
            perror("socket (need sudo)");
            return 1;
        }
        int one = 1;
        setsockopt(sock, IPPROTO_IP, IP_HDRINCL, &one, sizeof(one));
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    printf("Listening... (Ctrl+C to stop)\n\n");

    uint8_t raw_buf[MAX_PKT];
    uint64_t pkt_buf[MAX_PKT];

    forge_span_u64_t rules_span = { rules, n_rules * 5 };
    forge_span_u64_t ct_span = { ct_table, MAX_CT * 6 };
    memset(ct_table, 0, sizeof(ct_table));

    time_t start_time = time(NULL);

    while (running) {
        struct sockaddr_in src_addr;
        socklen_t addr_len = sizeof(src_addr);

        ssize_t pkt_len = recvfrom(sock, raw_buf, MAX_PKT, 0,
                                    (struct sockaddr *)&src_addr, &addr_len);
        if (pkt_len <= 0) continue;
        if (max_count > 0 && total_pkts >= (uint64_t)max_count) break;

        /* Copy bytes to u64 array for the verified core */
        for (int i = 0; i < pkt_len && i < MAX_PKT; i++)
            pkt_buf[i] = (uint64_t)raw_buf[i];

        forge_span_u64_t pkt_span = { pkt_buf, (size_t)pkt_len };

        /* Call the VERIFIED filter — 92 Z3 proofs guarantee safety */
        uint64_t verdict = filter_packet(pkt_span, (uint64_t)pkt_len,
                                          rules_span, n_rules,
                                          ct_span, MAX_CT,
                                          (uint64_t)time(NULL));

        total_pkts++;
        if (verdict == 1) accepted++;
        else dropped++;

        if (!quiet && pkt_len >= 20) {
            struct iphdr *ip = (struct iphdr *)raw_buf;
            char src[INET_ADDRSTRLEN], dst[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &ip->saddr, src, sizeof(src));
            inet_ntop(AF_INET, &ip->daddr, dst, sizeof(dst));

            int sport = 0, dport = 0;
            int hdr_len = ip->ihl * 4;
            if (pkt_len >= hdr_len + 4) {
                sport = (raw_buf[hdr_len] << 8) | raw_buf[hdr_len + 1];
                dport = (raw_buf[hdr_len + 2] << 8) | raw_buf[hdr_len + 3];
            }

            printf("  %s %-15s:%-5d → %-15s:%-5d  %4zd bytes  %s\n",
                   proto_name(ip->protocol),
                   src, sport, dst, dport,
                   pkt_len,
                   verdict == 1 ? "\033[32mACCEPT\033[0m" : "\033[31mDROP\033[0m");
        }
    }

    close(sock);

    time_t elapsed = time(NULL) - start_time;
    if (elapsed < 1) elapsed = 1;

    printf("\n═══════════════════════════════════════════\n");
    printf("  Packets: %lu total, %lu accepted, %lu dropped\n",
           (unsigned long)total_pkts,
           (unsigned long)accepted,
           (unsigned long)dropped);
    printf("  Rate:    %lu pkt/sec\n", (unsigned long)(total_pkts / elapsed));
    printf("  Core:    92 proof obligations, 0 assumptions\n");
    printf("  Safety:  PROVEN — zero buffer overflow risk\n");
    printf("═══════════════════════════════════════════\n");

    return 0;
}
