library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.ncl_signals.all;

entity th22d_tree_gen is
	generic(numInputs : integer := 4);
    port(
		a: in std_logic_vector((numInputs)-1 downto 0);
		rst: in std_logic;
		z: out std_logic);
end th22d_tree_gen;

architecture behavioral of th22d_tree_gen is

	component th22d_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			rst: in std_logic;
			z: out std_logic);
	end component;

	component th22d_a is
	port(a   : in  std_logic;
		 b   : in  std_logic;
		 rst : in  std_logic;
		 z   : out std_logic);
	end component;

signal TH22d_Outputs: std_logic_vector((2*numInputs)-1 downto 0);
signal TH22d_Output: std_logic;
begin

	--if numInputs is equal to 2
	check_if_numInputs_is_2: if numInputs = 2 generate

			th22d_a_instance : th22d_a
				port map(
					a => a(0),
					b => a(1),
					rst => rst,
					z => z);

	end generate check_if_numInputs_is_2;

	--if numInputs is of power of 2
	check_if_numInputs_powers_of_2: if numInputs = 2**(integer(ceil(log2(real(numInputs))))) and numInputs > 2 generate

	TH22d_Outputs (numInputs-1 downto 0) <= a (numInputs-1 downto 0);
	z <= TH22d_Outputs(2*numInputs-2);

		generate_global_ko_and_sleep : for i in 0 to ((numInputs))-1 generate

			th22d_instance : th22d_a
				port map(
					a => TH22d_Outputs(i*2),
					b => TH22d_Outputs(i*2+1),
					rst => rst,
					z => TH22d_Outputs(numInputs+i));

		end generate;

	end generate check_if_numInputs_powers_of_2;

	if_numInputs_not_power_of_2: if numInputs < 2**(integer(ceil(log2(real(numInputs))))) generate

			th22d_tree_instance : th22d_tree_gen
			generic map(numInputs => numInputs-1 )
				port map(
					a => a (numInputs-2 downto 0),
					rst => rst,
					z => TH22d_Output);

			th22d_instance : th22d_a
				port map(
					a => TH22d_Output,
					b => a (numInputs-1),
					rst => rst,
					z => z);

	end generate if_numInputs_not_power_of_2;

	
end behavioral;
