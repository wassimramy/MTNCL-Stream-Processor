---------
--Contains 
--compm - MTNCL completion block, resets high
--compdm - MTNCL completion block, resets low
--comp1m - MTNCL completion block, one additional Ki signal, resets high
--comp1dm - MTNCL completion block, one additional Ki signal, resets low



-- Generic Completion (sleep)
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity compm is
	generic(width: in integer := 4);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic;
		 rst: in std_logic;
		 sleep: in std_logic;
		 ko: out std_logic);
end compm;

architecture arch of compm is
	component th22n_a is 
		port(a: in std_logic; 
			 b: in std_logic;	
			 rst: in std_logic;
			 z: out std_logic ); 
	end component; 
	
	component inv_a is 
		port(a: in std_logic;
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
		
	component andtreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

component th12m_a is
port(a: in std_logic; 
		 b: in std_logic;
		 s: in std_logic; 
		 z: out std_logic); 
end component;

		
--signal t: std_logic_vector(width/2 downto 0);   --the orginal siganl declaration
signal t: std_logic_vector((width+1)/2 -1 downto 0); --my new signal declaration
signal tko, ttko: std_logic;

begin

	STAGE1: for i in 0 to width/2-1 generate
		Gs1: th24compm_a
			port map(a(i*2).rail0,a(i*2).rail1, a(i*2+1).rail0, a(i*2+1).rail1, sleep, t(i));
	end generate;

	ONEMORE: if width rem 2 = 1 generate
		Gsom: th12m_a
			port map(a(width-1).rail0, a(width-1).rail1, sleep, t(width/2));
	end generate;
	

	Gcompodd: if width rem 2 = 1 generate
	begin
		Gco: andtreem
			generic map(width/2+1)
			port map(t, sleep, tko);
	end generate;
	
	Gcompeven: if width rem 2 = 0 generate
	begin
		Gce: andtreem
			generic map(width/2)
			port map(t(width/2-1 downto 0), sleep, tko);
	end generate;
	
	Gfgate: th22n_a
		port map(tko, ki, rst, ttko);
	Gfinv: inv_a
		port map(ttko, ko);

end arch;


-- Generic Completion (sleep)
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity compdm is
	generic(width: in integer := 4);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic;
		 rst: in std_logic;
		 sleep: in std_logic;
		 ko: out std_logic);
end compdm;

architecture arch of compdm is

	component th22d_a is 
		port(a: in std_logic; 
			 b: in std_logic;	
			 rst: in std_logic;
			 z: out std_logic ); 
	end component; 
	
	component inv_a is 
		port(a: in std_logic;
			 z: out std_logic ); 
	end component;
		
	component andtreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

  component th24compm_a is
    port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic );
  end component;
		
component th12m_a is
port(a: in std_logic; 
		 b: in std_logic;
		 s: in std_logic; 
		 z: out std_logic); 
end component;

--signal t: std_logic_vector(width/2 downto 0); --original signal
signal t: std_logic_vector((width+1)/2 -1 downto 0); --my new signal declaration
signal tko, ttko: std_logic;

begin

	STAGE1: for i in 0 to width/2-1 generate
		Gs1: th24compm_a
			port map(a(i*2).rail0,a(i*2).rail1, a(i*2+1).rail0, a(i*2+1).rail1, sleep, t(i));
	end generate;

	ONEMORE: if width rem 2 = 1 generate
		Gsom: th12m_a
			port map(a(width-1).rail0, a(width-1).rail1, sleep, t(width/2));
	end generate;
	
	Gcompodd: if width rem 2 = 1 generate
	begin
		Gco: andtreem
			generic map(width/2+1)
			port map(t, sleep, tko);
	end generate;
	
	Gcompeven: if width rem 2 = 0 generate
	begin
		Gce: andtreem
			generic map(width/2)
			port map(t(width/2-1 downto 0), sleep, tko);
	end generate;
	
	Gfgate: th22d_a
		port map(tko, ki, rst, ttko);
	Gfinv: inv_a
		port map(ttko, ko);

end arch;


-- Generic Completion (sleep)
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity comp1m is
	generic(width: in integer := 4);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic;
		 kin: in std_logic;
		 rst: in std_logic;
		 sleep: in std_logic;
		 ko: out std_logic);
end comp1m;

architecture arch of comp1m is
	
	component th22n_a is 
		port(a: in std_logic; 
			 b: in std_logic;	
			 rst: in std_logic;
			 z: out std_logic ); 
	end component; 
	
	component th33n_a is 
		port(a: in std_logic; 
			 b: in std_logic;	
			 c: in std_logic;
			 rst: in std_logic;
			 z: out std_logic ); 
	end component; 
	
	component inv_a is 
		port(a: in std_logic;
			 z: out std_logic ); 
	end component;
		
	component andtreem is
		generic(width: in integer := 4);
			port(a: in std_logic_vector(width-1 downto 0);
				 sleep: in std_logic;
				 ko: out std_logic);
	end component;

  component th24compm_a is
    port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic );
  end component;
		
component th12m_a is
port(a: in std_logic; 
		 b: in std_logic;
		 s: in std_logic; 
		 z: out std_logic); 
end component;

		
signal t: std_logic_vector(width/2 downto 0);
signal tko, ttko: std_logic;

begin

	STAGE1: for i in 0 to width/2-1 generate
		Gs1: th24compm_a
			port map(a(i*2).rail0,a(i*2).rail1, a(i*2+1).rail0, a(i*2+1).rail1, sleep, t(i));
	end generate;
	
	ONEMORE: if width rem 2 = 1 generate
		Gsom: th12m_a
			port map(a(width-1).rail0, a(width-1).rail1, sleep, t(width/2));
	end generate;
	
	Gcompodd: if width rem 2 = 1 generate
	begin
		Gco: andtreem
			generic map(width/2+1)
			port map(t, sleep, tko);
	end generate;
	
	Gcompeven: if width rem 2 = 0 generate
	begin
		Gce: andtreem
			generic map(width/2)
			port map(t(width/2-1 downto 0), sleep, tko);
	end generate;
	
	Gfgate: th33n_a
		port map(tko, ki, kin, rst, ttko);
	Gfinv: inv_a
		port map(ttko, ko);

end arch;


-- Generic Completion (sleep)
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity comp1dm is
	generic(width: in integer := 4);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 ki: in std_logic;
		 kin: in std_logic;
		 rst: in std_logic;
		 sleep: in std_logic;
		 ko: out std_logic);
end comp1dm;

architecture arch of comp1dm is
	
	component th22n_a is 
		port(a: in std_logic; 
			 b: in std_logic;	
			 rst: in std_logic;
			 z: out std_logic ); 
	end component; 
	
	component th33d_a is 
		port(a: in std_logic; 
			 b: in std_logic;	
			 c: in std_logic;
			 rst: in std_logic;
			 z: out std_logic ); 
	end component; 
	
	component inv_a is 
		port(a: in std_logic;
			 z: out std_logic ); 
	end component;
		
	component andtreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;
  component th24compm_a is
    port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic );
  end component;
		
component th12m_a is
port(a: in std_logic; 
		 b: in std_logic;
		 s: in std_logic; 
		 z: out std_logic); 
end component;

		
signal t: std_logic_vector(width/2 downto 0);
signal tko, ttko: std_logic;

begin
	
	STAGE1: for i in 0 to width/2-1 generate
		Gs1: th24compm_a
			port map(a(i*2).rail0,a(i*2).rail1, a(i*2+1).rail0, a(i*2+1).rail1, sleep, t(i));
	end generate;
	
	ONEMORE: if width rem 2 = 1 generate
		Gsom: th12m_a
			port map(a(width-1).rail0, a(width-1).rail1, sleep, t(width/2));
	end generate;
	
	Gcompodd: if width rem 2 = 1 generate
	begin
		Gco: andtreem
			generic map(width/2+1)
			port map(t, sleep, tko);
	end generate;
	
	Gcompeven: if width rem 2 = 0 generate
	begin
		Gce: andtreem
			generic map(width/2)
			port map(t(width/2-1 downto 0), sleep, tko);
	end generate;
	
	Gfgate: th33d_a
		port map(tko, ki, kin, rst, ttko);
	Gfinv: inv_a
		port map(ttko, ko);

end arch;

