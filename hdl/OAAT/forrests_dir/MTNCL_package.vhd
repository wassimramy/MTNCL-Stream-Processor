library ieee;
package MTNCL_gates is
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

component bufferm_a is
	port(a: in std_logic;
		 s: in std_logic;
		 z: out std_logic);
end component;

component th12m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 s: in std_logic;
		 z: out std_logic);
end component;

component th12dm_a is
	port(a: in std_logic;
		 b: in std_logic;
		 rst: in std_logic;
		 s: in std_logic;
		 z: out std_logic);
end component;

component th12nm_a is
	port(a: in std_logic;
		 b: in std_logic;
		 rst: in std_logic;
		 s: in std_logic;
		 z: out std_logic);
end component;

component th13m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic);
end component;

component th14m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic);
end component;

component th22m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th23m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th23w2m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th24m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th24w2m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th24w22m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th24compm_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th33m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th34m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th34w2m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th34w22m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th34w3m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th34w32m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th44m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th44w2m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th44w22m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th44w3m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th44w322m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th54w22m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component th54w32m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component th54w322m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
 		 s: in std_logic;
		 z: out std_logic );
end component;

component thand0m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;

component thxor0m_a is
	port(a: in std_logic;
		 b: in std_logic;
		 c: in std_logic;
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic );
end component;
end MTNCL_gates;



library ieee;
use IEEE.std_logic_1164.all;

package tree_funcs is

function pow_u(B: integer; E: integer) return integer; -- B to the E
function div_u(D: integer; B: integer) return integer; -- ceiling of d/b
function log_u(L: integer; R: integer) return integer; -- ceiling of Log base R of L
function level_number(width, level, base: integer) return integer; -- bits to be combined on level of tree of width using base input gates

end tree_funcs;

package body tree_funcs is

function pow_u(B: integer; E: integer) return integer is
variable temp: integer := 1;
variable level: integer := 1;
begin
	if E = 0 then
		return 1;
	end if;
	if E = 1 then
		return B;
	end if;
	temp := B;
	while level < E loop
		temp := temp * B;
		level := level + 1;
	end loop;
return temp;
end;


function div_u(D: integer; B: integer) return integer is
variable temp: integer := 1;
variable level: integer := 0;
begin
	if D = 0 then
		return 0;
	end if;
	temp := D rem B;
	level := D/B;
	if temp /= 0 then
		level := level + 1;
	end if;
return level;
end;

function log_u(L: integer; R: integer) return integer is
variable temp: integer := 1;
variable level: integer := 0;
begin
	if L = 1 then
		return 0;
	end if;
	while temp < L loop
		temp := temp * R;
		level := level + 1;
	end loop;
return level;
end;

function level_number(width, level, base: integer) return integer is
variable num: integer := width;
begin
	if level /= 0 then
		for i in 1 to level loop
			if (log_u((num / base) + (num rem base), base) + i) = log_u(width, base) then
				num := (num / base) + (num rem base);
			else
				num := (num / base) + 1;
			end if;
		end loop;
	end if;
return num;
end;

end tree_funcs;