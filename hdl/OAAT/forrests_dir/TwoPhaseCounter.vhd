--Created by Spencer Nelson 8/24/20
--Two counters, linked together into a single output
--First output is 0
--Lower counter will increment by 1 until it reaches reset_count_lower
--Upper counter will increment each time lower counter resets until it reaches reset_count_upper
--Reset_count_upper and Reset_count_lower should be CONSTANT (remain at data for entireity of use)
--Accumulate_reset will be 1 when z is at max value


library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;



entity TwoPhaseCounter is
	generic(width_lower: integer := 4;
		width_upper: integer := 8);
	port(	reset_count_lower: in dual_rail_logic_vector(width_lower-1 downto 0);
		reset_count_upper: in dual_rail_logic_vector(width_upper-1 downto 0);
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		upper_is_max : out dual_rail_logic;
		accumulate_reset_lower: out dual_rail_logic;
		accumulate_reset_upper: out dual_rail_logic;
		z: out dual_rail_logic_vector(width_upper+width_lower-1 downto 0));
end TwoPhaseCounter;


architecture arch_TwoPhaseCounter of TwoPhaseCounter is
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

signal reg1_out_lower, count_equal_lower: dual_rail_logic_vector(width_lower-1 downto 0);
signal reg1_out_upper: dual_rail_logic_vector(width_upper-1 downto 0);
signal count_equal_upper : dual_rail_logic_vector(width_upper downto 0);
signal comp1_in, reg2_in, reg2_out : dual_rail_logic_vector(width_upper+width_lower+1 downto 0);
signal adder_out_lower : dual_rail_logic_vector(width_lower downto 0);
signal adder_out_upper : dual_rail_logic_vector(width_upper downto 0);
signal reg3_in, reg3_out, reg4_out, reg5_out, reg5_in : dual_rail_logic_vector(width_upper+width_lower+2 downto 0);
signal accumulate_reset_lower_temp, accumulate_reset_upper_temp, upper_is_max_temp : dual_rail_logic;
signal comp1_out, comp2_out, comp3_ki, comp3_out, comp4_out, inv_sleep: std_logic;
signal and_tree_in_lower, or_tree_in_lower : std_logic_vector(width_lower-1 downto 0);
signal and_tree_in_upper, or_tree_in_upper : std_logic_vector(width_upper-1 downto 0);
	
begin
	comp1: compm
		generic map(width => width_lower+width_upper+2)
		port map(
			a => reg2_in,
			ki => comp2_out,
			rst => reset,
			sleep => sleep_in,
			ko => comp1_out);


	reg2: regs_gen_null_res
		generic map(width => width_lower+width_upper+2)
		port map(
			d => reg2_in,
			q => reg2_out,
			reset => reset,
			sleep => comp1_out);

--	sleepInverter : inv_a
--		port map(
--			a => comp1_out,
--			z => inv_sleep);
--
reg1_out_gen_lower : for i in 1 to width_lower-1 generate
	reg1_out_lower(i).rail1 <= '0';
	reg1_out_lower(i).rail0 <= '1';
end generate;
	reg1_out_lower(0).rail1 <= '1';
	reg1_out_lower(0).rail0 <= '0';


	adder_lower: adder_gen
		generic map(width => width_lower)
		port map(
			a => reg1_out_lower,
			b => reg2_out(width_lower-1 downto 0),
			sleep => comp1_out,
			sum => adder_out_lower(width_lower-1 downto 0),
			cout => adder_out_lower(width_lower));

generate_xor_lower: for i in 0 to width_lower-1 generate

	thxor_lower_i	: thxor0m_a
		port map(
			a => adder_out_lower(i).rail1,
			b => reset_count_lower(i).rail1,
			c => adder_out_lower(i).rail0,
			d => reset_count_lower(i).rail0,
			s => comp1_out,
			z => count_equal_lower(i).rail1);

	thxnor_lower_i: thxor0m_a
		port map(
			a => adder_out_lower(i).rail0,
			b => reset_count_lower(i).rail1,
			c => adder_out_lower(i).rail1,
			d => reset_count_lower(i).rail0,
			s => comp1_out,
			z => count_equal_lower(i).rail0);

	end generate;

	generate_lower_tree_sigs : for i in 0 to width_lower-1 generate
		and_tree_in_lower(i) <= count_equal_lower(i).rail1;
		or_tree_in_lower(i) <= count_equal_lower(i).rail0;
	
	end generate;

	and_tree_lower : andtreem
		generic map(width => width_lower)
		port map(
			a => and_tree_in_lower,
			sleep => comp1_out,
			ko => accumulate_reset_lower_temp.rail1);

	or_tree_lower : ortreem
		generic map(width => width_lower)
		port map(
			a => or_tree_in_lower,
			sleep => comp1_out,
			ko => accumulate_reset_lower_temp.rail0);

generate_orand_lower: for i in 0 to width_lower-1 generate

	th22m_lower_i	: th22m_a
		port map(
			a => reg2_out(width_lower+width_upper).rail0,
			b => adder_out_lower(i).rail1,
			s => comp1_out,
			z => reg3_in(i).rail1);

	th12m_lower_i: th12m_a
		port map(
			a => reg2_out(width_lower+width_upper).rail1,
			b => adder_out_lower(i).rail0,
			s => comp1_out,
			z => reg3_in(i).rail0);

	end generate;


--BEGIN UPPER BIT STUFF

reg1_out_gen_upper : for i in 1 to width_upper-1 generate
	reg1_out_upper(i).rail1 <= '0';
	reg1_out_upper(i).rail0 <= '1';
end generate;
	reg1_out_upper(0) <= reg2_out(width_lower+width_upper);

	adder_upper: adder_gen
		generic map(width => width_upper)
		port map(
			a => reg1_out_upper,
			b => reg2_out(width_upper+width_lower-1 downto width_lower),
			sleep => comp1_out,
			sum => adder_out_upper(width_upper-1 downto 0),
			cout => adder_out_upper(width_upper));

generate_xor_upper: for i in 0 to width_upper-1 generate

	thxor_upper_i	: thxor0m_a
		port map(
			a => adder_out_upper(i).rail1,
			b => reset_count_upper(i).rail1,
			c => adder_out_upper(i).rail0,
			d => reset_count_upper(i).rail0,
			s => comp1_out,
			z => count_equal_upper(i).rail1);

	thxnor_upper_i: thxor0m_a
		port map(
			a => adder_out_upper(i).rail0,
			b => reset_count_upper(i).rail1,
			c => adder_out_upper(i).rail1,
			d => reset_count_upper(i).rail0,
			s => comp1_out,
			z => count_equal_upper(i).rail0);

	end generate;
	count_equal_upper(width_upper) <= accumulate_reset_lower_temp;

	generate_upper_tree_sigs : for i in 0 to width_upper-1 generate
		and_tree_in_upper(i) <= count_equal_upper(i).rail1;
		or_tree_in_upper(i) <= count_equal_upper(i).rail0;
	
	end generate;

	and_tree_upper : andtreem
		generic map(width => width_upper)
		port map(
			a => and_tree_in_upper,
			sleep => comp1_out,
			ko => upper_is_max_temp.rail1);

	or_tree_upper : ortreem
		generic map(width => width_upper)
		port map(
			a => or_tree_in_upper,
			sleep => comp1_out,
			ko => upper_is_max_temp.rail0);



	th22m_acc_reset	: th22m_a
		port map(
			a => upper_is_max_temp.rail1,
			b => accumulate_reset_lower_temp.rail1,
			s => comp1_out,
			z => accumulate_reset_upper_temp.rail1);

	th12m_acc_reset: th12m_a
		port map(
			a => upper_is_max_temp.rail0,
			b => accumulate_reset_lower_temp.rail0,
			s => comp1_out,
			z => accumulate_reset_upper_temp.rail0);

generate_orand_upper: for i in 0 to width_upper-1 generate

	th22m_upper_i	: th22m_a
		port map(
			a => reg2_out(width_lower+width_upper+1).rail0,
			b => adder_out_upper(i).rail1,
			s => comp1_out,
			z => reg3_in(i+width_lower).rail1);

	th12m_upper_i: th12m_a
		port map(
			a => reg2_out(width_lower+width_upper+1).rail1,
			b => adder_out_upper(i).rail0,
			s => comp1_out,
			z => reg3_in(i+width_lower).rail0);

	end generate;

--END UPPER BIT STUFF

reg3_in(width_lower+width_upper) <= accumulate_reset_lower_temp;
reg3_in(width_lower+width_upper+1) <= accumulate_reset_upper_temp;
reg3_in(width_lower+width_upper+2) <= upper_is_max_temp;

	comp2: compdm
		generic map(width => width_lower+width_upper+3)
		port map(
			a => reg3_in,
			ki => comp3_out,
			rst => reset,
			sleep => comp1_out,
			ko => comp2_out);


	reg3: regs_gen_zero_res
		generic map(width => width_lower+width_upper+3)
		port map(
			d => reg3_in,
			q => reg3_out,
			reset => reset,
			sleep => comp2_out);

	comp3: compm
		generic map(width => width_lower+width_upper+3)
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
		generic map(width => width_lower+width_upper+3)
		port map(
			d => reg3_out,
			q => reg4_out,
			reset => reset,
			sleep => comp3_out);

reg5_in(width_lower+width_upper) <= reg4_out(width_lower+width_upper);
reg5_in(width_lower+width_upper+1) <= reg4_out(width_lower+width_upper+1);
reg5_in(width_lower+width_upper+2) <= reg4_out(width_lower+width_upper+2);
reg5_in(width_lower+width_upper-1 downto 0) <= reg4_out(width_lower+width_upper-1 downto 0);


	comp4: compm
		generic map(width => width_lower+width_upper+3)
		port map(
			a => reg5_in,
			ki => comp1_out,
			rst => reset,
			sleep => comp3_out,
			ko => comp4_out);

	reg5: regs_gen_null_res
		generic map(width => width_lower+width_upper+3)
		port map(
			d => reg5_in,
			q => reg5_out,
			reset => reset,
			sleep => comp4_out);

z <= reg4_out(width_lower+width_upper-1 downto 0);
reg2_in <= reg5_out(width_lower+width_upper+1 downto 0);
ko <= comp1_out;
sleep_out <= comp3_out;
accumulate_reset_lower <= reg4_out(width_lower+width_upper);
accumulate_reset_upper <= reg4_out(width_lower+width_upper+1);
upper_is_max <= reg4_out(width_lower+width_upper+2);

end arch_TwoPhaseCounter;
