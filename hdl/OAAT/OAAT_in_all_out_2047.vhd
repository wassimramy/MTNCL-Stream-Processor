library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;

entity OAAT_in_all_out_2047 is
	generic( bitwidth : integer := 12;
		 numInputs : integer := 256;
		 counterWidth : integer := 8; --Log2 of numInputs
		 delay_amount : integer := 15);
	port(	 

		a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0)
	);
end OAAT_in_all_out_2047;

architecture arch_OAAT_in_all_out_2047 of OAAT_in_all_out_2047 is

		component OAAT_in_all_out_lite is
	generic( bitwidth : integer := 8;
		 numInputs : integer := 9;
		 counterWidth : integer := 4; --Log2 of numInputs
		 delay_amount : integer := 6);
	port(	 a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0));
end component;


signal reset_count : dual_rail_logic_vector(counterWidth-1 downto 0);
signal data0, data1 : dual_rail_logic;

begin

--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

gen_ko_out_delay : for i in 0 to counterWidth-1 generate
	reset_count(i) <= data1;	
end generate;
--reset_count(counterWidth-1) <= data1;
	

  sf_data_loader_instance : OAAT_in_all_out_lite
 generic map(
 							bitwidth => bitwidth,
							numInputs => numInputs,
							counterWidth => counterWidth, --Log2 of numInputs
							delay_amount => delay_amount)
  port map(
					    a => a,
					    reset_count => reset_count,
					    reset => reset,
					    ki => '1',
					    ko => ko,
					    sleep_in => sleep_in,
					    sleep_out => sleep_out,
					    z => z
    );


end arch_OAAT_in_all_out_2047;
