PHONY: all run clean cargo debug

OUTDIR:=target
TARGET:=x86_64-unknown-tyran-gnu
CFLAGS:=-ffreestanding -nostdlib -lc
MODE:=release

iso: ${OUTDIR}/kernel.iso

cargo: ${OUTDIR}/libboot.a ${OUTDIR}/kernel.o
	xargo build --release --target ${TARGET} --verbose
	grub-file --is-x86-multiboot ${OUTDIR}/${TARGET}/${MODE}/tyran

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

${OUTDIR}/kernel.o: src/kernel.c ${OUTDIR}
	clang --target=${TARGET} ${CFLAGS} -c src/kernel.c -o ${OUTDIR}/kernel.o -ggdb

${OUTDIR}/kernel.bin: ${OUTDIR}/kernel.o ${OUTDIR}/boot.o layout.ld
	clang --target=${TARGET} ${CFLAGS} ${OUTDIR}/boot.o ${OUTDIR}/kernel.o \
		-T layout.ld -o ${OUTDIR}/kernel.bin
	grub-file --is-x86-multiboot ${OUTDIR}/kernel.bin

${OUTDIR}/kernel.iso: cargo grub.cfg
	mkdir -p ${OUTDIR}/iso/boot/grub
	cp grub.cfg ${OUTDIR}/iso/boot/grub
	cp ${OUTDIR}/${TARGET}/${MODE}/tyran ${OUTDIR}/iso/boot
	grub-mkrescue -o ${OUTDIR}/kernel.iso ${OUTDIR}/iso
