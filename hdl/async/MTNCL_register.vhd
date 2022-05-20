---------
--Contains 
--regm - No reset register
--regdm - Reset high register
--regnm - Reset low register
--genregm - Generic sized no-reset register
--genregrstm - Generic sized resettable register
--ringregm - Generic sized ring register


----------------------------------------------------------- 
-- regm
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
use work.ncl_signals.all;
use work.MTNCL_gates.all;

entity regm is 
	port(a: in dual_rail_logic; 
		 s: in std_logic; 
		 z: out dual_rail_logic); 
end regm; 

architecture arch of regm is

	signal t0, t1: std_logic;
	
begin

	Gr0: th12m_a
		port map(a.rail0, t0, s, t0);
	Gr1: th12m_a
		port map(a.rail1, t1, s, t1);
		
	z.rail0 <= t0;	
	z.rail1 <= t1;
	
end arch; 

----------------------------------------------------------- 
-- regdm
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
use work.ncl_signals.all;
use work.MTNCL_gates.all;
entity regdm is 
	port(a: in dual_rail_logic; 
		 rst: in std_logic; 
		 s: in std_logic;
		 z: out dual_rail_logic); 
end regdm; 

architecture arch of regdm is

	signal t0, t1: std_logic;

begin

	Gr0: th12nm_a
		port map(a.rail0, t0, rst, s, t0);
	Gr1: th12dm_a
		port map(a.rail1, t1, rst, s, t1);
		
		z.rail0 <= t0;
		z.rail1 <= t1;	
		
end arch; 

----------------------------------------------------------- 
-- regnm
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
use work.ncl_signals.all;
use work.MTNCL_gates.all;
entity regnm is 
	port(a: in dual_rail_logic; 
		 rst: in std_logic; 
		 s: in std_logic;
		 z: out dual_rail_logic); 
end regnm; 
 
architecture arch of regnm is
 
signal t0, t1: std_logic;

begin

	Gr0: th12dm_a
		port map(a.rail0, t0, rst, s, t0);
	Gr1: th12nm_a
		 port map(a.rail1, t1, rst,s, t1);
		 
	z.rail0 <= t0;
	z.rail1 <= t1;	
		 
end arch; 

----------------------------------------------------------- 
-- regnullm
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
use work.ncl_signals.all;
use work.MTNCL_gates.all;
entity regnullm is 
	port(a: in dual_rail_logic; 
		 rst: in std_logic; 
		 s: in std_logic;
		 z: out dual_rail_logic); 
end regnullm; 
 
architecture arch of regnullm is
 
	signal t0, t1: std_logic;

begin

	Gr0: th12nm_a
		port map(a.rail0, t0, rst, s, t0);
	Gr1: th12nm_a
		port map(a.rail1, t1, rst,s, t1);
		 
	z.rail0 <= t0;
	z.rail1 <= t1;	
		 
end arch; 

-- Generic Sleep Register
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity genregm is
generic(width: in integer := 4);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 s: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end genregm;

architecture arch of genregm is

	component regm is 
		port(a: in dual_rail_logic; 
			 s: in std_logic;
			 z: out dual_rail_logic ); 
	end component; 

begin

	Greg: for i in 0 to width-1 generate
	begin
		Gsr0: regm
			port map(a(i), s, z(i));
	end generate;

end arch;

----------------------------------------------------------- 
-- regnm
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use work.ncl_signals.all;
use work.MTNCL_gates.all;
	 
entity genregrstm is
	generic(width: in integer := 4;
			dn: in bit := '1';
			value: in bit_vector := "0110");
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 rst: in std_logic;
		 s: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end genregrstm;
	 
architecture arch of genregrstm is

	component regnm is 
		port(a: in dual_rail_logic; 
			 rst: in std_logic; 
			 s: in std_logic;
			 z: out dual_rail_logic); 
	end component; 
		
	component regdm is 
		port(a: in dual_rail_logic; 
			 rst: in std_logic; 
			 s: in std_logic;
			 z: out dual_rail_logic); 
	end component; 
				
	component regnullm is 
		port(a: in dual_rail_logic; 
			 rst: in std_logic; 
			 s: in std_logic;
			 z: out dual_rail_logic); 
	end component; 
								 
begin
	Gwithreset: for i in 0 to width-1 generate
		Gresetnull: if dn = '0' generate
			G1: regnullm
				port map(a(i), rst, s, z(i));
		end generate;
			
		Gresetlow:if(dn = '1' and value(i) = '0') generate
			G2: regnm
				port map(a(i), rst, s, z(i));
		end generate;
		
		Gresethigh: if (dn = '1' and value(i) = '1') generate
			 G3: regdm
				port map(a(i), rst, s, z(i));
		end generate;
	end generate;

end arch;
	 
----------------------------------------------------------- 
-- 3-ring register
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use work.ncl_signals.all;
use work.MTNCL_gates.all;
			
entity ringregm is
	generic(width: in integer := 4;
			 value: in bit_vector := "0110");
	port(wrapin: in dual_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic;
		 rst: in std_logic;
		 combslp: out std_logic;
		 wrapout: out dual_rail_logic_vector(width-1 downto 0));
end ringregm; 
			
architecture arch of ringregm is
			
	component genregrstm is
		generic(width: in integer := 4;
				dn: in bit := '1';
				value: in bit_vector := "0110");
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 rst: in std_logic;
			 s: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;
				
	component comp1dm is
		generic(width: in integer := 4);
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 ki: in std_logic;
			 kin: in std_logic;
			 rst: in std_logic;
			 s: in std_logic;
			 ko: out std_logic);
	end component;
				
	component compm is
		generic(width: in integer := 4);
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 ki: in std_logic;
			 rst: in std_logic;
			 s: in std_logic;
			 ko: out std_logic);
	end component;
				
	component compdm is
		generic(width: in integer := 4);
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 ki: in std_logic;
			 rst: in std_logic;
			 s: in std_logic;
			 ko: out std_logic);
	end component;
				
	component genregm is
		generic(width: in integer := 4);			
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 s: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	signal wrap, r12, r23: dual_rail_logic_vector(width-1 downto 0);
	signal s1, s2, s3: std_logic;

begin

	Greg1: genregrstm
		generic map(width, '1', value)
		port map(wrapin, rst, s1, r12);
	Gcomp1: compm
		generic map(width)
		port map(wrapin, s2, rst, s3, s1);
	Greg2: genregrstm
		generic map(width, '0', value)
		port map(r12, rst, s2, r23);
	Gcomp2: comp1dm
		generic map(width)
		port map(r12, s3, ki, rst, s1, s2);
	Greg3: genregrstm
		generic map(width, '0', value)
		port map(r23, rst, s3, wrap);
	Gcomp3: compdm
		generic map(width)
		port map(r23, s1, rst, s2, s3);
	
	wrapout <= wrap;
	combslp <= s3;

end;