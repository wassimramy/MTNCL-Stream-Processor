

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity mux_21_gen_nic is
	generic(width: integer := 16);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end mux_21_gen_nic;

architecture behavioral of mux_21_gen_nic is

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

signal iza, izb : dual_rail_logic_vector(width-1 downto 0);

begin
		
	thxorm_gen: for i in 0 to width-1 generate
		th22m_a1_i : th22m_a
			port map(
				a => a(i).rail1,
				b => sel.rail0,
				s => sleep,
				z => iza(i).rail1);

		th22m_n1_i : th22m_a
			port map(
				a => b(i).rail1,
				b => sel.rail1,
				s => sleep,
				z => izb(i).rail1);

		th22m_a0_i : th22m_a
			port map(
				a => a(i).rail0,
				b => sel.rail0,
				s => sleep,
				z => iza(i).rail0);


		th22m_n0_i : th22m_a
			port map(
				a => b(i).rail0,
				b => sel.rail1,
				s => sleep,
				z => izb(i).rail0);

		th12m_1_i : th12m_a
			port map(
				a => iza(i).rail1,
				b => izb(i).rail1,
				s => sleep,
				z => z(i).rail1);

		th12m_0_i : th12m_a
			port map(
				a => iza(i).rail0,
				b => izb(i).rail0,
				s => sleep,
				z => z(i).rail0);
	end generate;
	
end behavioral;
