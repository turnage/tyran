ENTRY(_start)

SECTIONS {
	. = 1M;

	.multiboot BLOCK(256) : ALIGN(32) {
		*(.multiboot)
	}

	.text BLOCK(0x1000) : ALIGN(0x1000) {
		*(.text)
	}

	.rodata BLOCK(0x1000) : ALIGN(0x1000) {
		*(.rodata)
	}

	.data BLOCK(0x1000) : ALIGN(0x1000) {
		*(.data)
	}

	.bss BLOCK(0x1000) : ALIGN(0x1000) {
		*(COMMON)
		*(.bss)
	}

	/DISCARD/ : {
		*(.note.gnu.*)
	}
}
