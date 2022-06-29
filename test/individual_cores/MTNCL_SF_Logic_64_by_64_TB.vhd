use work.ncl_signals.all;
use std.textio.all;
library ieee;
use ieee.std_logic_textio.all;
use ieee.std_logic_1164.all;
use work.NCL_functions.all;
use work.ncl_signals.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity MTNCL_SF_Logic_TB is
generic(
			bitwidth : integer := 8;
			addresswidth : integer := 12;
			sf_cores : integer := 2;
			numberOfPixels : integer := 4096;
			size: in integer := 64;
			clock_delay : integer := 16;
			mem_delay : integer := 48);
end MTNCL_SF_Logic_TB;

architecture tb_arch of MTNCL_SF_Logic_TB is

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

  --Updated the file names
	file sf_data_loader_64_by_64, smoothed_image_64_by_64, image_64_by_64_check : text;
	type memoryData is array(0 to 9216-1) of std_logic_vector(sf_cores*bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size)*(size)) of std_logic_vector(sf_cores*bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_sf_logic_64_by_64_binary      : text open write_mode is "../test/output_files/output_sf_logic_64_by_64_binary.txt";
	file output_sf_logic_64_by_64      : text open write_mode is "../test/output_files/output_sf_logic_64_by_64.txt";


  signal pixel: dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);
  signal id, parallelism_en: dual_rail_logic;
  signal reset: std_logic;
  signal ko_sig: std_logic;
  signal ki_sig: std_logic;
  signal sleep_in: std_logic;
  signal sleep_out: std_logic;
  signal z: dual_rail_logic_vector(sf_cores*bitwidth-1 downto 0);

  signal  temp : std_logic_vector(sf_cores*bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(sf_cores*bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector(sf_cores*bitwidth-1 downto 0);

  begin
    
  uut: MTNCL_SF_Core_Logic
 generic map(
 							bitwidth => bitwidth, 
 							sf_cores => sf_cores)
  port map(
					    pixel => pixel,
					    reset => reset,
					    ki => ki_sig,
					    ko => ko_sig,
					    sleep_in => sleep_in,
					    sleep_out => sleep_out,
					    z => z
    );
    
 
    signal_tb: process

variable v_ILINE : line;
variable v_inval : std_logic_vector(sf_cores*bitwidth-1 downto 0);

    begin
    

	-- Get the image(s)
	file_open(sf_data_loader_64_by_64,		 "../test/input_files_lena/sf_data_loader_64_by_64_binary.txt",				 read_mode); -- Input image
	--file_open(sf_data_loader_64_by_64_binary,	 "../test/input_files_lena/self_smoothed_image_test_64_by_64_clean_binary",			 read_mode); -- Input image

  	-- Store the input image in an array
	for i in 0 to 9216-1 loop
			readline(sf_data_loader_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData(i) <= v_inval;
	end loop;

	-- Store the MatLab output image in an array
	--for i in 0 to size-1 loop
	--	for j in 0 to size-1 loop
	--		readline(smoothed_image_64_by_64, v_ILINE);
	--		read(v_ILINE, v_inval);
	--		matlab_memData((i*(size))+j) <= v_inval;
	--	end loop;
	--end loop;

	-- Start testing
	wait for 10 ns;

				wait for 10 ns;
        reset <= '1';
				sleep_in <= '1';
				parallelism_en.rail0 <= '0';
				parallelism_en.rail1 <= '1';
				id.rail0 <= '1';
				id.rail1 <= '0';

	for i in 0 to 9216-1 loop

			temp(sf_cores*bitwidth-1 downto 0) <= memData(i);

			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to sf_cores*bitwidth-1 loop
				pixel(k).rail0 <= not temp(k);
				pixel(k).rail1 <= temp(k);
			end loop;
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
	end loop;

				wait;
      end process;

        

	process(z)
begin
  if is_null(z) then
    ki_sig <= '1';
  elsif is_data(z) then
    ki_sig <= '0';
  end if;

	if is_data(z) then
		for i in 0 to sf_cores*bitwidth-1 loop			
			checker(i) <= z(i).rail1;
		end loop;
		--if checker = Icheck then
		--	report "correct";
		--	CORRECT <= '1';
		--else
		--	report "incorrect";
		--	CORRECT <= '0';
		--end if;
	end if;
end process;


process(ki_sig)
	variable row          : line;
	variable row_check          : line;
	variable row_check_inval : std_logic_vector(sf_cores*bitwidth-1 downto 0);

	begin

		if checker(0) <= 'U' then

		elsif (ki_sig = '0') then
			write(row, conv_integer(checker), right, 0);
			writeline(output_sf_logic_64_by_64,row);
			write(row, checker, right, 0);
			writeline(output_sf_logic_64_by_64_binary,row);
			--readline(image_64_by_64_check, row_check);
			--read(row_check, row_check_inval);
		end if;

	end process;

end;
