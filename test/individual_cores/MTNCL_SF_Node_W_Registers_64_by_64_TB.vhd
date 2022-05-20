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

entity MTNCL_SF_Node_W_Registers_TB is
generic(numInputs : integer := 9; bitwidth : integer := 8);
end MTNCL_SF_Node_W_Registers_TB;

architecture tb_arch of MTNCL_SF_Node_W_Registers_TB is

  component MTNCL_SF_Node_W_Registers is
    generic(bitwidth: in integer := 4);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth-1) downto 0)
      );
  end component;

  --Updated the file names
	file image_64_by_64, smoothed_image_64_by_64 : text;
	type memoryData is array(0 to 66*66) of std_logic_vector(7 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to 66*66) of std_logic_vector(7 downto 0);
	signal matlab_memData : matlab_memoryData;
	file output_smoothed_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64_binary.txt";
	file output_smoothed_image_64_by_64      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64.txt";

  signal input_signal: dual_rail_logic_vector((bitwidth)-1 downto 0);
  signal reset_signal: std_logic;
  signal ko_signal: std_logic;
  signal ki_signal: std_logic;
  signal sleepin_signal: std_logic;
  signal sleepout_signal: std_logic;
  signal S_signal: dual_rail_logic_vector(bitwidth-1 downto 0);
  
signal null_a : dual_rail_logic_vector(bitwidth-1 downto 0);

  signal  temp_1, temp_2, temp_3, temp_4, temp_5, temp_6 , temp_7, temp_8, temp_9 : std_logic_vector(bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector(bitwidth-1 downto 0);

  begin
    
  uut: MTNCL_SF_Node_W_Registers
 generic map(bitwidth => bitwidth)
  port map(
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
variable v_inval : std_logic_vector(7 downto 0);


    begin
    
	-- Get the image(s)
	file_open(image_64_by_64,		 "../test/input_files/image_test_64_by_64_clean_binary",				 read_mode); -- Input image
	file_open(smoothed_image_64_by_64,	 "../test/input_files/self_smoothed_image_test_64_by_64_clean_binary",			 read_mode); -- Input image

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

	wait for 10 ns;
        reset_signal <= '1';
	sleepin_signal <= '1';

	for i in 1 to 63 loop
		for j in 1 to 63 loop

			temp_1 <= memData(((i-1)*66)+(j-1));
			temp_2 <= memData(((i-1)*66)+j);
			temp_3 <= memData(((i-1)*66)+(j+1));
			temp_4 <= memData((i*66)+(j-1));
			temp_5 <= memData((i*66)+j);
			temp_6 <= memData((i*66)+(j+1));
			temp_7 <= memData(((i+1)*66)+(j-1));
			temp_8 <= memData(((i+1)*66)+(j));
			temp_9 <= memData(((i+1)*66)+(j+1));

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
			Icheck <= matlab_memData((i*66)+j);

		end loop;
	end loop;

	wait;
      end process;
        
        process(S_signal)
          begin
            if is_null(S_signal) then
		--wait for 5 ns;
              ki_signal <= '1';
            elsif is_data(S_signal) then
		--wait for 5 ns;
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

	process(ko_signal)
	variable row          : line;
	begin

		if checker(0) <= 'U' then

		elsif (ko_signal = '1') then
			write(row, conv_integer(checker), right, 0);
			writeline(output_smoothed_image_64_by_64,row);
			write(row, checker, right, 0);
			writeline(output_smoothed_image_64_by_64_binary,row);
		end if;

	end process;
end;
