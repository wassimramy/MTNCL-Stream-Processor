
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

component or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component or3_a is 
	port(a,b,c: in std_logic; 
		 z: out std_logic); 
end component; 

component inv_a is
	port(a : in  std_logic;
		 z : out std_logic);
end component;

	signal and_XnY_buffer, and_CINnX_buffer, and_CINnY_buffer, not_Y, xor_XxorY_buffer, xor_YxorCIN_buffer, not_xor_XxorY_buffer : std_logic;



begin

and_XnY : and2_a
		port map(A => X,
					B => Y,
					Z => and_XnY_buffer);

and_CINnX : and2_a
		port map(A => CIN,
					B => X,
					Z => and_CINnX_buffer );

and_CINnY : and2_a
		port map(A => CIN,
					B => Y,
					Z => and_CINnY_buffer);

or_COUT : or3_a
		port map(A => and_XnY_buffer,
					B => and_CINnX_buffer,
					C => and_CINnY_buffer,
					Z => COUT);

inv_Y : inv_a
		port map(A => Y,
					Z => not_Y);

xor_XxorY : MUX21_A 
		port map(
			A => Y, 
			B => not_Y,
			S => X,
			Z => xor_XxorY_buffer);					

xor_YxorCIN : MUX21_A 
		port map(
			A => Y, 
			B => not_Y,
			S => CIN,
			Z => xor_YxorCIN_buffer);	

inv_xor_XxorY_buffer : inv_a
		port map(A => xor_XxorY_buffer,
					Z => not_xor_XxorY_buffer);

xor_SUM : MUX21_A 
		port map(
			A => xor_XxorY_buffer, 
			B => not_xor_XxorY_buffer,
			S => xor_YxorCIN_buffer,
			Z => S);	

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
