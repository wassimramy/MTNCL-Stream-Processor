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

entity MTNCL_Control_Unit_sf_32_by_32_TB is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 10; numberOfPixels: in integer := 1024; size: in integer := 32; opCodeBitwidth: in integer := 2);
end  MTNCL_Control_Unit_sf_32_by_32_TB;

architecture tb_arch of  MTNCL_Control_Unit_sf_32_by_32_TB is

  component MTNCL_Control_Unit is
    generic(bitwidth: in integer := 4; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096; opCodeBitwidth: in integer := 2);
    port(
		opCode    	: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth)-1 downto 0)
      );
  end component;

  --Updated the file names
	file image_32_by_32, smoothed_image_32_by_32 : text;
	type memoryData is array(0 to (size+2)*(size+2)) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size+2)*(size+2)) of std_logic_vector(bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_smoothed_image_32_by_32_binary      : text open write_mode is "../test/output_files/output_smoothed_image_32_by_32_binary.txt";
	file output_smoothed_image_32_by_32      : text open write_mode is "../test/output_files/output_smoothed_image_32_by_32.txt";

  signal opCode_signal: dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
  signal input_signal: dual_rail_logic_vector(bitwidth-1 downto 0);
  signal reset_signal: std_logic;
  signal ko_signal: std_logic;
  signal ki_signal: std_logic;
  signal sleepin_signal: std_logic;
  signal sleepout_signal: std_logic;
  signal S_signal: dual_rail_logic_vector(bitwidth-1 downto 0);

  signal  temp_1, temp_2, temp_3, temp_4, temp_5, temp_6 , temp_7, temp_8, temp_9 : std_logic_vector(bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector(bitwidth-1 downto 0);

signal null_a : dual_rail_logic_vector(bitwidth-1 downto 0);

  signal data_0,data_1		: dual_rail_logic;

  begin
    
  uut: MTNCL_Control_Unit
 generic map(bitwidth => bitwidth, numberOfShades => numberOfShades,  shadeBitwidth =>shadeBitwidth , numberOfPixels => numberOfPixels, opCodeBitwidth => opCodeBitwidth)
  port map(
    opCode => opCode_signal,
    input => input_signal,
    ki => ki_signal,
    sleep => sleepin_signal,
    rst => reset_signal,
    ko => ko_signal,
    output => S_signal,
    sleepOut => sleepout_signal
    );
   
 generate_values : for i in 0 to bitwidth-1 generate

	null_a(i).rail1 <= '0';
	null_a(i).rail0 <= '0';

end generate;	 
 
    signal_tb: process

variable v_ILINE : line;
variable v_inval : std_logic_vector(bitwidth-1 downto 0);

    begin
    
	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	-- Get the image(s)
	file_open(image_32_by_32,		 "../test/input_files/image_test_32_by_32_clean_binary",				 read_mode); -- Input image
	file_open(smoothed_image_32_by_32,	 "../test/input_files/self_smoothed_image_test_32_by_32_clean_binary",			 read_mode); -- Input image

  	-- Store the input image in an array
	for i in 1 to size loop
		for j in 1 to size loop
			readline(image_32_by_32, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*(size+2))+j) <= v_inval;
		end loop;
	end loop;

	-- Store the MatLab output image in an array
	for i in 1 to size loop
		for j in 1 to size loop
			readline(smoothed_image_32_by_32, v_ILINE);
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
	opCode_signal <= data_0 & data_0;
        reset_signal <= '1';
	sleepin_signal <= '1';

	for i in 1 to size loop
		for j in 1 to size loop

			temp_1 <= memData(((i-1)*(size+2))+(j-1));
			temp_2 <= memData(((i-1)*(size+2))+j);
			temp_3 <= memData(((i-1)*(size+2))+(j+1));
			temp_4 <= memData((i*(size+2))+(j-1));
			temp_5 <= memData((i*(size+2))+j);
			temp_6 <= memData((i*(size+2))+(j+1));
			temp_7 <= memData(((i+1)*(size+2))+(j-1));
			temp_8 <= memData(((i+1)*(size+2))+(j));
			temp_9 <= memData(((i+1)*(size+2))+(j+1));

			wait on ko_signal until ko_signal = '1';
			reset_signal <= '0';
			sleepin_signal <= '0';

			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_1(k);
				input_signal(k).rail1 <= temp_1(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_2(k);
				input_signal(k).rail1 <= temp_2(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_3(k);
				input_signal(k).rail1 <= temp_3(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_4(k);
				input_signal(k).rail1 <= temp_4(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_5(k);
				input_signal(k).rail1 <= temp_5(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_6(k);
				input_signal(k).rail1 <= temp_6(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_7(k);
				input_signal(k).rail1 <= temp_7(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_8(k);
				input_signal(k).rail1 <= temp_8(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;

			wait on ko_signal until ko_signal = '1';
			wait for 5 ns;
			sleepin_signal <= '0';
			
			for k in 0 to bitwidth-1 loop
				input_signal(k).rail0 <= not temp_9(k);
				input_signal(k).rail1 <= temp_9(k);
			end loop;

			wait on ko_signal until ko_signal = '0';
			wait for 5 ns;
			sleepin_signal <= '1';
			input_signal <= null_a;
			Icheck <= matlab_memData((i*(size+2))+j);

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
		for i in 0 to bitwidth-1 loop			
			checker(i) <= S_signal(i).rail1;
		end loop;
		if checker = slowIcheck then
			report "correct";
			CORRECT <= '1';
		else
			report "incorrect";
			CORRECT <= '0';
		end if;
	end if;
        end process;
        
	--final process to assign output comparison
	process( checker)
	begin
		slowIcheck <= Icheck;
	end process;

	process(sleepout_signal)
	variable row          : line;
	begin

		if checker(0) <= 'U' then

		elsif (sleepout_signal = '1') then
			report "writing to o/p file";
			write(row, conv_integer(checker), right, 0);
			writeline(output_smoothed_image_32_by_32,row);
			write(row, checker, right, 0);
			writeline(output_smoothed_image_32_by_32_binary,row);
		end if;

	end process;

end;
