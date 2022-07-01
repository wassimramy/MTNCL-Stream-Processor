
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity reg_zero_res is
   port(d: in dual_rail_logic;
		reset: in std_logic;
		sleep: in std_logic;
		q: out dual_rail_logic);
end reg_zero_res;

architecture arch1 of reg_zero_res is

	component th12nm_a is 
		port(a: in std_logic; 
			b: in std_logic;
			rst : in std_logic;
			s:in std_logic; 
			z: out std_logic); 
	end component;
	component th12dm_a is 
		port(a: in std_logic; 
			b: in std_logic;
			rst : in std_logic;
			s:in std_logic;
			z: out std_logic); 
	end component; 
	
	signal sig1, sig2: std_logic;
	
begin
	g1: th12dm_a port map(
		d.rail0,
		sig1,
		reset,
		sleep,
		sig1);
	g2: th12nm_a port map(
		d.rail1,
		sig2,
		reset,
		sleep,
		sig2);
	
	q.rail0 <= sig1;
	q.rail1 <= sig2;
	
end arch1;