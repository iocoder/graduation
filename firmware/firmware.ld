ENTRY(start)

SECTIONS {

    . = 0x80000000;
    .bss    : {*(.bss COMMON)}

    . = 0x9FC00000;

    .entry  : {*(.entry )}
    .text   : {*(.text  )}
    .rodata : {*(.rodata)}

}
