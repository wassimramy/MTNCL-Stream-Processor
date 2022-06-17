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
		sf_cores : integer := 2;
		clock_delay : integer := 16;
		mem_delay : integer := 48);
	port(
		pixel 			: in dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
		reset 			: in std_logic;
		ki 				: in std_logic;
		parallelism_en 	: in dual_rail_logic;
		sleep_in 		: in std_logic;
		ko 				: out std_logic;
		sleep_out 		: out std_logic;
		z 				: out dual_rail_logic_vector(bitwidth-1 downto 0)
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

	component or2_a is
		port(a, b : in  std_logic;
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

	component mux_nto1_sr_gen is
	generic(
		bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			z: out std_logic_vector(bitwidth-1 downto 0));
	end component;

signal sleep_out_c , sleep_out_d, ko_d, sleep_in_b, sleep_in_image_store_load: std_logic;
signal data0, data1 : dual_rail_logic;
signal const_4096 : dual_rail_logic_vector(addresswidth downto 0);
signal count : dual_rail_logic_vector(addresswidth downto 0);
signal accRes, write_en: dual_rail_logic;
signal counters_ko: std_logic_vector (0 downto 0);

signal ki_sleep_out_control_vector : dual_rail_logic_vector(integer(ceil(log2(real(sf_cores))))-1 downto 0);
signal parallelism_en_vector : dual_rail_logic_vector(0 downto 0);
signal control: dual_rail_logic_vector(2*integer(ceil(log2(real(sf_cores))))-1 downto 0);
signal pixel_reg, pixel_a, output : dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
signal image_stored, image_loaded: std_logic_vector (sf_cores-1 downto 0);
signal ko_image_store_load, sleep_in_image_store_load_vector, ki_image_store_load, ki_image_store_load_or_load: std_logic_vector (sf_cores-1 downto 0);
signal select_sleep_out_image_store_load: std_logic_vector (integer(ceil(log2(real(sf_cores))))-1 downto 0);
signal sleep_out_image_store_load: std_logic_vector (sf_cores downto 0);
signal ki_control: std_logic_vector(sf_cores*sf_cores-1 downto 0);

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

	parallelism_en_vector (0) <= parallelism_en;
	ki_control(0) <= ki;
	generate_ki_control : for i in 1 to sf_cores-1 generate
		ki_control(i) <= '1';
		ki_control((i+1)*sf_cores-1 downto (i)*sf_cores) <= ki_control((i)*sf_cores-2 downto (i-1)*sf_cores) & '1';
	end generate;

	generate_control_signals_non_parallel : for i in 0 to integer(ceil(log2(real(sf_cores))))-1 generate
		control(i) 										<= count (addresswidth-(integer(ceil(log2(real(sf_cores))))-i));
		control(i+integer(ceil(log2(real(sf_cores))))) 	<= count (addresswidth-(integer(ceil(log2(real(sf_cores))))-i+1));
		--select_sleep_out_image_store_load(i) 			<= ki_sleep_out_control_vector(i).rail1;
	end generate;

	generate_pixel_reg : for i in 0 to sf_cores*bitwidth-1 generate
		generate_pixel_reg_rail0 : or2_a
			port map(
				a => pixel_a(i).rail0,
				b => image_stored(0),
				z => pixel_reg(i).rail0);
		pixel_reg(i).rail1 <= pixel_a(i).rail1;
	end generate;

	input_register: regs_gen_null_res_w_compm
		generic map(width => sf_cores*bitwidth)
		port map(
			d 			=> pixel,
			reset 		=> reset,
			sleep_in 	=> sleep_in,
			ki 			=> ko_image_store_load(0),
			sleep_out 	=> sleep_out_d,
			ko 			=> ko_d,
			q 			=> pixel_a
			);

		
		input_register_ki : MUX21_A 
		port map(
			A => ko_d, 
			B => ko_image_store_load(0),
			S => image_stored(0),
			Z => ko);

	write_en.rail0 <= image_stored(0);
	generate_write_en : inv_a
	port map(
		a => image_stored(0),
		z => write_en.rail1);

	MUX_select_generate : counter_selfReset
		generic map(
						width 	=> addresswidth+1)
		port map(
			reset_count 		=> const_4096,
			sleep_in 			=> sleep_in,
		 	reset 				=> reset,
		 	ko 					=> counters_ko(0),
		 	ki 					=> ki,
		 	sleep_out 			=> sleep_out_c,
		 	accumulate_reset 	=> accRes,
		 	z 					=> count);

		  	switch_to_other_half: mux_nto1_gen
			generic map(
							bitwidth 	=> integer(ceil(log2(real(sf_cores)))),
							numInputs 	=> 2
						)
 			port map(
	    		a 		=> control,
	    		sel 	=> parallelism_en_vector(0 downto 0),
	    		sleep 	=> '0',
    			z 		=> ki_sleep_out_control_vector);	

		image_store_load_instance_a_sleep_in : MUX21_A 
		port map(
			A => sleep_out_d, 
			B => '0',
			S => image_stored(0),
			Z => sleep_in_image_store_load);

			select_sleep_out_image_store_load(0) 			<= (image_loaded(0) and not image_loaded(1) and not image_loaded(2) and not image_loaded(3)) or (image_loaded(0) and image_loaded(1) and image_loaded(2) and not image_loaded(3));
			select_sleep_out_image_store_load(1) 			<= (image_loaded(0) and image_loaded(1) and not image_loaded(2) and not image_loaded(3)) or (image_loaded(0) and image_loaded(1) and image_loaded(2) and not image_loaded(3));

			choose_ki_image_store_load : mux_nto1_sr_gen
			generic map(bitwidth => sf_cores, numInputs => sf_cores)
			port map(
				a 	=> ki_control,
				sel => select_sleep_out_image_store_load,
				z 	=> ki_image_store_load);	

		generate_memory : for i in 0 to sf_cores-1 generate
			--This portion is to make sure that the counter does not reset itself
			generate_ki_i_or_load_i : or2_a
				port map(
					a => ki_image_store_load(i),
					b => image_loaded(i),
					z => ki_image_store_load_or_load(i));	

			image_store_load_instance_i : image_store_load
			generic map(
						addresswidth 	=> addresswidth-(integer(ceil(log2(real(sf_cores))))),
						bitwidth 		=> bitwidth,
						clock_delay 	=> clock_delay,
						mem_delay		=> mem_delay)

			port map(
					mem_data 			=> pixel_reg((i+1)*bitwidth-1 downto i*bitwidth),
					read_address 		=> const_4096 (addresswidth-integer(ceil(log2(real(sf_cores))))-1 downto 0),
					write_en 			=> write_en,
					standard_read_en 	=> data1,
					parallelism_en 		=> parallelism_en,
					reset 				=> reset,
					ki 					=> ki_image_store_load_or_load(i),
					ko 					=> ko_image_store_load(i),
					sleep_in 			=> sleep_in_image_store_load,
					sleep_out 			=> sleep_out_image_store_load(i),
					image_loaded 		=> image_loaded(i),
					image_stored 		=> image_stored(i),
					z 					=> output ((i+1)*bitwidth-1 downto i*bitwidth)
			);		
		end generate;

		sleep_in_image_store_load_vector(0) <= sleep_in_image_store_load;
		sleep_in_image_store_load_vector(1) <= sleep_in_image_store_load;
		sleep_in_image_store_load_vector(2) <= '1';
		sleep_in_image_store_load_vector(3) <= '1';
		choose_sleep_out_image_store_load : mux_nto1_sr_gen
		generic map(
						bitwidth 	=> 1, 
						numInputs 	=> sf_cores)
		port map(
			a 		=> sleep_out_image_store_load(sf_cores-1 downto 0),
			sel 	=> select_sleep_out_image_store_load,
			z 		=> sleep_out_image_store_load(sf_cores downto sf_cores));	

			global_sleep_out : MUX21_A 
			port map(
				A => '1', 
				B => sleep_out_image_store_load (sf_cores),
				S => image_stored(0),
				Z => sleep_out);	

		  	global_output: mux_nto1_gen
			generic map(
							bitwidth => bitwidth,
							numInputs => sf_cores)
 			port map(
	    		a 		=> output ,
	    		sel 	=> ki_sleep_out_control_vector,
	    		sleep 	=> sleep_out_image_store_load(1),
    			z 		=> z);	

end arch_MTNCL_SF_Core_Data_Output; 
