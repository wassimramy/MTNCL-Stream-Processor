--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity standard_address_generator is
	generic(bitwidth : integer := 8;
		addresswidth : integer := 12);
	port(
		mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
		write_en : in dual_rail_logic;
		parallelism_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		image_loaded_stored : out std_logic;
		accReset_loaded_stored : out dual_rail_logic;
		z : out dual_rail_logic_vector(addresswidth+bitwidth downto 0)
	);
end standard_address_generator;



architecture arch_standard_address_generator of standard_address_generator is 

	component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			sleep: in std_logic;
			z: out dual_rail_logic_vector(bitwidth-1 downto 0));
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

signal W_reg_sleep, counter_ko, counter_sleep_out, W_reg_sleep_in, image_loaded_temp: std_logic;

signal const_4096, const_2048, reset_count : dual_rail_logic_vector(addresswidth downto 0);
signal data0, data1 : dual_rail_logic;
signal reset_count_inputs : dual_rail_logic_vector(2*addresswidth+1 downto 0);
signal parallelism_en_vector : dual_rail_logic_vector(0 downto 0);


signal writeEnable_W_memData_W_address, output_data : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal address : dual_rail_logic_vector(addresswidth downto 0);
signal accRes: dual_rail_logic;

begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	--Generate reset_count depending on the number of words
	--Generate 4096
	generate_4096 : for i in 0 to addresswidth-1 generate
		const_4096(i) <= data0;
	end generate;
	const_4096(addresswidth) <= data1;
	--Generate 2048
	generate_2048 : for i in 0 to addresswidth-2 generate
		const_2048(i) <= data0;
	end generate;
	const_2048(addresswidth downto addresswidth-1) <= data0 & data1;

	parallelism_en_vector(0) <= parallelism_en;
	reset_count_inputs <= const_2048 & const_4096;
	choose_reset_count : mux_nto1_gen
	generic map(bitwidth => addresswidth+1,
			numInputs => 2)
		port map(
			a => reset_count_inputs,
			sel => parallelism_en_vector,
			sleep => '0',
			z => reset_count);


--WRITE ADDRESS GENERATION
ko <= counter_ko;

	counter_memWriteAddress : counter_selfReset
		generic map(width => addresswidth+1)
		port map(
			--reset_count => const_4096(addresswidth-1 downto 0),
			reset_count => reset_count,
			sleep_in => sleep_in,
		 	reset => reset,
		 	ki => W_reg_sleep,
		 	ko => counter_ko,
		 	sleep_out => counter_sleep_out,
		 	accumulate_reset => accRes,
		 	z => address(addresswidth downto 0));

	W_reg_sleep_in_gate : th22_a
	port map(a => sleep_in, 
			 b => counter_sleep_out,
			 z => W_reg_sleep_in); 

	comp_in_W_a: compm
		generic map(width => addresswidth+bitwidth+1)
		port map(
			a => writeEnable_W_memData_W_address,
			ki => ki,
			rst => reset,
			sleep => W_reg_sleep_in,
			ko => W_reg_sleep);

	W_reg: regs_gen_null_res
		generic map(width => addresswidth+bitwidth+1)
		port map(
			d => writeEnable_W_memData_W_address,
			q => z,
			reset => reset,
			sleep => W_reg_sleep);

	writeEnable_W_memData_W_address <= write_en & mem_data & address (addresswidth-1 downto 0);

	accReset_loaded_stored <= accRes;
	generate_image_loaded : th12nm_a
		port map(a => accRes.rail1,
			b => image_loaded_temp,
			rst => reset,
			s => '0',
			z => image_loaded_temp);

	image_loaded_stored <= image_loaded_temp;
	sleep_out <= W_reg_sleep;

end arch_standard_address_generator; 
