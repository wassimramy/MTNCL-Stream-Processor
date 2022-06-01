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

entity tb_sf_data_output is
generic(
			bitwidth : integer := 8;
			addresswidth : integer := 12;
			numberOfPixels : integer := 4096;
			size: in integer := 64;
			clock_delay : integer := 16;
			mem_delay : integer := 48);
end tb_sf_data_output;

architecture arch_tb_sf_data_output of tb_sf_data_output is

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
				ko : out std_logic;
				sleep_in : in std_logic;
				sleep_out : out std_logic;
				z : out dual_rail_logic_vector(bitwidth-1 downto 0)
			);
	end component;
	
	 --Updated the file names
	file image_64_by_64, output_image_64_by_64, image_64_by_64_check : text;
	type memoryData is array(0 to (size)*(size)) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size)*(size)) of std_logic_vector(bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_sf_data_output_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_sf_data_output_image_64_by_64_binary.txt";
	file output_sf_data_output_image_64_by_64      : text open write_mode is "../test/output_files/output_sf_data_output_image_64_by_64.txt";

	signal reset, ki_sig, ko_sig, sleep_in, sleep_out : std_logic;
	signal pixel : dual_rail_logic_vector(2*bitwidth-1 downto 0);
	signal z : dual_rail_logic_vector(bitwidth-1 downto 0);
	signal temp : std_logic_vector(2*bitwidth-1 downto 0);
	signal write_en: dual_rail_logic;

	  signal CORRECT: std_logic;
	  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
	  signal Icheck, slowIcheck : std_logic_vector(bitwidth-1 downto 0);

begin

	uut : MTNCL_SF_Core_Data_Output
		generic map(bitwidth => bitwidth,
					addresswidth => addresswidth)
		port map(
				pixel => pixel,
				reset => reset,
				ki => ki_sig,
				sleep_in => sleep_in,
				ko => ko_sig,
				sleep_out => sleep_out,
				z => z
		);
	
	process
	variable v_ILINE : line;
	variable v_inval : std_logic_vector(bitwidth-1 downto 0);

	begin

	-- Get the image(s)
	file_open(image_64_by_64,		 "../test/input_files/image_test_64_by_64_clean_binary",				 read_mode); -- Input image
	file_open(image_64_by_64_check,		 "../test/input_files/image_test_64_by_64_clean_binary",				 read_mode); -- Input image
  	-- Store the input image in an array
	for i in 0 to size-1 loop
		for j in 0 to size-1 loop
			readline(image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*(size))+j) <= v_inval;
		end loop;
	end loop;

	-- Start testing
	wait for 10 ns;

		reset <= '1';
		sleep_in <= '1';
		write_en.RAIL0 <= '0';
		write_en.RAIL1 <= '0';

	for i in 0 to (size/2)-1 loop
		for j in 0 to (size)-1 loop

			temp(bitwidth-1 downto 0) <= memData((i*(size))+j);
			temp(2*bitwidth-1 downto bitwidth) <= memData(((i+(size/2))*(size))+j);

			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to 2*bitwidth-1 loop
				pixel(k).rail0 <= not temp(k);
				pixel(k).rail1 <= temp(k);
			end loop;
			write_en <= to_DR('1');	
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
		end loop;
	end loop;



	for i in 0 to 0 loop
			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to 2*bitwidth-1 loop
				pixel(k).rail0 <= '0';
				pixel(k).rail1 <= '0';
			end loop;
			write_en <= to_DR('0');
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
	end loop;

	for i in 0 to size-1 loop
		for j in 0 to size-1 loop
			--Icheck <= memData((i*(size))+j);
			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			Icheck <= memData((i*(size))+j);
			write_en <= to_DR('0');
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
			--Icheck <= memData((i*(size))+j);
		end loop;
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

		if is_data(z) then
			for i in 0 to bitwidth-1 loop			
				checker(i) <= z(i).rail1;
			end loop;

		end if;
	end process;

	--final process to assign output comparison
	process( checker)
	begin
			if checker = Icheck then
				report "correct";
				CORRECT <= '1';
			else
				report "incorrect";
				CORRECT <= '0';
			end if;
	end process;

	process(ki_sig)
	variable row          : line;
	variable row_check          : line;
	variable row_check_inval : std_logic_vector(bitwidth-1 downto 0);

	begin

		if checker(0) <= 'U' then

		elsif (ki_sig = '0') then
			write(row, conv_integer(checker), right, 0);
			writeline(output_sf_data_output_image_64_by_64,row);
			write(row, checker, right, 0);
			writeline(output_sf_data_output_image_64_by_64_binary,row);
			readline(image_64_by_64_check, row_check);
			read(row_check, row_check_inval);
		end if;

	end process;



end arch_tb_sf_data_output;
