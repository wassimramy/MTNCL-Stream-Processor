use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.ncl_signals.all;
use work.NCL_functions.all;
use work.tree_funcs.all;

entity tb_weightMemory_4096x8 is
generic(bitwidth : integer := 8;
	addresswidth : integer := 12;
	wordCount : integer := 4096;
	clock_delay : integer := 16;
	mem_delay : integer := 48);
end tb_weightMemory_4096x8;

architecture arch_tb_weightMemory_4096x8 of tb_weightMemory_4096x8 is

	component sram_4096w_8b_8m_wrapper is
		generic(bitwidth : integer := bitwidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(address : in std_logic_vector(addresswidth-1 downto 0);
			mem_data : in std_logic_vector(bitwidth-1 downto 0);
			write_en : in dual_rail_logic;
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;
	
	signal reset, ki_sig, ko_sig, sleep_in, sleep_out : std_logic;
	signal address : std_logic_vector(addresswidth-1 downto 0);
	signal mem_data : std_logic_vector(bitwidth-1 downto 0);
	signal z : dual_rail_logic_vector(bitwidth-1 downto 0);
	signal write_en : dual_rail_logic;
begin

	uut : sram_4096w_8b_8m_wrapper
		generic map(bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)
		port map(
				address => address,
				mem_data => mem_data,
				write_en => write_en,
				reset => reset,
				ki => ki_sig,
				ko => ko_sig,
				sleep_in => sleep_in,
				sleep_out => sleep_out,
				z => z
		);
	

	process
	begin
		reset <= '1';
		sleep_in <= '1';

	for i in 0 to wordCount-1 loop

		wait for 5 ns;
		reset <= '0';
		sleep_in <= '0';
		address <= std_logic_vector(to_unsigned(i, addresswidth));
		mem_data <= std_logic_vector(to_unsigned(i, bitwidth));
		write_en <= to_DR('1');
		wait for 5 ns;
		sleep_in <= '1';
		wait for 5 ns;
		sleep_in <= '0';
		address <= std_logic_vector(to_unsigned(i, addresswidth));
		write_en <= to_DR('0');
		wait until ko_sig = '0';
		sleep_in <= '1';

	end loop;

		wait;
	end process;
	
	Ki_g: process(z)
	begin
		if is_null(z) then
			ki_sig <= '1';
		elsif is_data(z) then
			ki_sig <= '0';
		end if;
	
	end process;

end arch_tb_weightMemory_4096x8;
