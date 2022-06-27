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
		sf_cores : integer := 2;
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
		output : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Top_Level;

architecture arch_MTNCL_SF_Core_Top_Level of MTNCL_SF_Core_Top_Level is 


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
    generic(bitwidth: in integer := bitwidth);
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

signal ko_data_loader, sleepout_data_loader, ko_pixels_a: std_logic;

signal pixel : dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
signal input_sf_core : dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
signal ko_sf_cores: std_logic_vector (sf_cores downto 0);
signal sleep_out_sf_cores: std_logic_vector (sf_cores-1 downto 0);

begin 

	ko <= ko_data_loader;

	sf_data_loader_instance : MTNCL_SF_Core_Data_Loader
	generic map(
				addresswidth => addresswidth,
				bitwidth => bitwidth)

	port map(
			pixel => input,
			reset => reset,
			ki => ko_sf_cores (sf_cores),
			id => id,
			parallelism_en => parallelism_en,
			ko => ko_data_loader,
			sleep_in => sleep_in,
			sleep_out => sleepout_data_loader,
			z => input_sf_core
	);

	th22d_ko_sf_cores : th22d_tree_gen
	generic map(numInputs => sf_cores )
	port map(
		a => ko_sf_cores (sf_cores-1 downto 0),
		rst => reset,
		z => ko_sf_cores (sf_cores)
	);

	generate_sf_cores : for i in 0 to sf_cores-1 generate
		sf_core_w_reg_instance_i: MTNCL_SF_Node_W_Registers
 		generic map(bitwidth => bitwidth)
  		port map(
		    input => input_sf_core((i+1)*bitwidth-1 downto i*bitwidth),
		    ki => ko_pixels_a,
		    sleep => sleepout_data_loader,
		    rst => reset,
		    ko => ko_sf_cores (i),
		    output => pixel((i+1)*bitwidth-1 downto i*bitwidth),
		    sleepOut => sleep_out_sf_cores (i)
    );
	end generate;

	sf_core_data_output : MTNCL_SF_Core_Data_Output
		generic map(bitwidth => bitwidth,
					addresswidth => addresswidth)
		port map(
				pixel => pixel,
				reset => reset,
				ki => ki,
				parallelism_en 	=> parallelism_en,
				sleep_in => '0',
				ko => ko_pixels_a,
				sleep_out => sleep_out,
				z => output
	);

    --th22d_sleep_out_sf_cores : th22d_tree_gen
	--generic map(numInputs => sf_cores )
	--port map(
	--	a => sleep_out_sf_cores (sf_cores-1 downto 0),
	--	rst => reset,
	--	z => sleep_out_sf_cores (sf_cores)
	--);

end arch_MTNCL_SF_Core_Top_Level; 
