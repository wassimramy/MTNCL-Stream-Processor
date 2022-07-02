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

entity OAAT_in_all_out_TB is
generic(
			bitwidth : integer := 8;
			addresswidth : integer := 4;
			numberOfPixels : integer := 9;
			size: in integer := 64;
			clock_delay : integer := 16;
			mem_delay : integer := 48);
end OAAT_in_all_out_TB;

architecture tb_arch of OAAT_in_all_out_TB is

  --COMPONENT UNDER TEST
	component OAAT_in_all_out_2047 is
	generic( bitwidth : integer := 8;
		 numInputs : integer := 8;
		 counterWidth : integer := 3; --Log2 of numInputs
		 delay_amount : integer := 6);
	port(	 
		a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0));
end component;

  --Updated the file names
	file image_64_by_64, smoothed_image_64_by_64, image_64_by_64_check : text;
	type memoryData is array(0 to (size)*(size)) of std_logic_vector(bitwidth-1 downto 0);
	signal memData : memoryData;
	type matlab_memoryData is array(0 to (size)*(size)) of std_logic_vector(bitwidth-1 downto 0);
	signal matlab_memData : matlab_memoryData;

	file output_smoothed_image_64_by_64_binary      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64_binary.txt";
	file output_smoothed_image_64_by_64      : text open write_mode is "../test/output_files/output_smoothed_image_64_by_64.txt";


  signal pixel: dual_rail_logic_vector(bitwidth-1 downto 0);
  signal reset: std_logic;
  signal ko_sig: std_logic;
  signal ki_sig: std_logic;
  signal sleep_in: std_logic;
  signal sleep_out: std_logic;
  signal z: dual_rail_logic_vector((numberOfPixels)*bitwidth-1 downto 0);
	signal reset_count : dual_rail_logic_vector(addresswidth-2 downto 0);
	signal data0, data1 : dual_rail_logic;

  signal  temp : std_logic_vector(bitwidth-1 downto 0);	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector((numberOfPixels)*bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck, slowIcheck : std_logic_vector((numberOfPixels)*bitwidth-1 downto 0);

  begin
    
  uut: OAAT_in_all_out_2047
 generic map(
 							bitwidth => bitwidth,
							numInputs => numberOfPixels,
							counterWidth => addresswidth, --Log2 of numInputs
							delay_amount => 15)
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
    

	-- Get the image(s)
	file_open(image_64_by_64,		 "../test/input_files/image_test_64_by_64_clean_binary",				 read_mode); -- Input image

  	-- Store the input image in an array
	for i in 0 to size-1 loop
		for j in 0 to size-1 loop
			readline(image_64_by_64, v_ILINE);
			read(v_ILINE, v_inval);
			memData((i*(size))+j) <= v_inval;
		end loop;
	end loop;

	--Setting up the data0 & data1
	data1.rail0 <= '0';
	data1.rail1 <= '1';

	data0.rail0 <= '1';
	data0.rail1 <= '0';

	for i in 0 to addresswidth-2 loop
			reset_count(i).rail0 <= '0';
			reset_count(i).rail1 <= '1';
	end loop;

	-- Start testing
	wait for 10 ns;

				wait for 10 ns;
        reset <= '1';
				sleep_in <= '1';

	for i in 0 to (size-1) loop
		for j in 0 to (size-1) loop

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
							for i in 0 to (numberOfPixels)*bitwidth-1 loop			
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
	variable row_check_inval : std_logic_vector((numberOfPixels)*bitwidth-1 downto 0);

	begin

		if checker(0) <= 'U' then

		elsif (ki_sig = '0') then
			--write(row, conv_integer(checker), right, 0);
			--writeline(output_smoothed_image_64_by_64,row);
			--write(row, checker, right, 0);
			--writeline(output_smoothed_image_64_by_64_binary,row);
			--readline(image_64_by_64_check, row_check);
			--read(row_check, row_check_inval);
		end if;

	end process;

end;
