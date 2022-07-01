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

entity OAAT_out_all_in_TB is
generic(
			bitwidth : integer := 12;
			addresswidth : integer := 12;
			numberOfPixels : integer := 256;
			size: in integer := 64;
			clock_delay : integer := 16;
			mem_delay : integer := 48);
end OAAT_out_all_in_TB;

architecture tb_arch of OAAT_out_all_in_TB is

  --COMPONENT UNDER TEST
	component OAAT_out_all_in_255 is
	generic( bitwidth : integer := 8;
		 numInputs : integer := 256);
	port(	 
		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

  --Updated the file names
	file image_64_by_64, smoothed_image_64_by_64, image_64_by_64_check : text;
	type memoryData is array(0 to (numberOfPixels)) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size)*(size)) of std_logic_vector(bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_smoothed_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64_binary.txt";
	file output_smoothed_image_64_by_64      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64.txt";


  signal pixel: dual_rail_logic_vector(numberOfPixels*bitwidth-1 downto 0);
  signal reset: std_logic;
  signal ko_sig: std_logic;
  signal ki_sig: std_logic;
  signal sleep_in: std_logic;
  signal sleep_out: std_logic;
  signal z: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal data0, data1 : dual_rail_logic;

  signal  temp : std_logic_vector(numberOfPixels*bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector(bitwidth-1 downto 0);

  begin
    
  uut: OAAT_out_all_in_255
 generic map(
 							bitwidth => bitwidth,
							numInputs => numberOfPixels)
  port map(
					    a => pixel,
					    reset => reset,
					    ki => ki_sig,
					    ko => ko_sig,
					    sleep_in => sleep_in,
					    sleep_out => sleep_out,
					    z => z
    );
    
 
    signal_tb: process

variable v_ILINE : line;
variable v_inval : std_logic_vector(bitwidth-1 downto 0);

    begin
    

  	temp <= "000000010010000000010001000000010111000000001110000000001010000000010000000000011100000000010010000000001101000000001110000000000111000000011011000000000111000000001110000000010011000000001100000000011001000000001010000000010001000000010110000000010000000000001011000000001111000000010010000000011011000000000000000000010010000000010000000000010110000000011000000000000000000000011000000000011001000000000000000000010011000000010100000000010101000000001110000000010001000000010100000000000000000000100010000000000000000000010110000000001101000000010011000000010101000000011001000000000000000000100100000000000000000000101011000000000000000000000000000000011110000000000000000000110000000000000000000000000000000000101011000000000000000000100111000000000000000000000000000000110001000000000000000000000000000000110101000000000000000000000000000000101000000000000000000000000000000000100000000000000000000000100100000000000000000000101010000000000000000000000000000000100110000000000000000000011010000000000000000000011011000000101001000000000000000000000000000000110100000000000000000000000000000000100001000000000000000000101100000000000000000000000000000000010111000000100011000000000000000000000000000000100001000000000000000000011100000000100000000000000000000000011010000000000000000000011110000000000000000000011100000000000000000000011101000000011110000000000000000000100000000000000000000000100001000000000000000000101111000000000000000000000000000000101101000000000000000000000000000000110110000000000000000000000000000000000000000000110100000000000000000000000000000000101000000000000000000000011011000000000000000000100100000000000000000000100101000000000000000000000000000000100101000000000000000000100000000000000000000000011100000000000000000000010001000000010101000000011010000000000000000000011001000000001110000000011010000000000000000000010111000000010000000000010111000000000000000000010100000000011000000000011010000000000000000000011010000000000000000000010100000000011001000000010110000000000000000000100011000000000000000000100001000000000000000000011110000000000000000000101011000000000000000000000000000000100011000000000000000000101100000000000000000000010010000000000000000000010110000000011000000000010101000000000000000000010011000000010011000000010111000000000000000000010101000000011010000000000000000000010101000000010011000000010001000000001110000000010110000000010100000000000000000000010110000000010111000000011111000000000000000000010011000000000000000000010101000000001011000000010110000000001101000000001111000000010111000000010011000000010000000000010001000000011010000000000000000000001111000000001111000000010101000000001101000000001110000000010110000000001101000000010111000000011101000000000000000000011000000000000000000000010100000000011001000000000000000000011111000000000000000000100101000000000000000000011011000000000000000000100100000000000000000000100011000000000000000000100101000000000000000000100110000000000000000000000000000000010010000000010111000000010010000000001101000000001100000000001011000000010000000000001110";

	-- Start testing
	wait for 10 ns;

				wait for 10 ns;
        reset <= '1';
				sleep_in <= '1';

	for i in 0 to 0 loop
			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
			for k in 0 to numberOfPixels*bitwidth-1 loop
				pixel(k).rail0 <= not temp(k);
				pixel(k).rail1 <= temp(k);
			end loop;
			wait on ko_sig until ko_sig = '0';
			sleep_in <= '1';
	end loop;

	for i in 0 to numberOfPixels-1 loop
			wait on ko_sig until ko_sig = '1';
			reset <= '0';
			sleep_in <= '0';
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
