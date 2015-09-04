library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mux8x1 is
    Port ( EN   : in  STD_LOGIC;
           I0   : in  STD_LOGIC;
           I1   : in  STD_LOGIC;
           I2   : in  STD_LOGIC;
           I3   : in  STD_LOGIC;
           I4   : in  STD_LOGIC;
           I5   : in  STD_LOGIC;
           I6   : in  STD_LOGIC;
           I7   : in  STD_LOGIC;
           C0   : in  STD_LOGIC;
           C1   : in  STD_LOGIC;
           C2   : in  STD_LOGIC;
           O    : out STD_LOGIC
    );
end mux8x1;

architecture Dataflow of mux8x1 is

begin

    O <= ((I0 AND (NOT C0) AND (NOT C1) AND (NOT C2)) OR
          (I1 AND (    C0) AND (NOT C1) AND (NOT C2)) OR
          (I2 AND (NOT C0) AND (    C1) AND (NOT C2)) OR
          (I3 AND (    C0) AND (    C1) AND (NOT C2)) OR
          (I4 AND (NOT C0) AND (NOT C1) AND (    C2)) OR
          (I5 AND (    C0) AND (NOT C1) AND (    C2)) OR
          (I6 AND (NOT C0) AND (    C1) AND (    C2)) OR
          (I7 AND (    C0) AND (    C1) AND (    C2))) AND EN;

end architecture;
