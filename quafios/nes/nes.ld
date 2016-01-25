ENTRY(main)

SECTIONS {

        . = 0x80010000;
        base1 = .;
        .text   : {*(.entry) *(.text)}
        .rodata : {*(.rodata        )}
        .data   : {*(.data          )}
        base2 = .;
        .bss    : {*(.bss COMMON    )
                   rom = .;
                   *(.rawdata*)}

        /* cpu.s */
        __instr           = instr           - base1;

        /* mem.s */
        __read_routines   = read_routines   - base1;
        __read2_routines  = read2_routines  - base1;
        __instr_routines  = instr_routines  - base1;
        __write_routines  = write_routines  - base1;
        __write2_routines = write2_routines - base1;
        __ram             = ram             - base2;

        /* cartridge.s */
        __prgrom_start    = prgrom_start    - base1;
        __prgrom_cur      = prgrom_cur      - base1;
        __prgrom_last     = prgrom_last     - base1;

}
