
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity wrap_elem_mult_8 is
	port(a: in dual_rail_logic_vector(7 downto 0);
		b: in dual_rail_logic_vector(7 downto 0);
		reset : in std_logic;
		sleep_in_a : in std_logic;
		sleep_in_b : in std_logic;
		trunc : in dual_rail_logic_vector(2 downto 0);
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(7 downto 0));
end wrap_elem_mult_8;


architecture behavioral of wrap_elem_mult_8 is

	component BUFFER_C is 
		port(A: in std_logic; 
			 Z: out std_logic); 
	end component; 

	component BUFFER_A is 
		port(A: in std_logic; 
			 Z: out std_logic); 
	end component; 

--MAIN DESIGN BLOCK
component elem_mult_8 is
	port(a: in dual_rail_logic_vector(7 downto 0);
		b: in dual_rail_logic_vector(7 downto 0);
		reset : in std_logic;
		sleep_in_a : in std_logic;
		sleep_in_b : in std_logic;
		trunc : in dual_rail_logic_vector(2 downto 0);
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(7 downto 0));
end component;



--Signal Declarations
signal a_buf, b_buf, z_buf : dual_rail_logic_vector(7 downto 0);
signal trunc_buf : dual_rail_logic_vector(2 downto 0);
signal reset_buf, sleep_in_a_buf, sleep_in_b_buf, ki_buf, ko_buf, sleep_out_buf  : std_logic;

begin

gen_a : for i in 0 to 7 generate
	buffer_a_0_i : BUFFER_A
		port map(A => a(i).rail0,
			Z => a_buf(i).rail0);
	buffer_a_1_i : BUFFER_A
		port map(A => a(i).rail1,
			Z => a_buf(i).rail1);
end generate;

gen_b : for i in 0 to 7 generate
	buffer_b_0_i : BUFFER_A
		port map(A => b(i).rail0,
			Z => b_buf(i).rail0);
	buffer_b_1_i : BUFFER_A
		port map(A => b(i).rail1,
			Z => b_buf(i).rail1);
end generate;

gen_trunc : for i in 0 to 2 generate
	buffer_trunc_0_i : BUFFER_A
		port map(A => trunc(i).rail0,
			Z => trunc_buf(i).rail0);
	buffer_trunc_1_i : BUFFER_A
		port map(A => trunc(i).rail1,
			Z => trunc_buf(i).rail1);
end generate;

buffer_reset : BUFFER_A
	port map(A => reset,
		Z => reset_buf);

buffer_sleep_in_a : BUFFER_A
	port map(A => sleep_in_a,
		Z => sleep_in_a_buf);

buffer_sleep_in_b : BUFFER_A
	port map(A => sleep_in_b,
		Z => sleep_in_b_buf);

buffer_ki : BUFFER_A
	port map(A => ki,
		Z => ki_buf);

adder : elem_mult_8
	port map(a => a_buf,
		b => b_buf,
		reset => reset_buf,
		sleep_in_a => sleep_in_a_buf,
		sleep_in_b => sleep_in_b_buf,
		trunc => trunc_buf,
		ki => ki_buf,
		ko  => ko_buf,
		sleep_out => sleep_out_buf,
		z => z_buf);

buffer_ko : BUFFER_C
	port map(A => ko_buf,
		Z => ko);

buffer_sleep_out : BUFFER_C
	port map(A => sleep_out_buf,
		Z => sleep_out);

gen_z : for i in 0 to 7 generate
	buffer_z_0_i : BUFFER_C
		port map(A => z_buf(i).rail0,
			Z => z(i).rail0);
	buffer_z_1_i : BUFFER_C
		port map(A => z_buf(i).rail1,
			Z => z(i).rail1);
end generate;


end behavioral;
