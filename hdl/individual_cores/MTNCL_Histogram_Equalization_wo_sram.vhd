
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

entity MTNCL_Histogram_Equalization_wo_sram is
generic(
					bitwidth: in integer := 8; 
					addresswidth: in integer := 12; 
					clock_delay: in integer := 12; 
					mem_delay: in integer := 12; 
					numberOfShades: in integer := 256; 
					shadeBitwidth: in integer := 12; 
					numberOfPixels: in integer := 4096
				);
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

architecture arch of MTNCL_Histogram_Equalization_wo_sram is

	component MTNCL_Shade_Calculator is
	generic(bitwidth: in integer := 4;  shadeBitwidth: in integer := 12);
	port(
		input    	: in  dual_rail_logic_vector(shadeBitwidth-1 downto 0);
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
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		image_stored: out std_logic;
		output   	: out dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0));
	end component;


	  component OAAT_in_all_out_lite is
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

	component OAAT_out_all_in_forever is
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

	component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			sleep: in std_logic;
			z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
	end component; 

	component counter_selfReset is
		generic(width: integer);
		port(	reset_count: in dual_rail_logic_vector(width-1 downto 0);
			sleep_in: in std_logic;
		 	reset: in std_logic;
		 	ki: in std_logic;
		 	ko: out std_logic;
		 	sleep_out: out std_logic;
		 	accumulate_reset: out dual_rail_logic;
		 	z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	signal data_0,data_1		: dual_rail_logic;
	signal accReset_loaded, accReset_stored, accReset_1: dual_rail_logic;
	signal roundedPixelRegister	: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal reset_count	: dual_rail_logic_vector(shadeBitwidth downto 0);
	signal ko_trial: std_logic;
	signal kos, sleeps: std_logic_vector (6 downto 0);

	signal hold, accReg: dual_rail_logic_vector((shadeBitwidth)-1 downto 0);

	signal non_repeatable_register_count_0 : dual_rail_logic_vector((2*shadeBitwidth) downto 0);
	signal newShadeValues: dual_rail_logic_vector(numberOfShades*bitwidth-1 downto 0);
	signal shade_counter_output: dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0);
	
	signal count: dual_rail_logic_vector((shadeBitwidth) downto 0);
	signal write_en, write_en_sel: dual_rail_logic_vector(0 downto 0);
	signal image_loaded, image_stored, ki_image_reconstructor : std_logic;


begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	setting_reset_count : for i in 0 to shadeBitwidth-1 generate
		reset_count(i) <= data_0 ;
	end generate;
	reset_count(shadeBitwidth) <= data_1 ;

	global_ko : MUX21_A 
		port map(
			A => ko_trial, 
			B =>  kos(6),
			S => image_stored,
			Z => ko);		

ko_trial <= kos(1);

	--Shade counter to count the occurence of each shade in the input image 
	shade_counter_instance : MTNCL_Shade_Counter
	generic map(bitwidth => bitwidth, numberOfShades => numberOfShades, shadeBitwidth => shadeBitwidth)
	port map( input => input, 
		sleep => sleep,
		rst => rst, 
		sleepOut => sleeps(1), 
		ko => kos(1),
		image_stored => image_stored,
		output => shade_counter_output);

	--Hold the shade counts and will output them one by one to the Image Reconstructor
	shade_counter_register : OAAT_out_all_in_forever
	generic map(bitwidth => shadeBitwidth, numInputs => numberOfShades)
	port map( a => shade_counter_output,
 	reset_count => reset_count(bitwidth-1 downto 0),
	sleep_in => sleeps(1),
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
		ki => kos(5), 
		sleep => sleeps(3), 
		rst => rst, 
		sleepOut => sleeps(4), 
		ko => kos(4), 
		output => accReg ((shadeBitwidth-1) downto (shadeBitwidth-bitwidth)));

	--Take each new shade and output all at once
	new_shade_values_register : OAAT_in_all_out_lite
	generic map(bitwidth => bitwidth, numInputs => numberOfShades, counterWidth => bitwidth, delay_amount => 15)
	port map( 
	a => accReg ((shadeBitwidth-1) downto (shadeBitwidth-bitwidth)), 
	reset_count => reset_count(bitwidth-1 downto 0), 
	sleep_in => sleeps(4), 
	reset => rst, 
	ki => '1', 
	ko => kos(5), 
	sleep_out => sleeps(5), 
	z => newShadeValues(numberOfShades*bitwidth-1 downto 0));

	--Image constructor takes all the new shade values, the old pixel, and output the same pixel with the new shade 
	image_reconstructor_instance : MTNCL_Image_Reconstructor
	generic map(bitwidth => bitwidth, numberOfShades => numberOfShades)
	port map( input => newShadeValues(numberOfShades*bitwidth-1 downto 0), 
	pixel => input, 
	ki => ki,
	sleep => sleep, 
	rst => rst, 
	sleepOut => sleepOut, 
	ko => kos(6), 
	output => output);

end arch;
