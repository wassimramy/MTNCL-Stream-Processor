


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;


entity SDC_w_EN is
	generic(bitwidth : integer := 135);
	port(a : in std_logic_vector(bitwidth-1 downto 0);
		en : in std_logic;
		sleep : std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
end entity;

architecture arch_SDC_w_EN of SDC_w_EN is 

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

	component th22m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic;
			 z: out std_logic ); 
	end component; 

signal a_rail0 : std_logic_vector(bitwidth-1 downto 0);

begin 


generate_output : for i in 0 to bitwidth-1 generate
	inv_i : inv_a
		port map(a => a(i),
				z => a_rail0(i));

	th22m_i_rail1 : th22m_a
		port map(a => a(i),
			b => en,
			s => sleep,
			z => z(i).rail1);

	th22m_i_rail0 : th22m_a
		port map(a => a_rail0(i),
			b => en,
			s => sleep,
			z => z(i).rail0);

end generate;

end arch_SDC_w_EN; 
