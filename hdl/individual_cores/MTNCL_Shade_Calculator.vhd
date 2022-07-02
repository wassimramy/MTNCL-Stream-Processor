
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

entity MTNCL_Shade_Calculator is
generic(bitwidth: in integer := 8; shadeBitwidth: in integer := 12);
	port(
		input    	: in  dual_rail_logic_vector(shadeBitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_Shade_Calculator is

	component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    	port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component counter_selfReset_mod_inc is
		generic(width: integer);
		port(	 
			increment: in dual_rail_logic_vector(width-1 downto 0);
			sleep_in: in std_logic;
			reset: in std_logic;
			ki: in std_logic;
			ko: out std_logic;
			sleep_out: out std_logic;
			z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	signal kos, sleeps: std_logic_vector (1 downto 0);
	signal accumulate_reset_temp: dual_rail_logic_vector (0 downto 0);
	signal data_00: dual_rail_logic_vector (0 downto 0);
	signal roundedHold, accReg: dual_rail_logic_vector((shadeBitwidth)-1 downto 0);
	signal reset_count	: dual_rail_logic_vector(shadeBitwidth-1 downto 0);
	signal mux_Input: dual_rail_logic_vector(2*shadeBitwidth-1 downto 0);
	signal countUnit_Input, countUnit_Output: dual_rail_logic_vector(shadeBitwidth downto 0);
	signal data_0,data_1		: dual_rail_logic;

begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	data_00(0) <= data_0;
	--Setting a shadeBitwidth data_1 variable to use it later to avoid a 256 shade
	setting_reset_count : for i in 0 to shadeBitwidth-1 generate
		reset_count(i) <= data_1 ;
	end generate;

	--Set the block's global ko
	ko <= kos(1);

	--Add a data_0 to the roundedHold because the accumulator count width is set to log2(total number of pixels) instead of log2(total number of pixels -1)
	countUnit_Input <= data_0 & input;
	count_unit : counter_selfReset_mod_inc
		generic map(width => shadeBitwidth+1)
		port map(
			 increment => countUnit_Input,
			 sleep_in => sleep,
			 reset => rst,
			 ki => ki,
			 ko => kos(1),
			 sleep_out => sleeps(1),
			 z => countUnit_Output);

	--This mux is used to map the 256 shade value to 255 (reset_count) to prevent the overflow.
	mux_Input(2*shadeBitwidth-1 downto 0) <= reset_count (shadeBitwidth-1 downto 0) & countUnit_Output (shadeBitwidth-1 downto 0);
  	overflow: mux_nto1_gen
	generic map(bitwidth => shadeBitwidth,
		numInputs => 2)
 	port map(
    		a => mux_Input(2*shadeBitwidth-1 downto 0),
    		sel => countUnit_Output(shadeBitwidth downto shadeBitwidth),
    		sleep => '0',
    		z => accReg);

	--Set the global sleepOut
	sleepOut <= sleeps(1);

	--Divide the accReg by shifting right and then output the value
	output <= accReg((shadeBitwidth-1) downto (shadeBitwidth-bitwidth));
end arch;
