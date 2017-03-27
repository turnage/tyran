extern kernel_main

section .boot
MULTIBOOT2C equ 0xe85250d6
ARCH equ 0 ; Protected mode
HEADER_SIZE equ (header_end - header_start)
MIDCHECKSUM equ (MULTIBOOT2C + ARCH + HEADER_SIZE)
CHECKSUM equ (0x100000000 - MIDCHECKSUM)
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
	call check_multiboot
	call check_cpuid
	call kernel_main
	hlt

; checks that the kernel was loaded by a multiboot bootloader.
check_multiboot:
	cmp eax, 0x36d76289 ; Multiboot writes this to eax when loading the kernel so that we can
			    ; look for the constant.
	jne .multiboot_error
	ret
.multiboot_error:
	mov eax, ERROR_MULTIBOOT
	jmp error

check_cpuid:
    pushfq
    pop rax ; Load RFLAGS into rax
    mov rcx, rax ; store a copy in rcx
    xor rax, 1 << 21 ; flip the 21st bit (CPUID)
    push rax
    popfq ; attempt to write it back with bit flipped
    pushfq
    pop rax ; read the value again to
    push rcx
    popfq ; write the old value back, in case our flip succeeded
    cmp rax, rcx ; compare the retrieved value with our copy; iff the bit flipped CPUID is supported
    je .cpuid_error
    ret
.cpuid_error:
    mov eax, ERROR_CPUID
    jmp error

; Prints an error code to the screen and halts.
ERROR_MULTIBOOT equ 0x4f554f4d
ERROR_CPUID equ 0x4f554f43
error:
	mov dword [0xb8000], 0x4f524f45
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov dword [0xb800c], eax
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
