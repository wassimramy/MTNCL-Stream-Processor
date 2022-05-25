--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity image_load_store is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(
		mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
		read_address : in dual_rail_logic_vector(addresswidth-1 downto 0);
		write_en : in dual_rail_logic;
		parallelism_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		image_loaded : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end image_load_store;



architecture arch_image_load_store of image_load_store is 

--SRAM declaration
	component sram_4096w_8b_8m_wrapper is
		generic(bitwidth : integer := bitwidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(address : in dual_rail_logic_vector(addresswidth-1 downto 0);
			mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
			write_en : in dual_rail_logic;
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component image_store is
		generic(
			addresswidth : integer := addresswidth;
			bitwidth : integer := bitwidth);
		port(
			mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
			number_of_words : in dual_rail_logic_vector(addresswidth downto 0);
			write_en : in dual_rail_logic;
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			image_loaded : out std_logic;
			z : out dual_rail_logic_vector(addresswidth+bitwidth downto 0)
			);
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

	component MUX21_A_gen is 
		generic(bitwidth: integer);
		port(
			a: in std_logic_vector((2*bitwidth)-1 downto 0);
			sel: in std_logic;
			z: out std_logic_vector(bitwidth-1 downto 0));
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




signal sleepout_image_store, ko_SRAM, ko_image_store, sleep_in_SRAM  : std_logic;

signal address : dual_rail_logic_vector(2*(addresswidth+bitwidth+1)-1 downto 0);
signal sram_address : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal const_4096, const_2048, reset_count : dual_rail_logic_vector(addresswidth downto 0);
signal reset_count_inputs : dual_rail_logic_vector(2*addresswidth+1 downto 0);
signal input_sram : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal write_en_inputs : dual_rail_logic_vector(1 downto 0);
signal write_en_vector, sram_write_en, parallelism_en_vector : dual_rail_logic_vector(0 downto 0);
signal data0, data1 : dual_rail_logic;

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

	--Generate global_ko
	global_ko : MUX21_A 
		port map(
			B => ko_SRAM,
			A => ko_image_store,
			S => write_en.RAIL0,
			Z => ko);

	--Generate addresses from 0 to reset_count (4095/2047)
	image_store_instance : image_store
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth)
		port map(
				mem_data => mem_data,
				number_of_words => reset_count,
				write_en => write_en,
				reset => reset,
				ki => ko_SRAM,
				ko => ko_image_store,
				sleep_in => sleep_in,
				sleep_out => sleepout_image_store,
				image_loaded => image_loaded,
				z => input_sram
		);

	--Generate SRAM_sleep_in
	SRAM_sleep_in : MUX21_A 
		port map(
			B => sleep_in,
			A => sleepout_image_store,
			S => write_en.RAIL0,
			Z => sleep_in_SRAM);

	--Generate SRAM address for the wrapper depending on the read/write mode
	address <= input_sram & input_sram (addresswidth+bitwidth downto addresswidth) & read_address;
	generate_sram_address : mux_nto1_gen
	generic map(bitwidth => (addresswidth+bitwidth)+1,
			numInputs => 2)
		port map(
			a => address,
			sel => write_en_vector,
			sleep => sleep_in_SRAM,
			z => sram_address);
	--Convert write_en into a vector to use it for the MUX select
	write_en_vector(0) <= write_en;

	--Generate the write enable signal for the wrapper depending on the read/write mode
	write_en_inputs <= write_en & sram_address(addresswidth+bitwidth);
	write_enable : mux_nto1_gen
	generic map(bitwidth => 1,
			numInputs => 2)
		port map(
			a => write_en_inputs,
			sel => write_en_vector,
			sleep => sleep_in_SRAM,
			z => sram_write_en);

	--The wrapper + SRAM instance
	sram_4096w_8b_8m : sram_4096w_8b_8m_wrapper
		generic map(bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)
		port map(
				address => sram_address(addresswidth-1 downto 0),
				mem_data => sram_address (addresswidth+bitwidth-1 downto addresswidth),
				write_en => sram_write_en(0),
				reset => reset,
				ki => ki,
				ko => ko_SRAM,
				sleep_in => sleep_in_SRAM,
				sleep_out => sleep_out,
				z => z
		);

end arch_image_load_store; 
