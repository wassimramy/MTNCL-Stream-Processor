
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_Count_Equal is
generic(bitwidth: in integer := 4);
	port(
		a    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		b    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep 		: in  std_logic;
		z   	: out dual_rail_logic_vector(0 downto 0)
	);
end;

architecture arch of MTNCL_Count_Equal is

	component thxor0m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

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

	signal and_tree_in, or_tree_in: std_logic_vector (bitwidth-1 downto 0);
	signal count_equal: dual_rail_logic_vector(bitwidth-1 downto 0);
	
begin

generate_xor: for i in 0 to bitwidth-1 generate

	thxor_i	: thxor0m_a
		port map(
			a => a(i).rail1,
			b => b(i).rail1,
			c => a(i).rail0,
			d => b(i).rail0,
			s => sleep,
			z => count_equal(i).rail1);

	thxnor_i: thxor0m_a
		port map(
			a => a(i).rail0,
			b => b(i).rail1,
			c => a(i).rail1,
			d => b(i).rail0,
			s => sleep,
			z => count_equal(i).rail0);

end generate;

	generate_tree_sigs : for i in 0 to bitwidth-1 generate
		and_tree_in(i) <= count_equal(i).rail1;
		or_tree_in(i) <= count_equal(i).rail0;
	
	end generate;

	and_tree : andtreem
		generic map(width => bitwidth)
		port map(
			a => and_tree_in,
			sleep => sleep,
			ko => z(0).rail1);

	or_tree : ortreem
		generic map(width => bitwidth)
		port map(
			a => or_tree_in,
			sleep => sleep,
			ko => z(0).rail0);


end arch;
