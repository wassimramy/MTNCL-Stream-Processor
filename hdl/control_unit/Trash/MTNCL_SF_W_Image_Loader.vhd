
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

entity MTNCL_SF_W_Image_Loader is
generic(bitwidth: in integer := 4);
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

architecture arch of MTNCL_SF_W_Image_Loader is


  component MTNCL_SF_Node_W_Registers is
    generic(bitwidth: in integer := 4);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth-1) downto 0)
      );
  end component;

	signal input_1		: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal data_0, data_1	: dual_rail_logic;
	signal sleep_1, ko_1	: std_logic;

begin

	data_0.rail0 <= '1';
	data_0.rail1 <= '0';
	data_1.rail0 <= '0';
	data_1.rail1 <= '1';

	reset_count(0) <= data_0;
	reset_count(1) <= data_0;
	reset_count(2) <= data_0;
	reset_count(3) <= data_1;

	--store each pixel value and output all 9 pixels at once
	input_register : OAAT_in_all_out
	generic map(bitwidth, 9, 4, 1)
	port map( a => input, reset_count => reset_count, sleep_in => sleep, reset => rst, ki => ko_1, ko => ko, sleep_out => sleep_1, z => input_1);

	--give the values to  the SF node to apply the smoothing effect
	SF_W_Registers_instance : MTNCL_SF_Node_W_Registers
	generic map(bitwidth)
	port map(
						input => input_1,
						ki => ki,
						sleep => ,
						rst => rst, 
						sleepOut => sleepOut,
						ko => ko_1,
						output => output);

end arch;
