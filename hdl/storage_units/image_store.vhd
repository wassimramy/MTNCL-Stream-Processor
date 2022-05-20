--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity image_store is
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
		image_stored : out std_logic;
		accReset_stored : out dual_rail_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end image_store;



architecture arch_image_store of image_store is 

--SRAM declaration
	component sram_4096w_8b_8m_wrapper is
		generic(bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth;
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

	component standard_address_generator is
		generic(
			addresswidth : integer := addresswidth;
			bitwidth : integer := bitwidth);
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

signal input_sram : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal write_en_inputs : dual_rail_logic_vector(1 downto 0);
signal write_en_vector, sram_write_en : dual_rail_logic_vector(0 downto 0);


begin 

	--Generate global_ko
	global_ko : MUX21_A 
		port map(
			B => ko_SRAM,
			A => ko_image_store,
			S => write_en.RAIL0,
			Z => ko);

	--Generate addresses from 0 to reset_count (4095/2047)
	image_store_instance : standard_address_generator
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth)
		port map(
				mem_data => mem_data,
				write_en => write_en,
				parallelism_en => parallelism_en,
				reset => reset,
				ki => ko_SRAM,
				ko => ko_image_store,
				sleep_in => sleep_in,
				sleep_out => sleepout_image_store,
				image_loaded_stored => image_stored,
				accReset_loaded_stored => accReset_stored,
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
					addresswidth => addresswidth,
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

end arch_image_store; 
