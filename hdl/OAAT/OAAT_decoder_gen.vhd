
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity decoder_gen is
	generic(bitwidth: integer);
	port(a: in dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep : in std_logic;
		z : out dual_rail_logic_vector(2**bitwidth-1 downto 0));
end decoder_gen;


architecture behavioral of decoder_gen is


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

type treesigs is array(2**bitwidth-1 downto 0) of std_logic_vector(bitwidth-1 downto 0);
signal tree_signals_and, tree_signals_or: treesigs;

signal dual_rail_as_single : std_logic_vector(2*bitwidth-1 downto 0);
begin
gen_signal : for i in 0 to bitwidth-1 generate
	dual_rail_as_single(2*i) <= a(i).rail0;
	dual_rail_as_single((2*i)+1) <= a(i).rail1;
end generate;

gen_treesignal : for i in 0 to 2**bitwidth-1 generate
	gen_treesignal_2 : for j in 0 to bitwidth-1 generate
tree_signals_and(i)(j) <= dual_rail_as_single(2*j + ((i/(2**j) rem 2)));
tree_signals_or(i)(j) <= dual_rail_as_single(2*j + (((i/(2**j)+1) rem 2)));
end generate;
end generate;

gen_trees : for i in 0 to 2**bitwidth-1 generate

andTree_i : andtreem
	generic map(width => bitwidth)
	port map(a => tree_signals_and(i),
		sleep => sleep,
		ko => z(i).rail1);

orTree_i : ortreem
	generic map(width => bitwidth)
	port map(a => tree_signals_or(i),
		sleep => sleep,
		ko => z(i).rail0);


end generate;

end behavioral;
