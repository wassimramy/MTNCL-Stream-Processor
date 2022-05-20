
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Node is
generic(bitwidth: in integer := 4);
	port(
		input    	: in  dual_rail_logic_vector((9*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_SF_Node is

	component MTNCL_RCA_TREE_GEN is
	generic(numInputs: in integer := 8; bitwidth: in integer := 8);
	port(
		input    	: in  dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector((integer(ceil(log2(real(numInputs))))) + (bitwidth-1) downto 0)
		);
	end component;

  component MTNCL_Rounding_Checker is
    generic(bitwidth: in integer := 4);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		sel		: in  dual_rail_logic_vector(0 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)      );
  end component;

	signal input_1		: dual_rail_logic_vector((9*(bitwidth+2))-1 downto 0);
	signal sum_1		: dual_rail_logic_vector(bitwidth+5 downto 0);
	signal data_0		: dual_rail_logic;
	signal sleep_1, ko_1, ko_2	: std_logic;
begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';
	
	--Box Filter Multiplication
	input_1 <= data_0 & data_0 & input (9*bitwidth-1 downto 8*bitwidth) &
	data_0 & input (8*bitwidth-1 downto 7*bitwidth) & data_0 &
	data_0 & data_0 & input (7*bitwidth-1 downto 6*bitwidth) &
	data_0 & input (6*bitwidth-1 downto 5*bitwidth) & data_0 &
	input (5*bitwidth-1 downto 4*bitwidth) & data_0 & data_0 &
	data_0 & input (4*bitwidth-1 downto 3*bitwidth) & data_0 &
	data_0 & data_0 & input (3*bitwidth-1 downto 2*bitwidth) &
	data_0 & input (2*bitwidth-1 downto 1*bitwidth) & data_0 &
	data_0 & data_0 & input (1*bitwidth-1 downto 0*bitwidth) ;

	rca_9_inputs : MTNCL_RCA_TREE_GEN
	generic map(9, bitwidth+2)
	port map(input_1,
		ko_1, sleep, rst, sleep_1,
		ko_2, sum_1);

	ko <= ko_2;
	--Check for rounding
	rounding_checker : MTNCL_Rounding_Checker
	generic map(bitwidth)
	port map(sum_1 (bitwidth+3 downto 4),
		sum_1(3 downto 3), ki, sleep_1, rst, sleepOut,
		ko_1, output);

end arch;
