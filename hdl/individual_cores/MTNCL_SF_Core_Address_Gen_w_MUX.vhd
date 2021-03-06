--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Core_Address_Gen_w_MUX is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(
		input : in dual_rail_logic_vector(4096*bitwidth-1 downto 0);
		reset : in std_logic;
		ki : in std_logic;
		id 				: in dual_rail_logic;
		parallelism_en 	: in dual_rail_logic;
		sleep_in : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z: out dual_rail_logic_vector(2*bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Address_Gen_w_MUX;



architecture arch_MTNCL_SF_Core_Address_Gen_w_MUX of MTNCL_SF_Core_Address_Gen_w_MUX is 

	component inv_a is 
		port(a: in std_logic; 
			 z: out std_logic); 
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

	component mux_nto1_sr_gen is
		generic(bitwidth: integer := 4;
			numInputs : integer := 4);
	    port(a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			 z: out std_logic_vector(bitwidth-1 downto 0));
	end component;

	component sf_address_generator is
	generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth);
			
	port(
		reset : in std_logic;
		ki : in std_logic;
		sleep_in : in std_logic;
		id 				: in dual_rail_logic;
		parallelism_en 	: in dual_rail_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		sf_address_generator_done : out std_logic;
		z : out dual_rail_logic_vector(addresswidth downto 0));
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

	component and2_a is 
		port(a,b: in std_logic; 
			 z: out std_logic); 
	end component; 

signal output_mux_a, output_mux_b : dual_rail_logic_vector(bitwidth-1 downto 0);
signal output_register_input : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal input_mux : dual_rail_logic_vector(4356*bitwidth-1 downto 0);

signal input_mux_a : dual_rail_logic_vector(2*2244*bitwidth-1 downto 0);
signal input_mux_b : dual_rail_logic_vector(4*2244*bitwidth-1 downto 0);
signal choose_pixel_a_input, choose_pixel_b_input : dual_rail_logic_vector(2244*bitwidth-1 downto 0);

signal ko_sf_core_address_gen, sleep_in_sf_core_address_gen, sleepout_sf_add_gen, sf_address_generator_done, output_reg_ko, output_reg_sleep_out, sf_core_w_reg_sleep_out, sleepout_add_select_mux_a, sleepout_add_select_mux_b, ko_add_select_mux_a, ko_add_select_mux_b : std_logic;
signal ki_mux_input : std_logic_vector (1 downto 0);
signal ki_mux_output, ki_mux_select : std_logic_vector (0 downto 0);

signal select_mux: dual_rail_logic_vector(addresswidth downto 0);
signal select_mux_a, select_mux_b: dual_rail_logic_vector(addresswidth downto 0);
signal add_select_mux_a, add_select_mux_b: dual_rail_logic_vector(2*addresswidth-1  downto 0);
--signal const_1122: dual_rail_logic_vector(addresswidth-1 downto 0);

signal parallelism_en_vector_b : dual_rail_logic_vector(1  downto 0);
signal parallelism_en_vector_a : dual_rail_logic_vector(0  downto 0);

signal data0, data1 : dual_rail_logic;
signal accRes : dual_rail_logic;

begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	--const_1122 <= data0 & data1 & data0 & data0 & data0 & data1 & data1 & data0 & data0 & data0 & data1 & data0 ;
	--const_1122 <= data0 & data1 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data0 & data1 ;
	generate_sleep_select_0 : for i in 0 to 527 generate
		input_mux(i) <= data0;
	end generate;

	generate_sleep_select_1 : for i in 1 to 64 generate
		generate_sleep_select_2 : for j in 1 to 64 generate
			input_mux(i*66*bitwidth+j*bitwidth+bitwidth-1 downto i*66*bitwidth+j*bitwidth) <= input ((i-1)*64*bitwidth+(j-1)*bitwidth+bitwidth-1 downto (i-1)*64*bitwidth+(j-1)*bitwidth);
		end generate;
	end generate;

	generate_sleep_select_3 : for i in 1 to 64 generate
		generate_sleep_select_4 : for j in 1 to 16 generate
			input_mux(i*66*bitwidth-bitwidth-1+j) <= data0;
		end generate;
	end generate;

	generate_sleep_select_6 : for i in 34312 to 34847 generate
		input_mux(i) <= data0;
	end generate;

	choose_pixel_a : mux_nto1_gen
	generic map(bitwidth => bitwidth, numInputs => 2244)
		port map(
			--a => input_mux(2244*bitwidth-1 downto 0),
			a => choose_pixel_a_input,
			sel => select_mux (addresswidth-1 downto 0),
			sleep => '0',
			z => output_mux_a);	

	ko <= ko_sf_core_address_gen;

	generate_sleep_in_sf_core_address_gen : inv_a
	port map(
		a => ko_sf_core_address_gen,
		z => sleep_in_sf_core_address_gen);

		sf_add_gen_instance : sf_address_generator
		generic map(bitwidth => bitwidth,
					addresswidth => addresswidth)
		port map(
				reset 						=> reset,
				ki 							=> output_reg_ko,
				sleep_in 					=> sleep_in_sf_core_address_gen,
				id 							=> id,
				parallelism_en				=> parallelism_en,
				ko 							=> ko_sf_core_address_gen,
				sleep_out 					=> sleepout_sf_add_gen,
				sf_address_generator_done 	=> sf_address_generator_done,
				z 							=> select_mux
		);	

	generate_parallelism_en_vector_a_rail1 : and2_a 
	port map(
			a => parallelism_en.rail1,
			b => id.rail1,
			z => parallelism_en_vector_a(0).rail1);

	generate_parallelism_en_vector_a_rail0 : inv_a
	port map(
		a => parallelism_en_vector_a(0).rail1,
		z => parallelism_en_vector_a(0).rail0);

	input_mux_a <=  input_mux(4356*bitwidth-1 downto 2112*bitwidth) & input_mux(2244*bitwidth-1 downto 0) ;
	generate_choose_pixel_a_input : mux_nto1_gen
	generic map(bitwidth => 2244*bitwidth, numInputs => 2)
		port map(
			a => input_mux_a,
			sel => parallelism_en_vector_a(0 downto 0),
			sleep => '0',
			z => choose_pixel_a_input);	

	--generate_parallelism_en_vector_b_rail1 : and2_a 
	--port map(
	--		a => parallelism_en.rail1,
	--		b => id.rail0,
	--		z => parallelism_en_vector_b(0).rail1);

	--generate_parallelism_en_vector_b_rail0 : inv_a
	--port map(
	--	a => parallelism_en_vector_b(0).rail1,
	--	z => parallelism_en_vector_b(0).rail0);

	parallelism_en_vector_b (1 downto 0) <= id & parallelism_en;
	--Option 0
	input_mux_b (1*2244*bitwidth-1 downto 0) 				<= input_mux(4356*bitwidth-1 downto 2112*bitwidth);
	--Option 1
	input_mux_b (2*2244*bitwidth-1 downto 1*2244*bitwidth) 	<= input_mux(1056*bitwidth-1 downto 0) & input_mux(2244*bitwidth-1 downto 1056*bitwidth);
	--Option 2
	input_mux_b (3*2244*bitwidth-1 downto 2*2244*bitwidth) 	<= input_mux(4356*bitwidth-1 downto 2112*bitwidth);
	--Option 3
	input_mux_b (4*2244*bitwidth-1 downto 3*2244*bitwidth) 	<= input_mux(3168*bitwidth-1 downto 2112*bitwidth) & input_mux(4356*bitwidth-1 downto 3168*bitwidth);

	--input_mux_b <=  input_mux(1056*bitwidth-1 downto 0) & input_mux(2244*bitwidth-1 downto 1056*bitwidth) & input_mux(4356*bitwidth-1 downto 2112*bitwidth) ;
	generate_choose_pixel_b_input : mux_nto1_gen
	generic map(bitwidth => 2244*bitwidth, numInputs => 4)
		port map(
			a => input_mux_b,
			sel => parallelism_en_vector_b(1 downto 0),
			sleep => '0',
			z => choose_pixel_b_input);	

	--generate_choose_pixel_b_input : mux_nto1_gen
	--generic map(bitwidth => 2244*bitwidth, numInputs => 2)
	--	port map(
	--		a => input_mux_b,
	--		sel => parallelism_en_vector_b(0 downto 0),
	--		sleep => '0',
	--		z => choose_pixel_b_input);			

    choose_pixel_b : mux_nto1_gen
	generic map(bitwidth => bitwidth, numInputs => 2244)
		port map(
			--a => input_mux(4356*bitwidth-1 downto 2112*bitwidth),
			a => choose_pixel_b_input,
			sel => select_mux (addresswidth-1 downto 0),
			sleep => '0',
			z => output_mux_b);	

	
	output_register_input <= output_mux_b & output_mux_a;
	output_register: regs_gen_null_res_w_compm
		generic map(width => 2*bitwidth)
		port map(
			d => output_register_input,
			reset => reset,
			sleep_in => sleepout_sf_add_gen,
			ki => ki_mux_output(0),
			sleep_out => output_reg_sleep_out,
			ko => output_reg_ko,
			q => z
			);		

	ki_mux_select(0) <= sf_address_generator_done;
	ki_mux_input <= '1' & ki;
	generate_global_sleepout : mux_nto1_sr_gen
			generic map(	bitwidth => 1, numInputs => 2 )
				port map(
					a => ki_mux_input,
					sel => ki_mux_select,
					z => ki_mux_output);

    sleep_out <= output_reg_sleep_out;

end arch_MTNCL_SF_Core_Address_Gen_w_MUX; 
