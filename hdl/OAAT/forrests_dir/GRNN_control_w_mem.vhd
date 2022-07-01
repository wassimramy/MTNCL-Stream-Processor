

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;
use ieee.math_real.all;

entity GRNN_control_w_mem is
	generic(maxBitwidth : integer := 16;
		maxLayerSize : integer := 128);
	port(	
		--Configuration Ports
		numberLayers	: in dual_rail_logic_vector(1 downto 0);
		inputWidth	: in dual_rail_logic_vector(7 downto 0);
		layerBitwidth 	: in dual_rail_logic_vector(3 downto 0);
		layerSize 	: in dual_rail_logic_vector(3 downto 0);
		layerType 	: in dual_rail_logic_vector(3 downto 0);
		layerIsInput 	: in dual_rail_logic_vector(3 downto 0);
		prevLayerSize 	: in dual_rail_logic_vector(3 downto 0);
		nextLayerBitwidth : in dual_rail_logic_vector(3 downto 0);

		trunc_zt : in dual_rail_logic_vector(11 downto 0);
		trunc_htm1_zt : in dual_rail_logic_vector(11 downto 0);
		trunc_zeta : in dual_rail_logic_vector(11 downto 0);
		trunc_rt : in dual_rail_logic_vector(11 downto 0);
		trunc_htm1_rt : in dual_rail_logic_vector(11 downto 0);
		trunc_sht : in dual_rail_logic_vector(11 downto 0);
		trunc_ztm1_sht : in dual_rail_logic_vector(11 downto 0);
		trunc_bitchange : in dual_rail_logic_vector(11 downto 0);

		config_ko : out std_logic;
		config_sleep_in : in std_logic;

		--Layer Constants
		zeta		: in dual_rail_logic_vector(4*maxBitwidth-1 downto 0);
		nu		: in dual_rail_logic_vector(4*maxBitwidth-1 downto 0);

		--Primary Layer Inputs
		Xt : in dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0);
		reset : in std_logic;
		sleep_in : in std_logic;
		ki : in std_logic;

		--Bias Ports
		Zt_B_in : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Zt_B_in_sleep_in : in std_logic;
		Zt_B_in_ko : out std_logic;

		Rt_B_in : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Rt_B_in_sleep_in : in std_logic;
		Rt_B_in_ko : out std_logic;

		Sht_B_in : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Sht_B_in_sleep_in : in std_logic;
		Sht_B_in_ko : out std_logic;

		--Memory Ports
		Zt_W : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Zt_sleep_in : in std_logic;
		Zt_ko : out std_logic;

		Rt_W : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Rt_sleep_in : in std_logic;
		Rt_ko : out std_logic;

		Sht_W : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Sht_sleep_in : in std_logic;
		Sht_ko : out std_logic;

		writeEn : in dual_rail_logic;

		--Primary Layer Outputs
		sleep_out : out std_logic;
		ko : out std_logic;
		z : out dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0)
	);
end GRNN_control_w_mem;

architecture arch_GRNN_control_w_mem of GRNN_control_w_mem is 

component GRNN_layer_w_mem is
	generic(maxBitwidth : integer := 16;
		maxLayerSize : integer := 128);
	port(	
		--Layer Constants
		layerBitwidth : in std_logic; --0 = 8, 1 = 16
		layerSize	: in dual_rail_logic; --0 = 64, 1 = 128
		layerType	: in dual_rail_logic; --0 = GRU, 1 = fastGRNN
		layerIsInput	: in dual_rail_logic; --0 = no, 1 = yes
		prevLayerSize	: in std_logic; --0 = 64, 1 = 128
		layerNumber	: in dual_rail_logic_vector(1 downto 0);
		zeta		: in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		nu		: in dual_rail_logic_vector(maxBitwidth-1 downto 0);

		--Primary Layer Inputs
		Xt : in dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0);
		Ht : in dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0);
		reset : in std_logic;
		sleep_in : in std_logic;
		ki : in std_logic;

		--Bias Ports
		Zt_B : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Zt_B_sleep_in : in std_logic;
		Zt_B_ko : out std_logic;


		Rt_B : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Rt_B_sleep_in : in std_logic;
		Rt_B_ko : out std_logic;

		Sht_B : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Sht_B_sleep_in : in std_logic;
		Sht_B_ko : out std_logic;

		--Memory Ports
		Zt_W : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Zt_sleep_in : in std_logic;
		Zt_ko : out std_logic;

		Rt_W : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Rt_sleep_in : in std_logic;
		Rt_ko : out std_logic;

		Sht_W : in dual_rail_logic_vector(maxBitwidth-1 downto 0);
		Sht_sleep_in : in std_logic;
		Sht_ko : out std_logic;

		writeEn : in dual_rail_logic;

		--Truncation Ports
		trunc_zt : in dual_rail_logic_vector(2 downto 0);
		trunc_htm1_zt : in dual_rail_logic_vector(2 downto 0);
		trunc_zeta : in dual_rail_logic_vector(2 downto 0);
		trunc_rt : in dual_rail_logic_vector(2 downto 0);
		trunc_htm1_rt : in dual_rail_logic_vector(2 downto 0);
		trunc_sht : in dual_rail_logic_vector(2 downto 0);
		trunc_ztm1_sht : in dual_rail_logic_vector(2 downto 0);
		trunc_bitchange : in dual_rail_logic_vector(2 downto 0);

		--Primary Layer Outputs
		sleep_out : out std_logic;
		ko : out std_logic;
		z_8 : out dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0);
		z_16 : out dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0)
	);
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


	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;

	component compdm is
		generic(width: in integer);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;

	component regs_gen_zero_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;


	component compm is
		generic(width: in integer);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
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


	component andtreem is
		generic(width: in integer := 4);
		port(a: in std_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 ko: out std_logic);
	end component;

	component mux_nto1_gen is
		generic(bitwidth: in integer ;
			numInputs : integer := 64);
    	port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 	sleep: in std_logic;
		 	z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component th22m_en_gen is
		generic(bitwidth : integer);
		port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
			en : in std_logic;
			sleep : std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component th12m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic; 
			 z: out std_logic); 
	end component; 

	component th22m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 s: in std_logic; 
			 z: out std_logic); 
	end component; 

	component th14m_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 c: in std_logic;
			 d: in std_logic;
			 s: in std_logic; 
			 z: out std_logic); 
	end component; 

	component th22_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 z: out std_logic); 
	end component; 


	component th33_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 c: in std_logic; 
			 z: out std_logic); 
	end component;
 
	component th44_a is 
		port(a: in std_logic; 
			 b: in std_logic;
			 c: in std_logic; 
			 d: in std_logic; 
			 z: out std_logic); 
	end component; 

	component mux_21_gen is
		generic(width: integer);
	    port(a: in dual_rail_logic_vector(width-1 downto 0);
		 	 b: in dual_rail_logic_vector(width-1 downto 0);
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component mux_21_gen_nic is
		generic(width: integer);
	    port(a: in dual_rail_logic_vector(width-1 downto 0);
		 	 b: in dual_rail_logic_vector(width-1 downto 0);
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component MUX21_A is 
		port(A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			 Z: out std_logic); 
	end component; 

	component mux_21_nic is
	    port(a: in dual_rail_logic;
		 	 b: in dual_rail_logic;
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic);
	end component;

	component TwoPhaseCounter is
		generic(width_lower: integer;
			width_upper: integer);
		port(	reset_count_lower: in dual_rail_logic_vector(width_lower-1 downto 0);
			reset_count_upper: in dual_rail_logic_vector(width_upper-1 downto 0);
			sleep_in: in std_logic;
			reset: in std_logic;
			ki: in std_logic;
			ko: out std_logic;
			sleep_out: out std_logic;
			upper_is_max : out dual_rail_logic;
			accumulate_reset_lower: out dual_rail_logic;
			accumulate_reset_upper: out dual_rail_logic;
			z: out dual_rail_logic_vector(width_upper+width_lower-1 downto 0));
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

component MUX21_dr_gen is 
	generic(bitwidth : integer);
	port(A: in dual_rail_logic_vector(bitwidth-1 downto 0); 
		B: in dual_rail_logic_vector(bitwidth-1 downto 0);
		S: in std_logic;
		 Z: out dual_rail_logic_vector(bitwidth-1 downto 0)); 
end component; 

signal configBitsIn : dual_rail_logic_vector(247 downto 0);
signal configBits_reg : dual_rail_logic_vector(63 downto 0);
signal counterBits_prev, counterBits : dual_rail_logic_vector(14 downto 0);
signal const511 : dual_rail_logic_vector(9 downto 0);

signal const63, const127, const63_127 : dual_rail_logic_vector(7 downto 0);

signal Zt_bias_layer_0_count, Zt_bias_layer_1_count, Zt_bias_layer_2_count, Zt_bias_layer_3_count : dual_rail_logic_vector(6 downto 0);
signal Rt_bias_layer_0_count, Rt_bias_layer_1_count, Rt_bias_layer_2_count, Rt_bias_layer_3_count : dual_rail_logic_vector(6 downto 0);
signal Sht_bias_layer_0_count, Sht_bias_layer_1_count, Sht_bias_layer_2_count, Sht_bias_layer_3_count : dual_rail_logic_vector(6 downto 0);

signal config_acc_reset, Xt_select, data0, Xt_ko_select, layerIsInput_write, layerIsInput_mux_out, Zt_bias_layer_0_accReset, Zt_bias_layer_1_accReset, Zt_bias_layer_2_accReset, Zt_bias_layer_3_accReset, data1, Sht_bias_layer_0_accReset, Sht_bias_layer_1_accReset, Sht_bias_layer_2_accReset, Sht_bias_layer_3_accReset, Rt_bias_layer_0_accReset, Rt_bias_layer_1_accReset, Rt_bias_layer_2_accReset, Rt_bias_layer_3_accReset : dual_rail_logic;
signal configBits : dual_rail_logic_vector(61 downto 0);
signal configBits_prev : dual_rail_logic_vector(63 downto 0);
signal Xt_next, Ht_next_reg_out, Xt_next_reg_out, Ht_next_reg_out_zero, Htm1_next_reg_0_in, Htm1_next_reg_1_in, Htm1_next_reg_2_in, Htm1_next_reg_3_in, Htm1_next_reg_0_out, Htm1_next_reg_1_out, Htm1_next_reg_2_out, Htm1_next_reg_3_out, Main_Htm1, Xt_input_with_zeros, Main_Xt, Ht_next, Xt_next_mux_out, Ht_next_8, Ht_next_16, Ht_next_reg_8_out, Ht_next_reg_16_out : dual_rail_logic_vector(maxBitwidth*maxLayerSize-1 downto 0);
signal htm1_mux_in, zt_bias_all_in, sht_bias_all_in, rt_bias_all_in : dual_rail_logic_vector(4*maxBitwidth*maxLayerSize-1 downto 0);

signal Zt_bias_layer_0_out, Zt_bias_layer_1_out, Zt_bias_layer_2_out, Zt_bias_layer_3_out, Zt_B : dual_rail_logic_vector(15 downto 0);
signal Rt_bias_layer_0_out, Rt_bias_layer_1_out, Rt_bias_layer_2_out, Rt_bias_layer_3_out, Rt_B : dual_rail_logic_vector(15 downto 0);
signal Sht_bias_layer_0_out, Sht_bias_layer_1_out, Sht_bias_layer_2_out, Sht_bias_layer_3_out, Sht_B : dual_rail_logic_vector(15 downto 0);

signal Sht_bias_layer_out, Rt_bias_layer_out, Zt_bias_layer_out : dual_rail_logic_vector(63 downto 0);

signal layerNumber, layerNumber_mux_out  : dual_rail_logic_vector(1 downto 0); 
signal numberLayers_ext, layerNumber_ext : dual_rail_logic_vector(3 downto 0);
signal Ht_next_reg_ko, config_sleep_out, Main_ko, Xt_next_reg_ko, Main_ko_select_0, Main_ko_select_1, Main_ko_select_2, Main_ko_select_3, Htm1_next_reg_0_ko, configBits_select_0, Ht_next_en_1_en, Ht_next_en_2_en, Ht_next_en_3_en, Htm1_next_reg_1_ko, configBits_select_1, configBits_select_2, configBits_select_3, Htm1_next_reg_2_ko, Htm1_next_reg_3_ko, Main_sleep_in, Main_sleep_out, ht_reg_ki, Ht_next_reg_ko_a, Ht_next_reg_ko_b, Ht_next_reg_ko_c, runCounterko, runCounter_sleep_out, ht_next_reg_ki, Ht_next_reg_ko_a_lower, Ht_next_reg_ko_a_upper, Ht_next_reg_ko_a_mux, Htm1_next_reg_0_ko_lower, Htm1_next_reg_0_ko_upper, Htm1_next_reg_0_ko_mux, Htm1_next_reg_1_ko_lower, Htm1_next_reg_1_ko_upper, Htm1_next_reg_1_ko_mux, Htm1_next_reg_2_ko_lower, Htm1_next_reg_2_ko_upper, Htm1_next_reg_2_ko_mux, Htm1_next_reg_3_ko_lower, Htm1_next_reg_3_ko_upper, Htm1_next_reg_3_ko_mux, ht_next_reg_ki_and, Xt_next_reg_ko_lower, Xt_next_reg_ko_upper, Xt_next_reg_ko_mux, Zt_bias_in_OAAT_ki, Zt_bias_in_OAAT_sleep_out, Zt_bias_layer_0_ko, Zt_bias_layer_1_ko, Zt_bias_layer_2_ko, Zt_bias_layer_3_ko, Zt_bias_layer_0_ki, Zt_bias_layer_0_sleep_out, Zt_B_ko, Zt_bias_layer_1_ki, Zt_bias_layer_1_sleep_out, Zt_bias_layer_2_ki, Zt_bias_layer_2_sleep_out, Zt_bias_layer_3_ki, Zt_bias_layer_3_sleep_out, Zt_bias_layer_01_sleep_out, Zt_bias_layer_23_sleep_out, Zt_bias_layer_sleep_out, layerNumberIsNull, Zt_B_sleep_in, Rt_bias_in_OAAT_ki, Rt_bias_in_OAAT_sleep_out, Rt_bias_layer_0_ko, Rt_bias_layer_1_ko, Rt_bias_layer_2_ko, Rt_bias_layer_3_ko, Rt_bias_layer_0_ki, Rt_bias_layer_0_sleep_out, Rt_B_ko, Rt_bias_layer_1_ki, Rt_bias_layer_1_sleep_out, Rt_bias_layer_2_ki, Rt_bias_layer_2_sleep_out, Rt_bias_layer_3_ki, Rt_bias_layer_3_sleep_out, Rt_bias_layer_01_sleep_out, Rt_bias_layer_23_sleep_out, Rt_bias_layer_sleep_out,  Rt_B_sleep_in, Sht_bias_in_OAAT_ki, Sht_bias_in_OAAT_sleep_out, Sht_bias_layer_0_ko, Sht_bias_layer_1_ko, Sht_bias_layer_2_ko, Sht_bias_layer_3_ko, Sht_bias_layer_0_ki, Sht_bias_layer_0_sleep_out, Sht_B_ko, Sht_bias_layer_1_ki, Sht_bias_layer_1_sleep_out, Sht_bias_layer_2_ki, Sht_bias_layer_2_sleep_out, Sht_bias_layer_3_ki, Sht_bias_layer_3_sleep_out, Sht_bias_layer_01_sleep_out, Sht_bias_layer_23_sleep_out, Sht_bias_layer_sleep_out, Sht_B_sleep_in, Xt_ko_select_real, Xt_ko_select_isData, Ht_next_reg_8_ko_a_lower, Ht_next_reg_8_ko_a_upper, Ht_next_reg_16_ko_a_lower, Ht_next_reg_16_ko_a_upper, Ht_next_reg_8_ko_a_mux, Ht_next_reg_8_ko, Ht_next_reg_16_ko_a_mux, Ht_next_reg_16_ko : std_logic;

begin 

configBitsIn(0) <= layerBitwidth(0);
configBitsIn(1) <= layerSize(0);
configBitsIn(2) <= layerType(0);
configBitsIn(3) <= layerIsInput(0);
configBitsIn(4) <= prevLayerSize(0);

configBitsIn(7 downto 5) <= trunc_zt(2 downto 0);
configBitsIn(10 downto 8) <= trunc_htm1_zt(2 downto 0);
configBitsIn(13 downto 11) <= trunc_zeta(2 downto 0);
configBitsIn(16 downto 14) <= trunc_rt(2 downto 0);
configBitsIn(19 downto 17) <= trunc_htm1_rt(2 downto 0);
configBitsIn(22 downto 20) <= trunc_sht(2 downto 0);
configBitsIn(25 downto 23) <= trunc_ztm1_sht(2 downto 0);

configBitsIn(41 downto 26) <= zeta(15 downto 0);
configBitsIn(57 downto 42) <= nu(15 downto 0);

configBitsIn(60 downto 58) <= trunc_bitchange(2 downto 0);
configBitsIn(61) <= nextLayerBitwidth(0);

configBitsIn(62) <= layerBitwidth(1);
configBitsIn(63) <= layerSize(1);
configBitsIn(64) <= layerType(1);
configBitsIn(65) <= layerIsInput(1);
configBitsIn(66) <= prevLayerSize(1);

configBitsIn(69 downto 67) <= trunc_zt(5 downto 3);
configBitsIn(72 downto 70) <= trunc_htm1_zt(5 downto 3);
configBitsIn(75 downto 73) <= trunc_zeta(5 downto 3);
configBitsIn(78 downto 76) <= trunc_rt(5 downto 3);
configBitsIn(81 downto 79) <= trunc_htm1_rt(5 downto 3);
configBitsIn(84 downto 82) <= trunc_sht(5 downto 3);
configBitsIn(87 downto 85) <= trunc_ztm1_sht(5 downto 3);

configBitsIn(103 downto 88) <= zeta(31 downto 16);
configBitsIn(119 downto 104) <= nu(31 downto 16);

configBitsIn(122 downto 120) <= trunc_bitchange(5 downto 3);
configBitsIn(123) <= nextLayerBitwidth(1);

configBitsIn(124) <= layerBitwidth(2);
configBitsIn(125) <= layerSize(2);
configBitsIn(126) <= layerType(2);
configBitsIn(127) <= layerIsInput(2);
configBitsIn(128) <= prevLayerSize(2);

configBitsIn(131 downto 129) <= trunc_zt(8 downto 6);
configBitsIn(134 downto 132) <= trunc_htm1_zt(8 downto 6);
configBitsIn(137 downto 135) <= trunc_zeta(8 downto 6);
configBitsIn(140 downto 138) <= trunc_rt(8 downto 6);
configBitsIn(143 downto 141) <= trunc_htm1_rt(8 downto 6);
configBitsIn(146 downto 144) <= trunc_sht(8 downto 6);
configBitsIn(149 downto 147) <= trunc_ztm1_sht(8 downto 6);

configBitsIn(165 downto 150) <= zeta(47 downto 32);
configBitsIn(181 downto 166) <= nu(47 downto 32);

configBitsIn(184 downto 182) <= trunc_bitchange(8 downto 6);
configBitsIn(185) <= nextLayerBitwidth(2);

configBitsIn(186) <= layerBitwidth(3);
configBitsIn(187) <= layerSize(3);
configBitsIn(188) <= layerType(3);
configBitsIn(189) <= layerIsInput(3);
configBitsIn(190) <= prevLayerSize(3);

configBitsIn(193 downto 191) <= trunc_zt(11 downto 9);
configBitsIn(196 downto 194) <= trunc_htm1_zt(11 downto 9);
configBitsIn(199 downto 197) <= trunc_zeta(11 downto 9);
configBitsIn(202 downto 200) <= trunc_rt(11 downto 9);
configBitsIn(205 downto 203) <= trunc_htm1_rt(11 downto 9);
configBitsIn(208 downto 206) <= trunc_sht(11 downto 9);
configBitsIn(211 downto 209) <= trunc_ztm1_sht(11 downto 9);

configBitsIn(227 downto 212) <= zeta(63 downto 48);
configBitsIn(243 downto 228) <= nu(63 downto 48);

configBitsIn(246 downto 244) <= trunc_bitchange(11 downto 9);
configBitsIn(247) <= nextLayerBitwidth(3);

data0.rail0 <= '1';
data0.rail1 <= '0';

data1.rail0 <= '0';
data1.rail1 <= '1';

numberLayers_ext(0) <= numberLayers(0);
numberLayers_ext(1) <= numberLayers(1);
numberLayers_ext(2) <= data0;
numberLayers_ext(3) <= data0;

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

const511(0) <= data1;
const511(1) <= data1;
const511(2) <= data1;
const511(3) <= data1;
const511(4) <= data1;
const511(5) <= data1;
const511(6) <= data1;
const511(7) <= data1;
const511(8) <= data1;
const511(9) <= data0;

mux_63_127_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => const63,
		B => const127,
		S => configBits(1).rail1,
		 Z => const63_127);



OAAT_config_bits : OAAT_out_all_in_forever
	generic map(bitwidth => 62,
		numInputs => 4)
	port map(	 
		a => configBitsIn,
		reset_count => numberLayers,
		sleep_in => config_sleep_in,
		 reset => reset,
		 ki => Ht_next_reg_ko,
		 ko => config_ko,
		 sleep_out => config_sleep_out,
		 accumulate_reset => config_acc_reset,
		 count => layerNumber,
		 z => configBits);

generate_reg_zero_reset_x: for i in 0 to maxBitwidth*maxLayerSize-1 generate

	th22m_lower_i	: th22m_a
		port map(
			a => counterBits_prev(13).rail0,
			b => Xt_next_mux_out(i).rail1,
			s => Ht_next_reg_ko,
			z => Xt_next(i).rail1);

	th12m_lower_i: th12m_a
		port map(
			a => counterBits_prev(13).rail1,
			b => Xt_next_mux_out(i).rail0,
			s => Ht_next_reg_ko,
			z => Xt_next(i).rail0);

	end generate;

--	Xt_next_reg_comp : compdm
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(a => Xt_next,
--			ki => Main_ko,
--			rst => reset,
--			sleep => Ht_next_reg_ko,
--			ko => Xt_next_reg_ko);

--ADD split comp
	Xt_next_reg_comp_lower : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Xt_next((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => Main_ko,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Xt_next_reg_ko_lower);

	Xt_next_reg_comp_upper : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Xt_next(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => Main_ko,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Xt_next_reg_ko_upper);

	Xt_next_reg_ko_upper_lower : th22_a
		port map(a => Xt_next_reg_ko_lower, 
			 b => Xt_next_reg_ko_upper,
			 z => Xt_next_reg_ko_mux); 

	Xt_next_ko_a_mux : MUX21_A
		port map(A => Xt_next_reg_ko_lower,
			B => Xt_next_reg_ko_mux,
			S => configBits_prev(1).rail1,
		 	Z => Xt_next_reg_ko);

--END split comp

	Xt_next_reg : regs_gen_zero_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Xt_next,							
			q => Xt_next_reg_out,
			reset => reset,
			sleep => Xt_next_reg_ko);

generate_reg_zero_reset_h: for i in 0 to maxBitwidth*maxLayerSize-1 generate

	th22m_lower_i	: th22m_a
		port map(
			a => counterBits_prev(14).rail0,
			b => Ht_next_reg_out(i).rail1,
			s => Ht_next_reg_ko,
			z => Ht_next_reg_out_zero(i).rail1);

	th12m_lower_i: th12m_a
		port map(
			a => counterBits_prev(14).rail1,
			b => Ht_next_reg_out(i).rail0,
			s => Ht_next_reg_ko,
			z => Ht_next_reg_out_zero(i).rail0);

	end generate;

	Htm1_0_en_select_gate : th22m_a
		port map(a => configBits_prev(62).rail0,
			 b => configBits_prev(63).rail0,
			 s => '0',
			 z => Xt_select.rail1); 

	Xt_select_gate : th12m_a
		port map(a => configBits_prev(62).rail1,
			 b => configBits_prev(63).rail1,
			 s => '0',
			 z => Xt_select.rail0); 

	Xt_select_ko1_gate : th22m_a
		port map(a => layerNumber(0).rail0,
			 b => layerNumber(1).rail0,
			 s => '0',
			 z => Xt_ko_select.rail1); 

	Xt_select_ko0_gate : th12m_a
		port map(a => layerNumber(0).rail1,
			 b => layerNumber(1).rail1,
			 s => '0',
			 z => Xt_ko_select.rail0); 

xt_ko_sel_isData_gate : th12m_a
	port map(a => Xt_ko_select.rail0,
		b => Xt_ko_select.rail1,
		s => '0',
		z => Xt_ko_select_isData);

Xt_ko_select_real_gate : th22m_a
	port map(a => Xt_ko_select.rail1,
		b => Ht_next_reg_ko_b,
		s => '0',
		z => Xt_ko_select_real);

	

	Htm1_next_reg_0_en : th22m_en_gen
		generic map(bitwidth => maxBitwidth*maxLayerSize)
		port map(a => Ht_next_reg_out_zero,
			en => Xt_select.rail1,
			sleep => Ht_next_reg_ko,
			z => Htm1_next_reg_0_in);

--	Htm1_next_reg_0_comp : compdm
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(a => Htm1_next_reg_0_in,
--			ki => Main_ko_select_0,
--			rst => reset,
--			sleep => Ht_next_reg_ko,
--			ko => Htm1_next_reg_0_ko);

--ADD split comp
	Htm1_next_reg_0_comp_lower : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_0_in((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => Main_ko_select_0,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_0_ko_lower);

	Htm1_next_reg_0_comp_upper : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_0_in(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => Main_ko_select_0,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_0_ko_upper);

	Ht_next_reg_0_ko_upper_lower : th22_a
		port map(a => Htm1_next_reg_0_ko_lower, 
			 b => Htm1_next_reg_0_ko_upper,
			 z => Htm1_next_reg_0_ko_mux); 

	Ht_next_0_ko_a_mux : MUX21_A
		port map(A => Htm1_next_reg_0_ko_lower,
			B => Htm1_next_reg_0_ko_mux,
			S => configBits_prev(1).rail1,
		 	Z => Htm1_next_reg_0_ko);

--END split comp

	Htm1_0_mux_select_gate : th22m_a
		port map(a => layerNumber(0).rail0,
			 b => layerNumber(1).rail0,
			 s => '0',
			 z => configBits_select_0); 

	Htm1_next_reg_0_ki_mux : MUX21_A
		port map(A => '1',
			B => Main_ko,
			S => configBits_select_0,
		 	Z => Main_ko_select_0);

	Htm1_next_reg_0_reg : regs_gen_zero_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Htm1_next_reg_0_in,
			q => Htm1_next_reg_0_out,
			reset => reset,
			sleep => Htm1_next_reg_0_ko);

	Htm1_1_en_select_gate : th22m_a
		port map(a => configBits_prev(62).rail1,
			 b => configBits_prev(63).rail0,
			 s => '0',
			 z => Ht_next_en_1_en); 

	Htm1_next_reg_1_en : th22m_en_gen
		generic map(bitwidth => maxBitwidth*maxLayerSize)
		port map(a => Ht_next_reg_out_zero,
			en => Ht_next_en_1_en,
			sleep => Ht_next_reg_ko,
			z => Htm1_next_reg_1_in);

--	Htm1_next_reg_1_comp : compdm
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(a => Htm1_next_reg_1_in,
--			ki => Main_ko_select_1,
--			rst => reset,
--			sleep => Ht_next_reg_ko,
--			ko => Htm1_next_reg_1_ko);

--ADD split comp
	Htm1_next_reg_1_comp_lower : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_1_in((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => Main_ko_select_1,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_1_ko_lower);

	Htm1_next_reg_1_comp_upper : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_1_in(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => Main_ko_select_1,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_1_ko_upper);

Ht_next_reg_1_ko_upper_lower : th22_a
	port map(a => Htm1_next_reg_1_ko_lower, 
			 b => Htm1_next_reg_1_ko_upper,
			 z => Htm1_next_reg_1_ko_mux); 

	Ht_next_1_ko_a_mux : MUX21_A
		port map(A => Htm1_next_reg_1_ko_lower,
			B => Htm1_next_reg_1_ko_mux,
			S => configBits_prev(1).rail1,
		 	Z => Htm1_next_reg_1_ko);

--END split comp

	Htm1_1_mux_select_gate : th22m_a
		port map(a => layerNumber(0).rail1,
			 b => layerNumber(1).rail0,
			 s => '0',
			 z => configBits_select_1); 

	Htm1_next_reg_1_ki_mux : MUX21_A
		port map(A => '1',
			B => Main_ko,
			S => configBits_select_1,
		 	Z => Main_ko_select_1);

	Htm1_next_reg_1_reg : regs_gen_zero_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Htm1_next_reg_1_in,
			q => Htm1_next_reg_1_out,
			reset => reset,
			sleep => Htm1_next_reg_1_ko);

	Htm1_2_en_select_gate : th22m_a
		port map(a => configBits_prev(62).rail0,
			 b => configBits_prev(63).rail1,
			 s => '0',
			 z => Ht_next_en_2_en); 

	Htm1_next_reg_2_en : th22m_en_gen
		generic map(bitwidth => maxBitwidth*maxLayerSize)
		port map(a => Ht_next_reg_out_zero,
			en => Ht_next_en_2_en,
			sleep => Ht_next_reg_ko,
			z => Htm1_next_reg_2_in);

--	Htm1_next_reg_2_comp : compdm
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(a => Htm1_next_reg_2_in,
--			ki => Main_ko_select_2,
--			rst => reset,
--			sleep => Ht_next_reg_ko,
--			ko => Htm1_next_reg_2_ko);

--ADD split comp
	Htm1_next_reg_2_comp_lower : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_2_in((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => Main_ko_select_2,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_2_ko_lower);

	Htm1_next_reg_2_comp_upper : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_2_in(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => Main_ko_select_2,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_2_ko_upper);

Ht_next_reg_2_ko_upper_lower : th22_a
	port map(a => Htm1_next_reg_2_ko_lower, 
			 b => Htm1_next_reg_2_ko_upper,
			 z => Htm1_next_reg_2_ko_mux); 

	Ht_next_2_ko_a_mux : MUX21_A
		port map(A => Htm1_next_reg_2_ko_lower,
			B => Htm1_next_reg_2_ko_mux,
			S => configBits_prev(1).rail1,
		 	Z => Htm1_next_reg_2_ko);

--END split comp

	Htm1_2_mux_select_gate : th22m_a
		port map(a => layerNumber(0).rail0,
			 b => layerNumber(1).rail1,
			 s => '0',
			 z => configBits_select_2); 

	Htm1_next_reg_2_ki_mux : MUX21_A
		port map(A => '1',
			B => Main_ko,
			S => configBits_select_2,
		 	Z => Main_ko_select_2);

	Htm1_next_reg_2_reg : regs_gen_zero_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Htm1_next_reg_2_in,
			q => Htm1_next_reg_2_out,
			reset => reset,
			sleep => Htm1_next_reg_2_ko);

	Htm1_3_en_select_gate : th22m_a
		port map(a => configBits_prev(62).rail1,
			 b => configBits_prev(63).rail1,
			 s => '0',
			 z => Ht_next_en_3_en); 

	Htm1_next_reg_3_en : th22m_en_gen
		generic map(bitwidth => maxBitwidth*maxLayerSize)
		port map(a => Ht_next_reg_out_zero,
			en => Ht_next_en_3_en,
			sleep => Ht_next_reg_ko,
			z => Htm1_next_reg_3_in);

--	Htm1_next_reg_3_comp : compdm
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(a => Htm1_next_reg_3_in,
--			ki => Main_ko_select_3,
--			rst => reset,
--			sleep => Ht_next_reg_ko,
--			ko => Htm1_next_reg_3_ko);

--ADD split comp
	Htm1_next_reg_3_comp_lower : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_3_in((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => Main_ko_select_3,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_3_ko_lower);

	Htm1_next_reg_3_comp_upper : compdm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Htm1_next_reg_3_in(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => Main_ko_select_3,
			rst => reset,
			sleep => Ht_next_reg_ko,
			ko => Htm1_next_reg_3_ko_upper);

Ht_next_reg_3_ko_upper_lower : th22_a
	port map(a => Htm1_next_reg_3_ko_lower, 
			 b => Htm1_next_reg_3_ko_upper,
			 z => Htm1_next_reg_3_ko_mux); 

	Ht_next_3_ko_a_mux : MUX21_A
		port map(A => Htm1_next_reg_3_ko_lower,
			B => Htm1_next_reg_3_ko_mux,
			S => configBits_prev(1).rail1,
		 	Z => Htm1_next_reg_3_ko);

--END split comp

	Htm1_3_mux_select_gate : th22m_a
		port map(a => layerNumber(0).rail1,
			 b => layerNumber(1).rail1,
			 s => '0',
			 z => configBits_select_3); 

	Htm1_next_reg_3_ki_mux : MUX21_A
		port map(A => '1',
			B => Main_ko,
			S => configBits_select_3,
		 	Z => Main_ko_select_3);

	Htm1_next_reg_3_reg : regs_gen_zero_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Htm1_next_reg_3_in,
			q => Htm1_next_reg_3_out,
			reset => reset,
			sleep => Htm1_next_reg_3_ko);

htm1_mux_in <= Htm1_next_reg_3_out & Htm1_next_reg_2_out & Htm1_next_reg_1_out & Htm1_next_reg_0_out;

	htm1_Mux : mux_nto1_gen
		generic map(bitwidth => maxBitwidth*maxLayerSize,
			numInputs => 4)
    		port map(a => htm1_mux_in,
			sel => layerNumber,
		 	sleep => '0',
		 	z => Main_Htm1);

	xt_mux : mux_21_gen_nic
		generic map(width => maxBitwidth*maxLayerSize)
	   	port map(a => Xt_next_reg_out,
		 	 b => Xt,
			sel => Xt_ko_select,
			 sleep => '0',
			 z => Main_Xt);

	Xt_ko_Mux : MUX21_A
		port map(A => '0',
			B => Main_ko,
			S => xt_ko_select_real,
		 	Z => ko);

--------Zt BIAS-------------------------------------

Zt_bias_in_OAAT : OAAT_in_all_out
	generic map( bitwidth => 16,
		 numInputs => 512,
		 counterWidth => 10, --Log2 of numInputs
		 delay_amount => 6)
	port map(a => Zt_B_in,
		reset_count => const511,
		sleep_in => Zt_B_in_sleep_in,
		 reset => reset,
		 ki => Zt_bias_in_OAAT_ki,
		 ko => Zt_B_in_ko,
		 sleep_out => Zt_bias_in_OAAT_sleep_out,
		 z => zt_bias_all_in);

	Zt_bias_in_OAAT_ki_gate : th44_a 
		port map(a => Zt_bias_layer_0_ko,
			 b => Zt_bias_layer_1_ko,
			 c => Zt_bias_layer_2_ko,
			 d => Zt_bias_layer_3_ko,
			 z => Zt_bias_in_OAAT_ki); 

Zt_bias_layer_0 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => zt_bias_all_in(128*16-1 downto 0),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(0).rail1,
		layerSize => layerSize(0).rail1,
		sleep_in => Zt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Zt_bias_layer_0_ki,
		 ko => Zt_bias_layer_0_ko,
		 sleep_out => Zt_bias_layer_0_sleep_out,
		 accumulate_reset => Zt_bias_layer_0_accReset,
		 count => Zt_bias_layer_0_count,
		 z => Zt_bias_layer_0_out);

	Zt_bias_layer_0_ki_mux : MUX21_A
		port map(A => '1',
			B => Zt_B_ko,
			S => configBits_select_0,
		 	Z => Zt_bias_layer_0_ki);

Zt_bias_layer_1 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => zt_bias_all_in((128*16*2)-1 downto 128*16),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(1).rail1,
		layerSize => layerSize(1).rail1,
		sleep_in => Zt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Zt_bias_layer_1_ki,
		 ko => Zt_bias_layer_1_ko,
		 sleep_out => Zt_bias_layer_1_sleep_out,
		 accumulate_reset => Zt_bias_layer_1_accReset,
		 count => Zt_bias_layer_1_count,
		 z => Zt_bias_layer_1_out);

	Zt_bias_layer_1_ki_mux : MUX21_A
		port map(A => '1',
			B => Zt_B_ko,
			S => configBits_select_1,
		 	Z => Zt_bias_layer_1_ki);

Zt_bias_layer_2 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => zt_bias_all_in((128*16*3)-1 downto (128*16*2)),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(2).rail1,
		layerSize => layerSize(2).rail1,
		sleep_in => Zt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Zt_bias_layer_2_ki,
		 ko => Zt_bias_layer_2_ko,
		 sleep_out => Zt_bias_layer_2_sleep_out,
		 accumulate_reset => Zt_bias_layer_2_accReset,
		 count => Zt_bias_layer_2_count,
		 z => Zt_bias_layer_2_out);

	Zt_bias_layer_2_ki_mux : MUX21_A
		port map(A => '1',
			B => Zt_B_ko,
			S => configBits_select_2,
		 	Z => Zt_bias_layer_2_ki);

Zt_bias_layer_3 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => zt_bias_all_in((128*16*4)-1 downto (128*16*3)),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(3).rail1,
		layerSize => layerSize(3).rail1,
		sleep_in => Zt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Zt_bias_layer_3_ki,
		 ko => Zt_bias_layer_3_ko,
		 sleep_out => Zt_bias_layer_3_sleep_out,
		 accumulate_reset => Zt_bias_layer_3_accReset,
		 count => Zt_bias_layer_3_count,
		 z => Zt_bias_layer_3_out);

	Zt_bias_layer_3_ki_mux : MUX21_A
		port map(A => '1',
			B => Zt_B_ko,
			S => configBits_select_3,
		 	Z => Zt_bias_layer_3_ki);


Zt_bias_layer_out <= Zt_bias_layer_3_out & Zt_bias_layer_2_out & Zt_bias_layer_1_out & Zt_bias_layer_0_out;

	Zt_bias_layer_Mux : mux_nto1_gen
		generic map(bitwidth => 16,
			numInputs => 4)
    		port map(a => Zt_bias_layer_out,
			sel => layerNumber,
		 	sleep => '0',
		 	z => Zt_B);

	Zt_bias_layer_01_sleep_mux : MUX21_A
		port map(A => Zt_bias_layer_0_sleep_out,
			B => Zt_bias_layer_1_sleep_out,
			S => layerNumber(0).rail1,
		 	Z => Zt_bias_layer_01_sleep_out);

	Zt_bias_layer_23_sleep_mux : MUX21_A
		port map(A => Zt_bias_layer_2_sleep_out,
			B => Zt_bias_layer_3_sleep_out,
			S => layerNumber(0).rail1,
		 	Z => Zt_bias_layer_23_sleep_out);

	Zt_bias_layer_sleep_mux : MUX21_A
		port map(A => Zt_bias_layer_01_sleep_out,
			B => Zt_bias_layer_23_sleep_out,
			S => layerNumber(1).rail1,
		 	Z => Zt_bias_layer_sleep_out);

	Zt_bias_sleep_mux : MUX21_A
		port map(A => '1',
			B => Zt_bias_layer_sleep_out,
			S => layerNumberIsNull,
		 	Z => Zt_B_sleep_in);

	layerNumber_null : th14m_a
		port map(a => layerNumber(0).rail0,
			 b => layerNumber(0).rail1,
			 c => layerNumber(1).rail0,
			 d => layerNumber(1).rail1,
			 s => '0', 
			 z => layerNumberIsNull); 


-------Zt BIAS END----------------------------------

--------Sht BIAS-------------------------------------

Sht_bias_in_OAAT : OAAT_in_all_out
	generic map( bitwidth => 16,
		 numInputs => 512,
		 counterWidth => 10, --Log2 of numInputs
		 delay_amount => 6)
	port map(a => Sht_B_in,
		reset_count => const511,
		sleep_in => Sht_B_in_sleep_in,
		 reset => reset,
		 ki => Sht_bias_in_OAAT_ki,
		 ko => Sht_B_in_ko,
		 sleep_out => Sht_bias_in_OAAT_sleep_out,
		 z => Sht_bias_all_in);

	Sht_bias_in_OAAT_ki_gate : th44_a 
		port map(a => Sht_bias_layer_0_ko,
			 b => Sht_bias_layer_1_ko,
			 c => Sht_bias_layer_2_ko,
			 d => Sht_bias_layer_3_ko,
			 z => Sht_bias_in_OAAT_ki); 

Sht_bias_layer_0 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Sht_bias_all_in(128*16-1 downto 0),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(0).rail1,
		layerSize => layerSize(0).rail1,
		sleep_in => Sht_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Sht_bias_layer_0_ki,
		 ko => Sht_bias_layer_0_ko,
		 sleep_out => Sht_bias_layer_0_sleep_out,
		 accumulate_reset => Sht_bias_layer_0_accReset,
		 count => Sht_bias_layer_0_count,
		 z => Sht_bias_layer_0_out);

	Sht_bias_layer_0_ki_mux : MUX21_A
		port map(A => '1',
			B => Sht_B_ko,
			S => configBits_select_0,
		 	Z => Sht_bias_layer_0_ki);

Sht_bias_layer_1 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Sht_bias_all_in((128*16*2)-1 downto 128*16),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(1).rail1,
		layerSize => layerSize(1).rail1,
		sleep_in => Sht_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Sht_bias_layer_1_ki,
		 ko => Sht_bias_layer_1_ko,
		 sleep_out => Sht_bias_layer_1_sleep_out,
		 accumulate_reset => Sht_bias_layer_1_accReset,
		 count => Sht_bias_layer_1_count,
		 z => Sht_bias_layer_1_out);

	Sht_bias_layer_1_ki_mux : MUX21_A
		port map(A => '1',
			B => Sht_B_ko,
			S => configBits_select_1,
		 	Z => Sht_bias_layer_1_ki);

Sht_bias_layer_2 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Sht_bias_all_in((128*16*3)-1 downto (128*16*2)),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(2).rail1,
		layerSize => layerSize(2).rail1,
		sleep_in => Sht_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Sht_bias_layer_2_ki,
		 ko => Sht_bias_layer_2_ko,
		 sleep_out => Sht_bias_layer_2_sleep_out,
		 accumulate_reset => Sht_bias_layer_2_accReset,
		 count => Sht_bias_layer_2_count,
		 z => Sht_bias_layer_2_out);

	Sht_bias_layer_2_ki_mux : MUX21_A
		port map(A => '1',
			B => Sht_B_ko,
			S => configBits_select_2,
		 	Z => Sht_bias_layer_2_ki);

Sht_bias_layer_3 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Sht_bias_all_in((128*16*4)-1 downto (128*16*3)),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(3).rail1,
		layerSize => layerSize(3).rail1,
		sleep_in => Sht_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Sht_bias_layer_3_ki,
		 ko => Sht_bias_layer_3_ko,
		 sleep_out => Sht_bias_layer_3_sleep_out,
		 accumulate_reset => Sht_bias_layer_3_accReset,
		 count => Sht_bias_layer_3_count,
		 z => Sht_bias_layer_3_out);

	Sht_bias_layer_3_ki_mux : MUX21_A
		port map(A => '1',
			B => Sht_B_ko,
			S => configBits_select_3,
		 	Z => Sht_bias_layer_3_ki);


Sht_bias_layer_out <= Sht_bias_layer_3_out & Sht_bias_layer_2_out & Sht_bias_layer_1_out & Sht_bias_layer_0_out;

	Sht_bias_layer_Mux : mux_nto1_gen
		generic map(bitwidth => 16,
			numInputs => 4)
    		port map(a => Sht_bias_layer_out,
			sel => layerNumber,
		 	sleep => '0',
		 	z => Sht_B);

	Sht_bias_layer_01_sleep_mux : MUX21_A
		port map(A => Sht_bias_layer_0_sleep_out,
			B => Sht_bias_layer_1_sleep_out,
			S => layerNumber(0).rail1,
		 	Z => Sht_bias_layer_01_sleep_out);

	Sht_bias_layer_23_sleep_mux : MUX21_A
		port map(A => Sht_bias_layer_2_sleep_out,
			B => Sht_bias_layer_3_sleep_out,
			S => layerNumber(0).rail1,
		 	Z => Sht_bias_layer_23_sleep_out);

	Sht_bias_layer_sleep_mux : MUX21_A
		port map(A => Sht_bias_layer_01_sleep_out,
			B => Sht_bias_layer_23_sleep_out,
			S => layerNumber(1).rail1,
		 	Z => Sht_bias_layer_sleep_out);

	Sht_bias_sleep_mux : MUX21_A
		port map(A => '1',
			B => Sht_bias_layer_sleep_out,
			S => layerNumberIsNull,
		 	Z => Sht_B_sleep_in);

-------Sht BIAS END----------------------------------

--------Rt BIAS-------------------------------------

Rt_bias_in_OAAT : OAAT_in_all_out
	generic map( bitwidth => 16,
		 numInputs => 512,
		 counterWidth => 10, --Log2 of numInputs
		 delay_amount => 6)
	port map(a => Rt_B_in,
		reset_count => const511,
		sleep_in => Rt_B_in_sleep_in,
		 reset => reset,
		 ki => Rt_bias_in_OAAT_ki,
		 ko => Rt_B_in_ko,
		 sleep_out => Rt_bias_in_OAAT_sleep_out,
		 z => rt_bias_all_in);

	Rt_bias_in_OAAT_ki_gate : th44_a 
		port map(a => Rt_bias_layer_0_ko,
			 b => Rt_bias_layer_1_ko,
			 c => Rt_bias_layer_2_ko,
			 d => Rt_bias_layer_3_ko,
			 z => Rt_bias_in_OAAT_ki); 

Rt_bias_layer_0 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Rt_bias_all_in(128*16-1 downto 0),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(0).rail1,
		layerSize => layerSize(0).rail1,
		sleep_in => Rt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Rt_bias_layer_0_ki,
		 ko => Rt_bias_layer_0_ko,
		 sleep_out => Rt_bias_layer_0_sleep_out,
		 accumulate_reset => Rt_bias_layer_0_accReset,
		 count => Rt_bias_layer_0_count,
		 z => Rt_bias_layer_0_out);

	Rt_bias_layer_0_ki_mux : MUX21_A
		port map(A => '1',
			B => Rt_B_ko,
			S => configBits_select_0,
		 	Z => Rt_bias_layer_0_ki);

Rt_bias_layer_1 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Rt_bias_all_in((128*16*2)-1 downto 128*16),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(1).rail1,
		layerSize => layerSize(1).rail1,
		sleep_in => Rt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Rt_bias_layer_1_ki,
		 ko => Rt_bias_layer_1_ko,
		 sleep_out => Rt_bias_layer_1_sleep_out,
		 accumulate_reset => Rt_bias_layer_1_accReset,
		 count => Rt_bias_layer_1_count,
		 z => Rt_bias_layer_1_out);

	Rt_bias_layer_1_ki_mux : MUX21_A
		port map(A => '1',
			B => Rt_B_ko,
			S => configBits_select_1,
		 	Z => Rt_bias_layer_1_ki);

Rt_bias_layer_2 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Rt_bias_all_in((128*16*3)-1 downto (128*16*2)),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(2).rail1,
		layerSize => layerSize(2).rail1,
		sleep_in => Rt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Rt_bias_layer_2_ki,
		 ko => Rt_bias_layer_2_ko,
		 sleep_out => Rt_bias_layer_2_sleep_out,
		 accumulate_reset => Rt_bias_layer_2_accReset,
		 count => Rt_bias_layer_2_count,
		 z => Rt_bias_layer_2_out);

	Rt_bias_layer_2_ki_mux : MUX21_A
		port map(A => '1',
			B => Rt_B_ko,
			S => configBits_select_2,
		 	Z => Rt_bias_layer_2_ki);

Rt_bias_layer_3 : RCF_OAAT_out_all_in_128_forever
	generic map(bitwidth => 16,
		numInputs => 128)
	port map(	 
		a => Rt_bias_all_in((128*16*4)-1 downto (128*16*3)),
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth(3).rail1,
		layerSize => layerSize(3).rail1,
		sleep_in => Rt_bias_in_OAAT_sleep_out,
		 reset => reset,
		 ki => Rt_bias_layer_3_ki,
		 ko => Rt_bias_layer_3_ko,
		 sleep_out => Rt_bias_layer_3_sleep_out,
		 accumulate_reset => Rt_bias_layer_3_accReset,
		 count => Rt_bias_layer_3_count,
		 z => Rt_bias_layer_3_out);

	Rt_bias_layer_3_ki_mux : MUX21_A
		port map(A => '1',
			B => Rt_B_ko,
			S => configBits_select_3,
		 	Z => Rt_bias_layer_3_ki);


Rt_bias_layer_out <= Rt_bias_layer_3_out & Rt_bias_layer_2_out & Rt_bias_layer_1_out & Rt_bias_layer_0_out;

	Rt_bias_layer_out_Mux : mux_nto1_gen
		generic map(bitwidth => 16,
			numInputs => 4)
    		port map(a => Rt_bias_layer_out,
			sel => layerNumber,
		 	sleep => '0',
		 	z => Rt_B);

	Rt_bias_layer_01_sleep_mux : MUX21_A
		port map(A => Rt_bias_layer_0_sleep_out,
			B => Rt_bias_layer_1_sleep_out,
			S => layerNumber(0).rail1,
		 	Z => Rt_bias_layer_01_sleep_out);

	Rt_bias_layer_23_sleep_mux : MUX21_A
		port map(A => Rt_bias_layer_2_sleep_out,
			B => Rt_bias_layer_3_sleep_out,
			S => layerNumber(0).rail1,
		 	Z => Rt_bias_layer_23_sleep_out);

	Rt_bias_layer_sleep_mux : MUX21_A
		port map(A => Rt_bias_layer_01_sleep_out,
			B => Rt_bias_layer_23_sleep_out,
			S => layerNumber(1).rail1,
		 	Z => Rt_bias_layer_sleep_out);

	Rt_bias_sleep_mux : MUX21_A
		port map(A => '1',
			B => Rt_bias_layer_sleep_out,
			S => layerNumberIsNull,
		 	Z => Rt_B_sleep_in);

-------Rt BIAS END----------------------------------



GRNN_Computation : GRNN_layer_w_mem
	generic map(maxBitwidth => maxBitwidth,
		maxLayerSize => maxLayerSize)
	port map(	
		--Layer Constants
		layerBitwidth => configBits(0).rail1,
		layerSize => configBits(1),
		layerType => configBits(2),
		layerIsInput => configBits(3),
		prevLayerSize => configBits(4).rail1,
		layerNumber => layerNumber,
		zeta => configBits(41 downto 26),
		nu => configBits(57 downto 42),

		--Primary Layer Inputs
		Xt => Main_Xt,
		Ht => Main_Htm1,
		reset => reset,
		sleep_in => Main_sleep_in,
		ki => Ht_next_reg_ko,

		--Bias Ports
		Zt_B => Zt_B,
		Zt_B_sleep_in => Zt_B_sleep_in,
		Zt_B_ko => Zt_B_ko,

		Rt_B => Rt_B,
		Rt_B_sleep_in => Rt_B_sleep_in,
		Rt_B_ko => Rt_B_ko,

		Sht_B => Sht_B,
		Sht_B_sleep_in => Sht_B_sleep_in,
		Sht_B_ko => Sht_B_ko,

		--Memory Ports
		Zt_W => Zt_W,
		Zt_sleep_in => Zt_sleep_in,
		Zt_ko => Zt_ko,

		Rt_W => Rt_W,
		Rt_sleep_in => Rt_sleep_in,
		Rt_ko => Rt_ko,

		Sht_W => Sht_W,
		Sht_sleep_in => Sht_sleep_in,
		Sht_ko => Sht_ko,

		writeEn => writeEn,

		--Truncation Ports
		trunc_zt => configBits(7 downto 5),
		trunc_htm1_zt => configBits(10 downto 8),
		trunc_zeta => configBits(13 downto 11),
		trunc_rt => configBits(16 downto 14),
		trunc_htm1_rt => configBits(19 downto 17),
		trunc_sht => configBits(22 downto 20),
		trunc_ztm1_sht => configBits(25 downto 23),
		trunc_bitchange => configBits(60 downto 58),

		--Primary Layer Outputs
		sleep_out => Main_sleep_out,
		ko => Main_ko,
		z_8 => Ht_next_8,
		z_16 => Ht_next_16
	);

--	ht_next_reg_comp : compm
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(a => Ht_next,
--			ki => ht_reg_ki,
--			rst => reset,
--			sleep => Main_sleep_out,
--			ko => Ht_next_reg_ko_a);

--ADD split comp

--	ht_next_reg_comp_lower : compm
--		generic map(width => maxBitwidth*maxLayerSize/2)
--		port map(a => Ht_next((maxBitwidth*maxLayerSize/2)-1 downto 0),
--			ki => ht_reg_ki,
--			rst => reset,
--			sleep => Main_sleep_out,
--			ko => Ht_next_reg_ko_a_lower);
--
--	ht_next_reg_comp_upper : compm
--		generic map(width => maxBitwidth*maxLayerSize/2)
--		port map(a => Ht_next(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
--			ki => ht_reg_ki,
--			rst => reset,
--			sleep => Main_sleep_out,
--			ko => Ht_next_reg_ko_a_upper);
--
--Ht_next_reg_ko_upper_lower : th22_a
--	port map(a => Ht_next_reg_ko_a_lower, 
--			 b => Ht_next_reg_ko_a_upper,
--			 z => Ht_next_reg_ko_a_mux); 
--
--	Ht_next_ko_a_mux : MUX21_A
--		port map(A => Ht_next_reg_ko_a_lower,
--			B => Ht_next_reg_ko_a_mux,
--			S => configBits(1).rail1,
--		 	Z => Ht_next_reg_ko_a);
--
--END split comp
--
--
--	ht_next_reg : regs_gen_null_res
--		generic map(width => maxBitwidth*maxLayerSize)
--		port map(d => Ht_next,
--			q => Ht_next_reg_out,
--			reset => reset,
--			sleep => Ht_next_reg_ko);
--
--------------------------------------------------------------------------------------------------------
	ht_next_reg_8_comp_lower : compm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Ht_next_8((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => ht_reg_ki,
			rst => reset,
			sleep => Main_sleep_out,
			ko => Ht_next_reg_8_ko_a_lower);

	ht_next_reg_8_comp_upper : compm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Ht_next_8(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => ht_reg_ki,
			rst => reset,
			sleep => Main_sleep_out,
			ko => Ht_next_reg_8_ko_a_upper);

Ht_next_reg_8_ko_upper_lower : th22_a
	port map(a => Ht_next_reg_8_ko_a_lower, 
			 b => Ht_next_reg_8_ko_a_upper,
			 z => Ht_next_reg_8_ko_a_mux); 

	Ht_next_8_ko_a_mux : MUX21_A
		port map(A => Ht_next_reg_8_ko_a_lower,
			B => Ht_next_reg_8_ko_a_mux,
			S => configBits(1).rail1,
		 	Z => Ht_next_reg_8_ko);

--END split comp


	ht_next_reg_8 : regs_gen_null_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Ht_next_8,
			q => Ht_next_reg_8_out,
			reset => reset,
			sleep => Ht_next_reg_ko);
-----------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
	ht_next_reg_16_comp_lower : compm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Ht_next_16((maxBitwidth*maxLayerSize/2)-1 downto 0),
			ki => ht_reg_ki,
			rst => reset,
			sleep => Main_sleep_out,
			ko => Ht_next_reg_16_ko_a_lower);

	ht_next_reg_16_comp_upper : compm
		generic map(width => maxBitwidth*maxLayerSize/2)
		port map(a => Ht_next_16(maxBitwidth*maxLayerSize-1 downto (maxBitwidth*maxLayerSize/2)),
			ki => ht_reg_ki,
			rst => reset,
			sleep => Main_sleep_out,
			ko => Ht_next_reg_16_ko_a_upper);

Ht_next_reg_16_ko_upper_lower : th22_a
	port map(a => Ht_next_reg_16_ko_a_lower, 
			 b => Ht_next_reg_16_ko_a_upper,
			 z => Ht_next_reg_16_ko_a_mux); 

	Ht_next_16_ko_a_mux : MUX21_A
		port map(A => Ht_next_reg_16_ko_a_lower,
			B => Ht_next_reg_16_ko_a_mux,
			S => configBits(1).rail1,
		 	Z => Ht_next_reg_16_ko);

--END split comp


	ht_next_reg_16 : regs_gen_null_res
		generic map(width => maxBitwidth*maxLayerSize)
		port map(d => Ht_next_16,
			q => Ht_next_reg_16_out,
			reset => reset,
			sleep => Ht_next_reg_ko);
-----------------------------------------------------------------------------------------------
Actual_Ht_next_mux : mux_21_gen 
		generic map(width => maxBitwidth*maxLayerSize)
    port map(a => Ht_next_reg_8_out,
	 	 b => Ht_next_reg_16_out,
		sel => configBits_prev(0),
		 sleep => Ht_next_reg_ko,
		 z => Ht_next_reg_out);

Actual_Xt_next_mux : mux_21_gen 
		generic map(width => maxBitwidth*maxLayerSize)
    port map(a => Ht_next_reg_8_out,
	 	 b => Ht_next_reg_16_out,
		sel => configBits_prev(61),
		 sleep => Ht_next_reg_ko,
		 z => Xt_next_mux_out);




-----------------------------------------------------------------------------------------------

configBits_reg <= layerNumber & configBits;

	configBits_prev_reg_comp : compm
		generic map(width => 64)
		port map(a => configBits_reg,
			ki => ht_reg_ki,
			rst => reset,
			sleep => Main_sleep_out,
			ko => Ht_next_reg_ko_b);

	configBits_prev_reg : regs_gen_null_res
		generic map(width => 64)
		port map(d => configBits_reg,
			q => configBits_prev,
			reset => reset,
			sleep => Ht_next_reg_ko);

runCounter : TwoPhaseCounter
	generic map(width_lower => 4,
		width_upper => 8)
	port map(reset_count_lower => numberLayers_ext,
		reset_count_upper => inputWidth,
		sleep_in => '0',
		reset => reset,
		ki => Ht_next_reg_ko,
		ko => runCounterko,
		sleep_out => runCounter_sleep_out,
		upper_is_max => counterBits(14),
		accumulate_reset_lower => counterBits(12),
		accumulate_reset_upper => counterBits(13),
		z => counterBits(11 downto 0));

	counterBits_reg_comp : compm
		generic map(width => 15)
		port map(a => counterBits,
			ki => ht_reg_ki,
			rst => reset,
			sleep => Main_sleep_out,
			ko => Ht_next_reg_ko_c);

	counterBits_reg : regs_gen_null_res
		generic map(width => 15)
		port map(d => counterBits,
			q => counterBits_prev,
			reset => reset,
			sleep => Ht_next_reg_ko);

Ht_next_reg_ko_gate : th44_a
	port map(a => Ht_next_reg_8_ko, 
			 b => Ht_next_reg_ko_b,
			 c => Ht_next_reg_ko_c,
			 d => Ht_next_reg_16_ko,
			 z => Ht_next_reg_ko); 

	ht_next_reg_ki_and_gate : th14m_a
		port map(a => Htm1_next_reg_0_ko,
			 b => Htm1_next_reg_1_ko,
			 c => Htm1_next_reg_2_ko,
			 d => Htm1_next_reg_3_ko,
			 s => '0',
			 z => ht_next_reg_ki_and); 

	ht_next_reg_ki_gate : th22_a
		port map(a => ht_next_reg_ki_and, 
			 b => Xt_next_reg_ko,
			 z => ht_next_reg_ki); 

	Ht_next_ki_mux : MUX21_A
		port map(A => ht_next_reg_ki,
			B => ki,
			S => counterBits_prev(13).rail1,
		 	Z => ht_reg_ki);

	Ht_out_en : th22m_en_gen
		generic map(bitwidth => maxBitwidth*maxLayerSize)
		port map(a => Ht_next_reg_out,
			en => counterBits_prev(13).rail1,
			sleep => Ht_next_reg_ko,
			z => z);
sleep_out <= Ht_next_reg_ko;

end arch_GRNN_control_w_mem; 
