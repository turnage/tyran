PHONY: all run clean cargo debug

OUTDIR:=target
TARGET:=x86_64-unknown-tyran-gnu
CFLAGS:=-ffreestanding -nostdlib -lc
MODE:=release

iso: ${OUTDIR}/kernel.iso

cargo: ${OUTDIR}/libboot.a
	xargo build --release --target ${TARGET} --verbose
	grub-file --is-x86-multiboot2 ${OUTDIR}/${TARGET}/${MODE}/tyran

run: iso
	qemu-system-i386 -cdrom ${OUTDIR}/kernel.iso -curses

debug: iso
	qemu-system-i386 -cdrom ${OUTDIR}/kernel.iso -curses -s

clean:
	-rm -rf target

${OUTDIR}:
	mkdir target

${OUTDIR}/boot.o: src/asm/boot.asm ${OUTDIR}
	clang --target=${TARGET} -c src/asm/boot.asm -o ${OUTDIR}/boot.o -ggdb

${OUTDIR}/libboot.a: ${OUTDIR}/boot.o
	ar crus ${OUTDIR}/libboot.a ${OUTDIR}/boot.o

${OUTDIR}/kernel.iso: cargo grub.cfg
	mkdir -p ${OUTDIR}/iso/boot/grub
	cp grub.cfg ${OUTDIR}/iso/boot/grub
	cp ${OUTDIR}/${TARGET}/${MODE}/tyran ${OUTDIR}/iso/boot
	grub-mkrescue -o ${OUTDIR}/kernel.iso ${OUTDIR}/iso
