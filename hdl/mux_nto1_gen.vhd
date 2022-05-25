library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.ncl_signals.all;

entity mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end mux_nto1_gen;

architecture behavioral of mux_nto1_gen is

component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component mux_2nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;


signal MUX_Outputs: dual_rail_logic_vector((bitwidth*2)-1 downto 0);

begin

	check_if_numInputs_powers_of_2: if numInputs = 2**sel'length generate
			mux_2nto1_instance : mux_2nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs )
				port map(
					a => a,
					sel => sel,
					sleep => sleep,
					z => z);	
	end generate check_if_numInputs_powers_of_2;

	if_numInputs_not_power_of_2: if (numInputs < 2**sel'length) and (numInputs mod 2 = 0) generate
			mux_2nto1_instance : mux_2nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => 2**(sel'length-1) )
				port map(
					a => a((2**(sel'length-1)*bitwidth)-1 downto 0),
					sel => sel((sel'length-2) downto 0),
					sleep => sleep,
					z => MUX_Outputs(bitwidth-1 downto 0));	

			mux_nto1_instance : mux_nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs-2**(sel'length-1) )
				port map(
					a => a((numInputs*bitwidth)-1 downto (2**(sel'length-1)*bitwidth)),
					sel => sel(integer(ceil(log2(real(numInputs-2**(sel'length-1)))))-1 downto 0),
					sleep => sleep,
					z => MUX_Outputs((2*bitwidth)-1 downto bitwidth));

			mux_2nto1_final_stage : mux_2nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => 2 )
				port map(
					a => MUX_Outputs,
					sel => sel(integer(ceil(log2(real(numInputs))))-1 downto integer(ceil(log2(real(numInputs))))-1),
					sleep => sleep,
					z => z);		

	end generate if_numInputs_not_power_of_2;	

	if_numInputs_odd: if (numInputs mod 2 /= 0) generate

			MUX_Outputs (2*bitwidth-1 downto bitwidth) <= a((numInputs*bitwidth)-1 downto ((numInputs-1)*bitwidth));
			mux_nto1_instance : mux_nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs-1 )
				port map(
					a => a(((numInputs-1)*bitwidth)-1 downto 0),
					sel => sel(integer(ceil(log2(real(numInputs-1))))-1 downto 0),
					sleep => sleep,
					z => MUX_Outputs((bitwidth)-1 downto 0));

			mux_2nto1_final_stage : mux_2nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => 2 )
				port map(
					a => MUX_Outputs,
					sel => sel(integer(ceil(log2(real(numInputs))))-1 downto integer(ceil(log2(real(numInputs))))-1),
					sleep => sleep,
					z => z);		

	end generate if_numInputs_odd;		
	
end behavioral;



library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.ncl_signals.all;

entity mux_2nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end mux_2nto1_gen;

architecture behavioral of mux_2nto1_gen is


component mux_21_gen is
	generic(width: integer);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end component;

type dual_rail_2d_array is array(integer(ceil(log2(real(numInputs))))-1 downto 0, (numInputs/2)-1 downto 0) of dual_rail_logic_vector (bitwidth-1 downto 0);
signal MUX_outputs	: dual_rail_2d_array;

begin

		first_stage_gen: for i in 0 to (numInputs/2)-1 generate
			mux_21_i : mux_21_gen
			generic map(	width => bitwidth )
				port map(
					a => a(i*2*bitwidth+bitwidth-1 downto i*2*bitwidth),
					b => a(i*2*bitwidth+2*bitwidth-1 downto i*2*bitwidth+bitwidth),
					sel => sel(0),
					sleep => sleep,
					z => MUX_outputs(0, i));
		end generate;	
		
	
		i_stage_gen: for i in 1 to integer(ceil(log2(real(numInputs))))-1 generate
			j_stage_gen: for j in 0 to 2**(integer(ceil(log2(real(numInputs))))-i-1)-1 generate
			constant exponential: integer := integer(ceil(log2(real(numInputs))));
			begin
			mux_21_i : mux_21_gen
			generic map(	width => bitwidth )
				port map(
					a => MUX_outputs(i-1,j*2),
					b => MUX_outputs(i-1,j*2+1),
					sel => sel(i),
					sleep => sleep,
					z => MUX_outputs(i,j));
			end generate;	
		end generate;	
	
		z <= MUX_outputs(integer(ceil(log2(real(numInputs))))-1,0);
	
end behavioral;


library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity mux_21_gen is
	generic(width: integer);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end mux_21_gen;

architecture behavioral of mux_21_gen is
	component thxor0m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

begin
		
	thxorm_gen: for i in 0 to width-1 generate
		thxor0m_1_i : thxor0m_a
			port map(
				a => a(i).rail1,
				b => sel.rail0,
				c => b(i).rail1,
				d => sel.rail1,
				s => sleep,
				z => z(i).rail1);

		thxor0m_0_i : thxor0m_a
			port map(
				a => a(i).rail0,
				b => sel.rail0,
				c => b(i).rail0,
				d => sel.rail1,
				s => sleep,
				z => z(i).rail0);
	end generate;
	
end behavioral;
