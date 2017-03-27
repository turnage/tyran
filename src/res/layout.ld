ENTRY(_start)

SECTIONS {
	. = 1M;

	.boot : {
		KEEP(*(.boot))
	}

	.text : {
		*(.text)
	}

	.rodata : {
		*(.rodata)
	}

	.data : {
		*(.data)
	}

	.bss : {
		*(COMMON)
		*(.bss)
	}

	/DISCARD/ : {
		*(.note.gnu.*)
	}
}
