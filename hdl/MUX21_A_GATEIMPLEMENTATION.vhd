library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.ncl_signals.all;
use work.tree_funcs.all;
use ieee.math_real.all;

entity mux_nto1_sr_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out std_logic_vector(bitwidth-1 downto 0));
end mux_nto1_sr_gen;

architecture behavioral of mux_nto1_sr_gen is

component mux_nto1_sr_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out std_logic_vector(bitwidth-1 downto 0));
end component;

component mux_2nto1_sr_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out std_logic_vector(bitwidth-1 downto 0));
end component;


signal MUX_Outputs: std_logic_vector((bitwidth*2)-1 downto 0);

begin

	check_if_numInputs_powers_of_2: if numInputs = 2**sel'length generate
			mux_2nto1_instance : mux_2nto1_sr_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs )
				port map(
					a => a,
					sel => sel,
					z => z);	
	end generate check_if_numInputs_powers_of_2;

	if_numInputs_not_power_of_2: if (numInputs < 2**sel'length) and (numInputs mod 2 = 0) generate
			mux_2nto1_instance : mux_2nto1_sr_gen
			generic map(	bitwidth => bitwidth, numInputs => 2**(sel'length-1) )
				port map(
					a => a((2**(sel'length-1)*bitwidth)-1 downto 0),
					sel => sel((sel'length-2) downto 0),
					z => MUX_Outputs(bitwidth-1 downto 0));	

			mux_nto1_instance : mux_nto1_sr_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs-2**(sel'length-1) )
				port map(
					a => a((numInputs*bitwidth)-1 downto (2**(sel'length-1)*bitwidth)),
					sel => sel(integer(ceil(log2(real(numInputs-2**(sel'length-1)))))-1 downto 0),
					z => MUX_Outputs((2*bitwidth)-1 downto bitwidth));

			mux_2nto1_final_stage : mux_2nto1_sr_gen
			generic map(	bitwidth => bitwidth, numInputs => 2 )
				port map(
					a => MUX_Outputs,
					sel => sel(integer(ceil(log2(real(numInputs))))-1 downto integer(ceil(log2(real(numInputs))))-1),
					z => z);		

	end generate if_numInputs_not_power_of_2;	

	if_numInputs_odd: if (numInputs mod 2 /= 0) generate

			MUX_Outputs (2*bitwidth-1 downto bitwidth) <= a((numInputs*bitwidth)-1 downto ((numInputs-1)*bitwidth));
			mux_nto1_instance : mux_nto1_sr_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs-1 )
				port map(
					a => a(((numInputs-1)*bitwidth)-1 downto 0),
					sel => sel(integer(ceil(log2(real(numInputs-1))))-1 downto 0),
					z => MUX_Outputs((bitwidth)-1 downto 0));

			mux_2nto1_final_stage : mux_2nto1_sr_gen
			generic map(	bitwidth => bitwidth, numInputs => 2 )
				port map(
					a => MUX_Outputs,
					sel => sel(integer(ceil(log2(real(numInputs))))-1 downto integer(ceil(log2(real(numInputs))))-1),
					z => z);		

	end generate if_numInputs_odd;		
	
end behavioral;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.ncl_signals.all;
use work.tree_funcs.all;
use ieee.math_real.all;

entity mux_2nto1_sr_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out std_logic_vector(bitwidth-1 downto 0));
end mux_2nto1_sr_gen;

architecture behavioral of mux_2nto1_sr_gen is


component MUX21_A_gen is
	generic(bitwidth: integer);
    port(
    	a: in std_logic_vector(bitwidth-1 downto 0);
    	b: in std_logic_vector(bitwidth-1 downto 0);
		sel: in std_logic;
		z: out std_logic_vector(bitwidth-1 downto 0));
end component;

type dual_rail_2d_array is array(integer(ceil(log2(real(numInputs))))-1 downto 0, (numInputs/2)-1 downto 0) of std_logic_vector (bitwidth-1 downto 0);
signal MUX_outputs	: dual_rail_2d_array;

begin

		first_stage_gen: for i in 0 to (numInputs/2)-1 generate
			mux_21_i : MUX21_A_gen
			generic map(	bitwidth => bitwidth )
				port map(
					a => a(i*2*bitwidth+bitwidth-1 downto i*2*bitwidth),
					b => a(i*2*bitwidth+2*bitwidth-1 downto i*2*bitwidth+bitwidth),
					sel => sel(0),
					z => MUX_outputs(0, i));
		end generate;	
		
	
		i_stage_gen: for i in 1 to integer(ceil(log2(real(numInputs))))-1 generate
			j_stage_gen: for j in 0 to 2**(integer(ceil(log2(real(numInputs))))-i-1)-1 generate
			constant exponential: integer := integer(ceil(log2(real(numInputs))));
			begin
			mux_21_i : MUX21_A_gen
			generic map(	bitwidth => bitwidth )
				port map(
					a => MUX_outputs(i-1,j*2),
					b => MUX_outputs(i-1,j*2+1),
					sel => sel(i),
					z => MUX_outputs(i,j));
			end generate;	
		end generate;	
	
		z <= MUX_outputs(integer(ceil(log2(real(numInputs))))-1,0);
	
end behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.ncl_signals.all;
use work.tree_funcs.all;
use ieee.math_real.all;

entity MUX21_A_gen is
	generic(bitwidth: integer);
    port(	a: in std_logic_vector (bitwidth-1 downto 0);
		b: in std_logic_vector (bitwidth-1 downto 0);
		sel: in std_logic;
		z: out std_logic_vector (bitwidth-1 downto 0));
end MUX21_A_gen;

architecture behavioral of MUX21_A_gen is
	component MUX21_A is 
		port(	 
			 A: in std_logic; 
			 B: in std_logic; 
			 S: in std_logic; 
			 Z: out std_logic); 
	end component; 

begin
		
	MUX21_gen: for i in 0 to bitwidth-1 generate
		MUX21_A_i : MUX21_A
			port map(
				A => a(i),
				B => b(i),
				S => sel,
				Z => z(i));

	end generate;
	
end behavioral;



library ieee; 
use ieee.std_logic_1164.all; 

entity MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end MUX21_A; 

architecture arch of MUX21_A is
component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 
component inv_a is
	port(a : in  std_logic;
		 z : out std_logic);
end component;

signal nS, aZ, bZ : std_logic;

begin

	inv_s : inv_a
		port map(A => S,
			Z => nS);

	and_AnS : and2_a
		port map(A => A,
			B => nS,
			Z => aZ);
	and_BS : and2_a
		port map(A => B,
			B => S,
			Z => bZ);
	or_Z : or2_a
		port map(A => aZ,
			B => bZ,
			Z => Z);


end arch; 

