

-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;

entity SYNC_Counter is
generic(bitwidth: in integer := 8; delay: in integer := 50);
	port(
		limit    			: in  std_logic_vector(bitwidth-1 downto 0);
		clk  				: in std_logic;
		reset  				: in std_logic;
		hold  				: in std_logic;
		clk_0  				: out std_logic;
		clk_1		 		: out std_logic;
		count   			: out std_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of SYNC_Counter is

component DFFRX1MTR_No_QN is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic);
end component;

component inv_a is
	port(a : in  std_logic;
		 z : out std_logic);
end component;

component and2a_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			z: out std_logic);
end component;

component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
end component; 

component or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component th12nm_a is
		port(
			a : in std_logic;
			b : in std_logic;
			rst : in std_logic;
			s : in std_logic;
			z : out std_logic);
end component;

component BUFFER_C is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end component; 

	signal D, Q : std_logic_vector (bitwidth-1 downto 0);
	signal and2a_input : std_logic_vector (bitwidth-1 downto 0);
	signal reset_limit, reset_limit_hold, reset_limit_temp, new_reset, new_clk, th12nm_reset, new_th12nm_reset, clk_out_sig : std_logic;
signal clk_out_sig_delay: std_logic_vector (delay+1 downto 0);

begin

inv_0 : inv_a port map(A =>  Q(0), Z => D(0));
input_reg : DFFRX1MTR_No_QN 
	port map(
		D => D(0),
		clk => new_clk,
		rst => new_reset,
		Q => Q(0));	

counter_stage_gen: for i in 1 to bitwidth-1 generate
			inv_i : inv_a port map(A =>  Q(i), Z => D(i));
			input_reg : DFFRX1MTR_No_QN 
				port map(
					D => D(i),
					clk => D(i-1),
					rst => new_reset,
					Q => Q(i));	
end generate;

input_xnor_output: for i in 0 to bitwidth-1 generate
	XxnorY : MUX21_A 
	port map(
		A => D(i), 
		B => Q(i),
		S => limit(i),
		Z => and2a_input(i));
end generate;

and2a_counter_tree : and2a_tree_gen
generic map(numInputs => bitwidth )
	port map(
		a => and2a_input,
		z => reset_limit);

new_reset_gen : or2_a 
	port map(
		A => reset_limit, 
		B => reset,
		Z => new_reset);	

generate_reset_limit : th12nm_a
		port map(a => reset_limit,
			b => reset_limit_temp,
			rst => new_th12nm_reset,
			s => '0',
			z => reset_limit_temp);
reset_limit_hold <= reset_limit_temp;

new_th12nm_reset_gen : MUX21_A 
	port map(
		A => th12nm_reset, 
		B => reset,
		S => hold,
		Z => new_th12nm_reset);

th12nm_reset_gen : or2_a 
	port map(
		A => new_reset, 
		B => hold,
		Z => th12nm_reset);

new_clk_gen : or2_a 
	port map(
		A => reset_limit_hold, 
		B => clk,
		Z => new_clk);

clk_out_sig_gen : and2_a 
	port map(
		A => reset_limit_hold, 
		B => clk,
		Z => clk_out_sig);

clk_0 <= clk_out_sig_delay(delay);
clk_1 <= new_clk;

clk_out_sig_delay(0) <= clk_out_sig;
gen_comp_z_out_delay : for i in 0 to delay generate
	delay_comp_z_i : BUFFER_C
		port map(A => clk_out_sig_delay(i),
			Z => clk_out_sig_delay(i+1));
end generate;
count <= Q ;

end arch;
