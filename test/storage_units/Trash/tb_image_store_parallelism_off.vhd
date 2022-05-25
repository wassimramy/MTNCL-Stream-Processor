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

entity tb_image_store is
generic(bitwidth : integer := 8;
	addresswidth : integer := 12;
	numberOfPixels : integer := 4096;
	size: in integer := 64;
	clock_delay : integer := 16;
	mem_delay : integer := 48);
end tb_image_store;

architecture arch_tb_image_store of tb_image_store is

	component image_store is
		generic(bitwidth : integer := bitwidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(

			mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
			read_address : in dual_rail_logic_vector(addresswidth-1 downto 0);
			write_en : in dual_rail_logic;
			parallelism_en : in dual_rail_logic;
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			image_loaded : out std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0)
			);
	end component;
	
	  --Updated the file names
	file image_64_by_64, output_image_64_by_64 : text;
	type memoryData is array(0 to (size+2)*(size+2)) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size)*(size)) of std_logic_vector(bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_image_64_by_64_binary.txt";
	--file output_image_64_by_64      : text open write_mode is "../test/output_files/output_image_64_by_64.txt";

	signal reset, ki_sig, ko_sig, sleep_in, sleep_out, image_loaded : std_logic;
	signal read_address : dual_rail_logic_vector(addresswidth-1 downto 0);
	signal mem_data : dual_rail_logic_vector(bitwidth-1 downto 0);
	signal z : dual_rail_logic_vector(bitwidth-1 downto 0);
	signal write_en,  parallelism_en: dual_rail_logic;

	signal  temp : std_logic_vector(bitwidth-1 downto 0);	
begin

	uut : image_store
		generic map(bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)
		port map(
				mem_data => mem_data,
				read_address => read_address,
				write_en => write_en,
				parallelism_en => parallelism_en,
				reset => reset,
				ki => ki_sig,
				ko => ko_sig,
				sleep_in => sleep_in,
				sleep_out => sleep_out,
				image_loaded => image_loaded,
				z => z
		);
	

	process
	variable v_ILINE : line;
	variable v_inval : std_logic_vector(bitwidth-1 downto 0);

	begin

	-- Get the image(s)
	file_open(image_64_by_64,		 "../test/input_files/image_test_64_by_64_clean_binary",				 read_mode); -- Input image
	file_open(output_image_64_by_64,	 "../test/input_files/equalized_image_test_64_by_64_clean_binary",			 read_mode); -- Input image

  	-- Store the input image in an array
	for i in 1 to size loop
		for j in 1 to size loop
			readline(image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*(size+2))+j) <= v_inval;
		end loop;
	end loop;

	-- Store the MatLab output image in an array
--	for i in 1 to size loop
--		for j in 1 to size loop
--			readline(output_image_64_by_64, v_ILINE);
--			read(v_ILINE, v_inval);
--			matlab_memData((i*(size+2))+j) <= v_inval;
--		end loop;
--	end loop;

	-- Start testing
	wait for 10 ns;

	for i in 0 to size+1 loop
		memData((i*(size+2))+0) <= "00000000";
		memData((i*(size+2))+(size+1)) <= "00000000";
	end loop;

	for i in 1 to size loop
		memData(i) <= "00000000";
		memData((size+2)*(size+1)+i) <= "00000000";
	end loop;

	wait for 10 ns;

		reset <= '1';
		sleep_in <= '1';
		write_en.RAIL0 <= '0';
		write_en.RAIL1 <= '0';
--		parallelism_en.RAIL0 <= '0';
--		parallelism_en.RAIL1 <= '0';

		parallelism_en <= to_DR('0');	

	for i in 1 to size loop
		for j in 1 to size loop

			temp <= memData((i*(size+2))+j);

			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to bitwidth-1 loop
				mem_data(k).rail0 <= not temp(k);
				mem_data(k).rail1 <= temp(k);
			end loop;
			write_en <= to_DR('1');	
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
		end loop;
	end loop;

		--wait for 20 ns;
		--write_en <= to_DR('0');

	for i in 0 to numberOfPixels-1 loop

		wait on ko_sig until ko_sig = '1';
		reset <= '0';
		sleep_in <= '0';
		read_address <= to_DR(std_logic_vector(to_unsigned(i, addresswidth)));
		write_en <= to_DR('0');
		wait on ko_sig until ko_sig = '0';
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

end arch_tb_image_store;
