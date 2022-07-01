

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.ncl_signals.all;
use work.tree_funcs.all;

entity mux_nto1_gen is
	generic(bitwidth: integer := 16;
		numInputs : integer := 4);
    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end mux_nto1_gen;

architecture behavioral of mux_nto1_gen is


component mux_21_gen is
	generic(width: integer);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end component;


type mux_type is array(log_u(numInputs, 2) downto 0, numInputs-1 downto 0) of dual_rail_logic_vector(bitwidth-1 downto 0);
signal mux_array: mux_type;
begin
	RENAME: for i in 0 to numInputs-1 generate
		mux_array(0, i) <= a((i+1)*bitwidth-1 downto i*bitwidth);
	end generate;
		
	LEVELS: for i in 0 to log_u(numInputs, 2)-1 generate
	begin
		MAIN : for j in 0 to (level_number(numInputs, i, 2) / 2)-1 generate

			mux_ij : mux_21_gen
			generic map(width => bitwidth)
			    port map(a => mux_array(i,2*j),
				 	 b => mux_array(i,(2*j)+1),
					sel => sel(i),
					 sleep => sleep,
					 z => mux_array(i+1,j));

		end generate;
		
		LEFT_OVER_GATE: if log_u((level_number(numInputs, i, 2) / 2) + (level_number(numInputs, i, 2) rem 2), 2) + i + 1 
				/= log_u(numInputs, 2) generate

			mux_extra : mux_21_gen
			generic map(width => bitwidth)
			    port map(a => mux_array(i,2*(level_number(numInputs, i, 2) / 2)),
				 	 b => mux_array(i,2*(level_number(numInputs, i, 2) / 2)+1),
					sel => sel(i),
					 sleep => sleep,
					 z => mux_array(i+1,(level_number(numInputs, i, 2) / 2)));

		end generate;
		
		LEFT_OVER_SIGNAL: if (log_u((level_number(numInputs, i, 2) / 2) + (level_number(numInputs, i, 2) rem 2), 2) + i + 1
				= log_u(numInputs, 2)) and ((level_number(numInputs, i, 2) rem 2) /= 0) generate
			mux_array(i+1, (level_number(numInputs, i, 2) / 2)) <= mux_array(i,2*(level_number(numInputs, i, 2) / 2));
		end generate;

	end generate;

z <= mux_array(log_u(numInputs, 2),0);
end behavioral;
