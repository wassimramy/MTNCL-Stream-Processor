library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity subtractor_gen is
	generic(width: integer := 8);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 b: in dual_rail_logic_vector(width-1 downto 0);
		 sleep: in std_logic;
		 diff: out dual_rail_logic_vector(width-1 downto 0);
		 bout: out dual_rail_logic);
end subtractor_gen;

architecture arch1 of subtractor_gen is
	component full_adder is
		port(a: in dual_rail_logic;
			b: in dual_rail_logic;
			cin: in dual_rail_logic;
			sleep: in std_logic;
			sum: out dual_rail_logic;
			cout: out dual_rail_logic);
	end component;

signal borrows, b_inv: dual_rail_logic_vector(width downto 0);

begin
	subs: for i in 0 to width-1 generate
		sub1: if i = 0 generate
			sub1: full_adder
				port map(
					a => a(i),
					b => b_inv(i),
					cin => borrows(0),
					sleep => sleep,
					sum => diff(i),
					cout => borrows(i+1));
				b_inv(i).rail0 <= b(i).rail1;
				b_inv(i).rail1 <= b(i).rail0;
		end generate;
		subx: if i > 0 generate
			subx: full_adder
				port map(
					a => a(i),
					b => b_inv(i),
					cin => borrows(i),
					sleep => sleep,
					sum => diff(i),
					cout => borrows(i+1));
				b_inv(i).rail0 <= b(i).rail1;
				b_inv(i).rail1 <= b(i).rail0;
		end generate;
	end generate;
	
borrows(0).rail1 <= '1';   borrows(0).rail0 <= '0';
bout <= borrows(width);

end arch1;
