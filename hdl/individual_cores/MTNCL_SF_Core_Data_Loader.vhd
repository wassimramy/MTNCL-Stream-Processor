--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Core_Data_Loader is
	generic(
		bitwidth 		: integer := 8;
		sf_cores 		: integer := 2;
		addresswidth 	: integer := 12);
	port(
		pixel 			: in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset 			: in std_logic;
		ki 				: in std_logic;
		id 				: in dual_rail_logic;
		parallelism_en 	: in dual_rail_logic;
		ko 				: out std_logic;
		sleep_in 		: in std_logic;
		sleep_out 		: out std_logic;
		z 				: out dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Data_Loader;



architecture arch_MTNCL_SF_Core_Data_Loader of MTNCL_SF_Core_Data_Loader is 

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

	component MTNCL_SF_Core_Address_Gen_w_MUX is
	generic(
			bitwidth 		: integer := bitwidth;
			sf_cores 		: integer := sf_cores;
			addresswidth 	: integer := addresswidth);
			
	port(

			input 			: in dual_rail_logic_vector(4096*bitwidth-1 downto 0);
			reset 			: in std_logic;
			ki 				: in std_logic;
			id 				: in dual_rail_logic;
			parallelism_en 	: in dual_rail_logic;
			sleep_in 		: in std_logic;
			ko 				: out std_logic;
			sleep_out 		: out std_logic;
			z 				: out dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0));
	end component;

signal output_reg : dual_rail_logic_vector(4096*bitwidth-1 downto 0);
signal ko_sf_add_gen, sleep_out_reg : std_logic;
signal reset_count : dual_rail_logic_vector(addresswidth-1 downto 0);
--signal reset_count_p_1 : dual_rail_logic_vector(addresswidth downto 0);
signal data0, data1 : dual_rail_logic;

begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	reset_count <= data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1;	
	--reset_count_p_1 <= data1 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0;	
	output_all_pixels_at_once : OAAT_in_all_out
	generic map(bitwidth => bitwidth, numInputs => 4096, counterWidth => addresswidth, delay_amount => 0)
	port map( 
				a => pixel, 
				reset_count => reset_count,
				sleep_in => sleep_in, 
				reset => reset, 
				ki => '1', 
				ko => ko, 
				sleep_out => sleep_out_reg, 
				z => output_reg
			);

		sf_address_gen_w_mux_instance : MTNCL_SF_Core_Address_Gen_w_MUX
		generic map(
					bitwidth => bitwidth,
					--sf_cores => sf_cores,
					addresswidth => addresswidth)
		port map(
				input => output_reg,
				reset => reset,
				ki => ki,
				id => id,
				parallelism_en => parallelism_en,
				ko => ko_sf_add_gen,
				sleep_in => sleep_out_reg,
				sleep_out => sleep_out,
				z => z
		);	

end arch_MTNCL_SF_Core_Data_Loader; 
