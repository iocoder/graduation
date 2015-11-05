ENTRY(start)

SECTIONS {

        . = 0x00000000;
        .bss    : {*(.bss COMMON)}

	. = 0xC0000000;

        .entry  : {*(.entry )}
	.text   : {*(.text  )}
	.rodata : {*(.rodata)}


}
