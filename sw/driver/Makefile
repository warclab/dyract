# You must specify the following variables. You can leave the defaults if you
# like, but make sure they will work in your system.
# The VENDOR_ID and DEVICE_ID _must_ match what is configured on your FPGA's
# PCIe endpoint header (e.g. Xilinx ML506 is VENDOR_ID, DEVICE_ID = 10EE, 0506).
NAME := fpga
VENDOR_ID := 10EE
DEVICE_ID := 0509
MAJNUM := 100

# Build variables
KVER := $(shell uname -r)
KDIR := /lib/modules/`uname -r`/build
RHR := /etc/redhat-release

obj-m += $(NAME).o
$(NAME)-y := fpga_driver.o circ_queue.o

# Helper functions
define assert
  $(if $1,,$(error Assertion failed: $2))
endef
define assert-not-null
  $(call assert,$($1),The variable "$1" is null, please specify it.)
endef
define assert-variables
	$(call assert-not-null,NAME)
	$(call assert-not-null,MAJNUM)
	$(call assert-not-null,VENDOR_ID)
	$(call assert-not-null,DEVICE_ID)
	@printf "Compiling driver for kernel: %s with the following values\n" $(KVER)
	@printf "     NAME: '%s'\n" $(NAME)
	@printf "   MAJNUM: '%s'\n" $(MAJNUM)
	@printf "VENDOR_ID: '%s'\n" $(VENDOR_ID)
	@printf "DEVICE_ID: '%s'\n" $(DEVICE_ID)
	@printf "\n"
endef

default: $(NAME).ko

$(NAME).ko:
	$(call assert-variables)
	sed -i 's/#define MAJOR_NUM [^\n]*/#define MAJOR_NUM $(MAJNUM)/g' fpga_driver.h
	sed -i 's/#define DEVICE_NAME [^\n]*/#define DEVICE_NAME "$(NAME)"/g' fpga_driver.h
	sed -i 's/#define VENDOR_ID [^\n]*/#define VENDOR_ID 0x$(VENDOR_ID)/g' fpga_driver.h
	sed -i 's/#define DEVICE_ID [^\n]*/#define DEVICE_ID 0x$(DEVICE_ID)/g' fpga_driver.h
	make -C $(KDIR) SUBDIRS=`pwd` modules

load: build
	insmod $(NAME).ko
	
unload:
	rmmod $(NAME)

clean:
	rm -Rf *.ko *.cmd *.o .*.cmd Module.symvers Module.markers modules.order *.mod.c .tmp_versions

setup:
	if [ -f "$(RHR)" ]; then yum install kernel-devel-`uname -r`;\
	else apt-get install linux-headers-`uname -r`; fi

install: $(NAME).ko
	mkdir -p /lib/modules/$(KVER)/kernel/drivers/fpga
	cp $(NAME).ko /lib/modules/$(KVER)/kernel/drivers/fpga/
	if [ -f "$(RHR)" ]; then\
		printf "%b\n" "#!/bin/sh\nexec /sbin/modprobe $(NAME) >/dev/null 2>&1" > /etc/sysconfig/modules/fpga.modules;\
		chmod 755 /etc/sysconfig/modules/fpga.modules;\
	else\
		if ! grep -Fxq "$(NAME)" /etc/modules; then echo "$(NAME)" >> /etc/modules; fi;\
	fi
	printf "%b\n" "KERNEL==\"$(NAME)\", MODE=\"777\", GROUP=\"root\"" > /etc/udev/rules.d/99-$(NAME).rules
	cp fpga_driver.h /usr/include/
	cp fpga.h /usr/include/
	depmod

uninstall: 
	rm -rf /lib/modules/$(KVER)/kernel/drivers/fpga
	rm -f /etc/udev/rules.d/99-$(NAME).rules
	rm -f /usr/include/fpga_driver.h
	if [ -f "$(RHR)" ]; then rm -f /etc/sysconfig/modules/fpga.modules;\
	else cp /etc/modules ./etc.modules.bak; sed -i '/$(NAME)/d' /etc/modules; fi
	depmod


