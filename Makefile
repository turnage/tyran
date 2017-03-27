.PHONY: all clean cargo debug iso

OUTDIR:=target
TARGET:=x86_64-unknown-tyran-gnu
CFLAGS:=-ffreestanding -nostdlib -lc
MODE:=release

all: iso

iso: ${OUTDIR}/kernel.iso

cargo: ${OUTDIR}/libboot.a
	xargo build --release --target ${TARGET} --verbose
	grub-file --is-x86-multiboot2 ${OUTDIR}/${TARGET}/${MODE}/tyran

run: iso
	qemu-system-i386 -cdrom ${OUTDIR}/kernel.iso -curses -s

clean:
	-rm -rf target

${OUTDIR}:
	mkdir target

${OUTDIR}/boot.o: src/asm/boot.asm ${OUTDIR}
	nasm -felf64 src/asm/boot.asm -o ${OUTDIR}/boot.o -ggdb
	grub-file --is-x86-multiboot2 ${OUTDIR}/boot.o

${OUTDIR}/libboot.a: ${OUTDIR}/boot.o
	ar crus ${OUTDIR}/libboot.a ${OUTDIR}/boot.o
	grub-file --is-x86-multiboot2 ${OUTDIR}/libboot.a

${OUTDIR}/kernel.iso: cargo src/res/grub.cfg
	mkdir -p ${OUTDIR}/iso/boot/grub
	cp src/res/grub.cfg ${OUTDIR}/iso/boot/grub
	cp ${OUTDIR}/${TARGET}/${MODE}/tyran ${OUTDIR}/iso/boot
	grub-mkrescue -o ${OUTDIR}/kernel.iso ${OUTDIR}/iso
