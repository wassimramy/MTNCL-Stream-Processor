library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;
use ieee.math_real.all;

entity OAAT_out_all_in_255 is
	generic( bitwidth : integer := 12;
		 numInputs : integer := 256);
	port(	 
		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		z: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end OAAT_out_all_in_255;

architecture arch_OAAT_out_all_in_255 of OAAT_out_all_in_255 is

		component OAAT_out_all_in is
	generic( bitwidth : integer := 8;
		 numInputs : integer := 9);
	port(	 

		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
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


signal reset_count, count : dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
signal data0, data1, accumulate_reset : dual_rail_logic;

begin

--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

gen_ko_out_delay : for i in 0 to integer(ceil(log2(real(numInputs))))-1 generate
	reset_count(i) <= data1;	
end generate;

	

  sf_data_loader_instance : OAAT_out_all_in
 generic map(
 							bitwidth => bitwidth,
							numInputs => numInputs)
  port map(
					    a => a,
					    reset_count => reset_count,
					    reset => reset,
					    ki => ki,
					    ko => ko,
					    sleep_in => sleep_in,
					    sleep_out => sleep_out,
					    accumulate_reset => accumulate_reset,
					    count => count,
					    z => z
    );


end arch_OAAT_out_all_in_255;
