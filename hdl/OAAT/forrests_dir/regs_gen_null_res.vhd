library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity regs_gen_null_res is
	generic(width: integer := 16);
    port(d: in dual_rail_logic_vector(width-1 downto 0);
		q: out dual_rail_logic_vector(width-1 downto 0);
		reset: in std_logic;
		sleep: in std_logic);
end regs_gen_null_res;

architecture behavioral of regs_gen_null_res is
	component reg_null_res is
	   port(d: in dual_rail_logic;
			reset: in std_logic;
			sleep: in std_logic;
			q: out dual_rail_logic);
	end component;

begin
	gen_reg:
	for i in 0 to width-1 generate
		regx: reg_null_res port map(
			d(i),
			reset,
			sleep,
			q(i));
	end generate gen_reg;
end behavioral;
