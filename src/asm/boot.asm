.global _start

.set MULTIBOOTC, 0x1badb002
.set FLAGS, 0
.set CHECKSUM, -(MULTIBOOTC + FLAGS)

.section .multiboot
.align 4
.long MULTIBOOTC
.long FLAGS
.long CHECKSUM

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
