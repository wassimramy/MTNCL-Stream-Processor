library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity adder_gen is
	generic(width: integer);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		 sleep: in std_logic;
		 sum: out dual_rail_logic_vector(width-1 downto 0);
		 cout: out dual_rail_logic);
end adder_gen;

architecture behavioral of adder_gen is
	component half_adder is
		port(a: in dual_rail_logic;
			 b: in dual_rail_logic;
			 sleep: in std_logic;
			 sum: out dual_rail_logic;
			 cout: out dual_rail_logic);
	end component;
	component full_adder is
		port(a: in dual_rail_logic;
			 b: in dual_rail_logic;
			 cin: in dual_rail_logic;
			 sleep: in std_logic;
			 sum: out dual_rail_logic;
			 cout: out dual_rail_logic);
	end component;
	
signal c: dual_rail_logic_vector(width-1 downto 0);

begin
		
	adds: for i in 0 to width-1 generate
		add1: if i=0 generate
			add1: half_adder port map(
				a(i),
				b(i),
				sleep,
				sum(i),
				c(i));
		end generate;
		add_others: if i>0 generate
			add_others: full_adder port map(
				a(i),
				b(i),
				c(i-1),
				sleep,
				sum(i),
				c(i));
		end generate;
	end generate;
	
cout <= c(width-1);

end behavioral;