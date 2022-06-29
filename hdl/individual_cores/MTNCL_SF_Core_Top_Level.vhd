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

	component MTNCL_SF_Core_Logic is
    generic(bitwidth: in integer := bitwidth; sf_cores: in integer := sf_cores);
    port(
		pixel    		: in  dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
		reset 			: in std_logic;
		ki 				: in std_logic;
		ko 				: out std_logic;
		sleep_in 		: in std_logic;
		sleep_out 		: out std_logic;
		z 				: out dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0)
      );
  end component;

  	component th22d_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			rst: in std_logic;
			z: out std_logic);
	end component;

signal ko_data_loader, sleepout_data_loader, ko_pixels_a, sf_core_logic_sleep_out, sf_core_logic_ko: std_logic;

signal pixel : dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
signal input_sf_core : dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
--signal ko_sf_cores: std_logic_vector (sf_cores downto 0);
--signal sleep_out_sf_cores: std_logic_vector (sf_cores-1 downto 0);

begin 

	ko <= ko_data_loader;

	sf_data_loader_instance : MTNCL_SF_Core_Data_Loader
	generic map(
				addresswidth => addresswidth,
				bitwidth => bitwidth)

	port map(
			pixel => input,
			reset => reset,
			ki => sf_core_logic_ko,
			id => id,
			parallelism_en => parallelism_en,
			ko => ko_data_loader,
			sleep_in => sleep_in,
			sleep_out => sleepout_data_loader,
			z => input_sf_core
	);

	sf_core_logic : MTNCL_SF_Core_Logic
		generic map(bitwidth => bitwidth,
					sf_cores => sf_cores)
		port map(
				pixel => input_sf_core,
				reset => reset,
				ki => ko_pixels_a,
				sleep_in => sleepout_data_loader,
				ko => sf_core_logic_ko,
				sleep_out => sf_core_logic_sleep_out,
				z => pixel
	);

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

    

end arch_MTNCL_SF_Core_Top_Level; 
