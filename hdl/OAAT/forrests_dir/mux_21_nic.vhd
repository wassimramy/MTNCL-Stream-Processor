


library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity mux_21_nic is
    port(a: in dual_rail_logic;
	 	 b: in dual_rail_logic;
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic);
end mux_21_nic;

architecture behavioral of mux_21_nic is

	component th22m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 
	component th12m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

signal iza, izb : dual_rail_logic;

begin
		
		th22m_a1_i : th22m_a
			port map(
				a => a.rail1,
				b => sel.rail0,
				s => sleep,
				z => iza.rail1);

		th22m_n1_i : th22m_a
			port map(
				a => b.rail1,
				b => sel.rail1,
				s => sleep,
				z => izb.rail1);

		th22m_a0_i : th22m_a
			port map(
				a => a.rail0,
				b => sel.rail0,
				s => sleep,
				z => iza.rail0);


		th22m_n0_i : th22m_a
			port map(
				a => b.rail0,
				b => sel.rail1,
				s => sleep,
				z => izb.rail0);

		th12m_1_i : th12m_a
			port map(
				a => iza.rail1,
				b => izb.rail1,
				s => sleep,
				z => z.rail1);

		th12m_0_i : th12m_a
			port map(
				a => iza.rail0,
				b => izb.rail0,
				s => sleep,
				z => z.rail0);
	
end behavioral;