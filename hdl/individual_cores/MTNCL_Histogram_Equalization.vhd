
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
generic(
					bitwidth: in integer := 4; 
					addresswidth: in integer := 12; 
					clock_delay: in integer := 12; 
					mem_delay: in integer := 12; 
					numberOfShades: in integer := 256; 
					shadeBitwidth: in integer := 12; 
					numberOfPixels: in integer := 4096);
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
	
		component image_store_load is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(

			mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
			read_address : in dual_rail_logic_vector(addresswidth-1 downto 0);
			write_en : in dual_rail_logic;
			standard_read_en : in dual_rail_logic;
			parallelism_en : in dual_rail_logic;
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			image_loaded : out std_logic;
			accReset_loaded : out dual_rail_logic;
			image_stored : out std_logic;
			accReset_stored : out dual_rail_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0)
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
	
	signal write_en_inputs: dual_rail_logic_vector(1 downto 0);
	signal write_en, write_en_sel: dual_rail_logic_vector(0 downto 0);
	signal image_loaded, image_stored, ki_image_reconstructor : std_logic;


begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	setting_reset_count : for i in 0 to shadeBitwidth generate
		reset_count(i) <= data_1 ;
	end generate;

	--Generate the right write_en value
	write_en_sel(0).RAIL1 <= image_stored;
	write_en_generation : inv_a
		port map(a => image_stored,
			z => write_en_sel(0).RAIL0);

	write_en_inputs <= data_0 & data_1 ;
	generate_sram_address : mux_nto1_gen
	generic map(bitwidth => 1,
			numInputs => 2)
		port map(
			a => write_en_inputs,
			sel => write_en_sel(0 downto 0),
			sleep => '0',
			z => write_en);

	image_store_load_instance : image_store_load
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)

		port map(
				mem_data => input,
				read_address => reset_count(shadeBitwidth-1 downto 0),
				write_en => write_en(0),
				standard_read_en => data_1,
				parallelism_en => data_0,
				reset => rst,
				ki => kos(6),
				ko => kos(0),
				sleep_in => sleep,
				sleep_out => sleeps(0),
				image_loaded => image_loaded,
				accReset_loaded => accReset_loaded,
				image_stored => image_stored,
				accReset_stored => accReset_stored,
				z => roundedPixelRegister
		);

	th22d_global_ko : th22d_tree_gen
	generic map(numInputs => 2 )
		port map(
			a => kos(1 downto 0),
			rst => rst,
			z => ko_trial);

	--Shade counter to count the occurence of each shade in the input image 
	shade_counter_instance : MTNCL_Shade_Counter
	generic map(bitwidth => bitwidth, numberOfShades => numberOfShades, shadeBitwidth => shadeBitwidth)
	port map( input => input, 
		ki => kos(0), 
		sleep => sleep,
		rst => rst, 
		sleepOut => sleeps(1), 
		ko => kos(1), 
		output => shade_counter_output);

	--Hold the shade counts and will output them one by one to the Image Reconstructor
	shade_counter_register : OAAT_out_all_in
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
		count => non_repeatable_register_count_0(bitwidth-1 downto 0), 
		ki => kos(5), 
		sleep => sleeps(3), 
		rst => rst, 
		sleepOut => sleeps(4), 
		ko => kos(4), 
		output => accReg ((shadeBitwidth-1) downto (shadeBitwidth-bitwidth)));

--	--Take each new shade and output all at once
	new_shade_values_register : OAAT_in_all_out
	generic map(bitwidth => bitwidth, numInputs => numberOfShades, counterWidth => bitwidth, delay_amount => 0)
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
	pixel => roundedPixelRegister, 
	ki => ki_image_reconstructor, 
	sleep => sleeps(0), 
	rst => rst, 
	sleepOut => sleepOut, 
	ko => kos(6), 
	output => output);

	global_ko : MUX21_A 
		port map(
			A => kos(0),
			B => ko_trial, 
			S => sleeps(1),
			Z => ko);

	global_ki : MUX21_A 
		port map(
			A => ki,
			B => '1', 
			S => image_loaded,
			Z => ki_image_reconstructor);

end arch;
