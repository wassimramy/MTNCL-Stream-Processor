

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;
use ieee.math_real.all;

entity RCF_GRNN_fc_layer is
	generic(maxBitwidth : integer := 16;
		maxLayerSize : integer := 128);
	port(	
		--Configuration Ports
		numberLayers	: in dual_rail_logic;
		layerBitwidth 	: in dual_rail_logic;
		layerSize 	: in dual_rail_logic;

		trunc_fc : in dual_rail_logic_vector(2 downto 0);

		--Primary Layer Inputs
		Xt : in dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0);
		reset : in std_logic;
		sleep_in : in std_logic;
		ki : in std_logic;

		FC_W_in : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		FC_in_sleep_in : in std_logic;
		FC_in_ko : out std_logic;

		--Primary Layer Outputs
		sleep_out : out std_logic;
		ko : out std_logic;
		z : out dual_rail_logic_vector(maxBitwidth-1 downto 0)
	);
end RCF_GRNN_fc_layer;

architecture arch_RCF_GRNN_fc_layer of RCF_GRNN_fc_layer is 


component RCF_OAAT_out_all_in_128_RPT is
	generic(reset_count_upper_width: integer := 8; 
		bitwidth: integer := 16;
		numInputs : integer := 128);
	port(	 
		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		reset_count_lower : in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0); --CHANGE COUNTER WIDTH
		reset_count_upper : in dual_rail_logic_vector(reset_count_upper_width-1 downto 0); --CHANGE COUNTER WIDTH
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		layerSize	: std_logic; --0 = 64, 1 = 128
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 accumulate_reset: out dual_rail_logic;
		lowerIsMax : out dual_rail_logic;
		upperIsMax : out dual_rail_logic;
		count: out dual_rail_logic_vector(reset_count_upper_width + integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component RCF_OAAT_out_all_in_128_forever is
	generic(bitwidth: integer := 16;
		numInputs : integer := 128);
	port(	 
		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0); --CHANGE COUNTER WIDTH
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		layerSize	: std_logic; --0 = 64, 1 = 128
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 accumulate_reset: out dual_rail_logic;
		 count: out dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component OAAT_out_all_in_forever is
	generic(bitwidth: integer := 16;
		numInputs : integer := 64);
	port(	 
		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0); --CHANGE COUNTER WIDTH
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 accumulate_reset: out dual_rail_logic;
		 count: out dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component OAAT_in_all_out is
	generic( bitwidth : integer := 16;
		 numInputs : integer := 64;
		 counterWidth : integer := 6; --Log2 of numInputs
		 delay_amount : integer := 6);
	port(	 a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0));
end component;

	component th33_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 c: in std_logic; 
			 z: out std_logic); 
	end component;

	component MUX21_A is 
		port(A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			 Z: out std_logic); 
	end component; 


component mult_of_accumulate_8_16 is
	generic(counterWidth : integer := 8);
	port(a: in dual_rail_logic_vector(15 downto 0);
		b: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
		reset : in std_logic;
		sleep_in_a : in std_logic;
		sleep_in_b : in std_logic;
		trunc : in dual_rail_logic_vector(2 downto 0);
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(15 downto 0));
end component;

component adder_8_16 is
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
end component;

component mux_21_gen_nic is
	generic(width: integer);
    port(a: in dual_rail_logic_vector(width-1 downto 0);
	 	 b: in dual_rail_logic_vector(width-1 downto 0);
		sel: in dual_rail_logic;
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width-1 downto 0));
end component;

component MUX21_dr_gen is 
	generic(bitwidth : integer);
	port(A: in dual_rail_logic_vector(bitwidth-1 downto 0); 
		B: in dual_rail_logic_vector(bitwidth-1 downto 0);
		S: in std_logic;
		 Z: out dual_rail_logic_vector(bitwidth-1 downto 0)); 
end component; 

signal const63, const127, const63_127, const0_1, const1 : dual_rail_logic_vector(7 downto 0);
signal const257 : dual_rail_logic_vector(8 downto 0);
signal x_oaat_out, weights_0_out, weights_1_out, const0, mult_of_acc_out, FC_B, weightMem_out : dual_rail_logic_vector(15 downto 0);
signal weights_0_count, weights_1_count : dual_rail_logic_vector(6 downto 0);
signal bias_regs_count : dual_rail_logic_vector(1 downto 0);
signal x_oaat_count : dual_rail_logic_vector(14 downto 0);
signal FC_W_reg_out : dual_rail_logic_vector(258*16-1 downto 0);

signal data0, data1 : dual_rail_logic;
signal x_oaat_ki, x_oaat_ko, x_oaat_sleep_out, weights_0_ko, weights_1_ko, FC_w_in_reg_sleep_out, weight_01_bias_ko, bias_regs_ko, weights_0_ki, weights_0_sleep_out, weights_1_ki, weights_1_sleep_out, mult_of_acc_ko, bias_adder_ko, mult_of_acc_sleep_out, bias_regs_sleep_out : std_logic;
signal x_oaat_acc_reset, x_oaat_lowerIsMax, x_oaat_upperIsMax, weights_0_accReset, weights_1_accReset, bias_regs_accReset : dual_rail_logic;
signal Bias_value_reg_in : dual_rail_logic_vector(16*4-1 downto 0);

begin 



data0.rail0 <= '1';
data0.rail1 <= '0';

data1.rail0 <= '0';
data1.rail1 <= '1';

const63(0) <= data1;
const63(1) <= data1;
const63(2) <= data1;
const63(3) <= data1;
const63(4) <= data1;
const63(5) <= data1;
const63(6) <= data0;
const63(7) <= data0;

const127(0) <= data1;
const127(1) <= data1;
const127(2) <= data1;
const127(3) <= data1;
const127(4) <= data1;
const127(5) <= data1;
const127(6) <= data1;
const127(7) <= data0;

const257(0) <= data1;
const257(1) <= data0;
const257(2) <= data0;
const257(3) <= data0;
const257(4) <= data0;
const257(5) <= data0;
const257(6) <= data0;
const257(7) <= data0;
const257(8) <= data1;

const0(0) <= data0;
const0(1) <= data0;
const0(2) <= data0;
const0(3) <= data0;
const0(4) <= data0;
const0(5) <= data0;
const0(6) <= data0;
const0(7) <= data0;
const0(8) <= data0;
const0(9) <= data0;
const0(10) <= data0;
const0(11) <= data0;
const0(12) <= data0;
const0(13) <= data0;
const0(14) <= data0;
const0(15) <= data0;

const1(0) <= data1;
const1(1) <= data0;
const1(2) <= data0;
const1(3) <= data0;
const1(4) <= data0;
const1(5) <= data0;
const1(6) <= data0;
const1(7) <= data0;

ko <= x_oaat_ko;

mux_63_127_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => const63,
		B => const127,
		S => layerSize.rail1,
		 Z => const63_127);

mux_0_1_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => const0(7 downto 0),
		B => const1,
		S => numberLayers.rail1,
		 Z => const0_1);

x_OAAT : RCF_OAAT_out_all_in_128_RPT
	generic map(reset_count_upper_width => 8,
		bitwidth => maxBitwidth,
		numInputs => maxLayerSize)
	port map(	 
		a => Xt,
		reset_count_lower => const63_127(6 downto 0),
		reset_count_upper => const0_1,
		RCF_width => layerBitwidth.rail1,
		layerSize => layerSize.rail1,
		sleep_in => sleep_in,
		reset => reset,
		ki => mult_of_acc_ko,
		ko => x_oaat_ko,
		sleep_out => x_oaat_sleep_out,
		accumulate_reset => x_oaat_acc_reset,
		lowerIsMax => x_oaat_lowerIsMax,
		upperIsMax => x_oaat_upperIsMax,
		count => x_oaat_count,
		z => x_oaat_out);

FC_w_in_reg : OAAT_in_all_out
	generic map( bitwidth => 16,
		 numInputs => 258,
		 counterWidth => 9, --Log2 of numInputs
		 delay_amount => 6)
	port map(a => FC_w_in,
		reset_count => const257,
		sleep_in => FC_in_sleep_in,
		 reset => reset,
		 ki => weight_01_bias_ko,
		 ko => FC_in_ko,
		 sleep_out => FC_w_in_reg_sleep_out,
		 z => FC_W_reg_out);


	FC_w_in_ko_gate : th33_a
		port map(a => weights_0_ko,
			 b => weights_1_ko,
			 c => bias_regs_ko,
			 z => weight_01_bias_ko); 



weights_0 : OAAT_out_all_in_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => FC_W_reg_out(128*16-1 downto 0),
		reset_count => const63_127(6 downto 0),
		sleep_in => FC_w_in_reg_sleep_out,
		 reset => reset,
		 ki => weights_0_ki,
		 ko => weights_0_ko,
		 sleep_out => weights_0_sleep_out,
		 accumulate_reset => weights_0_accReset,
		 count => weights_0_count,
		 z => weights_0_out);

	weights_0_ki_mux : MUX21_A
		port map(A => '1',
			B => mult_of_acc_ko,
			S => x_oaat_count(7).rail0,
		 	Z => weights_0_ki);


weights_1 : OAAT_out_all_in_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => FC_W_reg_out(256*16-1 downto 128*16),
		reset_count => const63_127(6 downto 0),
		sleep_in => FC_w_in_reg_sleep_out,
		 reset => reset,
		 ki => weights_1_ki,
		 ko => weights_1_ko,
		 sleep_out => weights_1_sleep_out,
		 accumulate_reset => weights_1_accReset,
		 count => weights_1_count,
		 z => weights_1_out);

	weights_1_ki_mux : MUX21_A
		port map(A => '1',
			B => mult_of_acc_ko,
			S => x_oaat_count(7).rail1,
		 	Z => weights_1_ki);


weightmemory_mux : mux_21_gen_nic
	generic map(width => 16)
    port map(a => weights_0_out,
	 	 b => weights_1_out,
		sel => x_oaat_count(7),
		 sleep => '0',
		 z => weightMem_out);

 mult_of_accumulate : mult_of_accumulate_8_16
	generic map(counterWidth => 8)
	port map(a => x_oaat_out,
		b => weightMem_out,
		RCF_width => layerBitwidth.rail1,
		reset_count => const63_127,
		reset => reset,
		sleep_in_a => x_oaat_sleep_out,
		sleep_in_b => '0',
		trunc => trunc_fc,
		ki => bias_adder_ko,		
		ko => mult_of_acc_ko,
		sleep_out => mult_of_acc_sleep_out,
		z => mult_of_acc_out);

Bias_value_reg_in <= const0 & const0 & FC_W_reg_out(258*16-1 downto 257*16) & FC_W_reg_out(257*16-1 downto 256*16);

bias_regs : OAAT_out_all_in_forever
	generic map(bitwidth => 16,
		numInputs => 4)
	port map(	 
		a => Bias_value_reg_in,
		reset_count => const0_1(1 downto 0),
		sleep_in => FC_w_in_reg_sleep_out,
		 reset => reset,
		 ki => bias_adder_ko,
		 ko => bias_regs_ko,
		 sleep_out => bias_regs_sleep_out,
		 accumulate_reset => bias_regs_accReset,
		 count => bias_regs_count,
		 z => FC_B);


bias_adder : adder_8_16
	port map(a => mult_of_acc_out,
		b => FC_B,
		RCF_width => layerBitwidth.rail1,
		reset => reset,
		sleep_in_a => mult_of_acc_sleep_out,
		sleep_in_b => bias_regs_sleep_out,
		ki => ki,
		ko => bias_adder_ko,
		sleep_out => sleep_out,
		z  => z);





end arch_RCF_GRNN_fc_layer; 
