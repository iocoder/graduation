CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

OBJECT_NAME   = coreutils
OBJECT_PREFIX = $(BIN_DIR)
LIBS          = -lc -lgcc
TARGETS       = umount mount rmdir mkdir rm unlink link mknod dir ls \
                cat cp reboot readsect
DEPS          = $(ALLHFILES) Makefile \
                $(KERNEL_INCLUDE) \
		$(LIBC_INCLUDE) \
		$(LIBC_LIB)

%.o: %.c $(DEPS)
	$(QCC) $(QCFLAGS) -c -o $@ $<

umount: umount.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

mount: mount.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

rmdir: rmdir.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

mkdir: mkdir.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

rm: rm.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

unlink: unlink.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

link: link.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

mknod: mknod.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

dir: dir.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

ls: ls.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

cat: cat.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

cp: cp.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

reboot: reboot.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

readsect: readsect.o
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $< $(LIBS)

install-exec-local:
	## $(INSTALL) -D umount       $(OBJECT_PREFIX)/umount
	## $(INSTALL) -D mount        $(OBJECT_PREFIX)/mount
	## $(INSTALL) -D rmdir        $(OBJECT_PREFIX)/rmdir
	## $(INSTALL) -D mkdir        $(OBJECT_PREFIX)/mkdir
	## $(INSTALL) -D rm           $(OBJECT_PREFIX)/rm
	## $(INSTALL) -D unlink       $(OBJECT_PREFIX)/unlink
	## $(INSTALL) -D link         $(OBJECT_PREFIX)/link
	## $(INSTALL) -D mknod        $(OBJECT_PREFIX)/mknod
	## $(INSTALL) -D dir          $(OBJECT_PREFIX)/dir
	$(INSTALL) -D ls           $(OBJECT_PREFIX)/ls
	## $(INSTALL) -D cat          $(OBJECT_PREFIX)/cat
	## $(INSTALL) -D cp           $(OBJECT_PREFIX)/cp
	## $(INSTALL) -D reboot       $(OBJECT_PREFIX)/reboot
	## $(INSTALL) -D readsect     $(OBJECT_PREFIX)/readsect
	## $(INSTALL) -D $(CSD)/free  $(OBJECT_PREFIX)/free
	## $(INSTALL) -D $(CSD)/lsdev $(OBJECT_PREFIX)/lsdev

uninstall-local:
	rm -f $(OBJECT_PREFIX)/umount
	rm -f $(OBJECT_PREFIX)/mount
	rm -f $(OBJECT_PREFIX)/rmdir
	rm -f $(OBJECT_PREFIX)/mkdir
	rm -f $(OBJECT_PREFIX)/rm
	rm -f $(OBJECT_PREFIX)/unlink
	rm -f $(OBJECT_PREFIX)/link
	rm -f $(OBJECT_PREFIX)/mknod
	rm -f $(OBJECT_PREFIX)/dir
	rm -f $(OBJECT_PREFIX)/ls
	rm -f $(OBJECT_PREFIX)/cat
	rm -f $(OBJECT_PREFIX)/cp
	rm -f $(OBJECT_PREFIX)/reboot
	rm -f $(OBJECT_PREFIX)/readsect
	rm -f $(OBJECT_PREFIX)/free
	rm -f $(OBJECT_PREFIX)/lsdev
	- $(call REMOVE_EMPTY_DIR, $(prefix))

all-local: $(TARGETS)

clean-local:
	rm -f $(OBJ) $(TARGETS)
