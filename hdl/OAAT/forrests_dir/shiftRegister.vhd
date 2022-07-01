library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;


entity shiftRegister is
	generic(bitwidth : integer);
	port(D : in std_logic;
		reset : in std_logic;
		clk : in std_logic;
		Q : out std_logic_vector(bitwidth-1 downto 0));
end shiftRegister;

architecture arch_shiftRegister of shiftRegister is 

component DFFRX1MTR_No_QN is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic);
end component;

signal Q_i : std_logic_vector(bitwidth-1 downto 0);

begin 

input_reg : DFFRX1MTR_No_QN 
	port map(
		D => D,
		clk => clk,
		rst => reset,
		Q => Q_i(0));


generate_output : for i in 0 to bitwidth-2 generate

	reg_i : DFFRX1MTR_No_QN
		port map(
			D => Q_i(i),
			clk => clk,
			rst => reset,
			Q => Q_i(i+1));
			 
end generate;

Q <= Q_i(15 downto 0);
end arch_shiftRegister; 
