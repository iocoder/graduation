library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

package cpu_pkg is
    -- signed/unsigned extension
    function unsiext1 (input : in STD_LOGIC_VECTOR( 7 downto 0))
             return STD_LOGIC_VECTOR;
    function unsiext2 (input : in STD_LOGIC_VECTOR(15 downto 0))
             return STD_LOGIC_VECTOR;
    function signext1 (input : in STD_LOGIC_VECTOR( 7 downto 0))
             return STD_LOGIC_VECTOR;
    function signext2 (input : in STD_LOGIC_VECTOR(15 downto 0))
             return STD_LOGIC_VECTOR;
    -- alu functions
    function alu_cpy (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_add (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_sub (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_and (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_ior (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_xor (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_nor (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_lts (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_ltu (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_sll (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_srl (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_sra (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_mul (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_mulu(alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_div (alu1: in integer;
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    function alu_rem (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR;
    -- decoding functions
    function is_alureg (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_branchregimm (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_jmp (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_branch (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_aluimm (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_memload (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_memstore (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
    function is_cop0 (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean;
end package;

package body cpu_pkg is

    -- unsigned extend 8-bit to 32-bit
    function unsiext1 (input : in STD_LOGIC_VECTOR( 7 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := x"000000" & input;
        return output;
    end unsiext1;

    -- unsigned extend 16-bit to 32-bit
    function unsiext2 (input : in STD_LOGIC_VECTOR(15 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := x"0000" & input;
        return output;
    end unsiext2;

    -- signed extend 8-bit to 32-bit
    function signext1 (input : in STD_LOGIC_VECTOR( 7 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if (input(7) = '1') then
            output := x"FFFFFF" & input;
        else
            output := x"000000" & input;
        end if;
        return output;
    end signext1;

    -- signed extend 16-bit to 32-bit
    function signext2 (input : in STD_LOGIC_VECTOR(15 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if (input(15) = '1') then
            output := x"FFFF" & input;
        else
            output := x"0000" & input;
        end if;
        return output;
    end signext2;

    -- alu cpy
    function alu_cpy (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := alu2;
        return output;
    end alu_cpy;

    -- alu add
    function alu_add (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := std_logic_vector(unsigned(alu1) + unsigned(alu2));
        return output;
    end alu_add;

    -- alu sub
    function alu_sub (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := std_logic_vector(unsigned(alu1) - unsigned(alu2));
        return output;
    end alu_sub;

    -- alu and
    function alu_and (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := alu1 AND alu2;
        return output;
    end alu_and;

    -- alu ior
    function alu_ior (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := alu1 OR alu2;
        return output;
    end alu_ior;

    -- alu xor
    function alu_xor (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := alu1 XOR alu2;
        return output;
    end alu_xor;

    -- alu nor
    function alu_nor (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := alu1 NOR alu2;
        return output;
    end alu_nor;

    -- alu lts
    function alu_lts (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if (signed(alu1) < signed(alu2)) then
            output := x"00000001";
        else
            output := x"00000000";
        end if;
        return output;
    end alu_lts;

    -- alu ltu
    function alu_ltu (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if (unsigned(alu1) < unsigned(alu2)) then
            output := x"00000001";
        else
            output := x"00000000";
        end if;
        return output;
    end alu_ltu;

    -- alu sll
    function alu_sll (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := std_logic_vector(
            shift_left(unsigned(alu2),
            to_integer(unsigned(alu1(4 downto 0)))));
        return output;
    end alu_sll;

    -- alu srl
    function alu_srl (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := std_logic_vector(
            shift_right(unsigned(alu2),
            to_integer(unsigned(alu1(4 downto 0)))));
        return output;
    end alu_srl;

    -- alu sra
    function alu_sra (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output := std_logic_vector(
            shift_right(signed(alu2),
            to_integer(unsigned(alu1(4 downto 0)))));
        return output;
    end alu_sra;

    -- alu mul
    function alu_mul (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(63 downto 0);
    begin
        output := std_logic_vector(signed(alu1) * signed(alu2));
        return output;
    end alu_mul;

    -- alu mulu
    function alu_mulu(alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(63 downto 0);
    begin
        output := std_logic_vector(unsigned(alu1) * unsigned(alu2));
        return output;
    end alu_mulu;

    -- alu div
    function alu_div (alu1: in integer;
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
        variable first  : STD_LOGIC_VECTOR(31 downto 0) := x"00000001";
        variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        output :=
            std_logic_vector(
                signed(shift_left(unsigned(first),alu1))/
                signed(alu2));
        return output;
    end alu_div;

    -- alu rem
    function alu_rem (alu1: in STD_LOGIC_VECTOR(31 downto 0);
                      alu2: in STD_LOGIC_VECTOR(31 downto 0))
             return STD_LOGIC_VECTOR is
    variable output : STD_LOGIC_VECTOR(31 downto 0);
    begin
        --output := std_logic_vector(signed(alu1) rem signed(alu2));
        return output;
    end alu_rem;

    -- is alureg opcode
    function is_alureg (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode = "000000" then
            return true;
        else
            return false;
        end if;
    end is_alureg;

    -- is branchregimm opcode
    function is_branchregimm (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode = "000001" then
            return true;
        else
            return false;
        end if;
    end is_branchregimm;

    -- is jmp opcode
    function is_jmp (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode = "000010" or opcode = "000011" then
            return true;
        else
            return false;
        end if;
    end is_jmp;

    -- is branch opcode
    function is_branch (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode(5 downto 2) = "0001" then
            return true;
        else
            return false;
        end if;
    end is_branch;

    -- is aluimm opcode
    function is_aluimm (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode(5 downto 3) = "001" then
            return true;
        else
            return false;
        end if;
    end is_aluimm;

    -- is memload opcode
    function is_memload (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode(5 downto 3) = "100" then
            return true;
        else
            return false;
        end if;
    end is_memload;

    -- is memstore opcode
    function is_memstore (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode(5 downto 3) = "101" then
            return true;
        else
            return false;
        end if;
    end is_memstore;

    -- is cop0 opcode
    function is_cop0 (opcode: in STD_LOGIC_VECTOR(5 downto 0))
             return boolean is
    begin
        if opcode(5 downto 0) = "010000" then
            return true;
        else
            return false;
        end if;
    end is_cop0;

end cpu_pkg;
