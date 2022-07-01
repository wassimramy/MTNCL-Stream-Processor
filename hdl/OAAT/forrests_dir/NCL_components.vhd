-- Package used for Completion Component

Library IEEE;
use IEEE.std_logic_1164.all;

--package tree_funcs is
--
--function log_u(L: integer; R: integer) return integer; -- ceiling of Log base R of L
--function level_number(width, level, base: integer) return integer; -- bits to be combined on level of tree of width using base input gates
--
--end tree_funcs;
--
--package body tree_funcs is
--
--function log_u(L: integer; R: integer) return integer is
--variable temp: integer := 1;
--variable level: integer := 0;
--begin
--	if L = 1 then
--		return 0;
--	end if;
--	while temp < L loop
--		temp := temp * R;
--		level := level + 1;
--	end loop;
--return level;
--end;
--
--function level_number(width, level, base: integer) return integer is
--variable num: integer := width;
--begin
--	if level /= 0 then
--		for i in 1 to level loop
--			if (log_u((num / base) + (num rem base), base) + i) = log_u(width, base) then
--				num := (num / base) + (num rem base);
--			else
--				num := (num / base) + 1;
--			end if;
--		end loop;
--	end if;
--return num;
--end;
--
--end tree_funcs;


-- Generic Completion Component

library ieee;
use ieee.std_logic_1164.all;
use work.tree_funcs.all;

entity comp is
	generic(width: in integer := 4);
	port(a: in std_logic_vector(width-1 downto 0);
		 ko: out std_logic);
end comp;

architecture arch of comp is

	type completion is array(log_u(width, 4) downto 0, width-1 downto 0) of std_logic;
	signal comp_array: completion;

		component th22_a
			port(a: in std_logic;
				 b: in std_logic;
				 z: out std_logic);
		end component;

		component th33_a
			port(a: in std_logic;
				 b: in std_logic;
				 c: in std_logic;
				 z: out std_logic);
		end component;

		component th44_a
			port(a: in std_logic;
				 b: in std_logic;
				 c: in std_logic;
				 d: in std_logic;
				 z: out std_logic);
		end component;

begin
	RENAME: for i in 0 to width-1 generate
		comp_array(0, i) <= a(i);
	end generate;

	STRUCTURE: for k in 0 to log_u(width, 4)-1 generate
	begin
		NOT_LAST: if level_number(width, k, 4) > 4 generate
		begin
			PRinCIPLE: for j in 0 to (level_number(width, k, 4) / 4)-1 generate
				G4: th44_a
					port map(comp_array(k, j*4), comp_array(k, j*4+1), comp_array(k, j*4+2), comp_array(k, j*4+3),
						comp_array(k+1, j));
			end generate;

			LEFT_OVER_GATE: if log_u((level_number(width, k, 4) / 4) + (level_number(width, k, 4) rem 4), 4) + k + 1 
				/= log_u(width, 4) generate
			begin
				NEED22: if (level_number(width, k, 4) rem 4) = 2 generate
					G2: th22_a
						port map(comp_array(k, level_number(width, k, 4)-2), comp_array(k, level_number(width, k, 4)-1), 
							comp_array(k+1, (level_number(width, k, 4) / 4)));
				end generate;

				NEED33: if (level_number(width, k, 4) rem 4) = 3 generate
					G3: th33_a
						port map(comp_array(k, level_number(width, k, 4)-3), comp_array(k, level_number(width, k, 4)-2), 
							comp_array(k, level_number(width, k, 4)-1), comp_array(k+1, (level_number(width, k, 4) / 4)));
				end generate;
			end generate;

			LEFT_OVER_SIGNALS: if (log_u((level_number(width, k, 4) / 4) + (level_number(width, k, 4) rem 4), 4) + k + 1
				= log_u(width, 4)) and ((level_number(width, k, 4) rem 4) /= 0) generate
			begin
				RENAME_SIGNALS: for h in 0 to (level_number(width, k, 4) rem 4)-1 generate
					comp_array(k+1, (level_number(width, k, 4) / 4)+h) <= comp_array(k, level_number(width, k, 4)-1-h);
				end generate;
			end generate;
		end generate;

		LAST22: if level_number(width, k, 4) = 2 generate
			G2F: th22_a
				port map(comp_array(k, 0), comp_array(k, 1), ko);
		end generate;

		LAST33: if level_number(width, k, 4) = 3 generate
			G3F: th33_a
				port map(comp_array(k, 0), comp_array(k, 1), comp_array(k, 2), ko);
		end generate;

		LAST44: if level_number(width, k, 4) = 4 generate
			G4F: th44_a
				port map(comp_array(k, 0), comp_array(k, 1), comp_array(k, 2), comp_array(k, 3), ko);
		end generate;
	end generate;
end arch;


-- 1-bit Dual-Rail Register

use work.ncl_signals.all;
library ieee;
use ieee.std_logic_1164.all;

entity ncl_register_D1 is
	generic(initial_value: integer := -4); -- 1=DATA1, 0=DATA0, -4=NULL
	port(d: in dual_rail_logic;
		 ki: in std_logic;
		 rst: in std_logic;
		 q: out dual_rail_logic;
		 ko: out std_logic);
end ncl_register_D1;

architecture arch of ncl_register_d1 is
signal qbuf: dual_rail_logic;

component th22n_a 
	port(a: in std_logic;
		 b: in std_logic;
		 rst: in std_logic;
		 z: out std_logic);
end component;

component th22d_a 
	port(a: in std_logic;
		 b: in std_logic;
		 rst: in std_logic;
		 Z: out std_logic);
end component;

component th12b_a 
	port(a: in std_logic;
		 b: in std_logic;
		 z: out std_logic);
end component;

begin
	RstN: if initial_value = -4 generate
		R0: th22n_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22n_a
			port map(d.rail1, ki, rst, qbuf.rail1);
	end generate;
	
	Rst1: if initial_value = 1 generate
		R0: th22n_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22d_a
			port map(d.rail1, ki, rst, qbuf.rail1);
	end generate;
	
	Rst0: if initial_value = 0 generate
		R0: th22d_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22n_a
			port map(d.rail1, ki, rst, qbuf.rail1);
	end generate;
	
	q <= qbuf;

	COMP: th12b_a
		port map(qbuf.rail0, qbuf.rail1, ko);
end;


-- Generic Length Dual-Rail Register

use work.ncl_signals.all;
library ieee;
use ieee.std_logic_1164.all;

entity ncl_register_D is
	generic(width: positive := 2 ;
			initial_value: integer := -4); -- 1=DATA1, 0=DATA0, -4=NULL
	port(d: in dual_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic_vector(width-1 downto 0);
		 rst: in std_logic;
		 q: out dual_rail_logic_vector(width-1 downto 0);
		 ko: out std_logic_vector(width-1 downto 0));
end ncl_register_D;

architecture gen of ncl_register_D is
component ncl_register_D1 
	generic(initial_value: integer := -4); -- 1=DATA1, 0=DATA0, -4=NULL
	port(d: in dual_rail_logic;
		 ki: in std_logic;
		 rst: in std_logic;
		 q: out dual_rail_logic;
		 ko: out std_logic);
end component;

begin
	gen_reg: for i in 0 to D'length-1 generate
		REGi: ncl_register_D1
			generic map(initial_value)
			port map(d(i), ki(i), rst, q(i), ko(i));
		end generate;
end;


-- 1-bit Quad-Rail Register

use work.ncl_signals.all;
library ieee;
use ieee.std_logic_1164.all;

entity ncl_register_Q1 is
	generic(initial_value: integer := -4); -- 3=DATA3, 2=DATA2, 1=DATA1, 0=DATA0, -4=NULL
	port(d: in quad_rail_logic;
		 ki: in std_logic;
		 rst: in std_logic;
		 q: out quad_rail_logic;
		 ko: out std_logic);
end ncl_register_Q1;

architecture arch of ncl_register_Q1 is
signal qbuf: quad_rail_logic;

component th22n_a 
	port(a: in std_logic;
		 b: in std_logic;
		 rst: in std_logic;
		 z: out std_logic);
end component;

component th22d_a 
	port(a: in std_logic;
		 b: in std_logic;
		 rst: in std_logic;
		 z: out std_logic);
end component;

component th14b_a 
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 z: out std_logic);
end component;

begin
	RstN: if initial_value = -4 generate
		R0: th22n_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22n_a
			port map(d.rail1, ki, rst, qbuf.rail1);
			
		R2: th22n_a
			port map(d.rail2, ki, rst, qbuf.rail2);
			
		R3: th22n_a
			port map(d.rail3, ki, rst, qbuf.rail3);
	end generate;
	
	Rst3: if initial_value = 3 generate
		R0: th22n_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22n_a
			port map(d.rail1, ki, rst, qbuf.rail1);
			
		R2: th22n_a
			port map(d.rail2, ki, rst, qbuf.rail2);
			
		R3: th22d_a
			port map(d.rail3, ki, rst, qbuf.rail3);
	end generate;
	
	Rst2: if initial_value = 2 generate
		R0: th22n_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22n_a
			port map(d.rail1, ki, rst, qbuf.rail1);
			
		R2: th22d_a
			port map(d.rail2, ki, rst, qbuf.rail2);
			
		R3: th22n_a
			port map(d.rail3, ki, rst, qbuf.rail3);
	end generate;
	
	Rst1: if initial_value = 1 generate
		R0: th22n_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22d_a
			port map(d.rail1, ki, rst, qbuf.rail1);
			
		R2: th22n_a
			port map(d.rail2, ki, rst, qbuf.rail2);
			
		R3: th22n_a
			port map(d.rail3, ki, rst, qbuf.rail3);
	end generate;
	
	Rst0: if initial_value = 0 generate
		R0: th22d_a
			port map(d.rail0, ki, rst, qbuf.rail0);
			
		R1: th22n_a
			port map(d.rail1, ki, rst, qbuf.rail1);
			
		R2: th22n_a
			port map(d.rail2, ki, rst, qbuf.rail2);
			
		R3: th22n_a
			port map(d.rail3, ki, rst, qbuf.rail3);
	end generate;
	
	q <= qbuf;

	COMP: th14b_a
		port map(qbuf.rail0, qbuf.rail1, qbuf.rail2, qbuf.rail3, ko);
end;


-- Generic Length Quad-Rail Register

use work.ncl_signals.all;
library ieee;
use ieee.std_logic_1164.all;

entity ncl_register_Q is
	generic(width: positive := 2 ;
			initial_value: integer := -4); -- 3=DATA3, 2=DATA2, 1=DATA1, 0=DATA0, -4=NULL
	port(d: in quad_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic_vector(width-1 downto 0);
		 rst: in std_logic;
		 q: out quad_rail_logic_vector(width-1 downto 0);
		 ko: out std_logic_vector(width-1 downto 0));
end ncl_register_Q;

architecture gen of ncl_register_Q is
component ncl_register_Q1 
	generic(initial_value: integer := -4); -- 3=DATA3, 2=DATA2, 1=DATA1, 0=DATA0, -4=NULL
	port(d: in quad_rail_logic;
		 ki: in std_logic;
		 rst: in std_logic;
		 q: out quad_rail_logic;
		 ko: out std_logic);
end component;

begin
	gen_reg: for i in 0 to D'length-1 generate
		REGi: ncl_register_Q1
			generic map(initial_value)
			port map(d(i), ki(i), rst, q(i), ko(i));
		end generate;
end;
