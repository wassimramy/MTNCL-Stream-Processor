--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Core_Top_Level_wo_sram is
	generic(
		bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(
		input : in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset : in std_logic;
		ki : in std_logic;
		id 	: in dual_rail_logic;
		parallelism_en 	: in dual_rail_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		output : out dual_rail_logic_vector(2*bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Top_Level_wo_sram;

architecture arch_MTNCL_SF_Core_Top_Level_wo_sram of MTNCL_SF_Core_Top_Level_wo_sram is 


	component MTNCL_SF_Core_Data_Loader is
		generic(
			bitwidth 		: integer := bitwidth;
			addresswidth 	: integer := addresswidth);
		port(

			pixel 			: in dual_rail_logic_vector(bitwidth-1 downto 0);
			reset 			: in std_logic;
			ki 				: in std_logic;
			id 				: in dual_rail_logic;
			parallelism_en 	: in dual_rail_logic;
			ko 				: out std_logic;
			sleep_in 		: in std_logic;
			sleep_out 		: out std_logic;
			z 				: out dual_rail_logic_vector(2*bitwidth-1 downto 0)
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
				parallelism_en 	: in dual_rail_logic;
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


signal pixel : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal ko_data_loader, sleepout_data_loader, sleep_out_a, sleep_out_b, sleep_out_c, ko_sf_core_w_reg, ko_sf_core_w_reg_a, ko_sf_core_w_reg_b : std_logic;
signal output_image_store_load : dual_rail_logic_vector(bitwidth-1 downto 0);
signal input_sf_core : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal ko_pixels_a: std_logic; 
signal tree_input: std_logic_vector (1 downto 0);


begin 

	ko <= ko_data_loader;

	sf_data_loader_instance : MTNCL_SF_Core_Data_Loader
	generic map(
				addresswidth => addresswidth,
				bitwidth => bitwidth)

	port map(
			pixel => input,
			reset => reset,
			ki => ko_sf_core_w_reg,
			id => id,
			parallelism_en => parallelism_en,
			ko => ko_data_loader,
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
		z => ko_sf_core_w_reg
	);

    sf_core_w_reg_instance_a: MTNCL_SF_Node_W_Registers
 	generic map(bitwidth => bitwidth)
  	port map(
		    input => input_sf_core(bitwidth-1 downto 0),
		    ki => ki,
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
			    ki => ki,
			    sleep => sleepout_data_loader,
			    rst => reset,
			    ko => ko_sf_core_w_reg_b,
			    output => pixel(2*bitwidth-1 downto bitwidth),
			    sleepOut => sleep_out_b
    );


    generate_global_sleep_out : th22_a
	port map(
		a => sleep_out_a,
		b => sleep_out_b,
		z => sleep_out
	);

end arch_MTNCL_SF_Core_Top_Level_wo_sram; 
