-- Generic Completion, select whether to include bottom half of bits (sleep)
library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity compm_half_sel is
	generic(half_width: integer := 8);
	port(a: in dual_rail_logic_vector(half_width*2-1 downto 0);
		 sel: in std_logic;
		 ki: in std_logic;
		 rst: in std_logic;
		 sleep: in std_logic;
		 ko: out std_logic);
end compm_half_sel;

architecture arch of compm_half_sel is

	component compm is
		generic(width: in integer := 4);
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 ki: in std_logic;
			 rst: in std_logic;
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;
		

	component th33w2m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic;
			 s: in std_logic;
			 z: out std_logic ); 
	end component; 

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

signal not_sel, ko_bottom_half, ko_top_half : std_logic;
begin

compm_bottom_half : compm
	generic map(width => half_width)
	port map(a => a(half_width-1 downto 0),
		ki => ki,
		rst => rst,
		sleep => sleep,
		ko => ko_bottom_half);

compm_top_half : compm
	generic map(width => half_width)
	port map(a => a(half_width*2-1 downto half_width),
		ki => ki,
		rst => rst,
		sleep => sleep,
		ko => ko_top_half);

inv_sel : inv_a
	port map(a => sel,
		 z => not_sel);

ko_gate : th33w2m_a 
	port map(a => ko_top_half,
		b => ko_bottom_half,
		c => not_sel,
		s => '0',
		z => ko);

end arch;
