SUBDIRS = boot nes tools

export ROOT_DIR=$(prefix)
export BOOT_DIR=$(prefix)/boot
export ETC_DIR=$(prefix)/etc
export DEV_DIR=$(prefix)/dev
export BIN_DIR=$(prefix)/bin
export USR_DIR=$(prefix)/usr
export USR_INC_DIR=$(USR_DIR)/include
export USR_LIB_DIR=$(USR_DIR)/lib
export OPT_DIR=$(prefix)/opt
export MNT_DIR=$(prefix)/mnt
export HOME_DIR=$(prefix)/home
export RUN_DIR=$(prefix)/run

export TSD=$(shell realpath $(top_srcdir))/quafios
export TBD=$(shell realpath $(top_builddir))/quafios

export QCC=mipsel-linux-gnu-gcc
export QAS=mipsel-linux-gnu-as
export QLD=mipsel-linux-gnu-ld
export QOC=mipsel-linux-gnu-objcopy

export QCFLAGS = -mno-abicalls -mips1 \
	  -fno-zero-initialized-in-bss -fno-stack-protector -fno-exceptions \
	  -ffunction-sections -fno-builtin -Wno-pointer-to-int-cast -Werror \
	  -nostartfiles -nostdlib -nodefaultlibs -nostdinc -pedantic \
	  -Wno-implicit-function-declaration -std=c89 \
	  -Iinclude \
	  -I$(TSD)/kernel/include \
	  -I$(TSD)/qlibc/include \
	  -I$(TSD)/gui/include

export QLFLAGS = -L$(TBD)/qlibc/lib -L$(TBD)/gui/lib

export KERNEL_INCLUDE = \
	$(shell find $(TSD)/kernel/include -name "*.h" 2>/dev/null)
export LIBC_INCLUDE   = \
	$(shell find $(TSD)/qlibc/include  -name "*.h" 2>/dev/null)
export LIBGUI_INCLUDE = \
	$(shell find $(TSD)/gui/include    -name "*.h" 2>/dev/null)
export LIBC_LIB       = \
	$(shell find $(TBD)/qlibc/lib      -name "*.a" 2>/dev/null)
export LIBGUI_LIB     = \
	$(shell find $(TBD)/gui/lib        -name "*.a" 2>/dev/null)

REMOVE_EMPTY_DIR=@SUBDIRS=;\
	IFS=$$'\n'; \
	v=$$(find $(1)/ -type d | tac);\
	for i in $$v; do rm -d $$i 2>/dev/null; done;

all-local:
	rm -rf $(TSD)/autom4*
	rm -rf $(TBD)/autom4*

clean-local:
	rm -rf $(TBD)/disk
	rm -rf $(TBD)/iso
	rm -f $(TBD)/disk.img
	rm -f $(TBD)/quafios-2.0.1.iso
	- $(call REMOVE_EMPTY_DIR, $(TBD))

install-exec-local:
	mkdir -p ${prefix}/dev
	mkdir -p ${prefix}/tmp
	mkdir -p ${prefix}/mnt
	mkdir -p ${prefix}/run
	mkdir -p ${prefix}/sys

uninstall-local:
	- rm -d ${prefix}

setup:
	make install prefix=`pwd`/disk
	$(TSD)/scripts/setup.sh

diskimg:
	make install prefix=`pwd`/disk
	mkdir -p `pwd`/iso
	dd if=/dev/zero of=disk.img bs=256K count=1 &> /dev/null
	echo -e "o\nn\np\n1\n63\n\na\nw\n" | fdisk disk.img > /dev/null
	tools/mkdiskfs disk disk.img $(shell uuidgen) 32256

isolive: diskimg
	gzip disk.img -c > iso/ramdisk.gz
	cp boot/isolive.bin iso/isolive.bin
	mkisofs -R -b isolive.bin -boot-info-table \
		-boot-load-size 4 -no-emul-boot -graft-points \
		-input-charset utf-8 -o quafios-2.0.1.iso iso/

qemu-iso: isolive
	srcdir=$(TSD) $(TSD)/scripts/qemu.sh d

qemu-disk: diskimg
	srcdir=$(TSD) $(TSD)/scripts/qemu.sh c

xen-iso: isolive
	srcdir=$(TSD) $(TSD)/scripts/xen.sh
