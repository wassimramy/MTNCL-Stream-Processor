--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Core_Data_Output is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;
		mem_delay : integer := 48);
	port(
		pixel : in dual_rail_logic_vector(2*bitwidth-1 downto 0);
		reset : in std_logic;
		ki : in std_logic;
		--write_en : in dual_rail_logic;
		sleep_in : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Data_Output;



architecture arch_MTNCL_SF_Core_Data_Output of MTNCL_SF_Core_Data_Output is 

	component image_store_load is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY

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

signal ki_a, ki_b, sleep_out_a, sleep_out_b, sleep_out_c, sleep_out_d, ko_d, sleep_in_b, sleep_in_image_store_load, ki_input_register: std_logic;
signal data0, data1 : dual_rail_logic;
signal image_loaded_a, image_loaded_b, image_stored_a, image_stored_b : std_logic;
signal read_address : dual_rail_logic_vector(addresswidth-1 downto 0);
signal output : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal ki_sleep_out_control_vector : dual_rail_logic_vector(0 downto 0);
signal const_4096 : dual_rail_logic_vector(addresswidth downto 0);
signal count : dual_rail_logic_vector(addresswidth downto 0);
signal accRes, write_en: dual_rail_logic;
signal counters_ko: std_logic_vector (2 downto 0);
signal pixel_reg : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal pixel_a : dual_rail_logic_vector(2*bitwidth-1 downto 0);
begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	--This block generates the read_address
	generate_read_address : for i in 0 to addresswidth-1 generate
		read_address(i) <= data0; 
	end generate;

	--Generate reset_count depending on the number of words
	--Generate 4096
	generate_4096 : for i in 0 to addresswidth-1 generate
		const_4096(i) <= data0;
	end generate;
	const_4096(addresswidth) <= data1;

	--ko <= counters_ko(1);

	--pixel_a <= pixel (bitwidth-1 downto 0) & pixel (bitwidth-1 downto 0);
	input_register: regs_gen_null_res_w_compm
		generic map(width => 2*bitwidth)
		port map(
			d => pixel,
			reset => reset,
			sleep_in => sleep_in,
			--ki => ki_input_register,
			ki => counters_ko(1),
			sleep_out => sleep_out_d,
			--ko => ko_d,
			ko => ko,
			q => pixel_reg
			);

		
		--input_register_ki : MUX21_A 
		--port map(
		--	A => ko_d, 
		--	B => '1',
		--	S => image_stored_a,
		--	Z => ko);

	write_en.rail0 <= image_stored_a;
	generate_write_en : inv_a
	port map(
		a => image_stored_a,
		z => write_en.rail1);

	MUX_select_generate : counter_selfReset
		generic map(width => addresswidth+1)
		port map(reset_count => const_4096,
			sleep_in => sleep_in,
		 	reset => reset,
		 	ko => counters_ko(0),
		 	ki => ki,
		 	sleep_out => sleep_out_c,
		 	accumulate_reset => accRes,
		 	z => count);

	image_store_load_instance_a : image_store_load
		generic map(
					addresswidth => addresswidth-1,
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)

		port map(
				--mem_data => pixel(bitwidth-1 downto 0),
				mem_data => pixel_reg(bitwidth-1 downto 0),
				read_address => read_address (addresswidth-2 downto 0),
				write_en => write_en,
				standard_read_en => data1,
				parallelism_en => data0,
				reset => reset,
				ki => ki_a,
				ko => counters_ko(1),
				--sleep_in => sleep_in,
				sleep_in => sleep_in_image_store_load,
				sleep_out => sleep_out_a,
				image_loaded => image_loaded_a,
				image_stored => image_stored_a,
				z => output (bitwidth-1 downto 0)
		);

		image_store_load_instance_b : image_store_load
		generic map(
					addresswidth => addresswidth-1,
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)

		port map(
				--mem_data => pixel(2*bitwidth-1 downto bitwidth),
				mem_data => pixel_reg(2*bitwidth-1 downto bitwidth),
				read_address => read_address (addresswidth-2 downto 0),
				write_en => write_en,
				standard_read_en => data1,
				parallelism_en => data0,
				reset => reset,
				ki => ki_b,
				ko => counters_ko(2),
				--sleep_in => sleep_in,
				sleep_in => sleep_in_image_store_load,
				sleep_out => sleep_out_b,
				image_loaded => image_loaded_b,
				image_stored => image_stored_b,
				z => output (2*bitwidth-1 downto bitwidth)
		);

		ki_sleep_out_control_vector(0 downto 0) <= count (addresswidth-1 downto addresswidth-1);
		image_store_load_instance_a_sleep_in : MUX21_A 
		port map(
			A => sleep_out_d, 
			B => sleep_in,
			S => image_stored_a,
			Z => sleep_in_image_store_load);

		image_store_load_instance_a_ki : MUX21_A 
		port map(
			A => ki, 
			B => '1',
			S => ki_sleep_out_control_vector(0).rail1,
			Z => ki_a);

		image_store_load_instance_b_ki : MUX21_A 
		port map(
			A => '1',
			B => ki, 
			S => ki_sleep_out_control_vector(0).rail1,
			Z => ki_b);

		image_store_load_instance_b_sleep : MUX21_A 
		port map(
			A => sleep_out_a, 
			B => sleep_out_b,
			S => ki_sleep_out_control_vector(0).rail1,
			Z => sleep_out);

		  	global_output: mux_nto1_gen
			generic map(bitwidth => bitwidth,
			numInputs => 2)
 			port map(
	    		a => output ,
	    		sel => ki_sleep_out_control_vector(0 downto 0),
	    		sleep => sleep_out_b,
    			z => z);	

end arch_MTNCL_SF_Core_Data_Output; 
