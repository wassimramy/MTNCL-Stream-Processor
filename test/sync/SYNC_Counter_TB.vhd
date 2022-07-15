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

entity SYNC_Counter_TB is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12; numberOfPixels: in integer := 4096; size: in integer := 64);
end SYNC_Counter_TB;

architecture tb_arch of SYNC_Counter_TB is

  component  SYNC_Counter is
    generic(bitwidth: in integer := 8);
    port(
    	clk : in std_logic;
    	hold : in std_logic;
			input    	: in  std_logic_vector(bitwidth-1 downto 0);
			reset  		: in std_logic;
			clk_0  		: out std_logic;
			clk_1  		: out std_logic;
			output   	: out std_logic_vector((bitwidth-1) downto 0)
      );
  end component;

  signal input_signal: std_logic_vector(bitwidth-1 downto 0);
  signal reset_signal: std_logic;
  signal S_signal: std_logic_vector(bitwidth-1 downto 0);
	signal clk : std_logic := '0';
	signal hold, clk_0, clk_1 : std_logic ;
signal temp: std_logic_vector(9*bitwidth-1 downto 0);
  signal CORRECT: std_logic;

  signal checker : std_logic_vector(bitwidth-1 downto 0):= (others => 'U');		
  signal Icheck : std_logic_vector(bitwidth-1 downto 0);

  begin
    
  uut: SYNC_Counter
 generic map(bitwidth => bitwidth)
  port map(
  					clk => clk,
				    hold => hold,
				    input => input_signal,
				    reset => reset_signal,
				    clk_0 => clk_0,
				    clk_1 => clk_1,
				    output => S_signal
    );
    
 
    signal_tb: process

    begin
    
	-- Start testing
	wait for 10 ns;
  reset_signal <= '1';
  wait for 10 ns;
  reset_signal <= '0';
	wait for 10 ns;

	hold <= '0';
	input_signal <= "00001001";
	--input_signal <= "1000000000000";
	wait;
      end process;

        
clk_process :process
   begin
        clk <= not clk;
        wait for 50ns;
   end process;

end;
