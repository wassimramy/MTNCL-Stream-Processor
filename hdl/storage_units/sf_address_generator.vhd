--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity sf_address_generator is
	generic(bitwidth : integer := 8;
		addresswidth : integer := 12);
	port(
		reset : in std_logic;
		ki : in std_logic;
		sleep_in : in std_logic;
		id 				: in dual_rail_logic;
		parallelism_en 	: in dual_rail_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		sf_address_generator_done : out std_logic;
		z : out dual_rail_logic_vector(addresswidth downto 0)
	);
end sf_address_generator;

architecture arch_sf_address_generator of sf_address_generator is 

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
    		port(
			a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			z: out std_logic_vector(bitwidth-1 downto 0));
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

	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;

	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
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

	component th22_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 z: out std_logic); 
	end component; 

	component th12nm_a is
		port(
			a : in std_logic;
			b : in std_logic;
			rst : in std_logic;
			s : in std_logic;
			z : out std_logic);
	end component;

	component inv_a is 
		port(a: in std_logic; 
			 z: out std_logic); 
	end component; 

	component th12m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic; 
			 z: out std_logic); 
	end component; 

signal reset_count, const_2110, const_1055 : dual_rail_logic_vector(addresswidth downto 0);
signal reset_count_mux_input : dual_rail_logic_vector(2*addresswidth+2-1 downto 0);
signal data0, data1: dual_rail_logic;

signal accRes, counter_0_AccRes: dual_rail_logic;

signal count : dual_rail_logic_vector(18*(addresswidth+1)-1 downto 0);
signal base_address_adder_input : dual_rail_logic_vector(2*(addresswidth+1)-1 downto 0);
signal base_address_adder_output : dual_rail_logic_vector(addresswidth+1 downto 0);
signal address : dual_rail_logic_vector((9*(addresswidth+2)-1) downto 0);
signal const_9 : dual_rail_logic_vector(3 downto 0);
signal MUX_select : dual_rail_logic_vector(3  downto 0);
signal pre_z : dual_rail_logic_vector(addresswidth+1 downto 0);
signal sf_address_generator_done_temp, counter_0_ko, counter_0_sleep_out, counter_1_ko, counter_1_sleep_out, rca_0_sleep_out, rca_0_ko, accRes_inv, ko_output_reg, reset_and: std_logic;
signal base_address_adder_sleep_out, base_address_adder_ko: std_logic;
signal rca_sleep_out, rca_ko: std_logic_vector (8 downto 0);

signal select_output : dual_rail_logic_vector(66*66-1  downto 0);
signal sleep_state, parallelism_en_vector : dual_rail_logic_vector(0  downto 0);
signal ki_or_not_input, sleep_or_not_input : std_logic_vector(1  downto 0);
signal ki_mux_select, ki_select, sleep_mux_select : std_logic_vector(0  downto 0);
begin 

	--Setting up the dual rail constants
	--data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';
	--data0
	data0.rail0 <= '1';
	data0.rail1 <= '0';
	--dual rail 9
	const_9 <= data1 & data0 & data0 & data0;
	--dual rail 0
	count(2*(addresswidth+1)-1 downto 1*(addresswidth+1)) 	<= data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0;
	--dual rail 1
	count(4*(addresswidth+1)-1 downto 3*(addresswidth+1)) 	<= data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data1;
	--dual rail 2
	count(6*(addresswidth+1)-1 downto 5*(addresswidth+1)) 	<= data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data1 & data0;
	--dual rail 66
	count(8*(addresswidth+1)-1 downto 7*(addresswidth+1)) 	<= data0 & data0 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data0 & data1 & data0;
	--dual rail 67
	count(10*(addresswidth+1)-1 downto 9*(addresswidth+1)) 	<= data0 & data0 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data0 & data1 & data1;
	--dual rail 68
	count(12*(addresswidth+1)-1 downto 11*(addresswidth+1)) <= data0 & data0 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data1 & data0 & data0;
	--dual rail 132
	count(14*(addresswidth+1)-1 downto 13*(addresswidth+1)) <= data0 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data0 & data1 & data0 & data0;
	--dual rail 133
	count(16*(addresswidth+1)-1 downto 15*(addresswidth+1)) <= data0 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data0 & data1 & data0 & data1;
	--dual rail 134
	count(18*(addresswidth+1)-1 downto 17*(addresswidth+1)) <= data0 & data0 & data0 & data0 & data0 & data1 & data0 & data0 & data0 & data0 & data1 & data1 & data0;
	--reset count is set to 4221
	const_2110 <= data0 & data1 & data0 & data0 & data0 & data0 & data0 & data1 & data1 & data1 & data1 & data1 & data0;
	const_1055 <= data0 & data0 & data1 & data0 & data0 & data0 & data0 & data0 & data1 & data1 & data1 & data1 & data1;

	sf_address_generator_done <= sf_address_generator_done_temp;
	generate_sf_address_generator_done : th12nm_a
		port map(a => counter_0_AccRes.RAIL1,
			b => sf_address_generator_done_temp,
			rst => reset,
			s => '0',
			z => sf_address_generator_done_temp);


	reset_count_mux_input <= const_1055 & const_2110;
	parallelism_en_vector(0) <= parallelism_en;
	choose_reset_count : mux_nto1_gen
	generic map(bitwidth => addresswidth+1, numInputs => 2)
		port map(
			a => reset_count_mux_input,
			sel => parallelism_en_vector (0 downto 0),
			sleep => '0',
			z => reset_count);	

	counter_0 : counter_selfReset
	generic map(width => addresswidth+1)
		port map(
			reset_count => reset_count,
			sleep_in => sleep_in,
		 	reset => reset,
		 	ki => ki_mux_select(0),
		 	ko => counter_0_ko,
		 	sleep_out => counter_0_sleep_out,
		 	accumulate_reset => counter_0_AccRes,
		 	z => count (addresswidth downto 0));

	generate_address : for i in 0 to 8 generate

			MTNCL_RCA_GEN_instance_i : MTNCL_RCA_GEN
			generic map(bitwidth => addresswidth+1)
				port map(
					input => count(((i+1)*2)*(addresswidth+1)-1 downto (i*2)*(addresswidth+1)),
					ki => ki_mux_select(0),
					sleep => counter_0_sleep_out,
					rst => reset_and,
					sleepOut => rca_sleep_out(i),
					ko => rca_ko(i),
					S => address((i+1)*(addresswidth+1)+i downto (i)*(addresswidth+2)));

	end generate;

	generate_accRes_inv : inv_a
	port map(
		a => accRes.RAIL1,
		z => accRes_inv);

	generate_reset_or_ki_select : th12m_a
	port map(
		a => reset,
		b => ki_select(0),
		s => '0',
		z => reset_and);	

	MUX_select_generate : counter_selfReset
		generic map(width => 4)
		port map(reset_count => const_9,
			sleep_in => sleep_in,
		 	reset => reset_and,
		 	ko => ko,
		 	ki => ko_output_reg,
		 	sleep_out => counter_1_sleep_out,
		 	accumulate_reset => accRes,
		 	z => MUX_select);
	
	--Prepare the inputs for the RCAs
	generate_count_1 : for i in 1 to 8 generate
		count((2*(i)+1)*(addresswidth+1)-1 downto i*2*(addresswidth+1)) <= count(addresswidth downto 0) ;
	end generate;

	choose_address : mux_nto1_gen
	generic map(bitwidth => addresswidth+2,
			numInputs => 9)
		port map(
			a => address,
			sel => MUX_select,
			sleep => ki_select(0),
			z => pre_z);

	generate_sleep_select_1 : for i in 1 to 66 generate
		generate_sleep_select_2 : for j in 0 to 63 generate
			select_output((i-1)*66+j) <= data0;
		end generate;
	end generate;

	generate_sleep_select_3 : for i in 1 to 66 generate
		generate_sleep_select_4 : for j in 0 to 1 generate
			select_output((i)*64+(i-1)*2+j) <= data1;
		end generate;
	end generate;

	choose_output_or_not : mux_nto1_gen
	generic map(bitwidth => 1, numInputs => 66*66)
		port map(
			a => select_output,
			sel => count (addresswidth downto 0),
			sleep => '0',
			z => sleep_state);	

	ki_select (0) <= sleep_state(0).RAIL1;
	ki_or_not_input <= '0' & accRes_inv;
	choose_ki_or_ki : mux_nto1_sr_gen
	generic map(bitwidth => 1, numInputs => 2)
		port map(
			a => ki_or_not_input,
			sel => ki_select,
			z => ki_mux_select);			

	output_completion: compm
		generic map(width => addresswidth+1)
		port map(
			a => pre_z(addresswidth downto 0),
			ki => ki,
			rst => reset,
			sleep => counter_1_sleep_out,
			ko => ko_output_reg);

	output_register: regs_gen_null_res
		generic map(width => addresswidth+1)
		port map(
			d => pre_z(addresswidth downto 0),
			q => z,
			reset => reset,
			sleep => ko_output_reg
			);

			sleep_out <= ko_output_reg;
end arch_sf_address_generator; 
