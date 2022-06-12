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
		parallelism_en 	: in dual_rail_logic_vector(1 downto 0);
		sleep_in_node_1 : in std_logic;
		sleep_in_node_2 : in std_logic;
		ko_node_1 		: out std_logic;
		ko_node_2 		: out std_logic;
		sleep_out 		: out std_logic;
		z 				: out dual_rail_logic_vector(2*bitwidth-1 downto 0)
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

component th22d_a is
	port(a   : in  std_logic;
		 b   : in  std_logic;
		 rst : in  std_logic;
		 z   : out std_logic);
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

signal ki_single_core_input, sleep_out_single_core_input, ko_single_core_input, ki_main_memory, sleep_out_main_memory, ko_main_memory, pre_ko, pre_ko_node_1, pre_ko_node_2  : std_logic;
signal ko_counter, sleep_out_counter, global_sleep_in, ko_1, sleep_out_1 : std_logic;
signal ko_output_registers_2P, ko_output_registers_non_2P, sleep_out_output_registers_2P, sleep_out_output_registers_non_2P : std_logic;

signal pixel_a, pixel_b : dual_rail_logic_vector(bitwidth-1 downto 0);
signal pixel_output_registers_non_2P, pixel_output_registers_2P, double_pixel_a : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal input_output_2P_registers : dual_rail_logic_vector(4*bitwidth-1 downto 0);


signal const_4096, count : dual_rail_logic_vector(addresswidth downto 0);

signal input_mux : dual_rail_logic_vector(1 downto 0);
signal parallelism_en_vector : dual_rail_logic_vector(1 downto 0);

signal data0, data1 : dual_rail_logic;
signal accRes : dual_rail_logic;
begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	--Generate 4096
	generate_4096 : for i in 0 to addresswidth-1 generate
		const_4096(i) <= data0;
	end generate;
	const_4096(addresswidth) <= data1;


		input_mux <= count(addresswidth-1 downto addresswidth-1) & data0;
		global_input_mux: mux_nto1_gen
			generic map(bitwidth => 1,
			numInputs => 2)
 			port map(
	    		a => input_mux ,
	    		sel => parallelism_en(0 downto 0),
	    		sleep => '0',
    			z => parallelism_en_vector(1 downto 1));

	generate_global_sleep_in : MUX21_A 
		port map(
			A => sleep_in_node_1, 
			B => sleep_in_node_2,
			S => parallelism_en_vector(1).rail1,
			Z => global_sleep_in);

	MUX_select_generate : counter_selfReset
		generic map(width => addresswidth+1)
		port map(reset_count => const_4096,
			sleep_in => global_sleep_in,
		 	reset => reset,
		 	ko => ko_counter,
		 	ki => ki,
		 	sleep_out => sleep_out_counter,
		 	accumulate_reset => accRes,
		 	z => count);

		global_input: mux_nto1_gen
			generic map(bitwidth => bitwidth,
			numInputs => 2)
 			port map(
	    		a => pixel ,
	    		sel => parallelism_en_vector(1 downto 1),
	    		sleep => '0',
    			z => pixel_a);

	
		double_pixel_a <= pixel_a & pixel_a;
		output_registers_non_2P_mux : regs_gen_null_res_w_compm
		generic map(width => 2*bitwidth)
		port map(
			d => double_pixel_a,
			reset => reset,
			sleep_in => global_sleep_in,
			ki => ki,
			sleep_out => sleep_out_output_registers_non_2P,
			ko => ko_output_registers_non_2P,
			q => pixel_output_registers_non_2P
			);

		
		generate_pre_ko_node_1 : MUX21_A 
		port map(
			A => ko_counter,
			B => '1',
			S => parallelism_en_vector(1).rail1,
			Z => pre_ko_node_1);

		generate_pre_ko_node_2 : MUX21_A 
		port map(
			A => '1',
			B => ko_counter,
			S => parallelism_en_vector(1).rail1,
			Z => pre_ko_node_2);

		generate_ko_node_1 : MUX21_A 
		port map(
			A => pre_ko_node_1,
			B => ko_output_registers_2P,
			S => parallelism_en(1).rail1,
			Z => ko_node_1);

		generate_ko_node_2 : MUX21_A 
		port map(
			A => pre_ko_node_2,
			B => ko_output_registers_2P,
			S => parallelism_en(1).rail1,
			Z => ko_node_2);	
			
		
		output_2P_registers : regs_gen_null_res_w_compm
		generic map(width => 2*bitwidth)
		port map(
			d => pixel,
			reset => reset,
			sleep_in => sleep_in_node_1,
			ki => ki,
			sleep_out => sleep_out_output_registers_2P,
			ko => ko_output_registers_2P,
			q => pixel_output_registers_2P
			);  	

			input_output_2P_registers <= pixel_output_registers_2P & pixel_output_registers_non_2P;
			global_output_mux: mux_nto1_gen
			generic map(bitwidth => 2*bitwidth,
			numInputs => 2)
 			port map(
	    		a => input_output_2P_registers ,
	    		sel => parallelism_en(1 downto 1),
	    		sleep => '0',
    			z => z);

    		global_sleep_out : MUX21_A 
			port map(
			A => sleep_out_output_registers_non_2P,
			B => sleep_out_output_registers_2P,
			S => parallelism_en(1).rail1,
			Z => sleep_out);	

end arch_MTNCL_CU_Data_Output; 
