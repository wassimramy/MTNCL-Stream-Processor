library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.ncl_signals.all;
use work.functions.all;
use work.tree_funcs.all;

entity tbHQ_OAAT_in_all_out is
generic(bitwidth : integer := 8;
	numInputs : integer := 9;
--	numInputs : integer := 64;
--	counterWidth : integer := 6 ); --Log2 of numInputs
	counterWidth : integer := 4 ); --Log2 of numInputs
end tbHQ_OAAT_in_all_out;

architecture arch_tbHQ_OAAT_in_all_out of tbHQ_OAAT_in_all_out is


--COMPONENT UNDER TEST
component OAAT_in_all_out is
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

--COMPONENT TEST SIGNALS
signal a : dual_rail_logic_vector(bitwidth-1 downto 0);
signal reset_count : dual_rail_logic_vector(counterWidth-1 downto 0);
signal z : dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
signal sleep_in, reset, ki, ko, sleep_out : std_logic;

--DATA GENERATION AND SELF TEST SIGNALS
signal data_a, null_a : dual_rail_logic_vector(bitwidth-1 downto 0);
signal a_sr : std_logic_vector(bitwidth-1 downto 0);
signal z_sr, z_correct : std_logic_vector(numInputs*bitwidth-1 downto 0);


begin

--UNIT UNDER TEST INSTANTIATION

uut : OAAT_in_all_out
	generic map( bitwidth => bitwidth,
		 numInputs => numInputs,
		 counterWidth => counterWidth, --Log2 of numInputs
		 delay_amount => 6)
	port map(a => a,
		reset_count => reset_count,
		sleep_in => sleep_in,
		 reset => reset,
		 ki => ki,
		 ko => ko,
		 sleep_out => sleep_out,
		 z => z);


reset_proc : process
begin
	reset <= '1';
	wait for 10 ns;
	reset <= '0';
	wait;
end process;

--Constant values
generate_values : for i in 0 to bitwidth-1 generate
	data_a(i).rail1 <= a_sr(i);
	data_a(i).rail0 <= not a_sr(i);

	null_a(i).rail1 <= '0';
	null_a(i).rail0 <= '0';

end generate;

generate_z : for i in 0 to numInputs*bitwidth-1 generate
	z_sr(i) <= z(i).rail1;
end generate;



reset_count(0).rail0 <= '1';
reset_count(0).rail1 <= '0';
reset_count(1).rail0 <= '1';
reset_count(1).rail1 <= '0';
reset_count(2).rail0 <= '1';
reset_count(2).rail1 <= '0';
reset_count(3).rail0 <= '0';
reset_count(3).rail1 <= '1';
--reset_count(4).rail0 <= '0';
--reset_count(4).rail1 <= '1';
--reset_count(5).rail0 <= '0';
--reset_count(5).rail1 <= '1';


--reset_count(0).rail0 <= '0';
--reset_count(0).rail1 <= '1';
--reset_count(1).rail0 <= '0';
--reset_count(1).rail1 <= '1';
--reset_count(2).rail0 <= '0';
--reset_count(2).rail1 <= '1';
--reset_count(3).rail0 <= '0';
--reset_count(3).rail1 <= '1';
--reset_count(4).rail0 <= '0';
--reset_count(4).rail1 <= '1';
--reset_count(5).rail0 <= '0';
--reset_count(5).rail1 <= '1';

ki_proc: process
begin
	wait for 1 ns;
	if reset = '1' then
		ki <= '1';
	end if;
	if (IS_DATA(z)) then
		wait for 5 ns;
		ki <= '0';
	elsif (IS_NULL(z)) then 
		wait for 5 ns;
		ki <= '1';
	else
		wait for 1 ns;
	end if;
end process;

data_proc: process
begin
	if ko = '1' then
		wait for 5 ns;
		sleep_in <= '0';
		a <= data_a;
	elsif ko = '0' then
		wait for 5 ns;
		sleep_in <= '1';
		a <= null_a;
	else
		wait for 1 ns;
	end if;
end process;

data_sr_proc: process
begin
	wait for 1 ns;
	if reset = '1' then
		a_sr <= (others => '0'); 
	end if;
	wait until ko = '1';
		a_sr <= a_sr + '1';
	wait until ko = '0';
end process;

--CHANGE BASED ON BEHAVIOR OF UUT
z_correct_calc : process
begin
	wait for 1 ns;
	if reset = '1' then
		z_correct <= (others => '0');
	end if;
	wait until ko = '0';

	wait until ko = '1';
end process;

report_proc: process
begin
	wait until (IS_DATA(z));
	wait for 1 ns;
	if z_sr = z_correct then
		report "PASS";
	else
		report "FAIL";
	end if;
	wait until (IS_NULL(z));
end process;

end arch_tbHQ_OAAT_in_all_out;
