
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

entity MTNCL_Histogram_Equalization is
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

architecture arch of MTNCL_Histogram_Equalization is

	component MTNCL_Shade_Calculator is
	generic(bitwidth: in integer := 4;  shadeBitwidth: in integer := 12);
	port(
		input    	: in  dual_rail_logic_vector(shadeBitwidth-1 downto 0);
		count    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		lastPixel    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component MTNCL_Image_Reconstructor is
	generic(bitwidth: in integer := 4; numberOfShades: in integer := 256);
	port(
		input    	: in  dual_rail_logic_vector((numberOfShades)*bitwidth-1 downto 0);
		pixel    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component MTNCL_Shade_Counter is
	generic(bitwidth: in integer := 4; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12);
	port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0));
	end component;


	  component OAAT_in_all_out is
		generic( bitwidth : integer := 16; numInputs : integer := 64; counterWidth : integer := 6; delay_amount : integer := 6);
	    port(
			a : in dual_rail_logic_vector(bitwidth-1 downto 0);
			reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
			sleep_in: in std_logic;
			reset: in std_logic;
			ki: in std_logic;
			ko: out std_logic;
			sleep_out: out std_logic;
			z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0)
	      );
	  end component;

	component OAAT_out_all_in is
		generic(bitwidth: integer := 8; numInputs : integer := 256);
		port(a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0); --CHANGE COUNTER WIDTH
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		accumulate_reset: out dual_rail_logic;
		count: out dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		z: out dual_rail_logic_vector(bitwidth-1 downto 0));
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



	input_reg_0 : OAAT_in_all_out
	generic map(bitwidth => bitwidth, numInputs => numberOfPixels, counterWidth => shadeBitwidth+1, delay_amount => 0)
	port map( a => input, 
	reset_count => reset_count_plus_one,
	sleep_in => sleep,
	reset => rst, 
	ki => ko_2, 
	ko => ko, 
	sleep_out => sleep_out_1, 
	z => reg_00(numberOfPixels*bitwidth-1 downto 0));

	not_accReset_00 <= (not accReset_00.RAIL1) or (not kos(3));
	--not_accReset_00 <= (accReset_00.RAIL1) and (kos(3));

	reg_00((numberOfPixels+2)*bitwidth-1 downto numberOfPixels*bitwidth) <= reset_count_plus_one(bitwidth-1 downto 0) & reset_count_plus_one(bitwidth-1 downto 0);

	input_reg_1 : OAAT_out_all_in
	generic map(bitwidth => bitwidth, numInputs => numberOfPixels+2)
	port map( a => reg_00((numberOfPixels+2)*bitwidth-1 downto 0),
 	reset_count => reset_count_plus_one_plus_one,
	sleep_in => sleep_out_1,
	reset => rst, 
	ki => ko_0, 
	ko => ko_2, 
	sleep_out => sleep_out_2, 
	accumulate_reset => accReset_00, 
	count => non_repeatable_register_count_1 (shadeBitwidth downto 0), 
	z => new_input);

	th22d_global_ko : th22d_tree_gen
	generic map(numInputs => 2 )
		port map(
			a => kos(1 downto 0),
			rst => rst,
			z => ko_0);


	--Shade counter to count the occurence of each shade in the input image 
	shade_counter_instance : MTNCL_Shade_Counter
	generic map(bitwidth => bitwidth, numberOfShades => numberOfShades, shadeBitwidth => shadeBitwidth)
	--port map( input => input, ki => kos(0), sleep => sleep, rst => rst, sleepOut => sleeps(1), ko => kos(1), output => shade_counter_output);
	port map( input => new_input, ki => kos(0), sleep => sleep_out_2, rst => rst, sleepOut => sleeps(1), ko => kos(1), output => shade_counter_output);
	--port map( input => new_input, ki => ko_trial, sleep => sleep_out_2, rst => rst, sleepOut => sleeps(1), ko => kos(1), output => shade_counter_output);

	--Hold the shade counts and will output them one by one to the Image Reconstructor
	shade_counter_register : OAAT_out_all_in
	generic map(bitwidth => shadeBitwidth, numInputs => numberOfShades)
	port map( a => shade_counter_output,
 	reset_count => reset_count(bitwidth-1 downto 0),
	sleep_in => not_accReset_00,
	--sleep_in => sleeps(0),
	reset => rst, 
	ki => kos(4), 
	ko => kos(3), 
	sleep_out => sleeps(3), 
	accumulate_reset => accReset_1, 
	count => non_repeatable_register_count_0 (bitwidth-1 downto 0), 
	z => hold);

	--Shade calculator to calculate the new shade value to get mapped to
	shade_calculator_instance : MTNCL_Shade_Calculator
	generic map(bitwidth => bitwidth, shadeBitwidth => shadeBitwidth)
	port map( 
		input => hold, 
		count => non_repeatable_register_count_0(bitwidth-1 downto 0), 
		lastPixel => input_register_output((numberOfPixels+1)*bitwidth-1 downto (numberOfPixels)*bitwidth), 
		ki => kos(6), 
		sleep => sleeps(3), 
		rst => rst, 
		sleepOut => sleeps(4), 
		ko => kos(4), 
		output => accReg ((shadeBitwidth-1) downto (shadeBitwidth-bitwidth)));

	--Take each new shade and output all at once
	new_shade_values_register : OAAT_in_all_out
	generic map(bitwidth => bitwidth, numInputs => numberOfShades, counterWidth => bitwidth, delay_amount => 0)
	port map( 
	a => accReg ((shadeBitwidth-1) downto (shadeBitwidth-bitwidth)), 
	reset_count => reset_count(bitwidth-1 downto 0), 
	sleep_in => sleeps(4), 
	reset => rst, 
	ki => not_accReset, 
	ko => kos(6), 
	sleep_out => sleeps(6), 
	z => newShadeValues(numberOfShades*bitwidth-1 downto 0));

	--Use the not_accReset signal to control the ki of the special purpose calculator 
	not_accReset_generation : inv_a
		port map(a => accReset.RAIL1,
			z => not_accReset);

	--Store image pixels for future use in the Image Reconstructor
	input_register : OAAT_in_all_out
	generic map(bitwidth => bitwidth, numInputs => numberOfPixels+2, counterWidth => shadeBitwidth+1, delay_amount => 0)
	port map( 
	--a => input, 
	a => new_input, 
	reset_count => reset_count_plus_one,
	--sleep_in => sleep,
	sleep_in => sleep_out_2,
	reset => rst, 
	ki => not_accReset, 
	ko => kos(0), 
	sleep_out => sleeps(0), 
	z => input_register_output);

	nonRepeatableInput(numberOfPixels*bitwidth-1 downto 0) <= input_register_output(numberOfPixels*bitwidth-1 downto 0);
	--Add 2 new dummy values to make sure that the register will go through all pixels
	nonRepeatableInput((numberOfPixels+2)*bitwidth-1 downto (numberOfPixels)*bitwidth) <= reset_count_plus_one(bitwidth-1 downto 0) & reset_count_plus_one(bitwidth-1 downto 0);

	--Store all image pixels at once and output one by one for future use in the Image Reconstructor 
	non_repeatable_reg: OAAT_out_all_in
		generic map(bitwidth => bitwidth, numInputs => numberOfPixels+2)
		port map(a => nonRepeatableInput,
		reset_count => reset_count_plus_one , --Check the number limit
		sleep_in => sleeps(4),
		reset => rst,
		--ki => kos(5),
		ki => ko_trial,
		ko => kos(2),
		sleep_out => sleeps(2),
		accumulate_reset => accReset,
		count => non_repeatable_register_count (shadeBitwidth downto 0),
		z => roundedPixelRegister);

	--Image constructor takes all the new shade values, the old pixel, and output the same pixel with the new shade 
	image_reconstructor_instance : MTNCL_Image_Reconstructor
	generic map(bitwidth => bitwidth, numberOfShades => numberOfShades)
	port map( input => newShadeValues(numberOfShades*bitwidth-1 downto 0), 
	pixel => roundedPixelRegister, 
	ki => ki, 
	sleep => sleeps(2), 
	rst => rst, 
	sleepOut => sleepOut, 
	ko => kos(5), 
	output => output);
	--Generate sleep_SF

	global_ki : MUX21_A 
		port map(
			A => kos(5), 
			B => '1',
			S => accReset.RAIL1,
			Z => ko_trial);

end arch;
