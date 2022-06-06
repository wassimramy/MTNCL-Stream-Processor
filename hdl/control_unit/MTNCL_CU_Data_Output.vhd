--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_CU_Data_Output is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;
		mem_delay : integer := 48);
	port(
		pixel 			: in dual_rail_logic_vector(2*bitwidth-1 downto 0);
		reset 			: in std_logic;
		ki 				: in std_logic;
		parallelism_en 	: in dual_rail_logic;
		sleep_in 		: in std_logic;
		ko 				: out std_logic;
		sleep_out 		: out std_logic;
		z 				: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end MTNCL_CU_Data_Output;



architecture arch_MTNCL_CU_Data_Output of MTNCL_CU_Data_Output is 

	component MTNCL_SF_Core_Data_Output is
		generic(
			bitwidth 			: integer := bitwidth;
			addresswidth 	: integer := addresswidth;
			clock_delay 	: integer := clock_delay;
			mem_delay 		: integer := mem_delay
			);
		port(
				pixel : in dual_rail_logic_vector(2*bitwidth-1 downto 0);
				reset : in std_logic;
				ki : in std_logic;
				parallelism_en 	: in dual_rail_logic;
				ko : out std_logic;
				sleep_in : in std_logic;
				sleep_out : out std_logic;
				z : out dual_rail_logic_vector(bitwidth-1 downto 0)
			);
	end component;

	component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
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

	component inv_a is 
		port(a: in std_logic; 
			 z: out std_logic); 
	end component; 

	component or2_a is
		port(a, b : in  std_logic;
			 z : out std_logic);
	end component;

	component regs_gen_null_res_w_compm is
		generic(width: in integer := bitwidth);
		port(
				d: in dual_rail_logic_vector(width-1 downto 0);
				reset: in std_logic;
				sleep_in: in std_logic;
				ki: in std_logic;
				sleep_out: out std_logic;
				ko: out std_logic;
				q: out dual_rail_logic_vector(width-1 downto 0)
			);
	end component;

signal ki_single_core_input, sleep_out_single_core_input, ko_single_core_input, ki_main_memory, sleep_out_main_memory, ko_main_memory  : std_logic;
signal pixel_a, pixel_b : dual_rail_logic_vector(bitwidth-1 downto 0);
signal output : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal parallelism_en_vector : dual_rail_logic_vector(0 downto 0);
signal data0, data1 : dual_rail_logic;

begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	parallelism_en_vector(0) <= parallelism_en;
	single_core_input: regs_gen_null_res_w_compm
		generic map(width => bitwidth)
		port map(
			d => pixel (bitwidth-1 downto 0),
			reset => reset,
			sleep_in => sleep_in,
			ki => ki_single_core_input,
			sleep_out => sleep_out_single_core_input,
			ko => ko_single_core_input,
			q => pixel_a
			);

		
		global_ko : MUX21_A 
		port map(
			A => ko_single_core_input, 
			B => ko_main_memory,
			S => parallelism_en_vector(0).rail1,
			Z => ko);

		main_memory_instance : MTNCL_SF_Core_Data_Output
		generic map(bitwidth 		=> bitwidth,
					addresswidth 	=> addresswidth)
		port map(
				pixel 			=> pixel,
				reset 			=> reset,
				ki 				=> ki_main_memory,
				parallelism_en 	=> data0,
				sleep_in 		=> '0',
				ko 				=> ko_main_memory,
				sleep_out 		=> sleep_out_main_memory,
				z 				=> pixel_b
		);

		output <= pixel_b & pixel_a;
		global_output: mux_nto1_gen
			generic map(bitwidth => bitwidth,
			numInputs => 2)
 			port map(
	    		a => output ,
	    		sel => parallelism_en_vector(0 downto 0),
	    		sleep => '0',
    			z => z);

		image_store_load_instance_a_ki : MUX21_A 
		port map(
			A => ki, 
			B => '1',
			S => parallelism_en_vector(0).rail1,
			Z => ki_single_core_input);

		image_store_load_instance_b_ki : MUX21_A 
		port map(
			A => '1',
			B => ki, 
			S => parallelism_en_vector(0).rail1,
			Z => ki_main_memory);

		global_sleep_out : MUX21_A 
		port map(
			A => sleep_out_single_core_input, 
			B => sleep_out_main_memory,
			S => parallelism_en_vector(0).rail1,
			Z => sleep_out);	

		  	

end arch_MTNCL_CU_Data_Output; 
