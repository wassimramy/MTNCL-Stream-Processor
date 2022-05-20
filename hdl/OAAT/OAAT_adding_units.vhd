library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity half_adder is
	port(a: in dual_rail_logic;
	     b: in dual_rail_logic;
		 sleep: in std_logic;
	     sum: out dual_rail_logic;
	     cout: out dual_rail_logic);
end half_adder;



library ieee;
use ieee.std_logic_1164.all;
use work.NCL_signals.all;

entity full_adder is
	port(a: in dual_rail_logic;
	     b: in dual_rail_logic;
	     cin: in dual_rail_logic;
		 sleep: in std_logic;
	     sum: out dual_rail_logic;
	     cout: out dual_rail_logic);
end full_adder;



library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity adder_w_and is
	port(a: in dual_rail_logic;
		 b: in dual_rail_logic;
		 cin: in dual_rail_logic;
		 sum_in: in dual_rail_logic;
		 sleep: in std_logic;
		 sum_out: out dual_rail_logic;
		 cout: out dual_rail_logic);
end adder_w_and;



library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity adder_w_nand is
	port(a: in dual_rail_logic;
		 b: in dual_rail_logic;
		 cin: in dual_rail_logic;
		 sum_in: in dual_rail_logic;
		 sleep: in std_logic;
		 sum_out: out dual_rail_logic;
		 cout: out dual_rail_logic);
end adder_w_nand;



architecture behavioral of half_adder is
	component thxor0m_a
		port(a: in std_logic;
		     b: in std_logic;
		     c: in std_logic;
		     d: in std_logic;
			 s: in std_logic;
		     z: out std_logic);
	end component;

	component th22m_a
		port(a: in std_logic;
		     b: in std_logic;
			 s: in std_logic;
		     z: out std_logic);
	end component;

	component th12m_a
		port(a: in std_logic;
		     b: in std_logic;
			 s: in std_logic;
		     z: out std_logic);
	end component;

begin
	g0: thxor0m_a port map(
			a => a.rail0,
			b => b.rail1,
			c => a.rail1,
			d => b.rail0,
			s => sleep,
			z => sum.rail1);
	g1: th22m_a port map(
			a => a.rail1,
			b => b.rail1,
			s => sleep,
			z => cout.rail1);
	g2: thxor0m_a port map(
			a => a.rail0,
			b => b.rail0,
			c => a.rail1,
			d => b.rail1,
			s => sleep,
			z => sum.rail0);
	g3: th12m_a port map(
			a => a.rail0,
			b => b.rail0,
			s => sleep,
			z => cout.rail0);

end behavioral;



architecture arch1 of full_adder is
	component th34w2m_a is 
		port(a: in std_logic;
			b: in std_logic; 
			c: in std_logic; 
			d: in std_logic;
			s:in std_logic;
			z: out std_logic ); 
	end component; 
	component th23m_a
		port(a: in std_logic;
		     b: in std_logic;
		     c: in std_logic;
			 s: in std_logic;
		     z: out std_logic);
	end component;

signal g0sig, g1sig: std_logic;

begin

	g0: th23m_a
		port map(
			a.rail0,
			b.rail0,
			cin.rail0,
			sleep,
			g0sig);
	g1: th23m_a
		port map(
			a.rail1,
			b.rail1,
			cin.rail1,
			sleep,
			g1sig);
	g2: th34w2m_a
		port map(
			g1sig,
			a.rail0,
			b.rail0,
			cin.rail0,
			sleep,
			sum.rail0);
	g3: th34w2m_a
		port map(
			g0sig,
			a.rail1,
			b.rail1,
			cin.rail1,
			sleep,
			sum.rail1);
			
cout.rail0 <= g0sig;
cout.rail1 <= g1sig;

end arch1;



architecture arch1 of adder_w_and is
	component full_adder is
		port(a: in dual_rail_logic;
			 b: in dual_rail_logic;
			 cin: in dual_rail_logic;
			 sleep: in std_logic;
			 sum: out dual_rail_logic;
			 cout: out dual_rail_logic);
	end component;
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

signal add_in1: dual_rail_logic;

begin
	g0: th22m_a
		port map(
			a.rail1,
			b.rail1,
			sleep,
			add_in1.rail1);
	g1: th12m_a
		port map(
			a.rail0,
			b.rail0,
			sleep,
			add_in1.rail0);
	add: full_adder
		port map(
			add_in1,
			sum_in,
			cin,
			sleep,
			sum_out,
			cout);

end arch1;
			
			
			
architecture arch1 of adder_w_nand is
	component full_adder is
		port(
			a: in dual_rail_logic;
			b: in dual_rail_logic;
			cin: in dual_rail_logic;
			sleep: in std_logic;
			sum: out dual_rail_logic;
			cout: out dual_rail_logic);
	end component;
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

signal add_in1: dual_rail_logic;

begin
	g0: th22m_a
		port map(
			a.rail1,
			b.rail1,
			sleep,
			add_in1.rail0);
	g1: th12m_a
		port map(
			a.rail0,
			b.rail0,
			sleep,
			add_in1.rail1);
	add: full_adder
		port map(
			add_in1,
			sum_in,
			cin,
			sleep,
			sum_out,
			cout);

end arch1;