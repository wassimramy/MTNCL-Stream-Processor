library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;

entity accumulator_outputOnReset is
	generic(width: integer;
		counterWidth: integer);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		reset_count: in dual_rail_logic_vector(counterWidth-1 downto 0);
		 sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end accumulator_outputOnReset;

architecture arch_accumulator_outputOnReset of accumulator_outputOnReset is
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

	component th22d_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 rst: in std_logic; 
			 z: out std_logic); 
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

component counter_selfReset is
	generic(width: integer);
	port(	 reset_count: in dual_rail_logic_vector(width-1 downto 0);
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 accumulate_reset: out dual_rail_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
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

	component Add_of_checkV2 is
		generic(bitwidth : integer);
		port(a : in dual_rail_logic_vector(bitwidth downto 0);
			sign_bits : in dual_rail_logic_vector(1 downto 0);
			sleep : in std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0)
		);
	end component;

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

	component and2_a is
		port(a, b : in  std_logic;
			 z : out std_logic);
	end component;

	component th22m_en_gen is
		generic(bitwidth : integer);
		port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
			en : in std_logic;
			sleep : std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	
signal reg1_in, reg1_out, reg2_in, reg2_out, reg3_in, reg3_out, reg4_out, reg5_in, reg5_out: dual_rail_logic_vector(width-1 downto 0);
signal overflow_in, reg6_in, reg6_out: dual_rail_logic_vector(width downto 0);
signal comp1_in_a, comp1_in_b: dual_rail_logic_vector(width-1 downto 0);
signal counter_out, count_equal: dual_rail_logic_vector(counterWidth-1 downto 0);
signal accumulate_reset : dual_rail_logic;
signal comp1_out, comp2_out, comp3_ki, comp3_out, comp4_out, counter_ko, counter_sleep, counter_comp4_ko, comp5_out, comp5_ki, not_acc, comp1_out_a, comp1_out_b: std_logic;
signal and_tree_in, or_tree_in : std_logic_vector(counterWidth-1 downto 0);
signal sign_bits : dual_rail_logic_vector(1 downto 0);
	
begin
	comp1a: compm
		generic map(width => width)
		port map(
			a => comp1_in_a,
			ki => comp2_out,
			rst => reset,
			sleep => sleep_in,
			ko => comp1_out_a);

	comp1b: compm
		generic map(width => width)
		port map(
			a => comp1_in_b,
			ki => comp2_out,
			rst => reset,
			sleep => sleep_in,
			ko => comp1_out_b);

	comp1_gate : th22d_a 
		port map(
			a => comp1_out_a,
			b => comp1_out_b,
			rst => reset,
			z => comp1_out);

	reg1: regs_gen_null_res
		generic map(width => width)
		port map(
			d => reg1_in,
			q => reg1_out,
			reset => reset,
			sleep => comp1_out);

	reg2: regs_gen_null_res
		generic map(width => width)
		port map(
			d => reg2_in,
			q => reg2_out,
			reset => reset,
			sleep => comp1_out);

	adder: adder_gen
		generic map(width => width)
		port map(
			a => reg1_out,
			b => reg2_out,
			sleep => comp1_out,
			sum => overflow_in(width-1 downto 0),
			cout => overflow_in(width));

sign_bits(0) <= reg1_out(width-1);
sign_bits(1) <= reg2_out(width-1);

	overflowCheck: Add_of_checkV2
		generic map(bitwidth => width)
		port map(a => overflow_in,
			sign_bits => sign_bits,
			sleep => comp1_out,
			z => reg3_in
		);

	comp2: compm
		generic map(width => width)
		port map(
			a => reg3_in,
			ki => comp3_out,
			rst => reset,
			sleep => comp1_out,
			ko => comp2_out);

	reg3: regs_gen_null_res
		generic map(width => width)
		port map(
			d => reg3_in,
			q => reg3_out,
			reset => reset,
			sleep => comp2_out);

	comp3: compm
		generic map(width => width)
		port map(
			a => reg3_out,
			ki => comp3_ki,
			rst => reset,
			sleep => comp2_out,
			ko => comp3_out);

	comp3_ki_gate: th22n_a
		port map(
			a => comp5_out,
			b => comp4_out,
			rst => reset,
			z => comp3_ki);

--	counter_comp4_ko_gate: th22n_a
--		port map(
--			a => comp4_out,
--			b => counter_ko,
--			rst => reset,
--			z => counter_comp4_ko);
	
	counter_comp4_ko_gate: th22n_a
		port map(
			a => comp3_out,
			b => counter_sleep,
			rst => reset,
			z => counter_comp4_ko);
	reg4: regs_gen_null_res
		generic map(width => width)
		port map(
			d => reg3_out,
			q => reg4_out,
			reset => reset,
			sleep => comp3_out);

	u_counter: counter_selfReset
		generic map(width => counterWidth)
		port map( reset_count => reset_count,
			sleep_in => comp3_out,
			 reset => reset,
			 ki => comp3_ki,
			 ko => counter_ko,
			 sleep_out => counter_sleep,
			 accumulate_reset => accumulate_reset,
			 z => counter_out);
--COMMENTS BELOW REPLACED BY COUNTER_SELFRESET
--	u_counter: counter
--		generic map(width => counterWidth)
--		port map( sleep_in => comp3_out,
--			 reset => reset,
--			 ki => comp4_out,
--			 ko => counter_ko,
--			 sleep_out => counter_sleep,
--			 z => counter_out);
--
--generate_xor: for i in 0 to counterWidth-1 generate
--
--	thxor_i	: thxor0m_a
--		port map(
--			a => counter_out(i).rail1,
--			b => reset_count(i).rail1,
--			c => counter_out(i).rail0,
--			d => reset_count(i).rail0,
--			s => counter_sleep,
--			z => count_equal(i).rail1);
--
--	thxnor_i: thxor0m_a
--		port map(
--			a => counter_out(i).rail0,
--			b => reset_count(i).rail1,
--			c => counter_out(i).rail1,
--			d => reset_count(i).rail0,
--			s => counter_sleep,
--			z => count_equal(i).rail0);
--
--	end generate;
--
--	generate_tree_sigs : for i in 0 to counterWidth-1 generate
--		and_tree_in(i) <= count_equal(i).rail1;
--		or_tree_in(i) <= count_equal(i).rail0;
--	
--	end generate;
--
--	and_tree : andtreem
--		generic map(width => counterWidth)
--		port map(
--			a => and_tree_in,
--			sleep => counter_sleep,
--			ko => accumulate_reset.rail1);
--
--	or_tree : ortreem
--		generic map(width => counterWidth)
--		port map(
--			a => or_tree_in,
--			sleep => counter_sleep,
--			ko => accumulate_reset.rail0);

generate_orand: for i in 0 to width-1 generate

	th22m_i	: th22m_a
		port map(
			a => accumulate_reset.rail0,
			b => reg4_out(i).rail1,
			s => comp3_out,
			z => reg5_in(i).rail1);

	th12m_i: th12m_a
		port map(
			a => accumulate_reset.rail1,
			b => reg4_out(i).rail0,
			s => comp3_out,
			z => reg5_in(i).rail0);

	end generate;

	comp4: compdm
		generic map(width => width)
		port map(
			a => reg5_in,
			ki => comp1_out,
			rst => reset,
			sleep => comp3_out,
			ko => comp4_out);



	reg5: regs_gen_zero_res
		generic map(width => width)
		port map(
			d => reg5_in,
			q => reg5_out,
			reset => reset,
			sleep => comp4_out);

	comp5: compm
		generic map(width => width+1)
		port map(
			a => reg6_in,
			ki => comp5_ki,
			rst => reset,
			sleep => comp3_out,
			ko => comp5_out);

	reg6: regs_gen_null_res
		generic map(width => width+1)
		port map(
			d => reg6_in,
			q => reg6_out,
			reset => reset,
			sleep => comp5_out);

	inv_i : inv_a
		port map(a => reg6_out(0).rail0,
			z => not_acc);

	and_i : and2_a
		port map(a => not_acc,
			b => ki,
			z => comp5_ki);

	enable_gen : th22m_en_gen 
		generic map(bitwidth => width)
		port map(a => reg6_out(width downto 1),
			en => reg6_out(0).rail1,
			sleep => comp5_out,
			z => z);


reg6_in(0) <= accumulate_reset;
reg6_in(width downto 1) <= reg4_out;

--z <= reg4_out;
--acc_reset <= accumulate_reset;
reg1_in <= a;
reg2_in <= reg5_out(width-1 downto 0);
comp1_in_a <= reg1_in;
comp1_in_b <= reg2_in;
ko <= comp1_out;
sleep_out <= comp5_out;

end arch_accumulator_outputOnReset;
