--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Core_Top_Level is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(
		input : in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		output : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Top_Level;

architecture arch_MTNCL_SF_Core_Top_Level of MTNCL_SF_Core_Top_Level is 

	component image_store_load is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth;
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
	end component;

	component MTNCL_SF_Core_Data_Loader is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth);
		port(

			pixel : in dual_rail_logic_vector(bitwidth-1 downto 0);
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			z : out dual_rail_logic_vector(2*bitwidth-1 downto 0)
			);
	end component;

	component MTNCL_SF_Core_Data_Output is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth;
			clock_delay : integer := clock_delay;
			mem_delay : integer := mem_delay);
			
		port(
				pixel : in dual_rail_logic_vector(2*bitwidth-1 downto 0);
				reset : in std_logic;
				ki : in std_logic;
				ko : out std_logic;
				sleep_in : in std_logic;
				sleep_out : out std_logic;
				z : out dual_rail_logic_vector(bitwidth-1 downto 0)
			);
	end component;

	component MTNCL_SF_Node_W_Registers is
    generic(bitwidth: in integer := 4);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth-1) downto 0)
      );
  end component;

  	component th22d_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			rst: in std_logic;
			z: out std_logic);
	end component;

	component th22_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 z: out std_logic); 
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

	component OAAT_in_all_out is
		generic( bitwidth : integer := 16; numInputs : integer := 64; counterWidth : integer := 6; delay_amount : integer := 6);
	    port(
			a : in dual_rail_logic_vector(bitwidth-1 downto 0);
			reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
			sleep_in: in std_logic;
			reset: in std_logic;
			ki: in std_logic;
			ko: out std_logic;
			sleep_out: out std_logic;
			z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0)
	      );
	  end component;

	  component OAAT_out_all_in is
		generic(bitwidth: integer := 8; numInputs : integer := 256);
		port(a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0); --CHANGE COUNTER WIDTH
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		accumulate_reset: out dual_rail_logic;
		count: out dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;	


signal pixel : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal data0, data1, acc_res : dual_rail_logic;

signal ko_data_loader, ko_image_store_load, sleep_in_image_store_load, sleepout_image_store_load, sleepout_data_loader, sleep_out_a, sleep_out_b, sleep_out_c, ko_sf_core_w_reg, ko_sf_core_w_reg_a, ko_sf_core_w_reg_b,output_reg_ko : std_logic;
signal output_image_store_load : dual_rail_logic_vector(bitwidth-1 downto 0);
signal input_sf_core : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal sleep_out_pixels_c, sleep_out_pixels_b, sleep_out_pixels_a, ko_pixels_b, ko_pixels_a: std_logic; 
signal tree_input: std_logic_vector (1 downto 0);

signal const_2047 : dual_rail_logic_vector(10 downto 0);
signal const_2048, const_4095 : dual_rail_logic_vector(11 downto 0);
signal dummy_count : dual_rail_logic_vector(11 downto 0);
signal output_pixels : dual_rail_logic_vector(4096*bitwidth-1 downto 0);
begin 

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	const_2047 <= data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1 & data1;
	const_2048 <= data1 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0;
	const_4095 <= const_2047 & data1;
	--ko <= ko_image_store_load;

	--generate_sleep_in_image_store_load : inv_a
	--port map(
	--	a => ko_image_store_load,
	--	z => sleep_in_image_store_load);

	--sram : image_store_load
	--	generic map(
	--				addresswidth => addresswidth,
	--				bitwidth => bitwidth,
	--				clock_delay => 16,
	--				mem_delay => 48)
--
--		port map(
--				mem_data => mem_data,
--				read_address => read_address,
--				write_en => write_en,
--				standard_read_en => standard_read_en,
--				parallelism_en => parallelism_en,
--				reset => reset,
--				ki => ko_data_loader,
--				ko => ko_image_store_load,
--				sleep_in => sleep_in_image_store_load,
--				sleep_out => sleepout_image_store_load,
--				image_loaded => image_loaded,
--				image_stored => image_stored,
--				z => output_image_store_load
--		);

	ko <= ko_data_loader;

	--generate_sleep_in_image_store_load : inv_a
	--port map(
	--	a => ko_data_loader,
	--	z => sleepout_image_store_load);

	sf_data_loader_instance : MTNCL_SF_Core_Data_Loader
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth)

		port map(
				--pixel => output_image_store_load,
				pixel => input,
				reset => reset,
				ki => ko_sf_core_w_reg,
				ko => ko_data_loader,
				--sleep_in => sleepout_image_store_load,
				sleep_in => sleep_in,
				sleep_out => sleepout_data_loader,
				z => input_sf_core
		);

    	tree_input <= ko_sf_core_w_reg_a & ko_sf_core_w_reg_b;
		th22d_counter_tree : th22d_tree_gen
		generic map(numInputs => 2 )
		port map(
			a => tree_input,
			rst => reset,
			z => ko_sf_core_w_reg);

    sf_core_w_reg_instance_a: MTNCL_SF_Node_W_Registers
 	generic map(bitwidth => bitwidth)
  	port map(
    input => input_sf_core(bitwidth-1 downto 0),
    ki => ko_pixels_a,
    --ki => ki,
    sleep => sleepout_data_loader,
    rst => reset,
    ko => ko_sf_core_w_reg_a,
    output => pixel(bitwidth-1 downto 0),
    sleepOut => sleep_out_a
    );

	sf_core_w_reg_instance_b: MTNCL_SF_Node_W_Registers
 	generic map(bitwidth => bitwidth)
  	port map(
    input => input_sf_core(2*bitwidth-1 downto bitwidth),
    ki => ko_pixels_a,
    --ki => ki,
    sleep => sleepout_data_loader,
    rst => reset,
    ko => ko_sf_core_w_reg_b,
    output => pixel(2*bitwidth-1 downto bitwidth),
    --output => pixel,
    sleepOut => sleep_out_b
    );

	sf_core_data_output : MTNCL_SF_Core_Data_Output
		generic map(bitwidth => bitwidth,
					addresswidth => addresswidth)
		port map(
				pixel => pixel,
				reset => reset,
				ki => ki,
				--sleep_in => sleep_out_a,
				sleep_in => '0',
				ko => ko_pixels_a,
				sleep_out => sleep_out,
				z => output
		);

    --output_register: regs_gen_null_res_w_compm
	--	generic map(width => 2*bitwidth)
	--	port map(
	--		d => pixel,
	--		reset => reset,
	--		sleep_in => sleep_out_c,
	--		ki => ki,
	--		sleep_out => sleep_out,
	--		ko => output_reg_ko,
	--		q => z
	--		);

	generate_sleep_in_output_reg : th22_a
	port map(
		a => sleep_out_pixels_a,
		b => sleep_out_pixels_b,
		z => sleep_out_pixels_c);

    generate_global_sleep_out : th22_a
	port map(
		a => sleep_out_a,
		b => sleep_out_b,
		z => sleep_out_c);

end arch_MTNCL_SF_Core_Top_Level; 
