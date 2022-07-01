
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;
use ieee.math_real.all;

entity mult_of_check_8 is
	port(a : in dual_rail_logic_vector(15 downto 0);
		sign_bits : in dual_rail_logic_vector(1 downto 0);
		trunc : in dual_rail_logic_vector(2 downto 0);
		sleep : in std_logic;
		z : out dual_rail_logic_vector(7 downto 0)
	);
end mult_of_check_8;



architecture arch_mult_of_check_8 of mult_of_check_8 is 

	component thxor0m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

	component th12m_a
		port(a: in std_logic;
			 b: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

	component th22m_a
		port(a: in std_logic;
			 b: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

	component mux_nto1_gen is
		generic(bitwidth: integer := 16;
			numInputs : integer := 64);
	    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

signal same_bits, mux_out, overflow : dual_rail_logic_vector(8 downto 0);
signal correct_sign : dual_rail_logic;
signal and_tree_in, or_tree_in : std_logic_vector(8 downto 0);
signal mux_in : dual_rail_logic_vector(8*9-1 downto 0);
signal trunc_reverse : dual_rail_logic_vector(2 downto 0);

begin 

trunc_reverse(0).rail0 <= trunc(0).rail1;
trunc_reverse(0).rail1 <= trunc(0).rail0;
trunc_reverse(1).rail0 <= trunc(1).rail1;
trunc_reverse(1).rail1 <= trunc(1).rail0;
trunc_reverse(2).rail0 <= trunc(2).rail1;
trunc_reverse(2).rail1 <= trunc(2).rail0;

xor_correct_sign : thxor0m_a
		port map(
			a => sign_bits(0).rail1,
			b => sign_bits(1).rail1,
			c => sign_bits(0).rail0,
			d => sign_bits(1).rail0,
			s => sleep,
			z => correct_sign.rail0);

xnor_correct_sign : thxor0m_a
		port map(
			a => sign_bits(0).rail0,
			b => sign_bits(1).rail1,
			c => sign_bits(0).rail1,
			d => sign_bits(1).rail0,
			s => sleep,
			z => correct_sign.rail1);

generate_xor: for i in 0 to 7 generate

	thxor_i	: thxor0m_a
		port map(
			a => a(15-i).rail1,
			b => a(14-i).rail1,
			c => a(15-i).rail0,
			d => a(14-i).rail0,
			s => sleep,
			z => same_bits(i+1).rail1);

	thxnor_i	: thxor0m_a
		port map(
			a => a(15-i).rail0,
			b => a(14-i).rail1,
			c => a(15-i).rail1,
			d => a(14-i).rail0,
			s => sleep,
			z => same_bits(i+1).rail0);

end generate;

xor_correct_sign_check : thxor0m_a
		port map(
			a => correct_sign.rail1,
			b => a(15).rail1,
			c => correct_sign.rail0,
			d => a(15).rail0,
			s => sleep,
			z => same_bits(0).rail1);

xnor_correct_sign_check : thxor0m_a
		port map(
			a => correct_sign.rail0,
			b => a(15).rail1,
			c => correct_sign.rail1,
			d => a(15).rail0,
			s => sleep,
			z => same_bits(0).rail0);

generate_tree_sigs : for i in 0 to 8 generate
	and_tree_in(i) <= same_bits(i).rail1;
	or_tree_in(i) <= same_bits(i).rail0;

end generate;
overflow(0).rail0 <= same_bits(0).rail1;
overflow(0).rail1 <= same_bits(0).rail0;

gen_of_detect : for i in 0 to 6 generate
	th22m_i : th22m_a
		port map(a => overflow(i).rail0,
			b => and_tree_in(i+1),
			s => sleep,
			z => overflow(i+1).rail0);

	th12m_i : th12m_a
		port map(a => overflow(i).rail1,
			b => or_tree_in(i+1),
			s => sleep,
			z => overflow(i+1).rail1);
end generate;

gen_mux_in : for i in 0 to 7 generate
	mux_in(((i+1)*9)-2 downto i*9) <= a((i+8) downto i+1);
	mux_in(((i+1)*9)-1) <= overflow(7-i);
end generate;

--CHECK MUX
	mux : mux_nto1_gen
		generic map(bitwidth => 9,
			numInputs => 8)
	    port map(a => mux_in,
			sel => trunc,
			 sleep => sleep,
			 z => mux_out);

generate_output_nonSignBits : for i in 0 to 6 generate
	nsb_thxor_1_i : thxor0m_a
		port map(
			a => mux_out(8).rail1,
			b => correct_sign.rail0,
			c => mux_out(8).rail0,
			d => mux_out(i).rail1,
			s => sleep,
			z => z(i).rail1);

	nsb_thxor_0_i : thxor0m_a
		port map(
			a => mux_out(8).rail0,
			b => mux_out(i).rail0,
			c => mux_out(8).rail1,
			d => correct_sign.rail1,
			s => sleep,
			z => z(i).rail0);

end generate;


z(7).rail1 <= correct_sign.rail1;
z(7).rail0 <= correct_sign.rail0;



end arch_mult_of_check_8; 
