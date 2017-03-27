MULTIBOOT2C equ 0xe85250d6
ARCH equ 0 ; Protected mode
HEADER_SIZE equ (header_end - header_start)
MIDCHECKSUM equ (MULTIBOOT2C + ARCH + HEADER_SIZE)
CHECKSUM equ (0x100000000 - MIDCHECKSUM)

section .boot
header_start:
	dd  MULTIBOOT2C
	dd  ARCH
	dd  HEADER_SIZE
	dd  CHECKSUM

	dw 0
	dw 0
	dd 8
header_end:

section .bss
; Stack
align 16
stack_bottom:
	resb 16384
stack_top:

; Page tables (first 1GB)
align 4096
pml4:
	resb 4096
pdpt:
	resb 4096
pdt:
	resb 4096

section .text


global _start
_start:
	mov esp, stack_top
	extern kernel_main
	call kernel_main
	hlt

init_paging:
	PRESENT equ 0b1
	WRITEABLE equ 0b10
	DEFAULT_FLAGS equ (PRESENT + WRITEABLE)
	HUGE_PAGE equ 0b10000000

	mov eax, pdpt
	or eax, 0b11
	mov [pml4], eax

	mov eax, pdt
	or eax, 0b11
	mov [pdt], eax

.map_pdt:
	mov eax, 0x200000
	mul ecx
	or eax, 0b1000011

	ret
