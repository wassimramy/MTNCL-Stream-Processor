
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity TimesZeroCheck is
	generic(bitwidth : integer);
	port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		b: in dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep : in std_logic;
		sign_bits : out dual_rail_logic_vector(1 downto 0)
	);
end TimesZeroCheck;



architecture arch_TimesZeroCheck of TimesZeroCheck is 


	component andtreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

	component ortreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

	component th33m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

	component th13m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

signal and_tree_in0, and_tree_in1, or_tree_in0, or_tree_in1 : std_logic_vector(bitwidth-1 downto 0);
signal mult0_0, mult0_1 : dual_rail_logic;

begin 

generate_tree_sigs : for i in 0 to bitwidth-1 generate
	and_tree_in0(i) <= a(i).rail0;
	or_tree_in0(i) <= a(i).rail1;
	and_tree_in1(i) <= b(i).rail0;
	or_tree_in1(i) <= b(i).rail1;

end generate;


and_tree0 : andtreem
		generic map(width => bitwidth)
		port map(
			a => and_tree_in0,
			sleep => sleep,
			ko => mult0_0.rail1);

or_tree0 : ortreem
		generic map(width => bitwidth)
		port map(
			a => or_tree_in0,
			sleep => sleep,
			ko => mult0_0.rail0);

and_tree1 : andtreem
		generic map(width => bitwidth)
		port map(
			a => and_tree_in1,
			sleep => sleep,
			ko => mult0_1.rail1);

or_tree1 : ortreem
		generic map(width => bitwidth)
		port map(
			a => or_tree_in1,
			sleep => sleep,
			ko => mult0_1.rail0);

sign_bits_0_1 : th33m_a
		port map(
			a => a(bitwidth-1).rail1,
			b => mult0_0.rail0,
			c => mult0_1.rail0,
			s => sleep,
			z => sign_bits(0).rail1);

sign_bits_0_0 : th13m_a
		port map(
			a => a(bitwidth-1).rail0,
			b => mult0_0.rail1,
			c => mult0_1.rail1,
			s => sleep,
			z => sign_bits(0).rail0);

sign_bits_1_1 : th33m_a
		port map(
			a => b(bitwidth-1).rail1,
			b => mult0_0.rail0,
			c => mult0_1.rail0,
			s => sleep,
			z => sign_bits(1).rail1);

sign_bits_1_0 : th13m_a
		port map(
			a => b(bitwidth-1).rail0,
			b => mult0_0.rail1,
			c => mult0_1.rail1,
			s => sleep,
			z => sign_bits(1).rail0);



end arch_TimesZeroCheck; 