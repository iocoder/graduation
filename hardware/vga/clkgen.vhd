library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity clkgen is
    Port (CLK       : in  STD_LOGIC;
          CLK_56MHz : out STD_LOGIC;
          CLK_50MHz : out STD_LOGIC;
          CLK_28MHz : out STD_LOGIC;
          CLK_25MHz : out STD_LOGIC;
          CLK_12MHz : out STD_LOGIC);
end clkgen;

architecture Behavioral of clkgen is

component DCM
    generic (CLKFX_MULTIPLY        : integer := 27;
             CLKFX_DIVIDE          : integer := 24);
    port    (CLKIN                 : in  std_logic;
             CLKFB                 : in  std_logic;
             DSSEN                 : in  std_logic;
             PSINCDEC              : in  std_logic;
             PSEN                  : in  std_logic;
             PSCLK                 : in  std_logic;
             RST                   : in  std_logic;
             CLK0                  : out std_logic;
             CLK90                 : out std_logic;
             CLK180                : out std_logic;
             CLK270                : out std_logic;
             CLK2X                 : out std_logic;
             CLK2X180              : out std_logic;
             CLKDV                 : out std_logic;
             CLKFX                 : out std_logic;
             CLKFX180              : out std_logic;
             LOCKED                : out std_logic;
             PSDONE                : out std_logic;
             STATUS                : out std_logic_vector(7 downto 0));
end component;

component BUFG
  port (I   : in  std_logic;
        O   : out std_logic);
end component;

signal RST        : STD_LOGIC := '0';
signal GND        : STD_LOGIC := '0';
signal CLKFX      : STD_LOGIC := '0';
signal oCLK_56MHz : STD_LOGIC := '0';
signal oCLK_50MHz : STD_LOGIC := '0';
signal oCLK_28MHz : STD_LOGIC := '0';
signal oCLK_25MHz : STD_LOGIC := '0';
signal oCLK_12MHz : STD_LOGIC := '0';
signal bCLK_12MHz : STD_LOGIC := '0';
signal HALF       : STD_LOGIC := '0';

attribute clock_signal : string;
attribute clock_signal of oCLK_50MHz : signal is "yes";
attribute clock_signal of oCLK_25MHz : signal is "yes";
attribute clock_signal of oCLK_12MHz : signal is "yes";

signal reset      : integer   := 2;

begin

-- generate 50MHz clock
oCLK_50MHz <= CLK;

-- generate 25MHz clock
process(oCLK_50MHz)
begin
    if (oCLK_50MHz = '1' and oCLK_50MHz'event ) then
        oCLK_25MHz <= NOT oCLK_25MHz;
    end if;
end process;

-- generate 12MHz clock
process(oCLK_25MHz)
begin
    if (oCLK_25MHz = '1' and oCLK_25MHz'event ) then
        oCLK_12MHz <= NOT oCLK_12MHz;
    end if;
end process;

buf12: BUFG port map (oCLK_12MHz, bCLK_12MHz);

-- generate 56MHz clock
U0: DCM port map (CLKIN    => oCLK_50MHz,
                  CLKFB    => GND,
                  DSSEN    => GND,
                  PSINCDEC => GND,
                  PSEN     => GND,
                  PSCLK    => GND,
                  RST      => GND,
                  CLKFX    => CLKFX);

U1: BUFG port map (CLKFX, oCLK_56MHz);

-- generate 28MHz clock
process(oCLK_56MHz)
begin
    if (oCLK_56MHz = '1' and oCLK_56MHz'event ) then
        oCLK_28MHz <= NOT oCLK_28MHz;
    end if;
end process;

-- connect generated clock frequencies to outputs
CLK_56MHz <= oCLK_56MHz;
CLK_50MHz <= oCLK_50MHz;
CLK_28MHz <= oCLK_28MHz;
CLK_25MHz <= oCLK_25MHz;
CLK_12MHz <= bCLK_12MHz;

end Behavioral;
