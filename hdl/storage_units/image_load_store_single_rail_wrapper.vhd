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
		read_address : in std_logic_vector(addresswidth-1 downto 0);
		write_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end image_load_store;



architecture arch_image_load_store of image_load_store is 

--SRAM declaration
	component sram_4096w_8b_8m_wrapper is
		generic(bitwidth : integer := bitwidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(address : in std_logic_vector(addresswidth-1 downto 0);
			mem_data : in std_logic_vector(bitwidth-1 downto 0);
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

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

signal W_reg_sleep, counter_ko, counter_sleep_out, W_reg_sleep_in, W_reg_sleep_a, W_reg_sleep_b : std_logic;
signal ko_SRAM, ko_image_store, sleep_in_SRAM  : std_logic;
signal input_sram_sr : std_logic_vector(addresswidth+bitwidth downto 0);
signal address : std_logic_vector(2*(addresswidth+bitwidth+1)-1 downto 0);
signal sram_address : std_logic_vector(addresswidth+bitwidth downto 0);

signal const_4095 : dual_rail_logic_vector(12 downto 0);
signal memData_W_address : dual_rail_logic_vector(addresswidth+bitwidth-1 downto 0);
signal input_sram : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal accRes, data0, data1, WE : dual_rail_logic;

begin 

	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

generate_reset_count : for i in 0 to addresswidth-1 generate
	const_4095(i) <= data0;
end generate;
const_4095(addresswidth) <= data1;

	--Generate global_ko
	global_ko : MUX21_A 
		port map(
			A => ko_SRAM,
			B => ko_image_store,
			S => write_en.RAIL1,
			Z => ko);


--Store the input image in the SRAM
	image_store_instance : image_store
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth)
		port map(
				mem_data => mem_data,
				number_of_words => const_4095,
				write_en => write_en,
				reset => reset,
				ki => ko_SRAM,
				ko => ko_image_store,
				sleep_in => sleep_in,
				sleep_out => W_reg_sleep,
				z => input_sram
		);

	--Generate SRAM_sleep_in
	SRAM_sleep_in : MUX21_A 
		port map(
			A => sleep_in,
			B => W_reg_sleep,
			S => write_en.RAIL1,
			Z => sleep_in_SRAM);

	--Generate SRAM address
	address <= input_sram_sr & input_sram_sr (addresswidth+bitwidth downto addresswidth) & read_address;
	generate_sram_address : MUX21_A_gen
	generic map(bitwidth => (addresswidth+bitwidth)+1)
		port map(
			a => address,
			sel => write_en.RAIL1,
			z => sram_address);

generate_output : for i in 0 to addresswidth+bitwidth generate
	input_sram_sr(i) <= input_sram(i).rail1;
end generate;

	--Generate SRAM_sleep_in
	write_enable : MUX21_A 
		port map(
			A => write_en.RAIL1,
			B => sram_address(addresswidth+bitwidth),
			S => write_en.RAIL1,
			Z => WE.RAIL1);

--	WE_DR : inv_a 
--		port map(
--			a => WE.RAIL1,
--			z => WE.RAIL0);

WE.RAIL0 <= not  WE.RAIL1;

	sram_4096w_8b_8m : sram_4096w_8b_8m_wrapper
		generic map(bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)
		port map(
				address => sram_address(addresswidth-1 downto 0),
				mem_data => sram_address (addresswidth+bitwidth-1 downto addresswidth),
				write_en => WE,
				--write_en => write_en,
				reset => reset,
				ki => ki,
				ko => ko_SRAM,
				sleep_in => sleep_in_SRAM,
				sleep_out => sleep_out,
				z => z
		);

end arch_image_load_store; 
