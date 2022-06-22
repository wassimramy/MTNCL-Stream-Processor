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

entity MTNCL_Shade_Counter_TB is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096; size: in integer := 64);
end MTNCL_Shade_Counter_TB;

architecture tb_arch of MTNCL_Shade_Counter_TB is

  component MTNCL_Shade_Counter is
    generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((256*12)-1 downto 0)
      );
  end component;

  --Updated the file names
	file image_64_by_64, image_64_by_64_pixel_count_steps : text;
	type memoryData is array(0 to size*size) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to size*size) of std_logic_vector(numberOfShades*shadeBitwidth-1 downto 0);
	signal memData_pixel_count : matlab_memoryData;

	--type output_memoryData is array(0 to 256-1) of std_logic_vector(12-1 downto 0);
	--signal output_memData : output_memoryData;

	file output_image_64_by_64_binary_pixel_count_steps      : text open write_mode is "../test/output_files/output_image_64_by_64_binary_pixel_count_steps.txt";
	

  signal input_signal: dual_rail_logic_vector((bitwidth)-1 downto 0);
  signal reset_signal: std_logic;
  signal ko_signal: std_logic;
  signal ki_signal: std_logic;
  signal sleepin_signal: std_logic;
  signal sleepout_signal: std_logic;
  signal S_signal: dual_rail_logic_vector(numberOfShades*shadeBitwidth-1 downto 0);
  
  signal  temp : std_logic_vector(bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector(bitwidth-1 downto 0);
  signal pixelCount : std_logic_vector(numberOfShades*shadeBitwidth-1 downto 0);
	
  signal pixelCountTemp : std_logic_vector(256*12-1 downto 0);
  signal pixelCountChecker : std_logic_vector(12-1 downto 0) := "111111111111";

  begin
    
  uut: MTNCL_Shade_Counter
 generic map(bitwidth => bitwidth, numberOfShades => numberOfShades, shadeBitwidth => shadeBitwidth)
  port map(
    input => input_signal,
    ki => ki_signal,
    sleep => sleepin_signal,
    rst => reset_signal,
    ko => ko_signal,
    output => S_signal,
    sleepOut => sleepout_signal
    );
    
 
    signal_tb: process

variable v_ILINE : line;
variable v_inval : std_logic_vector(bitwidth-1 downto 0);
variable v_inval_pixel_count : std_logic_vector(numberOfShades*shadeBitwidth-1 downto 0);

    begin
    

	-- Get the image(s)
	file_open(image_64_by_64,		 										"../test/input_files_lena/image_test_64_by_64_clean_binary",				 									read_mode); 
	file_open(image_64_by_64_pixel_count_steps,		 	"../test/input_files_lena/image_test_64_by_64_clean_binary_pixel_count_steps",				read_mode);

  -- Store the input image in an array
	for i in 0 to size-1 loop
		for j in 0 to size-1 loop
			readline(image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*size)+j) <= v_inval;
		end loop;
	end loop;

	-- Store the input image pixel count in an array
	for i in 0 to size*size-1 loop
			readline(image_64_by_64_pixel_count_steps, v_ILINE);
			read(v_ILINE, v_inval_pixel_count);
			memData_pixel_count(i) <= v_inval_pixel_count;
	end loop;

	-- Start testing
	wait for 10 ns;
  reset_signal 		<= '1';
	sleepin_signal 	<= '1';


	for i in 0 to size-1 loop
		for j in 0 to size-1 loop

			temp <= memData((i*size)+j);

			wait on ko_signal until ko_signal = '1';
			reset_signal <= '0';
			sleepin_signal <= '0';
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp(k);
				input_signal(k).rail1 <= temp(k);
			end loop;
			wait on ko_signal until ko_signal = '0';
			sleepin_signal <= '1';
			--wait on ki_signal until ki_signal = '0';
			--pixelCount <= memData_pixel_count(i*size+j);
		end loop;
	end loop;

	wait;
      end process;

        
        process(S_signal)
          begin
            if is_null(S_signal) then
              ki_signal <= '1';
            elsif is_data(S_signal) then
              ki_signal <= '0';
            end if;

	if is_data(S_signal) then
		for i in 0 to numberOfShades*shadeBitwidth-1 loop
			pixelCountTemp(i) <= S_signal(i).rail1;
		end loop;
		if pixelCount = pixelCountTemp then
			CORRECT <= '1';
		else
			CORRECT <= '0';
		end if;
	end if;
  end process;
        


	process(ki_signal)
	variable row          : line;
	begin
		if ki_signal = '0' then
			write(row, pixelCountTemp);
			writeline(output_image_64_by_64_binary_pixel_count_steps,row);
		end if;	
	end process;
end;
