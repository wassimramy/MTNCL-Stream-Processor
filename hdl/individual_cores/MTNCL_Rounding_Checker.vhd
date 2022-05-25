
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

entity MTNCL_Rounding_Checker is
generic(bitwidth: in integer := 4);
	port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		sel		: in  dual_rail_logic_vector(0 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_Rounding_Checker is

	component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    	port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component MTNCL_RCA_GEN is
	generic(bitwidth : in integer := 4);
	port(
		input    	: in  dual_rail_logic_vector((2*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector(bitwidth downto 0));
	end component;

	signal sum_1		: dual_rail_logic_vector(bitwidth downto 0);
	signal data_0, data_1		: dual_rail_logic;
	signal round_value		: dual_rail_logic_vector (0 downto 0);
	signal mux_input 	: dual_rail_logic_vector((2*bitwidth)-1 downto 0);
	signal mux_output 	: dual_rail_logic_vector((bitwidth)-1 downto 0);
	signal round_rca_input 	: dual_rail_logic_vector((2*bitwidth)-1 downto 0);

begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	--Setting the value for the second operand of the rounding RCA
	--0 if there is no need to round up
	setting_mux_zero_input : for i in 0 to bitwidth-1 generate
		mux_input(i) <= data_0;
	end generate;
	--1 if there is a need to round up
	mux_input(bitwidth) <= data_1;
	setting_mux_one_input : for i in bitwidth+1 to (2*bitwidth)-1 generate
		mux_input(i) <= data_0;
	end generate;
	
	--Prepare the input for the rounding adder
	round_rca_input <= input & mux_output;

	--Decide which value to add 0 or 1
	-- 0 if there is no rounding up
	-- 1 if there is a rounding up
  	zero_or_one: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => 2)
 	port map(
    		a => mux_input,
    		sel => sel,
    		sleep => sleep,
    		z => mux_output);

	--calculate the 
	Rounding_RCA : MTNCL_RCA_GEN 
		generic map(bitwidth)
		port map(
		round_rca_input,
		 ki, sleep, rst, sleepOut, ko,
		 sum_1);

	--the carry bit is truncated because we don't need it since we rounded up the sum value
	output <= sum_1 (bitwidth-1 downto 0);
	
end arch;
