library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vgaram2 is
    Port (CLK           : in  STD_LOGIC;
          -- sequencer port:
          SeqReadEnable : in  STD_LOGIC;
          SeqAddr       : in  STD_LOGIC_VECTOR (11 downto 0);
          SeqDataOut    : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000";
          -- GU port:
          GUReadEnable  : in  STD_LOGIC;
          GUWriteEnable : in  STD_LOGIC;
          GUAddr        : in  STD_LOGIC_VECTOR (11 downto 0);
          GUDataIn      : in  STD_LOGIC_VECTOR ( 7 downto 0);
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0));
end vgaram2;

architecture Behavioral of vgaram2 is

type ram_t is array (0 to 4095) of STD_LOGIC_VECTOR (7 downto 0);
signal ram : ram_t := (

    -- Byte 0x00:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x01:
    x"00", x"00", x"7E", x"81", x"A5", x"81", x"81", x"BD",
    x"99", x"81", x"81", x"7E", x"00", x"00", x"00", x"00",

    -- Byte 0x02:
    x"00", x"00", x"7E", x"FF", x"DB", x"FF", x"FF", x"C3",
    x"E7", x"FF", x"FF", x"7E", x"00", x"00", x"00", x"00",

    -- Byte 0x03:
    x"00", x"00", x"00", x"00", x"36", x"7F", x"7F", x"7F",
    x"7F", x"3E", x"1C", x"08", x"00", x"00", x"00", x"00",

    -- Byte 0x04:
    x"00", x"00", x"00", x"00", x"08", x"1C", x"3E", x"7F",
    x"3E", x"1C", x"08", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x05:
    x"00", x"00", x"00", x"18", x"3C", x"3C", x"E7", x"E7",
    x"E7", x"99", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x06:
    x"00", x"00", x"00", x"18", x"3C", x"7E", x"FF", x"FF",
    x"7E", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x07:
    x"00", x"00", x"00", x"00", x"00", x"00", x"18", x"3C",
    x"3C", x"18", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x08:
    x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"E7", x"C3",
    x"C3", x"E7", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF",

    -- Byte 0x09:
    x"00", x"00", x"00", x"00", x"00", x"3C", x"66", x"42",
    x"42", x"66", x"3C", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x0A:
    x"FF", x"FF", x"FF", x"FF", x"FF", x"C3", x"99", x"BD",
    x"BD", x"99", x"C3", x"FF", x"FF", x"FF", x"FF", x"FF",

    -- Byte 0x0B:
    x"00", x"00", x"78", x"70", x"58", x"4C", x"1E", x"33",
    x"33", x"33", x"33", x"1E", x"00", x"00", x"00", x"00",

    -- Byte 0x0C:
    x"00", x"00", x"3C", x"66", x"66", x"66", x"66", x"3C",
    x"18", x"7E", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x0D:
    x"00", x"00", x"FC", x"CC", x"FC", x"0C", x"0C", x"0C",
    x"0C", x"0E", x"0F", x"07", x"00", x"00", x"00", x"00",

    -- Byte 0x0E:
    x"00", x"00", x"FE", x"C6", x"FE", x"C6", x"C6", x"C6",
    x"C6", x"E6", x"E7", x"67", x"03", x"00", x"00", x"00",

    -- Byte 0x0F:
    x"00", x"00", x"00", x"18", x"18", x"DB", x"3C", x"E7",
    x"3C", x"DB", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x10:
    x"00", x"01", x"03", x"07", x"0F", x"1F", x"7F", x"1F",
    x"0F", x"07", x"03", x"01", x"00", x"00", x"00", x"00",

    -- Byte 0x11:
    x"00", x"40", x"60", x"70", x"78", x"7C", x"7F", x"7C",
    x"78", x"70", x"60", x"40", x"00", x"00", x"00", x"00",

    -- Byte 0x12:
    x"00", x"00", x"18", x"3C", x"7E", x"18", x"18", x"18",
    x"18", x"7E", x"3C", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x13:
    x"00", x"00", x"66", x"66", x"66", x"66", x"66", x"66",
    x"66", x"00", x"66", x"66", x"00", x"00", x"00", x"00",

    -- Byte 0x14:
    x"00", x"00", x"FE", x"DB", x"DB", x"DB", x"DE", x"D8",
    x"D8", x"D8", x"D8", x"D8", x"00", x"00", x"00", x"00",

    -- Byte 0x15:
    x"00", x"3E", x"63", x"06", x"1C", x"36", x"63", x"63",
    x"36", x"1C", x"30", x"63", x"3E", x"00", x"00", x"00",

    -- Byte 0x16:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"7F", x"7F", x"7F", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x17:
    x"00", x"00", x"18", x"3C", x"7E", x"18", x"18", x"18",
    x"18", x"7E", x"3C", x"18", x"7E", x"00", x"00", x"00",

    -- Byte 0x18:
    x"00", x"00", x"18", x"3C", x"7E", x"18", x"18", x"18",
    x"18", x"18", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x19:
    x"00", x"00", x"18", x"18", x"18", x"18", x"18", x"18",
    x"18", x"7E", x"3C", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x1A:
    x"00", x"00", x"00", x"00", x"00", x"18", x"30", x"7F",
    x"30", x"18", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x1B:
    x"00", x"00", x"00", x"00", x"00", x"0C", x"06", x"7F",
    x"06", x"0C", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x1C:
    x"00", x"00", x"00", x"00", x"00", x"03", x"03", x"03",
    x"03", x"7F", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x1D:
    x"00", x"00", x"00", x"00", x"00", x"14", x"36", x"7F",
    x"36", x"14", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x1E:
    x"00", x"00", x"00", x"00", x"08", x"1C", x"1C", x"3E",
    x"3E", x"7F", x"7F", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x1F:
    x"00", x"00", x"00", x"00", x"7F", x"7F", x"3E", x"3E",
    x"1C", x"1C", x"08", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x20:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x21:
    x"00", x"00", x"18", x"3C", x"3C", x"3C", x"18", x"18",
    x"18", x"00", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x22:
    x"00", x"66", x"66", x"66", x"24", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x23:
    x"00", x"00", x"00", x"36", x"36", x"7F", x"36", x"36",
    x"36", x"7F", x"36", x"36", x"00", x"00", x"00", x"00",

    -- Byte 0x24:
    x"18", x"18", x"3E", x"63", x"43", x"03", x"3E", x"60",
    x"61", x"63", x"3E", x"18", x"18", x"00", x"00", x"00",

    -- Byte 0x25:
    x"00", x"00", x"00", x"00", x"43", x"63", x"30", x"18",
    x"0C", x"06", x"63", x"61", x"00", x"00", x"00", x"00",

    -- Byte 0x26:
    x"00", x"00", x"1C", x"36", x"36", x"1C", x"6E", x"3B",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x27:
    x"00", x"0C", x"0C", x"0C", x"06", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x28:
    x"00", x"00", x"30", x"18", x"0C", x"0C", x"0C", x"0C",
    x"0C", x"0C", x"18", x"30", x"00", x"00", x"00", x"00",

    -- Byte 0x29:
    x"00", x"00", x"0C", x"18", x"30", x"30", x"30", x"30",
    x"30", x"30", x"18", x"0C", x"00", x"00", x"00", x"00",

    -- Byte 0x2A:
    x"00", x"00", x"00", x"00", x"00", x"66", x"3C", x"FF",
    x"3C", x"66", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x2B:
    x"00", x"00", x"00", x"00", x"00", x"18", x"18", x"7E",
    x"18", x"18", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x2C:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"18", x"18", x"18", x"0C", x"00", x"00", x"00",

    -- Byte 0x2D:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"7F",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x2E:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x2F:
    x"00", x"00", x"00", x"00", x"40", x"60", x"30", x"18",
    x"0C", x"06", x"03", x"01", x"00", x"00", x"00", x"00",

    -- Byte 0x30:
    x"00", x"00", x"3E", x"63", x"63", x"73", x"6B", x"6B",
    x"67", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x31:
    x"00", x"00", x"18", x"1C", x"1E", x"18", x"18", x"18",
    x"18", x"18", x"18", x"7E", x"00", x"00", x"00", x"00",

    -- Byte 0x32:
    x"00", x"00", x"3E", x"63", x"60", x"30", x"18", x"0C",
    x"06", x"03", x"63", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x33:
    x"00", x"00", x"3E", x"63", x"60", x"60", x"3C", x"60",
    x"60", x"60", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x34:
    x"00", x"00", x"30", x"38", x"3C", x"36", x"33", x"7F",
    x"30", x"30", x"30", x"78", x"00", x"00", x"00", x"00",

    -- Byte 0x35:
    x"00", x"00", x"7F", x"03", x"03", x"03", x"3F", x"70",
    x"60", x"60", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x36:
    x"00", x"00", x"1C", x"06", x"03", x"03", x"3F", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x37:
    x"00", x"00", x"7F", x"63", x"60", x"60", x"30", x"18",
    x"0C", x"0C", x"0C", x"0C", x"00", x"00", x"00", x"00",

    -- Byte 0x38:
    x"00", x"00", x"3E", x"63", x"63", x"63", x"3E", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x39:
    x"00", x"00", x"3E", x"63", x"63", x"63", x"7E", x"60",
    x"60", x"60", x"30", x"1E", x"00", x"00", x"00", x"00",

    -- Byte 0x3A:
    x"00", x"00", x"00", x"00", x"18", x"18", x"00", x"00",
    x"00", x"18", x"18", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x3B:
    x"00", x"00", x"00", x"00", x"18", x"18", x"00", x"00",
    x"00", x"18", x"18", x"0C", x"00", x"00", x"00", x"00",

    -- Byte 0x3C:
    x"00", x"00", x"00", x"60", x"30", x"18", x"0C", x"06",
    x"0C", x"18", x"30", x"60", x"00", x"00", x"00", x"00",

    -- Byte 0x3D:
    x"00", x"00", x"00", x"00", x"00", x"00", x"7F", x"00",
    x"00", x"7F", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x3E:
    x"00", x"00", x"00", x"06", x"0C", x"18", x"30", x"60",
    x"30", x"18", x"0C", x"06", x"00", x"00", x"00", x"00",

    -- Byte 0x3F:
    x"00", x"00", x"3E", x"63", x"63", x"30", x"18", x"18",
    x"18", x"00", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x40:
    x"00", x"00", x"00", x"3E", x"63", x"63", x"7B", x"7B",
    x"7B", x"3B", x"03", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x41:
    x"00", x"00", x"08", x"1C", x"36", x"63", x"63", x"7F",
    x"63", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x42:
    x"00", x"00", x"3F", x"66", x"66", x"66", x"3E", x"66",
    x"66", x"66", x"66", x"3F", x"00", x"00", x"00", x"00",

    -- Byte 0x43:
    x"00", x"00", x"3C", x"66", x"43", x"03", x"03", x"03",
    x"03", x"43", x"66", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x44:
    x"00", x"00", x"1F", x"36", x"66", x"66", x"66", x"66",
    x"66", x"66", x"36", x"1F", x"00", x"00", x"00", x"00",

    -- Byte 0x45:
    x"00", x"00", x"7F", x"66", x"46", x"16", x"1E", x"16",
    x"06", x"46", x"66", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x46:
    x"00", x"00", x"7F", x"66", x"46", x"16", x"1E", x"16",
    x"06", x"06", x"06", x"0F", x"00", x"00", x"00", x"00",

    -- Byte 0x47:
    x"00", x"00", x"3C", x"66", x"43", x"03", x"03", x"7B",
    x"63", x"63", x"66", x"5C", x"00", x"00", x"00", x"00",

    -- Byte 0x48:
    x"00", x"00", x"63", x"63", x"63", x"63", x"7F", x"63",
    x"63", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x49:
    x"00", x"00", x"3C", x"18", x"18", x"18", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x4A:
    x"00", x"00", x"78", x"30", x"30", x"30", x"30", x"30",
    x"33", x"33", x"33", x"1E", x"00", x"00", x"00", x"00",

    -- Byte 0x4B:
    x"00", x"00", x"67", x"66", x"36", x"36", x"1E", x"1E",
    x"36", x"66", x"66", x"67", x"00", x"00", x"00", x"00",

    -- Byte 0x4C:
    x"00", x"00", x"0F", x"06", x"06", x"06", x"06", x"06",
    x"06", x"46", x"66", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x4D:
    x"00", x"00", x"63", x"77", x"7F", x"7F", x"6B", x"63",
    x"63", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x4E:
    x"00", x"00", x"63", x"67", x"6F", x"7F", x"7B", x"73",
    x"63", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x4F:
    x"00", x"00", x"1C", x"36", x"63", x"63", x"63", x"63",
    x"63", x"63", x"36", x"1C", x"00", x"00", x"00", x"00",

    -- Byte 0x50:
    x"00", x"00", x"3F", x"66", x"66", x"66", x"3E", x"06",
    x"06", x"06", x"06", x"0F", x"00", x"00", x"00", x"00",

    -- Byte 0x51:
    x"00", x"00", x"3E", x"63", x"63", x"63", x"63", x"63",
    x"63", x"6B", x"7B", x"3E", x"30", x"70", x"00", x"00",

    -- Byte 0x52:
    x"00", x"00", x"3F", x"66", x"66", x"66", x"3E", x"36",
    x"66", x"66", x"66", x"67", x"00", x"00", x"00", x"00",

    -- Byte 0x53:
    x"00", x"00", x"3E", x"63", x"63", x"06", x"1C", x"30",
    x"60", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x54:
    x"00", x"00", x"7E", x"7E", x"5A", x"18", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x55:
    x"00", x"00", x"63", x"63", x"63", x"63", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x56:
    x"00", x"00", x"63", x"63", x"63", x"63", x"63", x"63",
    x"63", x"36", x"1C", x"08", x"00", x"00", x"00", x"00",

    -- Byte 0x57:
    x"00", x"00", x"63", x"63", x"63", x"63", x"63", x"6B",
    x"6B", x"7F", x"36", x"36", x"00", x"00", x"00", x"00",

    -- Byte 0x58:
    x"00", x"00", x"63", x"63", x"36", x"36", x"1C", x"1C",
    x"36", x"36", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x59:
    x"00", x"00", x"66", x"66", x"66", x"66", x"3C", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x5A:
    x"00", x"00", x"7F", x"63", x"61", x"30", x"18", x"0C",
    x"06", x"43", x"63", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x5B:
    x"00", x"00", x"3C", x"0C", x"0C", x"0C", x"0C", x"0C",
    x"0C", x"0C", x"0C", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x5C:
    x"00", x"00", x"00", x"01", x"03", x"07", x"0E", x"1C",
    x"38", x"70", x"60", x"40", x"00", x"00", x"00", x"00",

    -- Byte 0x5D:
    x"00", x"00", x"3C", x"30", x"30", x"30", x"30", x"30",
    x"30", x"30", x"30", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x5E:
    x"08", x"1C", x"36", x"63", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x5F:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"FF", x"00", x"00",

    -- Byte 0x60:
    x"0C", x"0C", x"18", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x61:
    x"00", x"00", x"00", x"00", x"00", x"1E", x"30", x"3E",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x62:
    x"00", x"00", x"07", x"06", x"06", x"1E", x"36", x"66",
    x"66", x"66", x"66", x"3B", x"00", x"00", x"00", x"00",

    -- Byte 0x63:
    x"00", x"00", x"00", x"00", x"00", x"3E", x"63", x"03",
    x"03", x"03", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x64:
    x"00", x"00", x"38", x"30", x"30", x"3C", x"36", x"33",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x65:
    x"00", x"00", x"00", x"00", x"00", x"3E", x"63", x"7F",
    x"03", x"03", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x66:
    x"00", x"00", x"1C", x"36", x"26", x"06", x"0F", x"06",
    x"06", x"06", x"06", x"0F", x"00", x"00", x"00", x"00",

    -- Byte 0x67:
    x"00", x"00", x"00", x"00", x"00", x"6E", x"33", x"33",
    x"33", x"33", x"33", x"3E", x"30", x"33", x"1E", x"00",

    -- Byte 0x68:
    x"00", x"00", x"07", x"06", x"06", x"36", x"6E", x"66",
    x"66", x"66", x"66", x"67", x"00", x"00", x"00", x"00",

    -- Byte 0x69:
    x"00", x"00", x"18", x"18", x"00", x"1C", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x6A:
    x"00", x"00", x"60", x"60", x"00", x"70", x"60", x"60",
    x"60", x"60", x"60", x"60", x"66", x"66", x"3C", x"00",

    -- Byte 0x6B:
    x"00", x"00", x"07", x"06", x"06", x"66", x"36", x"1E",
    x"1E", x"36", x"66", x"67", x"00", x"00", x"00", x"00",

    -- Byte 0x6C:
    x"00", x"00", x"1C", x"18", x"18", x"18", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x6D:
    x"00", x"00", x"00", x"00", x"00", x"37", x"7F", x"6B",
    x"6B", x"6B", x"6B", x"6B", x"00", x"00", x"00", x"00",

    -- Byte 0x6E:
    x"00", x"00", x"00", x"00", x"00", x"3B", x"66", x"66",
    x"66", x"66", x"66", x"66", x"00", x"00", x"00", x"00",

    -- Byte 0x6F:
    x"00", x"00", x"00", x"00", x"00", x"3E", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x70:
    x"00", x"00", x"00", x"00", x"00", x"3B", x"66", x"66",
    x"66", x"66", x"66", x"3E", x"06", x"06", x"0F", x"00",

    -- Byte 0x71:
    x"00", x"00", x"00", x"00", x"00", x"6E", x"33", x"33",
    x"33", x"33", x"33", x"3E", x"30", x"30", x"78", x"00",

    -- Byte 0x72:
    x"00", x"00", x"00", x"00", x"00", x"3B", x"6E", x"46",
    x"06", x"06", x"06", x"0F", x"00", x"00", x"00", x"00",

    -- Byte 0x73:
    x"00", x"00", x"00", x"00", x"00", x"3E", x"63", x"06",
    x"1C", x"30", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x74:
    x"00", x"00", x"08", x"0C", x"0C", x"3F", x"0C", x"0C",
    x"0C", x"0C", x"6C", x"38", x"00", x"00", x"00", x"00",

    -- Byte 0x75:
    x"00", x"00", x"00", x"00", x"00", x"33", x"33", x"33",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x76:
    x"00", x"00", x"00", x"00", x"00", x"66", x"66", x"66",
    x"66", x"66", x"3C", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x77:
    x"00", x"00", x"00", x"00", x"00", x"63", x"63", x"63",
    x"6B", x"6B", x"7F", x"36", x"00", x"00", x"00", x"00",

    -- Byte 0x78:
    x"00", x"00", x"00", x"00", x"00", x"63", x"36", x"1C",
    x"1C", x"1C", x"36", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x79:
    x"00", x"00", x"00", x"00", x"00", x"63", x"63", x"63",
    x"63", x"63", x"63", x"7E", x"60", x"30", x"1F", x"00",

    -- Byte 0x7A:
    x"00", x"00", x"00", x"00", x"00", x"7F", x"33", x"18",
    x"0C", x"06", x"63", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x7B:
    x"00", x"00", x"70", x"18", x"18", x"18", x"0E", x"18",
    x"18", x"18", x"18", x"70", x"00", x"00", x"00", x"00",

    -- Byte 0x7C:
    x"00", x"00", x"18", x"18", x"18", x"18", x"00", x"18",
    x"18", x"18", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x7D:
    x"00", x"00", x"0E", x"18", x"18", x"18", x"70", x"18",
    x"18", x"18", x"18", x"0E", x"00", x"00", x"00", x"00",

    -- Byte 0x7E:
    x"00", x"00", x"6E", x"3B", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x7F:
    x"00", x"00", x"00", x"00", x"08", x"1C", x"36", x"63",
    x"63", x"63", x"7F", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0x80:
    x"00", x"00", x"3C", x"66", x"43", x"03", x"03", x"03",
    x"43", x"66", x"3C", x"30", x"60", x"3E", x"00", x"00",

    -- Byte 0x81:
    x"00", x"00", x"33", x"33", x"00", x"33", x"33", x"33",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x82:
    x"00", x"30", x"18", x"0C", x"00", x"3E", x"63", x"7F",
    x"03", x"03", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x83:
    x"00", x"08", x"1C", x"36", x"00", x"1E", x"30", x"3E",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x84:
    x"00", x"00", x"33", x"33", x"00", x"1E", x"30", x"3E",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x85:
    x"00", x"06", x"0C", x"18", x"00", x"1E", x"30", x"3E",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x86:
    x"00", x"1C", x"36", x"1C", x"00", x"1E", x"30", x"3E",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x87:
    x"00", x"00", x"00", x"00", x"3C", x"66", x"06", x"06",
    x"66", x"3C", x"30", x"60", x"3C", x"00", x"00", x"00",

    -- Byte 0x88:
    x"00", x"08", x"1C", x"36", x"00", x"3E", x"63", x"7F",
    x"03", x"03", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x89:
    x"00", x"00", x"63", x"63", x"00", x"3E", x"63", x"7F",
    x"03", x"03", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x8A:
    x"00", x"06", x"0C", x"18", x"00", x"3E", x"63", x"7F",
    x"03", x"03", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x8B:
    x"00", x"00", x"66", x"66", x"00", x"1C", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x8C:
    x"00", x"18", x"3C", x"66", x"00", x"1C", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x8D:
    x"00", x"06", x"0C", x"18", x"00", x"1C", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0x8E:
    x"00", x"63", x"63", x"08", x"1C", x"36", x"63", x"63",
    x"7F", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x8F:
    x"1C", x"36", x"1C", x"00", x"1C", x"36", x"63", x"63",
    x"7F", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x90:
    x"18", x"0C", x"06", x"00", x"7F", x"66", x"06", x"3E",
    x"06", x"06", x"66", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0x91:
    x"00", x"00", x"00", x"00", x"00", x"33", x"6E", x"6C",
    x"7E", x"1B", x"1B", x"76", x"00", x"00", x"00", x"00",

    -- Byte 0x92:
    x"00", x"00", x"7C", x"36", x"33", x"33", x"7F", x"33",
    x"33", x"33", x"33", x"73", x"00", x"00", x"00", x"00",

    -- Byte 0x93:
    x"00", x"08", x"1C", x"36", x"00", x"3E", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x94:
    x"00", x"00", x"63", x"63", x"00", x"3E", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x95:
    x"00", x"06", x"0C", x"18", x"00", x"3E", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x96:
    x"00", x"0C", x"1E", x"33", x"00", x"33", x"33", x"33",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x97:
    x"00", x"06", x"0C", x"18", x"00", x"33", x"33", x"33",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0x98:
    x"00", x"00", x"63", x"63", x"00", x"63", x"63", x"63",
    x"63", x"63", x"63", x"7E", x"60", x"30", x"1E", x"00",

    -- Byte 0x99:
    x"00", x"63", x"63", x"00", x"1C", x"36", x"63", x"63",
    x"63", x"63", x"36", x"1C", x"00", x"00", x"00", x"00",

    -- Byte 0x9A:
    x"00", x"63", x"63", x"00", x"63", x"63", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0x9B:
    x"00", x"18", x"18", x"3C", x"66", x"06", x"06", x"06",
    x"66", x"3C", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x9C:
    x"00", x"1C", x"36", x"26", x"06", x"0F", x"06", x"06",
    x"06", x"06", x"67", x"3F", x"00", x"00", x"00", x"00",

    -- Byte 0x9D:
    x"00", x"00", x"66", x"66", x"3C", x"18", x"7E", x"18",
    x"7E", x"18", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0x9E:
    x"00", x"1F", x"33", x"33", x"1F", x"23", x"33", x"7B",
    x"33", x"33", x"33", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0x9F:
    x"00", x"70", x"D8", x"18", x"18", x"18", x"7E", x"18",
    x"18", x"18", x"18", x"18", x"1B", x"0E", x"00", x"00",

    -- Byte 0xA0:
    x"00", x"18", x"0C", x"06", x"00", x"1E", x"30", x"3E",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0xA1:
    x"00", x"30", x"18", x"0C", x"00", x"1C", x"18", x"18",
    x"18", x"18", x"18", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0xA2:
    x"00", x"18", x"0C", x"06", x"00", x"3E", x"63", x"63",
    x"63", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0xA3:
    x"00", x"18", x"0C", x"06", x"00", x"33", x"33", x"33",
    x"33", x"33", x"33", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0xA4:
    x"00", x"00", x"6E", x"3B", x"00", x"3B", x"66", x"66",
    x"66", x"66", x"66", x"66", x"00", x"00", x"00", x"00",

    -- Byte 0xA5:
    x"6E", x"3B", x"00", x"63", x"67", x"6F", x"7F", x"7B",
    x"73", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0xA6:
    x"00", x"3C", x"36", x"36", x"7C", x"00", x"7E", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xA7:
    x"00", x"1C", x"36", x"36", x"1C", x"00", x"3E", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xA8:
    x"00", x"00", x"0C", x"0C", x"00", x"0C", x"0C", x"06",
    x"03", x"63", x"63", x"3E", x"00", x"00", x"00", x"00",

    -- Byte 0xA9:
    x"00", x"00", x"00", x"00", x"00", x"00", x"7F", x"03",
    x"03", x"03", x"03", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xAA:
    x"00", x"00", x"00", x"00", x"00", x"00", x"7F", x"60",
    x"60", x"60", x"60", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xAB:
    x"00", x"03", x"03", x"43", x"63", x"33", x"18", x"0C",
    x"06", x"73", x"C9", x"60", x"30", x"F8", x"00", x"00",

    -- Byte 0xAC:
    x"00", x"03", x"03", x"43", x"63", x"33", x"18", x"0C",
    x"66", x"73", x"59", x"FC", x"60", x"F0", x"00", x"00",

    -- Byte 0xAD:
    x"00", x"00", x"18", x"18", x"00", x"18", x"18", x"18",
    x"3C", x"3C", x"3C", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0xAE:
    x"00", x"00", x"00", x"00", x"00", x"CC", x"66", x"33",
    x"66", x"CC", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xAF:
    x"00", x"00", x"00", x"00", x"00", x"33", x"66", x"CC",
    x"66", x"33", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xB0:
    x"88", x"22", x"88", x"22", x"88", x"22", x"88", x"22",
    x"88", x"22", x"88", x"22", x"88", x"22", x"88", x"22",

    -- Byte 0xB1:
    x"AA", x"55", x"AA", x"55", x"AA", x"55", x"AA", x"55",
    x"AA", x"55", x"AA", x"55", x"AA", x"55", x"AA", x"55",

    -- Byte 0xB2:
    x"BB", x"EE", x"BB", x"EE", x"BB", x"EE", x"BB", x"EE",
    x"BB", x"EE", x"BB", x"EE", x"BB", x"EE", x"BB", x"EE",

    -- Byte 0xB3:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xB4:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"1F",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xB5:
    x"18", x"18", x"18", x"18", x"18", x"1F", x"18", x"1F",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xB6:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6F",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xB7:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"7F",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xB8:
    x"00", x"00", x"00", x"00", x"00", x"1F", x"18", x"1F",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xB9:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6F", x"60", x"6F",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xBA:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xBB:
    x"00", x"00", x"00", x"00", x"00", x"7F", x"60", x"6F",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xBC:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6F", x"60", x"7F",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xBD:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"7F",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xBE:
    x"18", x"18", x"18", x"18", x"18", x"1F", x"18", x"1F",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xBF:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"1F",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xC0:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"F8",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xC1:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"FF",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xC2:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"FF",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xC3:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"F8",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xC4:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"FF",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xC5:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"FF",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xC6:
    x"18", x"18", x"18", x"18", x"18", x"F8", x"18", x"F8",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xC7:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"EC",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xC8:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"EC", x"0C", x"FC",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xC9:
    x"00", x"00", x"00", x"00", x"00", x"FC", x"0C", x"EC",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xCA:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"EF", x"00", x"FF",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xCB:
    x"00", x"00", x"00", x"00", x"00", x"FF", x"00", x"EF",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xCC:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"EC", x"0C", x"EC",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xCD:
    x"00", x"00", x"00", x"00", x"00", x"FF", x"00", x"FF",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xCE:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"EF", x"00", x"EF",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xCF:
    x"18", x"18", x"18", x"18", x"18", x"FF", x"00", x"FF",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xD0:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"FF",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xD1:
    x"00", x"00", x"00", x"00", x"00", x"FF", x"00", x"FF",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xD2:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"FF",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xD3:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"FC",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xD4:
    x"18", x"18", x"18", x"18", x"18", x"F8", x"18", x"F8",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xD5:
    x"00", x"00", x"00", x"00", x"00", x"F8", x"18", x"F8",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xD6:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"FC",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xD7:
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"FF",
    x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C", x"6C",

    -- Byte 0xD8:
    x"18", x"18", x"18", x"18", x"18", x"FF", x"18", x"FF",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xD9:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"1F",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xDA:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"F8",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xDB:
    x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF",
    x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF",

    -- Byte 0xDC:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"FF",
    x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF",

    -- Byte 0xDD:
    x"0F", x"0F", x"0F", x"0F", x"0F", x"0F", x"0F", x"0F",
    x"0F", x"0F", x"0F", x"0F", x"0F", x"0F", x"0F", x"0F",

    -- Byte 0xDE:
    x"F0", x"F0", x"F0", x"F0", x"F0", x"F0", x"F0", x"F0",
    x"F0", x"F0", x"F0", x"F0", x"F0", x"F0", x"F0", x"F0",

    -- Byte 0xDF:
    x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xE0:
    x"00", x"00", x"00", x"00", x"00", x"6E", x"3B", x"1B",
    x"1B", x"1B", x"3B", x"6E", x"00", x"00", x"00", x"00",

    -- Byte 0xE1:
    x"00", x"00", x"00", x"00", x"00", x"3F", x"63", x"3F",
    x"63", x"63", x"3F", x"03", x"03", x"03", x"00", x"00",

    -- Byte 0xE2:
    x"00", x"00", x"7F", x"63", x"63", x"03", x"03", x"03",
    x"03", x"03", x"03", x"03", x"00", x"00", x"00", x"00",

    -- Byte 0xE3:
    x"00", x"00", x"00", x"00", x"01", x"7F", x"36", x"36",
    x"36", x"36", x"36", x"36", x"00", x"00", x"00", x"00",

    -- Byte 0xE4:
    x"00", x"00", x"00", x"7F", x"63", x"06", x"0C", x"18",
    x"0C", x"06", x"63", x"7F", x"00", x"00", x"00", x"00",

    -- Byte 0xE5:
    x"00", x"00", x"00", x"00", x"00", x"7E", x"1B", x"1B",
    x"1B", x"1B", x"1B", x"0E", x"00", x"00", x"00", x"00",

    -- Byte 0xE6:
    x"00", x"00", x"00", x"00", x"66", x"66", x"66", x"66",
    x"66", x"3E", x"06", x"06", x"03", x"00", x"00", x"00",

    -- Byte 0xE7:
    x"00", x"00", x"00", x"00", x"6E", x"3B", x"18", x"18",
    x"18", x"18", x"18", x"18", x"00", x"00", x"00", x"00",

    -- Byte 0xE8:
    x"00", x"00", x"00", x"7E", x"18", x"3C", x"66", x"66",
    x"66", x"3C", x"18", x"7E", x"00", x"00", x"00", x"00",

    -- Byte 0xE9:
    x"00", x"00", x"00", x"1C", x"36", x"63", x"63", x"7F",
    x"63", x"63", x"36", x"1C", x"00", x"00", x"00", x"00",

    -- Byte 0xEA:
    x"00", x"00", x"1C", x"36", x"63", x"63", x"63", x"36",
    x"36", x"36", x"36", x"77", x"00", x"00", x"00", x"00",

    -- Byte 0xEB:
    x"00", x"00", x"78", x"0C", x"18", x"30", x"7C", x"66",
    x"66", x"66", x"66", x"3C", x"00", x"00", x"00", x"00",

    -- Byte 0xEC:
    x"00", x"00", x"00", x"00", x"00", x"7E", x"DB", x"DB",
    x"DB", x"7E", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xED:
    x"00", x"00", x"00", x"C0", x"60", x"7E", x"F3", x"DB",
    x"CF", x"7E", x"06", x"03", x"00", x"00", x"00", x"00",

    -- Byte 0xEE:
    x"00", x"00", x"38", x"0C", x"06", x"06", x"3E", x"06",
    x"06", x"06", x"0C", x"38", x"00", x"00", x"00", x"00",

    -- Byte 0xEF:
    x"00", x"00", x"00", x"3E", x"63", x"63", x"63", x"63",
    x"63", x"63", x"63", x"63", x"00", x"00", x"00", x"00",

    -- Byte 0xF0:
    x"00", x"00", x"00", x"00", x"7F", x"00", x"00", x"7F",
    x"00", x"00", x"7F", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xF1:
    x"00", x"00", x"00", x"00", x"18", x"18", x"7E", x"18",
    x"18", x"00", x"00", x"FF", x"00", x"00", x"00", x"00",

    -- Byte 0xF2:
    x"00", x"00", x"00", x"0C", x"18", x"30", x"60", x"30",
    x"18", x"0C", x"00", x"7E", x"00", x"00", x"00", x"00",

    -- Byte 0xF3:
    x"00", x"00", x"00", x"30", x"18", x"0C", x"06", x"0C",
    x"18", x"30", x"00", x"7E", x"00", x"00", x"00", x"00",

    -- Byte 0xF4:
    x"00", x"00", x"70", x"D8", x"D8", x"18", x"18", x"18",
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",

    -- Byte 0xF5:
    x"18", x"18", x"18", x"18", x"18", x"18", x"18", x"18",
    x"1B", x"1B", x"1B", x"0E", x"00", x"00", x"00", x"00",

    -- Byte 0xF6:
    x"00", x"00", x"00", x"00", x"18", x"18", x"00", x"7E",
    x"00", x"18", x"18", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xF7:
    x"00", x"00", x"00", x"00", x"00", x"6E", x"3B", x"00",
    x"6E", x"3B", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xF8:
    x"00", x"1C", x"36", x"36", x"1C", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xF9:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"18",
    x"18", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xFA:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"18", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xFB:
    x"00", x"F0", x"30", x"30", x"30", x"30", x"30", x"37",
    x"36", x"36", x"3C", x"38", x"00", x"00", x"00", x"00",

    -- Byte 0xFC:
    x"00", x"1B", x"36", x"36", x"36", x"36", x"36", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xFD:
    x"00", x"0E", x"19", x"0C", x"06", x"13", x"1F", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xFE:
    x"00", x"00", x"00", x"00", x"3E", x"3E", x"3E", x"3E",
    x"3E", x"3E", x"3E", x"00", x"00", x"00", x"00", x"00",

    -- Byte 0xFF:
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"

);

begin

process (clk)
begin

    if (clk = '0' and clk'event) then
        if (GUWriteEnable = '1') then
            ram(conv_integer(unsigned(GUAddr))) <= GUDataIn;
        end if;
        if (GUReadEnable = '1') then
            SeqDataOut <= "00000000";
            GUDataOut  <= ram(conv_integer(unsigned(GUAddr)));
        elsif (SeqReadEnable = '1') then
            SeqDataOut <= ram(conv_integer(unsigned(SeqAddr)));
            GUDataOut  <= "00000000";
        else
            SeqDataOut <= "00000000";
            GUDataOut  <= "00000000";
        end if;
    end if;

end process;

end Behavioral;
