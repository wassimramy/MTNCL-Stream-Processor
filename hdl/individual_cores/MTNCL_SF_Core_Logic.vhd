--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_SF_Core_Logic is
	generic(
		bitwidth 		: integer := 8;
		sf_cores 		: integer := 2);
	port(
		pixel 			: in dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
		reset 			: in std_logic;
		ki 				: in std_logic;
		ko 				: out std_logic;
		sleep_in 		: in std_logic;
		sleep_out 		: out std_logic;
		z 				: out dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0)
	);
end MTNCL_SF_Core_Logic;



architecture arch_MTNCL_SF_Core_Logic of MTNCL_SF_Core_Logic is 

	component MTNCL_SF_Node_W_Registers is
    generic(bitwidth: in integer := bitwidth);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 		: in std_logic;
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

signal ko_sf_cores, sleep_out_sf_cores: std_logic_vector (sf_cores downto 0);

begin 

	ko <= ko_sf_cores (sf_cores);

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
		    input => pixel((i+1)*bitwidth-1 downto i*bitwidth),
		    ki => ki,
		    sleep => sleep_in,
		    rst => reset,
		    ko => ko_sf_cores (i),
		    output => z((i+1)*bitwidth-1 downto i*bitwidth),
		    sleepOut => sleep_out_sf_cores (i)
    );
	end generate;

	th22d_sleep_out_sf_cores : th22d_tree_gen
	generic map(numInputs => sf_cores )
	port map(
		a => sleep_out_sf_cores (sf_cores-1 downto 0),
		rst => reset,
		z => sleep_out_sf_cores (sf_cores)
	);

	sleep_out <= sleep_out_sf_cores (sf_cores);

end arch_MTNCL_SF_Core_Logic; 
