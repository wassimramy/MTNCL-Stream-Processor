

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity Add_of_checkV2 is
	generic(bitwidth : integer);
	port(a : in dual_rail_logic_vector(bitwidth downto 0);
		sign_bits : in dual_rail_logic_vector(1 downto 0);
		sleep : in std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end Add_of_checkV2;



architecture arch_Add_of_checkV2 of Add_of_checkV2 is 

	component thxor0m_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 c: in std_logic; 
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic ); 
	end component; 

component inv_a is
	port(a : in  std_logic;
		 z : out std_logic);
end component;


signal overflow : dual_rail_logic;
signal correct_sign : dual_rail_logic;
signal inversion : dual_rail_logic;
signal same_sign : dual_rail_logic;


begin 


--correct_sign.rail1 <= a(bitwidth).rail1;
--correct_sign.rail0 <= a(bitwidth).rail0;
ss_1_thxor : thxor0m_a
	port map(
		a => sign_bits(1).rail1,
		b => sign_bits(0).rail1,
		c => sign_bits(0).rail0,
		d => sign_bits(1).rail0,
		s => sleep,
		z => same_sign.rail1);
ss_0_thxor : thxor0m_a
	port map(
		a => sign_bits(1).rail1,
		b => sign_bits(0).rail0,
		c => sign_bits(0).rail1,
		d => sign_bits(1).rail0,
		s => sleep,
		z => same_sign.rail0);

cs_1_thxor : thxor0m_a
	port map(
		a => same_sign.rail1,
		b => a(bitwidth).rail1,
		c => same_sign.rail0,
		d => a(bitwidth-1).rail1,
		s => sleep,
		z => correct_sign.rail1);
cs_0_thxor : thxor0m_a
	port map(
		a => same_sign.rail1,
		b => a(bitwidth).rail0,
		c => same_sign.rail0,
		d => a(bitwidth-1).rail0,
		s => sleep,
		z => correct_sign.rail0);





of_1_thxor : thxor0m_a
	port map(
		a => correct_sign.rail1,
		b => a(bitwidth-1).rail0,
		c => correct_sign.rail0,
		d => a(bitwidth-1).rail1,
		s => sleep,
		z => overflow.rail1);
of_0_thxor : thxor0m_a
	port map(
		a => correct_sign.rail1,
		b => a(bitwidth-1).rail1,
		c => correct_sign.rail0,
		d => a(bitwidth-1).rail0,
		s => sleep,
		z => overflow.rail0);


generate_output_nonSignBits : for i in 0 to bitwidth-2 generate
	nsb_thxor_1_i : thxor0m_a
		port map(
			a => overflow.rail1,
			b => correct_sign.rail0,
			c => overflow.rail0,
			d => a(i).rail1,
			s => sleep,
			z => z(i).rail1);

	nsb_thxor_0_i : thxor0m_a
		port map(
			a => overflow.rail0,
			b => a(i).rail0,
			c => overflow.rail1,
			d => correct_sign.rail1,
			s => sleep,
			z => z(i).rail0);

end generate;


--z(bitwidth-1).rail1 <= correct_sign.rail1;
--z(bitwidth-1).rail0 <= correct_sign.rail0;
--FIX CADENCE PROBLEM

inv_1 : inv_a
	port map(a => correct_sign.rail1,
		 z => inversion.rail1);

inv_2 : inv_a
	port map(a => correct_sign.rail0,
		 z => inversion.rail0);

inv_3 : inv_a
	port map(a => inversion.rail1,
		 z => z(bitwidth-1).rail1);

inv_4 : inv_a
	port map(a => inversion.rail0,
		 z => z(bitwidth-1).rail0);




end arch_Add_of_checkV2; 