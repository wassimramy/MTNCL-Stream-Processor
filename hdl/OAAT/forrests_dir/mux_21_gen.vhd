
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity mux_21_gen is
	generic(width: integer := 16);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end mux_21_gen;

architecture behavioral of mux_21_gen is
	component thxor0m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

begin
		
	thxorm_gen: for i in 0 to width-1 generate
		thxor0m_1_i : thxor0m_a
			port map(
				a => a(i).rail1,
				b => sel.rail0,
				c => b(i).rail1,
				d => sel.rail1,
				s => sleep,
				z => z(i).rail1);

		thxor0m_0_i : thxor0m_a
			port map(
				a => a(i).rail0,
				b => sel.rail0,
				c => b(i).rail0,
				d => sel.rail1,
				s => sleep,
				z => z(i).rail0);
	end generate;
	
end behavioral;
