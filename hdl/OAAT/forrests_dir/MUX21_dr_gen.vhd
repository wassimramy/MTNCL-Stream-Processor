library ieee; 
use ieee.std_logic_1164.all; 
use work.NCL_signals.all;

entity MUX21_dr_gen is 
	generic(bitwidth : integer := 16);
	port(A: in dual_rail_logic_vector(bitwidth-1 downto 0); 
		B: in dual_rail_logic_vector(bitwidth-1 downto 0);
		S: in std_logic;
		 Z: out dual_rail_logic_vector(bitwidth-1 downto 0)); 
end MUX21_dr_gen; 

architecture arch of MUX21_dr_gen is

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
		A => A(i).rail0,
		B => B(i).rail0,
		S => S,
		Z => Z(i).rail0);

	MUX_21_A_1_i : MUX21_A
	port map(
		A => A(i).rail1,
		B => B(i).rail1,
		S => S,
		Z => Z(i).rail1);


end generate;

end arch; 

