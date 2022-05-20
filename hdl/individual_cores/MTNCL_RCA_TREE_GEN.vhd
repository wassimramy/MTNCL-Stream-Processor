

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.ncl_signals.all;

entity MTNCL_RCA_TREE_GEN is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    port(
		input    	: in  dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector((integer(ceil(log2(real(numInputs))))) + (bitwidth-1) downto 0)
	);
end;

architecture behavioral of MTNCL_RCA_TREE_GEN is

	component MTNCL_RCA_TREE_GEN is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
	port(	
		input    	: in  dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector((integer(ceil(log2(real(numInputs))))) + (bitwidth-1) downto 0));
	end component;

	component MTNCL_RCA_GEN is
	generic(bitwidth : in integer := 4);
	port(
		input    	: in  dual_rail_logic_vector((2*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector(bitwidth downto 0));
	end component;

	component th22d_a is
	port(a   : in  std_logic;
		 b   : in  std_logic;
		 rst : in  std_logic;
		 z   : out std_logic);
	end component;

signal S_1	: dual_rail_logic_vector(((bitwidth+1)*(numInputs/2))-1 downto 0);
signal SO	: dual_rail_logic_vector(13 downto 0);
signal ko_1,ko_2,sleep_1	: std_logic;
signal sleeps 	: std_logic_vector (numInputs-2 downto 0);
signal kos 	: std_logic_vector (numInputs-2 downto 0);
signal odd_input: dual_rail_logic_vector( 3 * (bitwidth) -1 downto 0);
signal odd_output: dual_rail_logic_vector(  13 downto 0);
signal data_0		: dual_rail_logic;

begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	--if numInputs is equal to 2
	check_if_numInputs_is_2: if numInputs = 2 generate

		generate_2n_tree : for i in 0 to (numInputs/2)-1 generate

			MTNCL_RCA_GEN_instance : MTNCL_RCA_GEN
			generic map(bitwidth => bitwidth)
				port map(
					input => input(((i+1)*2*bitwidth)-1 downto i*2*bitwidth),
					ki => ki,
					sleep => sleep,
					rst => rst,
					sleepOut => sleepOut, --ALL SLEEPS NEED TO BE CMBINED AND GIVEN TO THE NEXT SET OF RCAs
					ko => ko, --ALL KOs NEED TO BE COMBINED AND GIVEN TO THE GLOBAL KO,
					S => S);--ALL SUMS NEED TO COMBINED AND GIVEN TO THE NEXT SET OF RCAs);	
		end generate;


	end generate check_if_numInputs_is_2;

	--if numInputs is of power of 2
	check_if_numInputs_powers_of_2: if numInputs = 2**(integer(ceil(log2(real(numInputs))))) and numInputs > 2 generate


		ko <= kos(numInputs-2);
		generate_global_ko_and_sleep : for i in 0 to ((numInputs/2))-2 generate

			andKO_i : th22d_a
				port map(
					a => kos(i*2),
					b => kos(i*2+1),
					rst => rst,
					z => kos(numInputs/2+i));

			andSLEEPOUT_i : th22d_a
				port map(
					a => sleeps(i*2),
					b => sleeps(i*2+1),
					rst => rst,
					z => sleeps(numInputs/2+i));
		end generate;

		generate_2n_tree : for i in 0 to (numInputs/2)-1 generate

			MTNCL_RCA_GEN_instance : MTNCL_RCA_GEN
			generic map(bitwidth => bitwidth)
				port map(
					input => input(((i+1)*2*bitwidth)-1 downto i*2*bitwidth),
					ki => ko_1,
					sleep => sleep,
					rst => rst,
					sleepOut => sleeps(i), --ALL SLEEPS NEED TO BE CMBINED AND GIVEN TO THE NEXT SET OF RCAs
					ko => kos(i), --ALL KOs NEED TO BE COMBINED AND GIVEN TO THE GLOBAL KO,
					S => S_1((i+1)*bitwidth+i downto i*bitwidth+i));--ALL SUMS NEED TO COMBINED AND GIVEN TO THE NEXT SET OF RCAs);	
		end generate;

			MTNCL_RCA_TREE_GEN_instance : MTNCL_RCA_TREE_GEN
			generic map(	bitwidth => bitwidth+1, numInputs => numInputs/2 )
				port map(
					input => S_1,
					ki => ki,
					sleep => sleeps(numInputs-2),
					rst => rst,
					sleepOut => sleepOut,
					ko => ko_1,
					S => S);	

	end generate check_if_numInputs_powers_of_2;

	if_numInputs_not_power_of_2: if numInputs < 2**(integer(ceil(log2(real(numInputs))))) generate

			S <= odd_output(13 downto 0);
			MTNCL_RCA_TREE_GEN_instance : MTNCL_RCA_TREE_GEN
			generic map(	bitwidth => bitwidth, numInputs => 2**(integer(floor(log2(real(numInputs))))) )
				port map(
					input => input((2**(integer(floor(log2(real(numInputs))))))*bitwidth-1 downto 0),
					ki => ko_1,
					sleep => sleep,
					rst => rst,
					sleepOut => sleep_1,
					ko => ko_2,
					S => S_1 (12 downto 0));

			ko <= ko_1;
			odd_input (25 downto 0) <= data_0 & data_0 & data_0 & input(numInputs*bitwidth-1 downto (numInputs-1)*bitwidth) & S_1 (12 downto 0);
			MTNCL_RCA_GEN_instance : MTNCL_RCA_GEN
			generic map(bitwidth => bitwidth+3)
				port map(
					input => odd_input (25 downto 0),
					ki => ki,
					sleep => sleep_1,
					rst => rst,
					sleepOut => sleepOut,
					ko => ko_1,
					S => odd_output(13 downto 0) );	

	end generate if_numInputs_not_power_of_2;	
	
end behavioral;
