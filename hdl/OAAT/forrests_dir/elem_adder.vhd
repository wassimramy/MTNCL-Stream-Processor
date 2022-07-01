
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity elem_adder is
	generic(bitwidth: integer);
	port(a: in dual_rail_logic_vector(bitwidth-1 downto 0);
		b: in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset : in std_logic;
		sleep_in_a : in std_logic;
		sleep_in_b : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
end elem_adder;


architecture behavioral of elem_adder is

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

	component th22d_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 rst: in std_logic; 
			 z: out std_logic); 
	end component; 

	component and2_a is 
		port(a: in std_logic; 
			b : in std_logic;
			 z: out std_logic); 
	end component; 

	component adder_gen is
		generic(width: integer);
    		port(a: in dual_rail_logic_vector(width-1 downto 0);
	 		 b: in dual_rail_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 sum: out dual_rail_logic_vector(width-1 downto 0);
			 cout: out dual_rail_logic);
	end component;

	component Add_of_checkV2 is
		generic(bitwidth : integer);
		port(a : in dual_rail_logic_vector(bitwidth downto 0);
			sign_bits : in dual_rail_logic_vector(1 downto 0);
			sleep : in std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0)
		);
	end component;



--Signal Declarations
signal input_reg_in, input_reg_out : dual_rail_logic_vector(2*bitwidth-1 downto 0);
signal reg_out_in : dual_rail_logic_vector(bitwidth-1 downto 0);
signal sleep_in, input_reg_sleep_a, input_reg_sleep_b, input_reg_sleep, comp_out_out : std_logic;

signal add_out : dual_rail_logic_vector(bitwidth downto 0);
signal sign_bits : dual_rail_logic_vector(1 downto 0);





begin
input_reg_in(bitwidth-1 downto 0) <= a;
input_reg_in(bitwidth*2-1 downto bitwidth) <= b;


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

	comp_in_a: compm
		generic map(width => bitwidth)
		port map(
			a => input_reg_in(bitwidth-1 downto 0),
			ki => comp_out_out,
			rst => reset,
			sleep => sleep_in,
			ko => input_reg_sleep_a);

	comp_in_b: compm
		generic map(width => bitwidth)
		port map(
			a => input_reg_in(bitwidth*2-1 downto bitwidth),
			ki => comp_out_out,
			rst => reset,
			sleep => sleep_in,
			ko => input_reg_sleep_b);

	input_reg: regs_gen_null_res
		generic map(width => bitwidth*2)
		port map(
			d => input_reg_in,
			q => input_reg_out,
			reset => reset,
			sleep => input_reg_sleep);


	adder : adder_gen
		generic map(width => bitwidth)
    		port map(a => input_reg_out(bitwidth-1 downto 0),
	 		 b => input_reg_out(bitwidth*2-1 downto bitwidth),
			 sleep => input_reg_sleep,
			 sum => add_out(bitwidth-1 downto 0),
			 cout => add_out(bitwidth));

	sign_bits(0) <= input_reg_out(bitwidth-1);
	sign_bits(1) <= input_reg_out(bitwidth*2-1);

	add_of_check : Add_of_checkV2 
		generic map(bitwidth => bitwidth)
		port map(a => add_out,
			sign_bits => sign_bits,
			sleep => input_reg_sleep,
			z => reg_out_in
		);

	comp_out: compm
		generic map(width => bitwidth)
		port map(
			a => reg_out_in,
			ki => ki,
			rst => reset,
			sleep => input_reg_sleep,
			ko => comp_out_out);

	reg_out: regs_gen_null_res
		generic map(width => bitwidth)
		port map(
			d => reg_out_in,
			q => z,
			reset => reset,
			sleep => comp_out_out);

sleep_out <= comp_out_out;


end behavioral;
