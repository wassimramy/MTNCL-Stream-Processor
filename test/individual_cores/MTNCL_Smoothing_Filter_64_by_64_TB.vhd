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

entity MTNCL_Smoothing_Filter_TB is
generic(
			bitwidth : integer := 8;
			addresswidth : integer := 12;
			numberOfPixels : integer := 4096;
			size: in integer := 64;
			clock_delay : integer := 16;
			mem_delay : integer := 48);
end MTNCL_Smoothing_Filter_TB;

architecture tb_arch of MTNCL_Smoothing_Filter_TB is

  component MTNCL_SF_Core_Top_Level is
    generic(
    					bitwidth: in integer := 4; 
    					addresswidth: in integer := 12; 
    					clock_delay: in integer := 16; 
    					mem_delay: in integer := 48);
    port(
					input : in dual_rail_logic_vector(bitwidth-1 downto 0);
					reset : in std_logic;
					ki : in std_logic;
					ko : out std_logic;
					sleep_in : in std_logic;
					sleep_out : out std_logic;
					output : out dual_rail_logic_vector(bitwidth-1 downto 0)
      );
  end component;

  --Updated the file names
	file image_64_by_64, smoothed_image_64_by_64, image_64_by_64_check : text;
	type memoryData is array(0 to (size+2)*(size+2)) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size+2)*(size+2)) of std_logic_vector(bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_smoothed_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64_binary.txt";
	file output_smoothed_image_64_by_64      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64.txt";


  signal pixel: dual_rail_logic_vector(bitwidth-1 downto 0);
  signal reset: std_logic;
  signal ko_sig: std_logic;
  signal ki_sig: std_logic;
  signal sleep_in: std_logic;
  signal sleep_out: std_logic;
  signal z: dual_rail_logic_vector(bitwidth-1 downto 0);

  signal  temp : std_logic_vector(bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector(bitwidth-1 downto 0);

  begin
    
  uut: MTNCL_SF_Core_Top_Level
 generic map(
 							bitwidth => bitwidth, 
 							addresswidth => addresswidth,  
 							clock_delay => clock_delay, 
 							mem_delay => mem_delay)
  port map(
					    input => pixel,
					    reset => reset,
					    ki => ki_sig,
					    ko => ko_sig,
					    sleep_in => sleep_in,
					    sleep_out => sleep_out,
					    output => z
    );
    
 
    signal_tb: process

variable v_ILINE : line;
variable v_inval : std_logic_vector(bitwidth-1 downto 0);

    begin
    

	-- Get the image(s)
	file_open(image_64_by_64,		 "../test/input_files/image_test_64_by_64_clean_binary",				 read_mode); -- Input image
	file_open(smoothed_image_64_by_64,	 "../test/input_files/smoothed_image_test_64_by_64_clean_binary",			 read_mode); -- Input image

  	-- Store the input image in an array
	for i in 1 to size loop
		for j in 1 to size loop
			readline(image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*(size+2))+j) <= v_inval;
		end loop;
	end loop;

	-- Store the MatLab output image in an array
	for i in 1 to size loop
		for j in 1 to size loop
			readline(smoothed_image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			matlab_memData((i*(size+2))+j) <= v_inval;
		end loop;
	end loop;

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

	for i in 1 to (size) loop
		for j in 1 to (size) loop

			temp(bitwidth-1 downto 0) <= memData((i*(size))+j);

			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to bitwidth-1 loop
				pixel(k).rail0 <= not temp(k);
				pixel(k).rail1 <= temp(k);
			end loop;
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
		end loop;
	end loop;

	for i in 0 to 0 loop
			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to bitwidth-1 loop
				pixel(k).rail0 <= '0';
				pixel(k).rail1 <= '0';
			end loop;
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
	end loop;

	for i in 1 to size loop
		for j in 1 to size loop
			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			Icheck <= memData((i*(size))+j);
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
		end loop;
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
							for i in 0 to bitwidth-1 loop			
								checker(i) <= z(i).rail1;
							end loop;
						end if;
        end process;

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
			writeline(output_smoothed_image_64_by_64,row);
			write(row, checker, right, 0);
			writeline(output_smoothed_image_64_by_64_binary,row);
			--readline(image_64_by_64_check, row_check);
			--read(row_check, row_check_inval);
		end if;

	end process;

end;
