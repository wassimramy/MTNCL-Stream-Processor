library ieee; 
use ieee.std_logic_1164.all; 
use work.NCL_signals.all;

entity MUX21_gen is 
	generic(bitwidth : integer);
	port(A: in std_logic_vector(bitwidth-1 downto 0); 
		B: in std_logic_vector(bitwidth-1 downto 0);
		S: in std_logic;
		 Z: out std_logic_vector(bitwidth-1 downto 0)); 
end MUX21_gen; 

architecture arch of MUX21_gen is

component MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end component; 



begin

gen_muxes : for i in 0 to bitwidth-1 generate

	MUX_21_A_0_i : MUX21_A
	port map(
		A => A(i),
		B => B(i),
		S => S,
		Z => Z(i));


end generate;

end arch; 

