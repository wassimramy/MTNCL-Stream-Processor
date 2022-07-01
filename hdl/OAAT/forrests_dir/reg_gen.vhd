library IEEE;
use IEEE.std_logic_1164.all;
-- Boolean Generic Register
entity reg_gen is
	generic(width : integer := 135);
	port(
		D   : in  std_logic_vector(width - 1 downto 0);
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic_vector(width - 1 downto 0));
end reg_gen;

architecture arch of reg_gen is
	component DFFRX1MTR_No_QN is
		port(
			D   : in  std_logic;
			clk : in  std_logic;
			rst : in  std_logic;
			Q   : out std_logic);
	end component;

begin
	Gen1 : for i in 0 to width - 1 generate
		RegA : DFFRX1MTR_No_QN
			port map(D(i), clk, rst, Q(i));
	end generate;
end arch;
