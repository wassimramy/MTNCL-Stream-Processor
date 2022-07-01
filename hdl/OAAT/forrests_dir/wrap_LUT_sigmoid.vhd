
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity wrap_LUT_sigmoid is
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
end wrap_LUT_sigmoid;


architecture behavioral of wrap_LUT_sigmoid is

	component BUFFER_C is 
		port(A: in std_logic; 
			 Z: out std_logic); 
	end component; 

	component BUFFER_A is 
		port(A: in std_logic; 
			 Z: out std_logic); 
	end component; 

--MAIN DESIGN BLOCK

component LUT_sigmoid is
	generic(bitwidth : integer;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 109);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(address : in dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep_in : in std_logic;
		reset : in std_logic;
		ki : in std_logic;
		sleep_out : out std_logic;
		ko : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end component;



--Signal Declarations
signal address_buf, z_buf : dual_rail_logic_vector(bitwidth-1 downto 0);
signal reset_buf, sleep_in_buf, ki_buf, ko_buf, sleep_out_buf  : std_logic;

begin

gen_address : for i in 0 to bitwidth-1 generate
	buffer_address_0_i : BUFFER_A
		port map(A => address(i).rail0,
			Z => address_buf(i).rail0);
	buffer_address_1_i : BUFFER_A
		port map(A => address(i).rail1,
			Z => address_buf(i).rail1);
end generate;


buffer_reset : BUFFER_A
	port map(A => reset,
		Z => reset_buf);

buffer_sleep_in : BUFFER_A
	port map(A => sleep_in,
		Z => sleep_in_buf);


buffer_ki : BUFFER_A
	port map(A => ki,
		Z => ki_buf);


LUT : LUT_sigmoid
	generic map(bitwidth => 16,
		clock_delay => 16,		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay => 109)		--ADD DELAY FOR INCREASED MEMORY DELAY
	port map(address => address_buf,
		sleep_in => sleep_in,
		reset => reset_buf,
		ki => ki_buf,
		sleep_out => sleep_out_buf,
		ko  => ko_buf,
		z => z_buf
	);

buffer_ko : BUFFER_C
	port map(A => ko_buf,
		Z => ko);

buffer_sleep_out : BUFFER_C
	port map(A => sleep_out_buf,
		Z => sleep_out);

gen_z : for i in 0 to bitwidth-1 generate
	buffer_z_0_i : BUFFER_C
		port map(A => z_buf(i).rail0,
			Z => z(i).rail0);
	buffer_z_1_i : BUFFER_C
		port map(A => z_buf(i).rail1,
			Z => z(i).rail1);
end generate;


end behavioral;
