



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;


entity th22m_en_gen is
	generic(bitwidth : integer);
	port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		en : in std_logic;
		sleep : std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
end entity;

architecture arch_th22m_en_gen of th22m_en_gen is 

	component th22m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic;
			 z: out std_logic ); 
	end component; 


begin 


generate_output : for i in 0 to bitwidth-1 generate

	th22m_i_rail1 : th22m_a
		port map(a => a(i).rail1,
			b => en,
			s => sleep,
			z => z(i).rail1);

	th22m_i_rail0 : th22m_a
		port map(a => a(i).rail0,
			b => en,
			s => sleep,
			z => z(i).rail0);

end generate;

end arch_th22m_en_gen; 