
-----------------------------------------
-- Definition of  full_add
-----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.MTNCL_gates.all;

-- MTNCL Full Adder
entity FAm is
	port(
		CIN   : IN  dual_rail_logic;
		X     : IN  dual_rail_logic;
		Y     : IN  dual_rail_logic;
		sleep : in  std_logic;
		COUT  : OUT dual_rail_logic;
		S     : OUT dual_rail_logic);
end FAm;

architecture archthfax0 of FAm is

   component th23m_a is 
      port(a: in std_logic; 
           b: in std_logic; 
           c: in std_logic;
      	   s:in std_logic;
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

	signal s0_buffer : std_logic;
	signal s1_buffer : std_logic;
	signal y0_buffer : std_logic;
	signal y1_buffer : std_logic;

begin
	S.rail0    <= s0_buffer;
	S.rail1    <= s1_buffer;
	COUT.rail0 <= y0_buffer;
	COUT.rail1 <= y1_buffer;
	th0 : th23m_a
		port map(X.rail0,
			     Y.rail0,
			     CIN.rail0,
			     sleep,
			     y0_buffer);
	th1 : th23m_a
		port map(X.rail1,
			     Y.rail1,
			     CIN.rail1,
			     sleep,
			     y1_buffer);
	th2 : th34w2m_a
		port map(y0_buffer,
			     X.rail1,
			     Y.rail1,
			     CIN.rail1,
			     sleep,
			     s1_buffer);

	th3 : th34w2m_a
		port map(y1_buffer,
			     X.rail0,
			     Y.rail0,
			     CIN.rail0,
			     sleep,
			     s0_buffer);

end archthfax0;



-----------------------------------------
-- Definition of  half_add
-----------------------------------------
use work.ncl_signals.all;
use work.MTNCL_gates.all;
library ieee;
use ieee.std_logic_1164.all;

-- MTNCL Half Adder
entity HAm is
	port(
		X     : IN  dual_rail_logic;
		Y     : IN  dual_rail_logic;
		sleep : in  std_logic;
		COUT  : OUT dual_rail_logic;
		S     : OUT dual_rail_logic);
end HAm;
architecture arch of HAm is

   component th12m_a is 
      port(a: in std_logic; 
           b: in std_logic;
           s:in std_logic; 
           z: out std_logic); 
  end component; 

   component th22m_a is 
      port(a: in std_logic; 
           b: in std_logic;
      s:in std_logic;
           z: out std_logic ); 
  end component;

   component th24compm_a is 
      port(a: in std_logic; 
           b: in std_logic; 
           c: in std_logic; 
           d: in std_logic; 
           s:in std_logic;
	   z: out std_logic ); 
  end component; 

begin
	g0 : th12m_a port map(
			X.rail0,
			Y.rail0,
			sleep,
			COUT.rail0);

	g1 : th22m_a port map(
			X.rail1,
			Y.rail1,
			sleep,
			COUT.rail1);

	g2 : th24compm_a port map(
			X.rail0,
			Y.rail1,
			Y.rail0,
			X.rail1,
			sleep,
			S.rail0);

	g3 : th24compm_a port map(
			X.rail0,
			Y.rail0,
			Y.rail1,
			X.rail1,
			sleep,
			S.rail1);
end arch;

-----------------------------------------
-- Definition of  half_add with one input '1' (No gates needed)
-----------------------------------------
use work.ncl_signals.all;
use work.MTNCL_gates.all;
library ieee;
use ieee.std_logic_1164.all;

-- MTNCL Half Adder with  Y='1'
entity HAm1 is
    port(
        X     : IN  dual_rail_logic;
        COUT  : OUT dual_rail_logic;
        S     : OUT dual_rail_logic);
end HAm1;
architecture arch of HAm1 is

begin
    COUT <= X;
    S.rail1 <= X.rail0;
    S.rail0 <= X.rail1;
end arch;

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.MTNCL_gates.all;

---------------------------------------------------
-- NCL Full adder with Cin = '1'
-- Similar to Half Adder, used by the substractor
---------------------------------------------------
entity FAm1 is
	port(X     : dual_rail_logic;
		 Y     : in  dual_rail_logic;
		 sleep : in  std_logic;
		 COUT  : out dual_rail_logic;
		 S     : out dual_rail_logic);
end FAm1;

-- Full Adder with Cin = '1'
architecture arch of FAm1 is

component th12m_a is 
      port(a: in std_logic; 
           b: in std_logic;
           s:in std_logic; 
           z: out std_logic); 
  end component; 

   component th22m_a is 
      port(a: in std_logic; 
           b: in std_logic;
      sleep:in std_logic;
           z: out std_logic ); 
  end component;

   component th24compm_a is 
      port(a: in std_logic; 
           b: in std_logic; 
           c: in std_logic; 
           d: in std_logic; 
           sleep:in std_logic;
	   z: out std_logic ); 
  end component; 

begin
	cout0 : th12m_a
		port map(X.rail1, Y.rail1, sleep, COUT.rail1);
	cout1 : th22m_a
		port map(X.rail0, Y.rail0, sleep, COUT.rail0);

	sum0 : th24compm_a
		port map(X.rail0, Y.rail0, Y.rail1, X.rail1, sleep, S.rail0);

	sum1 : th24compm_a
		port map(X.rail0, Y.rail1, Y.rail0, X.rail1, sleep, S.rail1);

end arch;

-- MTNCL Carry Save Adder
use work.ncl_signals.all;
library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------
-- MTNCL Carry Save Adder
-----------------------------------------
entity CSAm is
	port(
		AI    : IN  dual_rail_logic;
		BI    : IN  dual_rail_logic;
		CIN   : IN  dual_rail_logic;
		SIN   : IN  dual_rail_logic;
		sleep : in  std_logic;
		COUT  : OUT dual_rail_logic;
		SOUT  : OUT dual_rail_logic);  
end CSAm;

architecture archcsax0 of CSAm is
	component FAm is
		port(
			CIN   : IN  dual_rail_logic;
			X     : IN  dual_rail_logic;
			Y     : IN  dual_rail_logic;
			sleep : in  std_logic;
			COUT  : OUT dual_rail_logic;
			S     : OUT dual_rail_logic);
	end component;

	component and2im is
		port(a     : IN  dual_rail_logic;
			 b     : IN  dual_rail_logic;
			 sleep : in  std_logic;
			 z     : OUT dual_rail_logic);
	end component;

	signal Casin : dual_rail_logic;

begin
	th0 : and2im
		port map(AI, BI, sleep, Casin);
	th1 : FAm
		port map(CIN, Casin, SIN, sleep, COUT, SOUT);

end archcsax0;

-----------------------------------------
-- Definition of  Carry Save Adder for signed multipler
-----------------------------------------
use work.ncl_signals.all;
library ieee;
use ieee.std_logic_1164.all;
entity CSAm_inv is
	port(
		AI    : IN  dual_rail_logic;
		BI    : IN  dual_rail_logic;
		CIN   : IN  dual_rail_logic;
		SIN   : IN  dual_rail_logic;
		sleep : in  std_logic;
		COUT  : OUT dual_rail_logic;
		SOUT  : OUT dual_rail_logic);  
end CSAm_inv;

architecture archcsax0 of CSAm_inv is
	component FAm is
		port(
			CIN   : IN  dual_rail_logic;
			X     : IN  dual_rail_logic;
			Y     : IN  dual_rail_logic;
			sleep : in  std_logic;
			COUT  : OUT dual_rail_logic;
			S     : OUT dual_rail_logic);
	end component;

	component and2im is
		port(a     : IN  dual_rail_logic;
			 b     : IN  dual_rail_logic;
			 sleep : in  std_logic;
			 z     : OUT dual_rail_logic);
	end component;

	component NCL_inv is
		port(x : IN  dual_rail_logic;
			 y : OUT dual_rail_logic);
	end component;

	signal Casin, Casin_inv : dual_rail_logic;

begin
	th0 : and2im
		port map(AI,
			     BI,
			     sleep,
			     Casin);
	th1 : FAm
		port map(CIN,
			     Casin_inv,
			     SIN,
			     sleep,
			     COUT,
			     SOUT); 
	th2 : NCL_inv
		port map(Casin, Casin_inv);

end archcsax0;



