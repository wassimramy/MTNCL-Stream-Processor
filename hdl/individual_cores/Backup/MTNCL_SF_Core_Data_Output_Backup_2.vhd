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
		write_en : in dual_rail_logic;
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

	component th22d_a is
	port(a   : in  std_logic;
		 b   : in  std_logic;
		 rst : in  std_logic;
		 z   : out std_logic);
	end component;

	component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
	end component;

	component BUFFER_A is 
		port(A: in std_logic; 
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

	component inv_a is
		port(a : in  std_logic;
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

signal output_reg : dual_rail_logic_vector(4096*bitwidth-1 downto 0);
signal ki_a, ki_b, ko_a, ko_b, sleep_out_a, sleep_out_b, sleep_in_b: std_logic;
signal data0, data1 : dual_rail_logic;
signal image_loaded_a, image_loaded_b, image_stored_a, image_stored_b, ki_sleep_out_control, not_image_stored_b , not_image_loaded_a, output_reg_ko: std_logic;
signal read_address : dual_rail_logic_vector(addresswidth-1 downto 0);
signal output : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal output_register_input : dual_rail_logic_vector(bitwidth-1 downto 0);
signal ki_sleep_out_control_vector : dual_rail_logic_vector(0 downto 0);
signal delayed_image_loaded_a : std_logic_vector(201 downto 0);

signal counter_ko, counter_sleep_out : std_logic;
signal const_4096 : dual_rail_logic_vector(addresswidth downto 0);
signal count : dual_rail_logic_vector(addresswidth downto 0);
signal accRes: dual_rail_logic;
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


	image_store_load_instance_a : image_store_load
		generic map(
					addresswidth => addresswidth-1,
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)

		port map(
				mem_data => pixel(bitwidth-1 downto 0),
				read_address => read_address (addresswidth-2 downto 0),
				write_en => write_en,
				standard_read_en => data1,
				parallelism_en => data0,
				reset => reset,
				--ki => ki,
				ki => output_reg_ko,
				ko => ko_a,
				sleep_in => sleep_in,
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
				mem_data => pixel(2*bitwidth-1 downto bitwidth),
				read_address => read_address (addresswidth-2 downto 0),
				write_en => write_en,
				standard_read_en => data1,
				parallelism_en => data0,
				reset => reset,
				ki => delayed_image_loaded_a(50),
				--ki => ki_b,
				ko => ko_b,
				sleep_in => sleep_in_b,
				--sleep_in => not_image_loaded_a,
				sleep_out => sleep_out_b,
				image_loaded => image_loaded_b,
				image_stored => image_stored_b,
				z => output (2*bitwidth-1 downto bitwidth)
		);

		delay_sleep1_gate : BUFFER_A 
		port map(A => ki_b,
			 Z => delayed_image_loaded_a(0));

		gen_pre_delay_sleep : for i in 0 to 200 generate
		delay_sleep_gate_i : BUFFER_A
		port map(A => delayed_image_loaded_a(i),
			Z => delayed_image_loaded_a(i+1));
		end generate;	 

		ki_sleep_out_control_vector(0).rail0 <= ki_sleep_out_control;
		generate_ki_sleep_out_control_vector : inv_a 
		port map(a => ki_sleep_out_control,
			 z => ki_sleep_out_control_vector(0).rail1);
		--ki_sleep_out_control_vector(0) <= 

		generate_not_image_stored_b : inv_a 
		port map(a => image_stored_b,
			 z => not_image_stored_b);

		generate_not_image_loaded_a : inv_a 
		port map(a => image_loaded_a,
			 z => not_image_loaded_a);	 

		generate_ki_sleep_out_control : MUX21_A 
		port map(
			A => image_stored_b, 
			B => not_image_stored_b,
			S => image_loaded_a,
			--S => delayed_image_loaded_a(101),
			Z => ki_sleep_out_control);


		image_store_load_instance_b_sleep_in : MUX21_A 
		port map(
			A => '0', 
			B => sleep_in,
			S => ki_sleep_out_control,
			Z => sleep_in_b);

		image_store_load_instance_b_ki : MUX21_A 
		port map(
			--A => ki, 
			A => output_reg_ko, 
			B => '1',
			S => ki_sleep_out_control,
			Z => ki_b);

		--image_store_load_instance_b_sleep : MUX21_A 
		--port map(
		--	A => sleep_out_b, 
		--	B => sleep_out_a,
		--	S => ki_sleep_out_control,
		--	Z => sleep_out);

		image_store_load_instance_b_ko : MUX21_A 
		port map(
			A => ko_b, 
			B => ko_a,
			S => ki_sleep_out_control,
			Z => ko);

		  	global_output: mux_nto1_gen
			generic map(bitwidth => bitwidth,
			numInputs => 2)
 			port map(
	    		a => output ,
	    		sel => ki_sleep_out_control_vector(0 downto 0),
	    		--sel => count(0 downto 0),
	    		sleep => sleep_out_b,
    			z => output_register_input);	

	output_register: regs_gen_null_res_w_compm
		generic map(width => bitwidth)
		port map(
			d => output_register_input,
			reset => reset,
			sleep_in => sleep_out_a,
			ki => ki,
			sleep_out => sleep_out,
			ko => output_reg_ko,
			q => z
			);

end arch_MTNCL_SF_Core_Data_Output; 
