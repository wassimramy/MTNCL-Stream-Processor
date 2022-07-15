
-----------------------------------------
-- Definition of registers used in Spencer's RNN
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity regs_gen_zero_res is
	generic(width: integer);
    port(d: in dual_rail_logic_vector(width-1 downto 0);
		q: out dual_rail_logic_vector(width-1 downto 0);
		reset: in std_logic;
		sleep: in std_logic);
end regs_gen_zero_res;

architecture arch1 of regs_gen_zero_res is
	component reg_zero_res is
	   port(d: in dual_rail_logic;
			reset: in std_logic;
			sleep: in std_logic;
			q: out dual_rail_logic);
	end component;

begin
	gen_reg:
	for i in 0 to width-1 generate
		regx: reg_zero_res port map(
			d(i),
			reset,
			sleep,
			q(i));
	end generate gen_reg;
end arch1;

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity reg_null_res is
   port(d: in dual_rail_logic;
		reset: in std_logic;
		sleep: in std_logic;
		q: out dual_rail_logic);
end reg_null_res;

architecture behavioral of reg_null_res is

	component th12nm_a is 
		port(a: in std_logic; 
			b: in std_logic;
			rst : in std_logic;
			s:in std_logic; 
			z: out std_logic); 
	end component;
	
	signal sig1, sig2: std_logic;
	
begin
	g1: th12nm_a port map(
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
	
end behavioral;


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

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity regs_gen_null_res is
	generic(width : integer := 8);
    port(d: in dual_rail_logic_vector(width-1 downto 0);
		q: out dual_rail_logic_vector(width-1 downto 0);
		reset: in std_logic;
		sleep: in std_logic);
end regs_gen_null_res;

architecture behavioral of regs_gen_null_res is
	component reg_null_res is
	   port(d: in dual_rail_logic;
			reset: in std_logic;
			sleep: in std_logic;
			q: out dual_rail_logic);
	end component;

begin
	gen_reg:
	for i in 0 to width-1 generate
		regx: reg_null_res port map(
			d(i),
			reset,
			sleep,
			q(i));
	end generate gen_reg;
end behavioral;

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity regs_gen_null_res_w_compm is
	generic(width : integer := 8);
    port(
    	d: in dual_rail_logic_vector(width-1 downto 0);
		reset: in std_logic;
		sleep_in: in std_logic;
		ki: in std_logic;
		sleep_out: out std_logic;
		ko: out std_logic;
		q: out dual_rail_logic_vector(width-1 downto 0)
		);
end regs_gen_null_res_w_compm;

architecture behavioral of regs_gen_null_res_w_compm is
	component regs_gen_null_res is
	generic(width: in integer := 4);
	   port(d: in dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic;
			q: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;

signal compm_ko : std_logic;
begin

	completion_component_instance: compm
		generic map(width => width)
		port map(
			a => d,
			ki => ki,
			rst => reset,
			sleep => sleep_in,
			ko => compm_ko);

	registers_instance: regs_gen_null_res
		generic map(width => width)
		port map(
			d => d,
			q => q,
			reset => reset,
			sleep => compm_ko
			);

	ko <= compm_ko;	
	sleep_out <= compm_ko;		

end behavioral;

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity regs_genregm_w_compm is
	generic(width : integer := 8);
    port(
    	d: in dual_rail_logic_vector(width-1 downto 0);
    	rst: in std_logic;
		sleep_in: in std_logic;
		ki: in std_logic;
		sleep_out: out std_logic;
		ko: out std_logic;
		q: out dual_rail_logic_vector(width-1 downto 0)
		);
end regs_genregm_w_compm;

architecture behavioral of regs_genregm_w_compm is

	component genregm is
	generic(width : in integer := 4);
	port(a     : IN  dual_rail_logic_vector(width-1 downto 0);
		 s : in  std_logic;
		 z     : out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;

signal compm_ko : std_logic;
begin

	completion_component_instance: compm
		generic map(width => width)
		port map(
			a => d,
			ki => ki,
			rst => rst,
			sleep => sleep_in,
			ko => compm_ko);

	registers_instance: genregm
		generic map(width => width)
		port map(
			a => d,
			z => q,
			s => compm_ko
			);

	ko <= compm_ko;	
	sleep_out <= compm_ko;		

end behavioral;

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity DFFRX1MTR_No_QN_gen is
	generic(bitwidth : integer := 8);
    port(
		    	d: in std_logic_vector(bitwidth-1 downto 0);
		    	clk: in std_logic;
		    	reset: in std_logic;
				q: out std_logic_vector(bitwidth-1 downto 0)
		);
end DFFRX1MTR_No_QN_gen;

architecture behavioral of DFFRX1MTR_No_QN_gen is

	component DFFRX1MTR_No_QN is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic);
end component;

begin


gen_reg: for i in 0 to bitwidth-1 generate
		regx: DFFRX1MTR_No_QN 
		port map(
						D => d(i),
						rst => reset,
						clk => clk,
						Q => q(i));
	end generate gen_reg;	

end behavioral;