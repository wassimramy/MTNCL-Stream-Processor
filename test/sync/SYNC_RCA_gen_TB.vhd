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

entity SYNC_RCA_GEN_TB is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096; size: in integer := 64);
end SYNC_RCA_GEN_TB;

architecture tb_arch of SYNC_RCA_GEN_TB is

  component SYNC_RCA_GEN is
    generic(bitwidth: in integer := 8);
    port(
    				clk : in std_logic;
						input    	: in  std_logic_vector(2*bitwidth-1 downto 0);
						reset  		: in std_logic;
						S   			: out std_logic_vector((bitwidth) downto 0)
      );
  end component;

  signal input_signal: std_logic_vector(2*bitwidth-1 downto 0);
  signal reset_signal: std_logic;
  signal S_signal: std_logic_vector(bitwidth downto 0);
	signal clk : std_logic := '0';

  signal  temp_4, temp_5 : std_logic_vector(bitwidth-1 downto 0):= (others => '0');	
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck : std_logic_vector(bitwidth-1 downto 0);

  begin
    
  uut: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth)
  port map(
  					clk => clk,
				    input => input_signal,
				    reset => reset_signal,
				    S => S_signal
    );
    
 
    signal_tb: process


    begin
    

	-- Start testing
	wait for 10 ns;
  reset_signal <= '1';
  wait for 10 ns;
  reset_signal <= '0';
	wait for 10 ns;

	temp_5 <= "00000000";
	temp_4 <= "00000000";
	
	for i in 0 to size-1 loop
		for j in 0 to size-1 loop

			temp_5 <=  temp_5 + 1;
			wait on clk until clk = '0';
			for k in 0 to bitwidth-1 loop
				input_signal(k) <= temp_5(k);
				input_signal(k+bitwidth) <= temp_4(k);
			end loop;

		end loop;
	temp_4 <= temp_4 + 1;	
	end loop;

	wait;
      end process;

        
clk_process :process
   begin
        clk <= not clk;
        wait for 50ns;
   end process;

end;
