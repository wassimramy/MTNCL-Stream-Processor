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

entity SYNC_SF_Core_TB is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096; size: in integer := 64);
end SYNC_SF_Core_TB;

architecture tb_arch of SYNC_SF_Core_TB is

  component SYNC_SF_Core is
    generic(bitwidth: in integer := 8);
    port(
    	clk : in std_logic;
			pixel_in    	: in  std_logic_vector(bitwidth-1 downto 0);
			reset  		: in std_logic;
			parallelism_en : in std_logic;
			id: in std_logic;
			pixel_out   	: out std_logic_vector((2*bitwidth-1) downto 0)
      );
  end component;

--Updated the file names
	file image_64_by_64, smoothed_image_64_by_64 : text;
	type memoryData is array(0 to 66*66) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to 66*66) of std_logic_vector(bitwidth-1  downto 0);
	signal matlab_memData : matlab_memoryData;
	file output_smoothed_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64_binary.txt";
	file output_smoothed_image_64_by_64      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64.txt";

  signal input_signal: std_logic_vector(bitwidth-1 downto 0);
  signal reset_signal: std_logic;
  signal S_signal: std_logic_vector(2*bitwidth-1 downto 0);
	signal clk, parallelism_en, id : std_logic := '0';

signal temp: std_logic_vector(9*bitwidth-1 downto 0);
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck : std_logic_vector(bitwidth-1 downto 0);

  begin
    
  uut: SYNC_SF_Core
 generic map(bitwidth => bitwidth)
  port map(
  					clk => clk,
				    pixel_in => input_signal,
				    reset => reset_signal,
				    parallelism_en => parallelism_en,
				    id => id,
				    pixel_out => S_signal
    );
    
 
    signal_tb: process

variable v_ILINE : line;
variable v_inval : std_logic_vector(bitwidth-1 downto 0);

    begin
    
  
	-- Get the image(s)
	file_open(image_64_by_64 ,		 "../test/input_files_lena/image_test_64_by_64_clean_binary",				 read_mode); -- Input image
	file_open(smoothed_image_64_by_64 ,	 "../test/input_files_lena/self_smoothed_image_test_64_by_64_clean_binary",			 read_mode); -- Input image

  	-- Store the input image in an array
	for i in 1 to 64 loop
		for j in 1 to 64 loop
			readline(image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*66)+j) <= v_inval;
		end loop;
	end loop;

	-- Store the MatLab output image in an array
	for i in 1 to 64 loop
		for j in 1 to 64 loop
			readline(smoothed_image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			matlab_memData((i*66)+j) <= v_inval;
		end loop;
	end loop;

	-- Start testing
	wait for 10 ns;

	for i in 0 to 65 loop
		memData((i*66)+0) <= "00000000";
		memData((i*66)+65) <= "00000000";
	end loop;

	for i in 1 to 64 loop
		memData(i) <= "00000000";
		memData(66*65+i) <= "00000000";
	end loop;

	-- Start testing
	wait for 10 ns;
	parallelism_en <= '1';
	id <= '0';
  reset_signal <= '1';
  wait for 10 ns;
  reset_signal <= '0';
	wait for 10 ns;

	
	for i in 1 to size loop
		for j in 1 to size loop

			wait on clk until clk = '0';
			input_signal <= memData((i*66)+j);
				
		end loop;
	end loop;

	wait;
      end process;

        
clk_process :process
   begin
        clk <= not clk;
        wait for 50ns;
   end process;

end;
