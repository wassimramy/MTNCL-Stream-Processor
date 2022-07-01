

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity flashAccessGRNN is
	generic(bitwidth : integer := 16;
		delay : integer := 600);
	port( 
		ki : in std_logic;
		reset : in std_logic;
		DO : in std_logic;
		cs : out std_logic;
		clk : out std_logic;
		DIO : out std_logic;
		sleep_out : out std_logic;
		inputReady : out std_logic;
		count_out : out dual_rail_logic_vector(19 downto 0);
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end flashAccessGRNN;



architecture arch_flashAccessGRNN of flashAccessGRNN is 

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

component BUFFER_C is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end component; 

component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component th12nm_a is
	port(a : in std_logic;
		b : in std_logic;
		rst : in std_logic;
		s : in std_logic;
		z : out std_logic);
end component;

component inv_a is
	port(a : in std_logic;
		z : out std_logic);
end component;

component SDC_w_EN is
	generic(bitwidth : integer);
	port(a : in std_logic_vector(bitwidth-1 downto 0);
		en : in std_logic;
		sleep : std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component shiftRegister is
	generic(bitwidth : integer);
	port(D : in std_logic;
		reset : in std_logic;
		clk : in std_logic;
		Q : out std_logic_vector(bitwidth-1 downto 0));
end component;

component th22m_en_gen is
	generic(bitwidth : integer);
	port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		en : in std_logic;
		sleep : std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component th22n_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 rst: in std_logic; 
		 z: out std_logic); 
end component; 

signal clk_temp, counter_ko, counter_ki, DIO_pre, DIO_pre1, counter32, inv_clk, clk_inv, clk_no_control, notki, kiHasBeenZero, not16andhasBeenZero, kiHasBeenZero_not, counter16_kiHasNotBeenZero, sdc_en, clk_control, clk_temp_pre, counter_sleep_out, setOfSixteen01_1, setOfSixteen23_1, setOfSixteen01_0, setOfSixteen23_0, counter32EX, clk_and_32, sleep_out_temp, counter_ki_temp, sdc_en_temp, sdc_en_and_ki, counter_ki_pre, inputReady_temp : std_logic;
signal shift_reg_out, bits_out : std_logic_vector(15 downto 0);
signal accumulate_reset, data0, data1, setOfSixteen : dual_rail_logic;
signal counter_bits : dual_rail_logic_vector(19 downto 0);
signal const_723136 : dual_rail_logic_vector(19 downto 0);

signal inv_clk_delay: std_logic_vector(delay-1 downto 0);
signal clk_inv_delay : std_logic_vector(19 downto 0);

begin 

data0.rail0 <= '1';
data0.rail1 <= '0';
data1.rail0 <= '0';
data1.rail1 <= '1';


--CHANGE COUNT
const_723136(0) <= data0;
const_723136(1) <= data0;
const_723136(2) <= data0;
const_723136(3) <= data0;
const_723136(4) <= data0;
const_723136(5) <= data0;
const_723136(6) <= data1;
const_723136(7) <= data1;
const_723136(8) <= data0;
const_723136(9) <= data0;
const_723136(10) <= data0;
const_723136(11) <= data1;
const_723136(12) <= data0;
const_723136(13) <= data0;
const_723136(14) <= data0;
const_723136(15) <= data0;
const_723136(16) <= data1;
const_723136(17) <= data1;
const_723136(18) <= data0;
const_723136(19) <= data1;

counter : counter_selfReset
	generic map(width => 20)
	port map( reset_count => const_723136,
		sleep_in => '0',
		 reset => reset,
		 ki => counter_ki,
		 ko => counter_ko,
		 sleep_out => counter_sleep_out,
		 accumulate_reset => accumulate_reset,
		 z => counter_bits);

counter32_gate : th12nm_a
	port map(a => counter_bits(5).rail1,
		b => counter32,
		rst => reset,
		s => '0',
		z => counter32);

inputReady_gate : th12nm_a
	port map(a => accumulate_reset.rail1,
		b => inputReady_temp,
		rst => reset,
		s => '0',
		z => inputReady_temp);

inputReady <= inputReady_temp;

shiftReg : shiftRegister
	generic map(bitwidth => bitwidth)
	port map(D => DO,
		reset => reset,
		clk => clk_and_32,
		Q => shift_reg_out);

bitSwitch_gen : for i in 0 to bitwidth-1 generate
	bits_out(i) <= shift_reg_out(bitwidth-1-i);
end generate;

sdc_gen : SDC_w_EN
	generic map(bitwidth => bitwidth)
	port map(a => bits_out,
		en => sdc_en,
		sleep => sleep_out_temp,
		z => z);

sleep_out_gate : inv_a
	port map(a => sdc_en,
		z => sleep_out_temp);

enable_gen : th22m_en_gen 
	generic map(bitwidth => 20)
	port map(a => counter_bits,
		en => sdc_en,
		sleep => sleep_out_temp,
		z => count_out);

clock_and_32_gate : and2_a
	port map(a => clk_temp,
		b => counter32,
		z => clk_and_32);

setOfSixteen01_1_gate : and2_a
	port map(a => counter_bits(0).rail1,
		b => counter_bits(1).rail1,
		z => setOfSixteen01_1);
setOfSixteen23_1_gate : and2_a
	port map(a => counter_bits(2).rail1,
		b => counter_bits(3).rail1,
		z => setOfSixteen23_1);
setOfSixteen_1_gate : and2_a
	port map(a => setOfSixteen01_1,
		b => setOfSixteen23_1,
		z => setOfSixteen.rail1);

counter32Ex_gate : and2_a
	port map(a => setOfSixteen.rail1,
		b => counter_bits(4).rail1,
		z => counter32EX);

setOfSixteen01_0_gate : or2_a
	port map(a => counter_bits(0).rail0,
		b => counter_bits(1).rail0,
		z => setOfSixteen01_0);
setOfSixteen23_0_gate : or2_a
	port map(a => counter_bits(2).rail0,
		b => counter_bits(3).rail0,
		z => setOfSixteen23_0);
setOfSixteen_0_gate : or2_a
	port map(a => setOfSixteen01_0,
		b => setOfSixteen23_0,
		z => setOfSixteen.rail0);

--sdc_en

sdc_en_gate : and2_a
	port map(a => clk_and_32,
		b => setOfSixteen.rail1,
		z => sdc_en_temp);

sdc_en_th22 : th22n_a
	port map(a => sdc_en_temp,
		b => ki,
		rst => reset,
		z => sdc_en);

DIO_pre_Gate : and2_a
	port map(a => counter_bits(2).rail1,
		 b => counter_bits(1).rail1,
		 z => DIO_pre);

DIO_pre1_Gate : and2_a
	port map(a => DIO_pre,
		 b => counter_bits(3).rail0,
		 z => DIO_pre1);

DIO_Gate : and2_a
	port map(a => DIO_pre1,
		 b => counter_bits(4).rail0,
		 z => DIO);


inv_clk_delay_gate : BUFFER_C
	port map(A => counter_sleep_out,
		 Z => inv_clk_delay(0)); 

inv_clk_delay_gen : for i in 0 to delay-2 generate
	inv_clk_delay_i : BUFFER_C 
	port map(A => inv_clk_delay(i),
		Z => inv_clk_delay(i+1));
end generate;

inv_clk_delay_gate2 : BUFFER_C
	port map(A => inv_clk_delay(delay-1),
		 Z => inv_clk); 

inv_clock_gate : inv_a
	port map(a => inv_clk,
		z => clk_temp_pre);

clock_or_sdc_gate : or2_a
	port map(a => clk_temp_pre,
		b => sdc_en,
		z => clk_temp);

clock_inv_gate : inv_a
	port map(a => clk_temp,
		z => clk_inv);

clk_inv_delay_gate : BUFFER_C
	port map(A => clk_inv,
		 Z => clk_inv_delay(0)); 

clk_inv_delay_gen : for i in 0 to 18 generate
	inv_clk_delay_i : BUFFER_C 
	port map(A => clk_inv_delay(i),
		Z => clk_inv_delay(i+1));
end generate;

clk_inv_delay_gate2 : BUFFER_C
	port map(A => clk_inv_delay(19),
		 Z => counter_ki_temp); 

counter_ki_pre_gate : and2_a
	port map(a => ki,
		 b => counter_ki_temp,
		 z => counter_ki_pre);

sdc_en_and_ki_gate : and2_a
	port map(a => ki,
		 b => sdc_en,
		 z => sdc_en_and_ki);

counter_ki_gate : or2_a
	port map(a => counter_ki_pre,
		b => sdc_en_and_ki,
		z => counter_ki);

clk <= clk_temp;
cs <= reset;
sleep_out <= sleep_out_temp;


end arch_flashAccessGRNN; 
