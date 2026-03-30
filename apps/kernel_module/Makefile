## Forge Verified Netfilter Module — Makefile
##
## Usage:
##   make                  — build the kernel module
##   sudo insmod forge_netfilter.ko — load it
##   dmesg | grep forge    — check status
##   sudo rmmod forge_netfilter     — unload
##
## Prerequisites:
##   - Linux kernel headers (apt install linux-headers-$(uname -r))
##   - Forge compiler (for regenerating filter_core.c from filter_core.fg)

obj-m += forge_netfilter.o
# Local stubs for stdint.h/stdbool.h/stdlib.h override userspace headers
# Suppress strict-prototype warnings from Forge-generated code (main() decl)
ccflags-y := -I$(M) -Wno-strict-prototypes

# Kernel build directory
KDIR ?= /lib/modules/$(shell uname -r)/build

# Forge compiler (only needed to regenerate the verified core)
FORGE ?= ../../_build/default/bin/main.exe

all: modules

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	rm -f filter_core.c

# Regenerate the verified C core from Forge source
verify:
	$(FORGE) build filter_core.fg

# Install the module
install:
	sudo insmod forge_netfilter.ko

# Unload the module
uninstall:
	sudo rmmod forge_netfilter

# Show module stats
stats:
	@dmesg | grep forge_netfilter | tail -5

.PHONY: all modules clean verify install uninstall stats
