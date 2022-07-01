
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity LUT_sigmoid_8_16 is
	port(a: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset : in std_logic;
		sleep_in : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(15 downto 0));
end LUT_sigmoid_8_16;


architecture behavioral of LUT_sigmoid_8_16 is

--MAIN DESIGN BLOCKS


	component wrap_LUT_sigmoid_8 is
		generic(clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := 109);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(address : in dual_rail_logic_vector(7 downto 0);
			sleep_in : in std_logic;
			reset : in std_logic;
			ki : in std_logic;
			sleep_out : out std_logic;
			ko : out std_logic;
			z : out dual_rail_logic_vector(7 downto 0));
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

	component wrap_LUT_sigmoid is
		generic(bitwidth : integer;
			clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := 109);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(address : in dual_rail_logic_vector(bitwidth-1 downto 0);
			sleep_in : in std_logic;
			reset : in std_logic;
			ki : in std_logic;
			sleep_out : out std_logic;
			ko : out std_logic;
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
signal input_reg_in, input_reg_out : dual_rail_logic_vector(15 downto 0);
signal reg_out_in, LUT_out, LUT_16_out, LUT_8_out : dual_rail_logic_vector(15 downto 0);
signal input_reg_sleep, comp_out_out, LUT_ko, LUT_8_ko, LUT_16_ko, LUT_sleep_out, LUT_8_sleep_out, LUT_16_sleep_out : std_logic;
signal RCF_width_dr : dual_rail_logic;

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

ko <= input_reg_sleep; 

	comp_in_a: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => input_reg_in(15 downto 0),
			sel => RCF_width,
			ki => LUT_ko,
			rst => reset,
			sleep => sleep_in,
			ko => input_reg_sleep);

	input_reg: regs_gen_null_res
		generic map(width => 16)
		port map(
			d => input_reg_in,
			q => input_reg_out,
			reset => reset,
			sleep => input_reg_sleep);

	LUT_sigmoid_8 : wrap_LUT_sigmoid_8
		generic map(clock_delay => 16,	--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay => 109)		--ADD DELAY FOR INCREASED MEMORY DELAY
		port map(address => input_reg_out(15 downto 8),
			sleep_in => sleep_in_8,
			reset => reset,
			ki => comp_out_out,
			sleep_out => LUT_8_sleep_out,
			ko => LUT_8_ko,
			z => LUT_8_out(15 downto 8));

gen_add_8_out_low : for i in 0 to 7 generate
	LUT_8_out(i).rail0 <= '0';
	LUT_8_out(i).rail1 <= '0';
end generate;

	LUT_sigmoid : wrap_LUT_sigmoid
		generic map(bitwidth => 16,
			clock_delay => 16,	--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay => 109)		--ADD DELAY FOR INCREASED MEMORY DELAY
		port map(address => input_reg_out(15 downto 0),
			sleep_in => sleep_in_16,
			reset => reset,
			ki => comp_out_out,
			sleep_out => LUT_16_sleep_out,
			ko => LUT_16_ko,
			z => LUT_16_out(15 downto 0));

	--MUXES FOR ADDER_OUT, ADDER_KO, ADDER_SLEEP_OUT

	adder_sleep_out_mux : MUX21_A
	    port map(A => LUT_8_sleep_out,
		 	B => LUT_16_sleep_out,
			S => RCF_width,
			 Z => LUT_sleep_out);

	adder_ko_mux : MUX21_A
	    port map(A => LUT_8_ko,
		 	 B => LUT_16_ko,
			S => RCF_width,
			 Z => LUT_ko);


	adder_out_mux : mux_21_gen_nic
		generic map(width => 16)
	    	port map(a => LUT_8_out,
		 	 b => LUT_16_out,
			sel =>  RCF_width_dr,
			 sleep => LUT_sleep_out,
			 z => LUT_out);

	comp_out: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => LUT_out,
			sel => RCF_width,
			ki => ki,
			rst => reset,
			sleep => LUT_sleep_out,
			ko => comp_out_out);

	reg_out: regs_gen_null_res
		generic map(width => 16)
		port map(
			d => LUT_out,
			q => z,
			reset => reset,
			sleep => comp_out_out);

sleep_out <= comp_out_out;


end behavioral;
