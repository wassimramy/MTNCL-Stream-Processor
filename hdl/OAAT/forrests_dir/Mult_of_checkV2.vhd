
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity mult_of_checkV2 is
	generic(bitwidth_in : integer;
		bitwidth_out : integer);
	port(a : in dual_rail_logic_vector(bitwidth_in-1 downto 0);
		sign_bits : in dual_rail_logic_vector(1 downto 0);
		sleep : in std_logic;
		z : out dual_rail_logic_vector(bitwidth_out-1 downto 0)
	);
end mult_of_checkV2;



architecture arch_mult_of_checkV2 of mult_of_checkV2 is 

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

signal same_bits : dual_rail_logic_vector(3 downto 0);
signal overflow : dual_rail_logic;
signal correct_sign : dual_rail_logic;
signal and_tree_in, or_tree_in : std_logic_vector(3 downto 0);

begin 

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

generate_xor: for i in 0 to 2 generate

	thxor_i	: thxor0m_a
		port map(
			a => a(bitwidth_in-i-1).rail1,
			b => a(bitwidth_in-i-2).rail1,
			c => a(bitwidth_in-i-1).rail0,
			d => a(bitwidth_in-i-2).rail0,
			s => sleep,
			z => same_bits(i).rail1);

	thxnor_i	: thxor0m_a
		port map(
			a => a(bitwidth_in-i-1).rail0,
			b => a(bitwidth_in-i-2).rail1,
			c => a(bitwidth_in-i-1).rail1,
			d => a(bitwidth_in-i-2).rail0,
			s => sleep,
			z => same_bits(i).rail0);

end generate;

generate_tree_sigs : for i in 0 to 3 generate
	and_tree_in(i) <= same_bits(i).rail1;
	or_tree_in(i) <= same_bits(i).rail0;

end generate;

xor_correct_sign_check : thxor0m_a
		port map(
			a => correct_sign.rail1,
			b => a(bitwidth_in-1).rail1,
			c => correct_sign.rail0,
			d => a(bitwidth_in-1).rail0,
			s => sleep,
			z => same_bits(3).rail1);

xnor_correct_sign_check : thxor0m_a
		port map(
			a => correct_sign.rail0,
			b => a(bitwidth_in-1).rail1,
			c => correct_sign.rail1,
			d => a(bitwidth_in-1).rail0,
			s => sleep,
			z => same_bits(3).rail0);

and_tree : andtreem
		generic map(width => 4)
		port map(
			a => and_tree_in,
			sleep => sleep,
			ko => overflow.rail0);

or_tree : ortreem
		generic map(width => 4)
		port map(
			a => or_tree_in,
			sleep => sleep,
			ko => overflow.rail1);
			
generate_output_nonSignBits : for i in 0 to bitwidth_out-2 generate
	nsb_thxor_1_i : thxor0m_a
		port map(
			a => overflow.rail1,
			b => correct_sign.rail0,
			c => overflow.rail0,
			d => a(i+13).rail1,
			s => sleep,
			z => z(i).rail1);

	nsb_thxor_0_i : thxor0m_a
		port map(
			a => overflow.rail0,
			b => a(i+13).rail0,
			c => overflow.rail1,
			d => correct_sign.rail1,
			s => sleep,
			z => z(i).rail0);

end generate;


z(bitwidth_out-1).rail1 <= correct_sign.rail1;
z(bitwidth_out-1).rail0 <= correct_sign.rail0;



end arch_mult_of_checkV2; 
