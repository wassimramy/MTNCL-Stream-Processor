--Created by Spencer Nelson 8/24/20
--Counter with automatic self reset
--First output value is 0
--Will increment by 1 until it reaches reset_count
--Reset_count should be a CONSTANT (remain at data for entireity of use)
--Accumulate_reset will be 1 when z is at max value

library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;


entity counter_selfReset is
	generic(width: integer);
	port(	 reset_count: in dual_rail_logic_vector(width-1 downto 0);
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 accumulate_reset: out dual_rail_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end counter_selfReset;

architecture arch_counter_selfReset of counter_selfReset is
	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;
	component regs_gen_zero_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;
	component adder_gen is
		generic(width: integer);
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			b: in dual_rail_logic_vector(width-1 downto 0);
			sleep: in std_logic;
			sum: out dual_rail_logic_vector(width-1 downto 0);
			cout: out dual_rail_logic);
	end component;
	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;
	component compdm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;

	component th22n_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 rst: in std_logic; 
			 z: out std_logic); 
	end component; 

	component thxor0m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

	component andtreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

	component ortreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

	component th12m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic; 
			 z: out std_logic); 
	end component; 

	component th22m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic; 
			 z: out std_logic); 
	end component; 

	
component inv_a is 
	port(a: in std_logic; 
		 z: out std_logic); 
end component; 

signal reg1_in, reg1_out: dual_rail_logic_vector(width-1 downto 0);
signal adder_out, reg5_out, reg2_in, reg2_out, reg5_in, count_equal : dual_rail_logic_vector(width downto 0);
signal reg3_in, reg3_out, reg4_out : dual_rail_logic_vector(width+1 downto 0);
signal comp1_in: dual_rail_logic_vector(width*2-1 downto 0);
signal accumulate_reset_temp : dual_rail_logic;
signal comp1_out, comp2_out, comp3_ki, comp3_out, comp4_out, inv_sleep: std_logic;
signal and_tree_in, or_tree_in : std_logic_vector(width-1 downto 0);
	
begin
	comp1: compm
		generic map(width => width+1)
		port map(
			a => reg2_in,
			ki => comp2_out,
			rst => reset,
			sleep => sleep_in,
			ko => comp1_out);


	reg2: regs_gen_null_res
		generic map(width => width+1)
		port map(
			d => reg2_in,
			q => reg2_out,
			reset => reset,
			sleep => comp1_out);

reg1_out_gen : for i in 1 to width-1 generate
	reg1_out(i).rail1 <= '0';
	reg1_out(i).rail0 <= '1';
end generate;
	reg1_out(0).rail1 <= '1';
	reg1_out(0).rail0 <= '0';


	adder: adder_gen
		generic map(width => width)
		port map(
			a => reg1_out,
			b => reg2_out(width-1 downto 0),
			sleep => comp1_out,
			sum => adder_out(width-1 downto 0),
			cout => adder_out(width));

generate_xor: for i in 0 to width-1 generate

	thxor_i	: thxor0m_a
		port map(
			a => adder_out(i).rail1,
			b => reset_count(i).rail1,
			c => adder_out(i).rail0,
			d => reset_count(i).rail0,
			s => comp1_out,
			z => count_equal(i).rail1);

	thxnor_i: thxor0m_a
		port map(
			a => adder_out(i).rail0,
			b => reset_count(i).rail1,
			c => adder_out(i).rail1,
			d => reset_count(i).rail0,
			s => comp1_out,
			z => count_equal(i).rail0);

	end generate;

	generate_tree_sigs : for i in 0 to width-1 generate
		and_tree_in(i) <= count_equal(i).rail1;
		or_tree_in(i) <= count_equal(i).rail0;
	
	end generate;

	and_tree : andtreem
		generic map(width => width)
		port map(
			a => and_tree_in,
			sleep => comp1_out,
			ko => accumulate_reset_temp.rail1);

	or_tree : ortreem
		generic map(width => width)
		port map(
			a => or_tree_in,
			sleep => comp1_out,
			ko => accumulate_reset_temp.rail0);

generate_orand: for i in 0 to width generate

	th22m_i	: th22m_a
		port map(
			a => reg2_out(width).rail0,
			b => adder_out(i).rail1,
			s => comp1_out,
			z => reg3_in(i).rail1);

	th12m_i: th12m_a
		port map(
			a => reg2_out(width).rail1,
			b => adder_out(i).rail0,
			s => comp1_out,
			z => reg3_in(i).rail0);

	end generate;

reg3_in(width+1) <= accumulate_reset_temp;
	comp2: compdm
		generic map(width => width+2)
		port map(
			a => reg3_in,
			ki => comp3_out,
			rst => reset,
			sleep => comp1_out,
			ko => comp2_out);


	reg3: regs_gen_zero_res
		generic map(width => width+2)
		port map(
			d => reg3_in,
			q => reg3_out,
			reset => reset,
			sleep => comp2_out);

	comp3: compm
		generic map(width => width+2)
		port map(
			a => reg3_out,
			ki => comp3_ki,
			rst => reset,
			sleep => comp2_out,
			ko => comp3_out);

	comp3_ki_gate: th22n_a
		port map(
			a => ki,
			b => comp4_out,
			rst => reset,
			z => comp3_ki);
	
	reg4: regs_gen_null_res
		generic map(width => width+2)
		port map(
			d => reg3_out,
			q => reg4_out,
			reset => reset,
			sleep => comp3_out);

reg5_in(width) <= reg4_out(width+1);
reg5_in(width-1 downto 0) <= reg4_out(width-1 downto 0);


	comp4: compm
		generic map(width => width+1)
		port map(
			a => reg5_in,
			ki => comp1_out,
			rst => reset,
			sleep => comp3_out,
			ko => comp4_out);

	reg5: regs_gen_null_res
		generic map(width => width+1)
		port map(
			d => reg5_in,
			q => reg5_out,
			reset => reset,
			sleep => comp4_out);

z <= reg4_out(width-1 downto 0);
reg2_in <= reg5_out(width downto 0);
ko <= comp1_out;
sleep_out <= comp3_out;
accumulate_reset <= reg4_out(width+1);

end arch_counter_selfReset;
