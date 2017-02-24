PHONY: all run clean

OUTDIR:=target
TARGET:=i686-unknown-none-eabihf
CFLAGS:=-ffreestanding -nostdlib -lc

${OUTDIR}:
	mkdir target

${OUTDIR}/boot.o: src/asm/boot.asm ${OUTDIR}
	clang --target=${TARGET} -c src/asm/boot.asm -o ${OUTDIR}/boot.o

${OUTDIR}/kernel.o: src/kernel.c ${OUTDIR}
	clang --target=${TARGET} ${CFLAGS} -c src/kernel.c -o ${OUTDIR}/kernel.o

${OUTDIR}/kernel.bin: ${OUTDIR}/kernel.o ${OUTDIR}/boot.o layout.ld
	clang --target=${TARGET} ${CFLAGS} ${OUTDIR}/boot.o ${OUTDIR}/kernel.o \
		-T layout.ld -o ${OUTDIR}/kernel.bin
	grub-file --is-x86-multiboot ${OUTDIR}/kernel.bin

${OUTDIR}/kernel.iso: ${OUTDIR}/kernel.bin grub.cfg
	mkdir -p ${OUTDIR}/iso/boot/grub
	cp grub.cfg ${OUTDIR}/iso/boot/grub
	cp ${OUTDIR}/kernel.bin ${OUTDIR}/iso/boot
	grub-mkrescue -o ${OUTDIR}/kernel.iso ${OUTDIR}/iso

all: ${OUTDIR}/kernel.iso

run: all
	qemu-system-i386 -cdrom ${OUTDIR}/kernel.iso -curses

clean:
	-rm -rf target
