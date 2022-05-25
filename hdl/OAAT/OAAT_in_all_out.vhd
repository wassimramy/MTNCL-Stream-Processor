library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;

entity OAAT_in_all_out is
	generic( bitwidth : integer := 16;
		 numInputs : integer := 64;
		 counterWidth : integer := 6; --Log2 of numInputs
		 delay_amount : integer := 6);
	port(	 

		a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
		sleep_in: in std_logic;
		reset: in std_logic;
		ki: in std_logic;
		ko: out std_logic;
		sleep_out: out std_logic;
		z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0)
	);
end OAAT_in_all_out;

architecture arch_OAAT_in_all_out of OAAT_in_all_out is

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

	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;


	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;


	component th22m_en_gen is
		generic(bitwidth : integer);
		port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
			en : in std_logic;
			sleep : std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component decoder_gen is
		generic(bitwidth: integer);
		port(a: in dual_rail_logic_vector(bitwidth-1 downto 0);
			sleep : in std_logic;
			z : out dual_rail_logic_vector(2**bitwidth-1 downto 0));
	end component;

	component th23w2m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 c: in std_logic;
			 s: in std_logic;
			 z: out std_logic ); 
	end component; 

	component reg_null_res is
	   port(d: in dual_rail_logic;
			reset: in std_logic;
			sleep: in std_logic;
			q: out dual_rail_logic);
	end component;

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

	component and2_a is
		port(a, b : in  std_logic;
			 z : out std_logic);
	end component;

	component or2_a is
		port(a, b : in  std_logic;
			 z : out std_logic);
	end component;

	component th22n_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 rst: in std_logic; 
			 z: out std_logic); 
	end component; 



component BUFFER_C is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end component; 


signal comp_z_out, comp_a_out, counter_ko, counter_sleep_out, en_sleep, not_comp_z_ki, not_max, sleep_reset, not_ko, comp_z_ki, ki_and_ko : std_logic;
signal reg_a_out : dual_rail_logic_vector(bitwidth-1 downto 0);
signal comp_z_in : dual_rail_logic_vector(bitwidth+counterwidth downto 0);
signal count : dual_rail_logic_vector(counterWidth-1 downto 0);
signal count_1hot : dual_rail_logic_vector(2**counterWidth-1 downto 0);
signal accumulate_reset, reg_max_out : dual_rail_logic;
signal reg_i_in : dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
signal regsleeps, regsleeps_not : std_logic_vector(numInputs-1 downto 0);
signal comp_z_out_delay_ko, comp_z_out_a, comp_z_out_b : std_logic;
signal comp_z_out_delay : std_logic_vector(delay_amount downto 0);


begin

ko <= comp_a_out;
	comp_a: compm
		generic map(width => bitwidth)
		port map(
			a => a,
			ki => comp_z_out_delay_ko, --comp_z_out,
			rst => reset,
			sleep => sleep_in,
			ko => comp_a_out);


	reg_a: regs_gen_null_res
		generic map(width => bitwidth)
		port map(
			d => a,
			q => reg_a_out,
			reset => reset,
			sleep => comp_a_out);

	count_unit : counter_selfReset
		generic map(width => counterWidth)
		port map(reset_count => reset_count,
			sleep_in => '0',
			 reset => reset,
			 ki => comp_z_out_delay_ko, --comp_z_out,
			 ko => counter_ko,
			 sleep_out => counter_sleep_out,
			 accumulate_reset => accumulate_reset,
			 z => count);

decoder : decoder_gen
	generic map(bitwidth => counterWidth)
	port map(a => count,
		sleep => counter_sleep_out,
		z => count_1hot);

register_gen : for i in 0 to numInputs-1 generate
	
	th22m_en_i : th22m_en_gen
		generic map(bitwidth => bitwidth)
		port map(a  => reg_a_out,
			en => count_1hot(i).rail1,
			sleep => comp_a_out,
			z => reg_i_in(bitwidth*(i+1)-1 downto bitwidth*(i)));

	th23w2_i : th23w2m_a
		port map(a => regsleeps_not(i),
			b => count_1hot(i).rail1, 
			c => not_ko,
			s => sleep_reset,
			z => regsleeps_not(i));


	sleep_inv_i : inv_a
		port map(a => regsleeps_not(i),
			z => regsleeps(i));

	reg_i : regs_gen_null_res
		generic map(width => bitwidth)
		port map(
			d => reg_i_in(bitwidth*(i+1)-1 downto bitwidth*(i)),
			q => z(bitwidth*(i+1)-1 downto bitwidth*(i)),
			reset => reset,
			sleep => regsleeps(i));
end generate;


reg_max : reg_null_res
   port map(d => accumulate_reset,
		reset => reset,
		sleep => comp_z_out,
		q => reg_max_out);

comp_z_in(bitwidth-1 downto 0) <= reg_a_out;
comp_z_in(bitwidth) <= accumulate_reset;
comp_z_in(bitwidth+counterWidth downto bitwidth+1) <= count;

	comp_z_a: compm
		generic map(width => bitwidth)
		port map(
			a => comp_z_in(bitwidth-1 downto 0),
			ki => comp_z_ki,
			rst => reset,
			sleep => comp_a_out,
			ko => comp_z_out_a);

	comp_z_b: compm
		generic map(width => counterWidth+1)
		port map(
			a => comp_z_in(bitwidth+counterWidth downto bitwidth),
			ki => comp_z_ki,
			rst => reset,
			sleep => comp_a_out,
			ko => comp_z_out_b);

	compz_out_gate: th22n_a
		port map(
			a => comp_z_out_a,
			b => comp_z_out_b,
			rst => reset,
			z => comp_z_out);

comp_z_out_delay(0) <= comp_z_out;
gen_comp_z_out_delay : for i in 0 to delay_amount-1 generate
	delay_comp_z_i : BUFFER_C
		port map(A => comp_z_out_delay(i),
			Z => comp_z_out_delay(i+1));
end generate;

	delay_comp_z_final : BUFFER_C
		port map(A => comp_z_out_delay(delay_amount),
			Z => comp_z_out_delay_ko);

	inv_not_max : inv_a
		port map(a => reg_max_out.rail0,
			z => not_max);

	and_z_ki : and2_a
		port map(a => not_max,
			b => ki,
			z => comp_z_ki);

	inv_comp_z_ki : inv_a
		port map(a => ki,
			z => not_comp_z_ki);

	and_kiko : and2_a
		port map(a => not_comp_z_ki,
			b => comp_z_out,
			z => ki_and_ko);

	sleep_reset_gate : or2_a
		port map(a => reset,
			b => ki_and_ko,
			z => sleep_reset);

	ko_inv : inv_a
		port map(a => comp_z_out,
			z => not_ko);

	sleepOut_gen : inv_a
		port map(a => accumulate_reset.rail1,
			z => sleep_out);

end arch_OAAT_in_all_out;
