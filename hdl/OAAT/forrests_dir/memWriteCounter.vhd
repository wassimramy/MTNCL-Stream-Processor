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



entity memWriteCounter is
	port(	sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		upper_is_max : out dual_rail_logic;
		accumulate_reset_lower: out dual_rail_logic;
		accumulate_reset_upper: out dual_rail_logic;
		z: out dual_rail_logic_vector(4+12-1 downto 0));
end memWriteCounter;


architecture arch_memWriteCounter of memWriteCounter is
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

	component mux_21_gen_nic is
		generic(width: integer);
	    port(a: in dual_rail_logic_vector(width-1 downto 0);
		 	 b: in dual_rail_logic_vector(width-1 downto 0);
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;



signal reg1_out_lower, count_equal_lower: dual_rail_logic_vector(12-1 downto 0);
signal reg1_out_upper: dual_rail_logic_vector(3 downto 0);
signal count_equal_upper : dual_rail_logic_vector(4 downto 0);
signal comp1_in, reg2_in, reg2_out : dual_rail_logic_vector(4+12+1 downto 0);
signal adder_out_lower : dual_rail_logic_vector(12 downto 0);
signal adder_out_upper : dual_rail_logic_vector(4 downto 0);
signal reg3_in, reg3_out, reg4_out, reg5_out, reg5_in : dual_rail_logic_vector(4+12+2 downto 0);
signal accumulate_reset_lower_temp, accumulate_reset_upper_temp, upper_is_max_temp : dual_rail_logic;
signal comp1_out, comp2_out, comp3_ki, comp3_out, comp4_out, inv_sleep: std_logic;
signal and_tree_in_lower, or_tree_in_lower : std_logic_vector(12-1 downto 0);
signal and_tree_in_upper, or_tree_in_upper : std_logic_vector(3 downto 0);
signal reset_count_lower, const2175, const4095: dual_rail_logic_vector(12-1 downto 0);
signal reset_count_upper: dual_rail_logic_vector(3 downto 0);

signal data1, data0, reset_count_sel : dual_rail_logic;
begin

data1.rail1 <= '1';
data1.rail0 <= '0';

data0.rail0 <= '1';
data0.rail1 <= '0';

const2175(0) <= data1;
const2175(1) <= data1;
const2175(2) <= data1;
const2175(3) <= data1;
const2175(4) <= data1;
const2175(5) <= data1;
const2175(6) <= data1;
const2175(7) <= data0;
const2175(8) <= data0;
const2175(9) <= data0;
const2175(10) <= data0;
const2175(11) <= data1;

const4095(0) <= data1;
const4095(1) <= data1;
const4095(2) <= data1;
const4095(3) <= data1;
const4095(4) <= data1;
const4095(5) <= data1;
const4095(6) <= data1;
const4095(7) <= data1;
const4095(8) <= data1;
const4095(9) <= data1;
const4095(10) <= data1;
const4095(11) <= data1;

	comp1: compm
		generic map(width => 12+4+2)
		port map(
			a => reg2_in,
			ki => comp2_out,
			rst => reset,
			sleep => sleep_in,
			ko => comp1_out);


	reg2: regs_gen_null_res
		generic map(width => 12+4+2)
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
reg1_out_gen_lower : for i in 1 to 12-1 generate
	reg1_out_lower(i).rail1 <= '0';
	reg1_out_lower(i).rail0 <= '1';
end generate;
	reg1_out_lower(0).rail1 <= '1';
	reg1_out_lower(0).rail0 <= '0';


	adder_lower: adder_gen
		generic map(width => 12)
		port map(
			a => reg1_out_lower,
			b => reg2_out(12-1 downto 0),
			sleep => comp1_out,
			sum => adder_out_lower(12-1 downto 0),
			cout => adder_out_lower(12));

	reset_count_sel_1_gate : th12m_a
		port map(a => reg2_out(12).rail1,
			 b => reg2_out(13).rail1,
			 s => comp1_out,
			 z => reset_count_sel.rail1); 

	reset_count_sel_0_gate : th22m_a
		port map(a => reg2_out(12).rail0,
			 b => reg2_out(13).rail0,
			 s => comp1_out,
			 z => reset_count_sel.rail0); 

	reset_count_mux : mux_21_gen_nic
		generic map(width => 12)
	    port map(a => const2175,
		 	 b => const4095,
			sel => reset_count_sel,
			 sleep => comp1_out,
			 z => reset_count_lower);


generate_xor_lower: for i in 0 to 12-1 generate

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

	generate_lower_tree_sigs : for i in 0 to 12-1 generate
		and_tree_in_lower(i) <= count_equal_lower(i).rail1;
		or_tree_in_lower(i) <= count_equal_lower(i).rail0;
	
	end generate;

	and_tree_lower : andtreem
		generic map(width => 12)
		port map(
			a => and_tree_in_lower,
			sleep => comp1_out,
			ko => accumulate_reset_lower_temp.rail1);

	or_tree_lower : ortreem
		generic map(width => 12)
		port map(
			a => or_tree_in_lower,
			sleep => comp1_out,
			ko => accumulate_reset_lower_temp.rail0);

generate_orand_lower: for i in 0 to 12-1 generate

	th22m_lower_i	: th22m_a
		port map(
			a => reg2_out(12+4).rail0,
			b => adder_out_lower(i).rail1,
			s => comp1_out,
			z => reg3_in(i).rail1);

	th12m_lower_i: th12m_a
		port map(
			a => reg2_out(12+4).rail1,
			b => adder_out_lower(i).rail0,
			s => comp1_out,
			z => reg3_in(i).rail0);

	end generate;


--BEGIN UPPER BIT STUFF

reg1_out_gen_upper : for i in 1 to 3 generate
	reg1_out_upper(i).rail1 <= '0';
	reg1_out_upper(i).rail0 <= '1';
end generate;
	reg1_out_upper(0) <= reg2_out(12+4);

reset_count_upper(0) <= data1;
reset_count_upper(1) <= data1;
reset_count_upper(2) <= data0;
reset_count_upper(3) <= data0;

	adder_upper: adder_gen
		generic map(width => 4)
		port map(
			a => reg1_out_upper,
			b => reg2_out(4+12-1 downto 12),
			sleep => comp1_out,
			sum => adder_out_upper(3 downto 0),
			cout => adder_out_upper(4));

generate_xor_upper: for i in 0 to 3 generate

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
	count_equal_upper(4) <= accumulate_reset_lower_temp;

	generate_upper_tree_sigs : for i in 0 to 3 generate
		and_tree_in_upper(i) <= count_equal_upper(i).rail1;
		or_tree_in_upper(i) <= count_equal_upper(i).rail0;
	
	end generate;

	and_tree_upper : andtreem
		generic map(width => 4)
		port map(
			a => and_tree_in_upper,
			sleep => comp1_out,
			ko => upper_is_max_temp.rail1);

	or_tree_upper : ortreem
		generic map(width => 4)
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

generate_orand_upper: for i in 0 to 3 generate

	th22m_upper_i	: th22m_a
		port map(
			a => reg2_out(12+4+1).rail0,
			b => adder_out_upper(i).rail1,
			s => comp1_out,
			z => reg3_in(i+12).rail1);

	th12m_upper_i: th12m_a
		port map(
			a => reg2_out(12+4+1).rail1,
			b => adder_out_upper(i).rail0,
			s => comp1_out,
			z => reg3_in(i+12).rail0);

	end generate;

--END UPPER BIT STUFF

reg3_in(12+4) <= accumulate_reset_lower_temp;
reg3_in(12+4+1) <= accumulate_reset_upper_temp;
reg3_in(12+4+2) <= upper_is_max_temp;

	comp2: compdm
		generic map(width => 12+4+3)
		port map(
			a => reg3_in,
			ki => comp3_out,
			rst => reset,
			sleep => comp1_out,
			ko => comp2_out);


	reg3: regs_gen_zero_res
		generic map(width => 12+4+3)
		port map(
			d => reg3_in,
			q => reg3_out,
			reset => reset,
			sleep => comp2_out);

	comp3: compm
		generic map(width => 12+4+3)
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
		generic map(width => 12+4+3)
		port map(
			d => reg3_out,
			q => reg4_out,
			reset => reset,
			sleep => comp3_out);

reg5_in(12+4) <= reg4_out(12+4);
reg5_in(12+4+1) <= reg4_out(12+4+1);
reg5_in(12+4+2) <= reg4_out(12+4+2);
reg5_in(12+4-1 downto 0) <= reg4_out(12+4-1 downto 0);


	comp4: compm
		generic map(width => 12+4+3)
		port map(
			a => reg5_in,
			ki => comp1_out,
			rst => reset,
			sleep => comp3_out,
			ko => comp4_out);

	reg5: regs_gen_null_res
		generic map(width => 12+4+3)
		port map(
			d => reg5_in,
			q => reg5_out,
			reset => reset,
			sleep => comp4_out);

z <= reg4_out(12+3 downto 0);
reg2_in <= reg5_out(12+4+1 downto 0);
ko <= comp1_out;
sleep_out <= comp3_out;
accumulate_reset_lower <= reg4_out(12+4);
accumulate_reset_upper <= reg4_out(12+4+1);
upper_is_max <= reg4_out(12+4+2);

end arch_memWriteCounter;
