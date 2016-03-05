ENTRY(main)

SECTIONS {

	. = 0x80010000;

	kernel_physical_start = .;

	.text   : {*(.text.main .text)}
	.rodata : {*(.rodata         )}
	.data   : {*(.data           )}
	.bss    : {*(.bss COMMON     )}

	. = (. + 0xFFF) & 0xFFFFF000;

	kernel_physical_end = . ;

        /* physical memory map is allocated here */
        pmmap = . ;

}
