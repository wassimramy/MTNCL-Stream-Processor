
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

entity MTNCL_HEQ_W_Image_Loader is
generic(bitwidth: in integer := 4; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096);
	port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_HEQ_W_Image_Loader is

  component MTNCL_Histogram_Equalization is
    generic(bitwidth: in integer := 4; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth)-1 downto 0)
      );
  end component;

	component th22d_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			rst: in std_logic;
			z: out std_logic);
	end component;

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

	component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
	end component; 

	signal data_0,data_1		: dual_rail_logic;
	signal accReset, accReset_1: dual_rail_logic;
	signal roundedPixelRegister	: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal reset_count, reset_count_plus_one, reset_count_plus_one_plus_one	: dual_rail_logic_vector(shadeBitwidth downto 0);
	signal not_accReset, ko_trial: std_logic;
	signal kos, sleeps: std_logic_vector (6 downto 0);


	signal hold, accReg: dual_rail_logic_vector((shadeBitwidth)-1 downto 0);

	signal non_repeatable_register_count, non_repeatable_register_count_0, non_repeatable_register_count_1, count_equal: dual_rail_logic_vector((2*shadeBitwidth) downto 0);
	signal newShadeValues: dual_rail_logic_vector(numberOfShades*bitwidth-1 downto 0);
	signal shade_counter_output: dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0);
	signal input_register_output, nonRepeatableInput: dual_rail_logic_vector(((numberOfPixels+2)*bitwidth)-1 downto 0);
	
	signal sleep_out_1, ko_1, ko_0, sleep_out_2, ko_2: std_logic;
	signal reg_00: dual_rail_logic_vector(((numberOfPixels+2)*bitwidth)-1 downto 0);
	signal new_input: dual_rail_logic_vector((bitwidth)-1 downto 0);
	signal accReset_00: dual_rail_logic;
	signal not_accReset_00: std_logic;
begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	setting_reset_count : for i in 0 to shadeBitwidth generate
		reset_count(i) <= data_1 ;
	end generate;

	setting_reset_count_plus_one : for i in 1 to shadeBitwidth-1 generate
		reset_count_plus_one(i) <= data_0 ;
		reset_count_plus_one_plus_one(i) <= data_0;
	end generate;
	reset_count_plus_one(0) <= data_0 ;
	reset_count_plus_one_plus_one (0) <= data_1;
	reset_count_plus_one(shadeBitwidth) <= data_1 ;
	reset_count_plus_one_plus_one(shadeBitwidth) <= data_1 ;




end arch;
