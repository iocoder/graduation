ENTRY(start)

SECTIONS {

	. = 0x00000000;

        .entry  : {*(.entry )}
	.text   : {*(.text  )}
	.rodata : {*(.rodata)}

	. = 0x00010000;
	.bss    : {*(.bss COMMON)}

}
