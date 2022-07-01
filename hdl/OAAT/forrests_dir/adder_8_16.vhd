
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity adder_8_16 is
	port(a: in dual_rail_logic_vector(15 downto 0);
		b: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset : in std_logic;
		sleep_in_a : in std_logic;
		sleep_in_b : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(15 downto 0));
end adder_8_16;


architecture behavioral of adder_8_16 is

--MAIN DESIGN BLOCKS


	component wrap_elem_adder_8 is
		generic(bitwidth: integer := 8);
		port(a: in dual_rail_logic_vector(bitwidth-1 downto 0);
			b: in dual_rail_logic_vector(bitwidth-1 downto 0);
			reset : in std_logic;
			sleep_in_a : in std_logic;
			sleep_in_b : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_out : out std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component compm_half_sel is
		generic(half_width: in integer := 4);
		port(a: in dual_rail_logic_vector(half_width*2-1 downto 0);
			 sel: in std_logic;
			 ki: in std_logic;
			 rst: in std_logic;
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

	component wrap_elem_adder is
		generic(bitwidth: integer := 16);
		port(a: in dual_rail_logic_vector(bitwidth-1 downto 0);
			b: in dual_rail_logic_vector(bitwidth-1 downto 0);
			reset : in std_logic;
			sleep_in_a : in std_logic;
			sleep_in_b : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_out : out std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;

	component mux_21_nic is
	    port(a: in dual_rail_logic;
		 	 b: in dual_rail_logic;
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic);
	end component;

	component mux_21_gen_nic is
		generic(width: integer);
	    port(a: in dual_rail_logic_vector(width-1 downto 0);
		 	 b: in dual_rail_logic_vector(width-1 downto 0);
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component th22d_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 rst: in std_logic; 
			 z: out std_logic); 
	end component; 

component MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end component; 

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

component or2_a is 
	port(a: in std_logic; 
		b: in std_logic;
		 z: out std_logic); 
end component; 

--Signal Declarations
signal input_reg_in, input_reg_out : dual_rail_logic_vector(31 downto 0);
signal reg_out_in, adder_out, adder_16_out, adder_8_out : dual_rail_logic_vector(15 downto 0);
signal sleep_in, input_reg_sleep_a, input_reg_sleep_b, input_reg_sleep, comp_out_out, adder_ko, adder_8_ko, adder_16_ko, adder_sleep_out, adder_8_sleep_out, adder_16_sleep_out : std_logic;
signal RCF_width_dr : dual_rail_logic;
signal add_out : dual_rail_logic_vector(15 downto 0);

signal sleep_in_8, sleep_in_16 : std_logic;


begin

	RCF_width_r0_gate : inv_a
		port map(a => RCF_width,
			 z => RCF_width_dr.rail0);

RCF_0_or : or2_a
	port map(a => RCF_width_dr.rail0,
		b => input_reg_sleep,
		 z => sleep_in_16); 

RCF_width_dr.rail1 <= RCF_width;

RCF_1_or : or2_a
	port map(a => RCF_width_dr.rail1, 
		b => input_reg_sleep,
		 z => sleep_in_8); 

input_reg_in(15 downto 0) <= a;
input_reg_in(31 downto 16) <= b;


	sleep_in_calc : th22d_a
		port map(a => sleep_in_a,
			 b => sleep_in_b,
			 rst => reset,
			 z => sleep_in);


	input_reg_sleep_calc : th22d_a
		port map(a => input_reg_sleep_a,
			 b => input_reg_sleep_b,
			 rst => reset,
			 z => input_reg_sleep);

ko <= input_reg_sleep; 

	comp_in_a: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => input_reg_in(15 downto 0),
			sel => RCF_width,
			ki => adder_ko,
			rst => reset,
			sleep => sleep_in,
			ko => input_reg_sleep_a);

	comp_in_b: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => input_reg_in(31 downto 16),
			sel => RCF_width,
			ki => adder_ko,
			rst => reset,
			sleep => sleep_in,
			ko => input_reg_sleep_b);

	input_reg: regs_gen_null_res
		generic map(width => 32)
		port map(
			d => input_reg_in,
			q => input_reg_out,
			reset => reset,
			sleep => input_reg_sleep);



	adder_8 : wrap_elem_adder_8
		generic map(bitwidth => 8)
		port map(a => input_reg_out(15 downto 8),
			b => input_reg_out(31 downto 24),
			reset => reset,
			sleep_in_a => sleep_in_8,
			sleep_in_b => sleep_in_8,
			ki => comp_out_out,
			ko => adder_8_ko,
			sleep_out => adder_8_sleep_out,
			z => adder_8_out(15 downto 8));

gen_add_8_out_low : for i in 0 to 7 generate
	adder_8_out(i).rail0 <= '0';
	adder_8_out(i).rail1 <= '0';
end generate;

	adder_16 : wrap_elem_adder
		generic map(bitwidth => 16)
		port map(a => input_reg_out(15 downto 0),
			b => input_reg_out(31 downto 16),
			reset => reset,
			sleep_in_a => sleep_in_16,
			sleep_in_b => sleep_in_16,
			ki => comp_out_out,
			ko => adder_16_ko,
			sleep_out => adder_16_sleep_out,
			z => adder_16_out);

	--MUXES FOR ADDER_OUT, ADDER_KO, ADDER_SLEEP_OUT

	adder_sleep_out_mux : MUX21_A
	    port map(A => adder_8_sleep_out,
		 	B => adder_16_sleep_out,
			S => RCF_width,
			 Z => adder_sleep_out);

	adder_ko_mux : MUX21_A
	    port map(A => adder_8_ko,
		 	 B => adder_16_ko,
			S => RCF_width,
			 Z => adder_ko);


	adder_out_mux : mux_21_gen_nic
		generic map(width => 16)
	    	port map(a => adder_8_out,
		 	 b => adder_16_out,
			sel =>  RCF_width_dr,
			 sleep => adder_sleep_out,
			 z => adder_out);

	comp_out: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => adder_out,
			sel => RCF_width,
			ki => ki,
			rst => reset,
			sleep => adder_sleep_out,
			ko => comp_out_out);

	reg_out: regs_gen_null_res
		generic map(width => 16)
		port map(
			d => adder_out,
			q => z,
			reset => reset,
			sleep => comp_out_out);

sleep_out <= comp_out_out;


end behavioral;
