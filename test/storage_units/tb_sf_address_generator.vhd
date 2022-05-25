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

entity tb_sf_address_generator is
generic(bitwidth : integer := 8;
	addresswidth : integer := 12;
	numberOfPixels : integer := 4096;
	size: in integer := 64;
	clock_delay : integer := 16;
	mem_delay : integer := 48);
end tb_sf_address_generator;

architecture arch_tb_sf_address_generator of tb_sf_address_generator is

	component sf_address_generator is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth);
			
		port(

		mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
		write_en : in dual_rail_logic;
		parallelism_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		image_loaded_stored : out std_logic;
		accReset_loaded_stored : out dual_rail_logic;
		z : out dual_rail_logic_vector(addresswidth-1 downto 0)
			);
	end component;
	
	  --Updated the file names
	signal reset, ki_sig, ko_sig, sleep_in, sleep_out, image_loaded : std_logic;
	signal read_address : dual_rail_logic_vector(addresswidth-1 downto 0);
	signal mem_data : dual_rail_logic_vector(bitwidth-1 downto 0);
	signal z : dual_rail_logic_vector(addresswidth-1 downto 0);
	signal write_en,  parallelism_en, accReset_loaded_stored: dual_rail_logic;

	signal  temp : std_logic_vector(bitwidth-1 downto 0);	
begin

	uut : sf_address_generator
		generic map(bitwidth => bitwidth,
					addresswidth => addresswidth)
		port map(
				mem_data => mem_data,
				write_en => write_en,
				parallelism_en => parallelism_en,
				reset => reset,
				ki => ki_sig,
				ko => ko_sig,
				sleep_in => sleep_in,
				sleep_out => sleep_out,
				image_loaded_stored => image_loaded,
				accReset_loaded_stored => accReset_loaded_stored,
				z => z
		);
	

	process


	begin

	-- Start testing
	wait for 10 ns;

		reset <= '1';
		sleep_in <= '1';
		write_en.RAIL0 <= '0';
		write_en.RAIL1 <= '0';
		parallelism_en <= to_DR('0');	

	for i in 0 to 9*4096-1 loop

		wait on ko_sig until ko_sig = '1';
		--wait for 50 ns;
		reset <= '0';
		sleep_in <= '0';
		--read_address <= to_DR(std_logic_vector(to_unsigned(i, addresswidth)));
		--write_en <= to_DR('0');
		wait on ko_sig until ko_sig = '0';
		--wait for 50 ns;
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

end arch_tb_sf_address_generator;
