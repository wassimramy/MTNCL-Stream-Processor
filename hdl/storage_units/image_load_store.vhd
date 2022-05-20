--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity image_store_load is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
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
		image_stored : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end image_store_load;



architecture arch_image_store_load of image_store_load is 

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
		generic(bitwidth : integer := bitwidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
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




signal sleepout_image_store, ko_SRAM, ko_image_store, ko_image_load, sleep_in_SRAM  : std_logic;
signal image_stored_and_std_read_enable, image_stored_image_store, sleepout_image_load, sleepin_image_store, sleepin_image_load  : std_logic;

signal address : dual_rail_logic_vector(2*(addresswidth+bitwidth+1)-1 downto 0);
signal sram_address : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal const_4096, const_2048, reset_count : dual_rail_logic_vector(addresswidth downto 0);
signal reset_count_inputs : dual_rail_logic_vector(2*addresswidth+1 downto 0);
signal input_sram : dual_rail_logic_vector(addresswidth+bitwidth downto 0);
signal write_en_inputs : dual_rail_logic_vector(1 downto 0);
signal write_en_vector, sram_write_en, parallelism_en_vector : dual_rail_logic_vector(0 downto 0);
signal data0, data1 : dual_rail_logic;

signal read_address_sram :  dual_rail_logic_vector(addresswidth+bitwidth downto 0);
begin 

	--Generate global ko
	global_ko : MUX21_A 
		port map(
			A => ko_image_store,
			B => ko_image_load,
			S => image_stored_and_std_read_enable,
			Z => ko);

	--Generate sleep_in_image_store
	generate_sleep_in_image_store : MUX21_A 
		port map(
			A => sleep_in,
			B => sleepout_image_load,
			S => image_stored_and_std_read_enable,
			Z => sleepin_image_store);

	image_stored_and_std_read_enable <= image_stored_image_store and standard_read_en.RAIL1;
	image_store_instance : image_store
		generic map(
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay
		)

		port map(
				mem_data => mem_data,
				read_address => read_address,
				write_en => write_en,
				parallelism_en => parallelism_en,
				reset => reset,
				ki => ki,
				ko => ko_image_store,
				sleep_in => sleepin_image_store,
				sleep_out => sleep_out,
				image_loaded => image_stored_image_store,
				z => z
		);

	--Generate sleep_in_image_store
	generate_sleep_in_image_load : MUX21_A 
		port map(
			A => '1',
			B => sleep_in,
			S => image_stored_and_std_read_enable,
			Z => sleepin_image_load);

	--Generate addresses from 0 to reset_count (4095/2047)
	image_load_instance : standard_address_generator
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth)
		port map(
				mem_data => mem_data,
				write_en => write_en,
				parallelism_en => parallelism_en,
				reset => reset,
				ki => ko_image_store,
				ko => ko_image_load,
				sleep_in => sleepin_image_load,
				sleep_out => sleepout_image_load,
				image_loaded_stored => image_loaded,
				z => read_address_sram
		);

--
--	--Generate SRAM address for the wrapper depending on the read/write mode
--	address <= input_sram & input_sram (addresswidth+bitwidth downto addresswidth) & read_address;
--	generate_sram_address : mux_nto1_gen
--	generic map(bitwidth => (addresswidth+bitwidth)+1,
--			numInputs => 2)
--		port map(
--			a => address,
--			sel => write_en_vector,
--			sleep => sleep_in_SRAM,
--			z => sram_address);
--	--Convert write_en into a vector to use it for the MUX select
--	write_en_vector(0) <= write_en;
--
end arch_image_store_load; 
