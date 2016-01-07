ENTRY(main)

SECTIONS {

	. = 0x80010000;

	.text   : {*(.text.main) *(.text)}
	.rodata : {*(.rodata            )}
	.data   : {*(.data              )}
	.bss    : {*(.bss COMMON        )}

}
