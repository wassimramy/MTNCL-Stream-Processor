
-----------------------------------------
-- Definition of  full_add
-----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.MTNCL_gates.all;

-- MTNCL Full Adder
entity FA is
	port(
		CIN   : IN  std_logic;
		X     : IN  std_logic;
		Y     : IN  std_logic;
		COUT  : OUT std_logic;
		S     : OUT std_logic);
end FA;

architecture archthfax0 of FA is

component HA
		port(X, Y    : in  std_logic;
			 COUT, S : out std_logic);
	end component;

component or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 	

	signal ha0_sum_buffer, ha0_cout_buffer, ha1_cout_buffer : std_logic;



begin
HA_0 : HA port map(X => X, Y => Y, COUT => ha0_cout_buffer, S => ha0_sum_buffer);
HA_1 : HA port map(X => ha0_sum_buffer, Y => CIN, COUT => ha1_cout_buffer, S => S);
or_0 : or2_a port map(a => ha0_cout_buffer, b => ha1_cout_buffer, z => COUT);
end archthfax0;



-----------------------------------------
-- Definition of  half_add
-----------------------------------------
use work.ncl_signals.all;
use work.MTNCL_gates.all;
library ieee;
use ieee.std_logic_1164.all;

-- MTNCL Half Adder
entity HA is
	port(
		X     : IN  std_logic;
		Y     : IN  std_logic;
		COUT  : OUT std_logic;
		S     : OUT std_logic);
end HA;
architecture arch of HA is

component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
end component; 

component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component inv_a is
	port(a : in  std_logic;
		 z : out std_logic);
end component;

signal not_Y : std_logic;

begin

inv_Y : inv_a
		port map(A => Y,
					Z => not_Y);

xor_XxorY : MUX21_A 
		port map(
			A => Y, 
			B => not_Y,
			S => X,
			Z => S);	

and_XnY : and2_a
		port map(A => X,
					B => Y,
					Z => COUT);

end arch;
