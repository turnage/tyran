.global _start

.set MULTIBOOT2C, 0xe85250d6
.set ARCH, 0 # Protected mode
.set HEADER_SIZE, (header_end - header_start)
.set MIDCHECKSUM, MULTIBOOT2C + ARCH + HEADER_SIZE
.set CHECKSUM, 0x100000000 - MIDCHECKSUM

.section .multiboot
header_start:
.align 4
.long MULTIBOOT2C
.long ARCH
.long HEADER_SIZE
.long CHECKSUM

.short 0
.short 0
.long 8
header_end:

.section .bss
.align 16
stack_bottom:
.skip 16384
stack_top:

.section .text
_start:
	mov $stack_top, %esp
	call kernel_main
	hlt
