extern kernel_main
bits 32

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
	call check_longmode
	call init_paging
	call enter_longmode
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
	pushfd
	pop eax ; Load RFLAGS into rax
	mov ecx, eax ; store a copy in rcx
	xor eax, 1 << 21 ; flip the 21st bit (CPUID)
	push eax
	popfd ; attempt to write it back with bit flipped
	pushfd
	pop eax ; read the value again to
	push ecx
	popfd ; write the old value back, in case our flip succeeded
	cmp eax, ecx ; compare the retrieved value with our copy; iff the bit flipped CPUID is supported
	je .cpuid_error
	ret
.cpuid_error:
	mov eax, ERROR_CPUID
	jmp error

check_longmode:
	mov eax, 0x80000000 ; request extended functions
	cpuid
	cmp eax, 0x80000004 ; if result is less than this, extended functions aren't supported
	jb .extended_func_error

	; see https://en.wikipedia.org/wiki/CPUID#EAX.3D80000000h:_Get_Highest_Extended_Function_Supported
	mov eax, 0x80000001 ; request extended processor info
	cpuid
	test edx, 1 << 29
	jz .longmode_error
	ret
.extended_func_error:
	mov eax, ERROR_EFUNC
	jmp error
.longmode_error:
	mov eax, ERROR_LONGMODE
	jmp error

; Prints an error code to the screen and halts.
ERROR_MULTIBOOT equ 0x4f554f4d ; "MU"
ERROR_CPUID equ 0x4f554f43 ; "CU"
ERROR_LONGMODE equ 0x4f4f4f4c ; "LO"
ERROR_EFUNC equ 0x4f464f45 ; "EF"
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
	HUGE_PAGE equ 0b1000000
	PAGE_SIZE equ 0x200000

	mov eax, pdpt
	or eax, DEFAULT_FLAGS
	mov [pml4], eax

	mov eax, pdt
	or eax, DEFAULT_FLAGS
	mov [pdpt], eax

	mov ecx, 0 ; page index
.map_pdt:
	mov eax, PAGE_SIZE
	mul ecx
	or eax, (HUGE_PAGE + DEFAULT_FLAGS)
	mov [pdt + ecx + 8], eax

	ret

enter_longmode:
	PHYS_ADDR_EXT equ 1 << 5
	EFER_MSR_CODE equ 0xc0000080
	LONG_MODE equ 1 << 8
	PAGING equ 1 << 31

	mov eax, pml4
	mov cr3, eax

	mov eax, cr4
	or eax, PHYS_ADDR_EXT
	mov cr4, eax

	mov ecx, EFER_MSR_CODE
	rdmsr
	or eax, LONG_MODE
	wrmrsr

	;mov eax, cr0
	;or eax, PAGING
	;mov cr0, eax

	ret
