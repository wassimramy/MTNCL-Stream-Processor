library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;
use ieee.math_real.all;

entity GRNN_layer_w_mem is
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
end GRNN_layer_w_mem;

architecture arch_GRNN_layer_w_mem of GRNN_layer_w_mem is 

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

component th22_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 z: out std_logic); 
end component; 

component th44_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 z: out std_logic); 
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

component MUX21_dr_gen is 
	generic(bitwidth : integer);
	port(A: in dual_rail_logic_vector(bitwidth-1 downto 0); 
		B: in dual_rail_logic_vector(bitwidth-1 downto 0);
		S: in std_logic;
		 Z: out dual_rail_logic_vector(bitwidth-1 downto 0)); 
end component; 

component mult_8_16 is
	port(a: in dual_rail_logic_vector(15 downto 0);
		b: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
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

component convert_8_16 is
	port(a : in dual_rail_logic_vector(15 downto 0);
		correct_sign : in dual_rail_logic;
		trunc : in dual_rail_logic_vector(2 downto 0);
		sleep : in std_logic;
		z : out dual_rail_logic_vector(15 downto 0)
	);
end component;

component MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end component; 

component or2_a is 
	port(a: in std_logic; 
		b: in std_logic;
		 z: out std_logic); 
end component; 

component and2_A is 
	port(A: in std_logic; 
		B: in std_logic;
		 Z: out std_logic); 
end component; 

component xor2_a is 
	port(a: in std_logic; 
		b: in std_logic;
		 z: out std_logic); 
end component; 

component RCF_OAAT_in_all_out is
	generic( bitwidth : integer := 16;
		 numInputs : integer := 64;
		 counterWidth : integer := 6; --Log2 of numInputs
		 delay_amount : integer := 6);
	port(	 a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset_count : in dual_rail_logic_vector(counterWidth-1 downto 0);
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 z: out dual_rail_logic_vector(numInputs*bitwidth-1 downto 0));
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

component RCF_OAAT_out_all_in_RPT is
	generic(reset_count_upper_width: integer := 8; 
		bitwidth: integer := 16;
		numInputs : integer := 64);
	port(	 
		
		a : in dual_rail_logic_vector(numInputs*bitwidth-1 downto 0);
		reset_count_lower : in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0); --CHANGE COUNTER WIDTH
		reset_count_upper : in dual_rail_logic_vector(reset_count_upper_width-1 downto 0); --CHANGE COUNTER WIDTH
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		layerSize	: std_logic; --0 = 64, 1 = 128
		layerIsInput	: std_logic; --0 = no, 1 = yes
		prevLayerSize	: std_logic; --0 = 64, 1 = 128
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

component RCF_OAAT_out_all_in_128 is
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

component LUT_tanh_8_16 is
	port(	 a : in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 z: out dual_rail_logic_vector(15 downto 0));
end component;

component LUT_sigmoid_8_16 is
	port(	 a : in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		sleep_in: in std_logic;
		 reset: in std_logic;
		 ki: in std_logic;
		 ko: out std_logic;
		 sleep_out: out std_logic;
		 z: out dual_rail_logic_vector(15 downto 0));
end component;


component one_sub_8_16_reverse is
	port(a: in dual_rail_logic_vector(15 downto 0);
		b: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset : in std_logic;
		sleep_in : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(15 downto 0));
end component;

component one_mult_8_16 is
	port(a: in dual_rail_logic_vector(15 downto 0);
		b: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset : in std_logic;
		sleep_in : in std_logic;
		trunc : in dual_rail_logic_vector(2 downto 0);
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(15 downto 0));
end component;

component one_adder_8_16 is
	port(a: in dual_rail_logic_vector(15 downto 0);
		b: in dual_rail_logic_vector(15 downto 0);
		RCF_width : in std_logic;		--0 = 8, 1 = 16
		reset : in std_logic;
		sleep_in : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(15 downto 0));
end component;

component addressGen is
	generic(Lower_count_size : integer := 8;
		Upper_count_size : integer := 8;
		Address_width : integer := 12);
	port(R_reset_count_lower : dual_rail_logic_vector(Lower_count_size-1 downto 0);
		R_reset_count_upper : dual_rail_logic_vector(Upper_count_size-1 downto 0);
		R_accumulate_reset_lower : in dual_rail_logic;
		R_accumulate_reset_upper : in dual_rail_logic;
		R_LayerNumber : in dual_rail_logic_vector(1 downto 0);
		W_data : in dual_rail_logic_vector(15 downto 0);
		isInputLayer : in dual_rail_logic;
		writeEn : in dual_rail_logic;
		hSize : in dual_rail_logic;
		reset : in std_logic;
		R_sleep_in : in std_logic;
		W_sleep_in : in std_logic;
		ki : in std_logic;
		R_ko : out std_logic;
		W_ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(Address_width+1+16 downto 0));
end component;

component weightMemory_2176x16 is
	generic(bitwidth : integer := 16;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(address : in dual_rail_logic_vector(11 downto 0);
		mem_data : in dual_rail_logic_vector(15 downto 0);
		write_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end component;

component weightMemory_4096x16 is
	generic(bitwidth : integer := 16;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(address : in dual_rail_logic_vector(11 downto 0);
		mem_data : in dual_rail_logic_vector(15 downto 0);
		write_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
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

component weightMemory_4Layers is
	generic(bitwidth : integer := 16;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(address : in dual_rail_logic_vector(11 downto 0);
		layerNumber : in dual_rail_logic_vector(1 downto 0);
		mem_data : in dual_rail_logic_vector(15 downto 0);
		write_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end component;

component mux_nto1_gen is
	generic(bitwidth: integer := 16;
		numInputs : integer := 64);
    port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
		sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component convert_16_8 is
	port(a : in dual_rail_logic_vector(15 downto 0);
		correct_sign : in dual_rail_logic;
		trunc : in dual_rail_logic_vector(2 downto 0);
		sleep : in std_logic;
		z : out dual_rail_logic_vector(15 downto 0)
	);
end component;

signal data0, data1, xh_oaat_acc_reset, htm1_for_zt_acc_reset, htm1_for_rt_acc_reset, sh_xh_oaat_acc_reset, zt_pre_bias_reg_out_acc_reset, xh_oaat_lowerIsMax, xh_oaat_upperIsMax, layerSize_MuxOut, zt_writeEn, rt_writeEn, sh_xh_oaat_lowerIsMax, sh_xh_oaat_upperIsMax, sht_writeEn : dual_rail_logic;
signal ko_grnn, layerSize_or_prevLayerSize, layerSize_xor_prevLayerSize, htm1_for_zt_ko, xh_oaat_ko, htm1_for_rt_ko, xt_sh_reg_ko, ko_gru, xh_oaat_ki, xh_oaat_sleep_out, zt_mult_of_acc_ko, sht_mult_of_acc_ko, xh_ki_gru, zt_mem_sleep_out, zt_mult_of_ki, zt_mult_of_acc_sleep_out, zt_bias_adder_ko, sht_bias_adder_ko, sht_mult_ko, zt_ko_grnn, zt_bias_sleep_out, zt_LUT_ko, htm1_zt_mult_ko, one_minus_zt_ko, zt_LUT_ki, zt_LUT_sleep_out, htm1_for_zt_sleep_out, ht_adder_ko, htm1_zt_sleep_out, zeta_mult_ko, one_minus_ki, one_minus_zt_sleep_out, nu_adder_ko, zeta_mult_sleep_out, nu_sleep_out, rt_mem_sleep_out, rt_mult_of_acc_ko, rt_mult_of_acc_sleep_out, rt_LUT_ko, rt_bias_adder_ko, rt_bias_sleep_out, rt_htm1_mult_ko, rt_LUT_sleep_out, htm1_for_rt_sleep_out, htm1_reg_ko, rt_htm1_mult_sleep_out, rt_htm1_reg_ko, sh_xh_oaat_ko, rt_htm1_reg_sleep_out, xt_sh_reg_bottom64, xt_sh_reg_lower64, bottom64_lower64, sht_mult_sleep_in, sh_xh_oaat_sleep_out, sht_mult_of_acc_sleep_out, sht_zt_mux_sleep_out, sht_LUT_ko, sht_bias_sleep_out, sht_LUT_sleep_out, one_minus_z_mux_sleep_out, sht_mult_sleep_out, output_reg_ko, ht_adder_sleep_out, output_reg_sleep_out, zt_pre_bias_reg_in_ko, zt_pre_bias_reg_out_ko, zt_pre_bias_reg_in_sleep_out, zt_pre_bias_reg_out_sleep_out, gen_comp_units_sleep_in, zt_addr_mult_ko, rt_addr_mult_ko, zt_memAddress_R_ko, zt_memAddress_ki, Zt_data_comp_ko, zt_memAddress_W_ko, zt_memAddress_sleep_out, layerNumber_0, layerNumber_1, layerNumber_2, layerNumber_3, zt_mem_read_sleep_0, Zt_weightMem_0_ki, Zt_weightMem_0_ko, Zt_weightMem_0_sleep_out, zt_mem_read_sleep_1, Zt_weightMem_1_ki, Zt_weightMem_1_ko, Zt_weightMem_1_sleep_out, Zt_weightMem_2_ki, Zt_weightMem_2_ko, zt_mem_read_sleep_2, Zt_weightMem_2_sleep_out, Zt_weightMem_3_ki, Zt_weightMem_3_ko, zt_mem_read_sleep_3, Zt_weightMem_3_sleep_out, zt_mem_mux_01_sleep, zt_mem_mux_23_sleep, zt_mem_mux_sleep, rt_memAddress_R_ko, rt_memAddress_ki, Rt_data_comp_ko, rt_memAddress_W_ko, rt_memAddress_sleep_out, rt_mem_read_sleep_0, Rt_weightMem_0_ki, Rt_weightMem_0_ko, Rt_weightMem_0_sleep_out, rt_mem_read_sleep_1, Rt_weightMem_1_ki, Rt_weightMem_1_ko, Rt_weightMem_1_sleep_out, Rt_weightMem_2_ki, Rt_weightMem_2_ko, rt_mem_read_sleep_2, Rt_weightMem_2_sleep_out, Rt_weightMem_3_ki, Rt_weightMem_3_ko, rt_mem_read_sleep_3, Rt_weightMem_3_sleep_out, rt_mem_mux_01_sleep, rt_mem_mux_23_sleep, rt_mem_mux_sleep, rt_mult_of_acc_sleep_in_a, sht_memAddress_R_ko, sht_memAddress_ki, Sht_data_comp_ko, sht_memAddress_W_ko, sht_memAddress_sleep_out, sht_mem_read_sleep_0, Sht_weightMem_0_ki, Sht_weightMem_0_ko, Sht_weightMem_0_sleep_out, sht_mem_read_sleep_1, Sht_weightMem_1_ki, Sht_weightMem_1_ko, Sht_weightMem_1_sleep_out, Sht_weightMem_2_ki, Sht_weightMem_2_ko, sht_mem_read_sleep_2, Sht_weightMem_2_sleep_out, Sht_weightMem_3_ki, Sht_weightMem_3_ko, sht_mem_read_sleep_3, Sht_weightMem_3_sleep_out, sht_mem_mux_01_sleep, sht_mem_mux_23_sleep, sht_mem_mux_sleep, sht_addr_mult_ko, zt_address_mux_ki, zt_address_mux_01_ki, zt_address_mux_23_ki, Zt_ko_a, Zt_weightMem_ko, Zt_weightMem_ki, Zt_weightMem_sleep_out, Rt_weightMem_ko, Rt_weightMem_ki, Rt_weightMem_sleep_out, Sht_weightMem_ko, Shr_weightMem_ki, Sht_weightMem_sleep_out, mux16_sleep, mux8_sleep, output_reg_8_ko, output_reg_16_ko, output_reg_8_sleep_out, output_reg_16_sleep_out  : std_logic;

signal xt_sh_reg_tree : std_logic_vector(maxLayerSize-1 downto 0);

signal Zt_address_out, Rt_address_out, Sht_address_out : dual_rail_logic_vector(29 downto 0);

signal const63, const64, const127, const128, const191, const255, const63_127, inputLayer_64_128, layer_127_255, layer_191, const_acc_value : dual_rail_logic_vector(7 downto 0);

signal xh_oaat_count, sh_xh_oaat_count, Zt_W_reg_out, Rt_W_reg_out, Sht_W_reg_out, Zt_weightMem_out, Rt_weightMem_out, Sht_weightMem_out : dual_rail_logic_vector(15 downto 0);

signal xh_oaat_in, sh_xh_oaat_in : dual_rail_logic_vector(2*maxLayerSize*maxBitwidth-1 downto 0);

signal rt_htm1_reg_out, Xt_sh_out, zt_pre_bias_oaat_between : dual_rail_logic_vector(maxLayerSize*maxBitwidth-1 downto 0);

signal htm1_for_zt_count, htm1_for_rt_count, zt_pre_bias_reg_out_count : dual_rail_logic_vector(6 downto 0);

signal xh_oaat_out, zt_pre_bias, zt_bias_out, zt, htm1_for_zt, htm1_zt_out, const1_8bit, const1_16bit, one_mux_out, one_minus_zt, zeta_mult_out, nu_adder_out, one_minus_z_mux_out, rt_pre_bias, rt_bias_out, rt, htm1_rt, rt_htm1_mult_out, sh_xh_oaat_out, sht_pre_bias, sht_bias_out , sht_zt_mux_out, sht, sht_mult_out, ht_adder_out, zt_pre_bias_oaat_in, Zt_weightMem_0_out, Zt_weightMem_1_out, Zt_weightMem_2_out, Zt_weightMem_3_out, zt_mem_mux_01_out, zt_mem_mux_23_out, zt_mem_mux_out, Rt_weightMem_0_out, Rt_weightMem_1_out, Rt_weightMem_2_out, Rt_weightMem_3_out, rt_mem_mux_01_out, rt_mem_mux_23_out, rt_mem_mux_out, Sht_weightMem_0_out, Sht_weightMem_1_out, Sht_weightMem_2_out, Sht_weightMem_3_out, sht_mem_mux_01_out, sht_mem_mux_23_out, sht_mem_mux_out, ht_adder_out_bottom8_replace, output_mux_in_16, output_reg_16_in, output_mux_in_8, output_reg_8_in : dual_rail_logic_vector(maxBitwidth-1 downto 0);

signal mux_out_16, mux_out_8 : dual_rail_logic_vector(7 downto 0);

signal mux_in_16, mux_in_8 : dual_rail_logic_vector(63 downto 0);

begin 
data0.rail0 <= '1';
data0.rail1 <= '0';

data1.rail0 <= '0';
data1.rail1 <= '1';

--const1_8bit
const1_8bit(0) <= data0;
const1_8bit(1) <= data0;
const1_8bit(2) <= data0;
const1_8bit(3) <= data0;
const1_8bit(4) <= data0;
const1_8bit(5) <= data0;
const1_8bit(6) <= data0;
const1_8bit(7) <= data0;
const1_8bit(8) <= data1;
const1_8bit(9) <= data1;
const1_8bit(10) <= data1;
const1_8bit(11) <= data1;
const1_8bit(12) <= data1;
const1_8bit(13) <= data1;
const1_8bit(14) <= data1;
const1_8bit(15) <= data0;
--const1_16bit

const1_16bit(0) <= data0;
const1_16bit(1) <= data0;
const1_16bit(2) <= data0;
const1_16bit(3) <= data0;
const1_16bit(4) <= data0;
const1_16bit(5) <= data0;
const1_16bit(6) <= data0;
const1_16bit(7) <= data0;
const1_16bit(8) <= data0;
const1_16bit(9) <= data0;
const1_16bit(10) <= data0;
const1_16bit(11) <= data0;
const1_16bit(12) <= data0;
const1_16bit(13) <= data1;
const1_16bit(14) <= data0;
const1_16bit(15) <= data0;

const63(0) <= data1;
const63(1) <= data1;
const63(2) <= data1;
const63(3) <= data1;
const63(4) <= data1;
const63(5) <= data1;
const63(6) <= data0;
const63(7) <= data0;

const64(0) <= data0;
const64(1) <= data0;
const64(2) <= data0;
const64(3) <= data0;
const64(4) <= data0;
const64(5) <= data0;
const64(6) <= data1;
const64(7) <= data0;

const127(0) <= data1;
const127(1) <= data1;
const127(2) <= data1;
const127(3) <= data1;
const127(4) <= data1;
const127(5) <= data1;
const127(6) <= data1;
const127(7) <= data0;

const128(0) <= data0;
const128(1) <= data0;
const128(2) <= data0;
const128(3) <= data0;
const128(4) <= data0;
const128(5) <= data0;
const128(6) <= data0;
const128(7) <= data1;

const191(0) <= data1;
const191(1) <= data1;
const191(2) <= data1;
const191(3) <= data1;
const191(4) <= data1;
const191(5) <= data1;
const191(6) <= data0;
const191(7) <= data1;

const255(0) <= data1;
const255(1) <= data1;
const255(2) <= data1;
const255(3) <= data1;
const255(4) <= data1;
const255(5) <= data1;
const255(6) <= data1;
const255(7) <= data1;

mux_63_127_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => const63,
		B => const127,
		S => layerSize.rail1,
		 Z => const63_127);

inputLayer_64_128_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => const64,
		B => const128,
		S => layerSize.rail1,
		 Z => inputLayer_64_128); 

layerSize_or_prevLayerSize_gate : or2_a
	port map(a => layerSize.rail1,
		b => prevLayerSize,
		 z => layerSize_or_prevLayerSize);

layerSize_xor_prevLayerSize_gate : xor2_a
	port map(a => layerSize.rail1,
		b => prevLayerSize,
		 z => layerSize_xor_prevLayerSize);

layer_127_255_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => const127,
		B => const255,
		S => layerSize_or_prevLayerSize,
		 Z => layer_127_255); 

layer_191_mux : MUX21_dr_gen
	generic map(bitwidth => 8)
	port map(A => layer_127_255,
		B => const191,
		S => layerSize_xor_prevLayerSize,
		 Z => layer_191); 

inputLayer_mux : MUX21_dr_gen 
	generic map(bitwidth => 8)
	port map(A => layer_191,
		B => inputLayer_64_128,
		S => layerIsInput.rail1,
		 Z => const_acc_value); 


ko_gate_grnn : th22_a
	port map(a => xh_oaat_ko, 
			 b => htm1_for_zt_ko,
			 z => ko_grnn); 

ko_gate_gru : th44_a
	port map(a => xh_oaat_ko, 
			 b => htm1_for_zt_ko,
			 c => htm1_for_rt_ko, 
			 d => xt_sh_reg_ko,
			 z => ko_gru); 

Mux_ko : MUX21_A
	port map(A => ko_gru,
		B => ko_grnn,
		S => layerType.rail1,
		 Z => ko);

xh_oaat_in(64*maxBitwidth-1 downto 0) <= Ht(64*maxBitwidth-1 downto 0);

xh_oaat_in_data_mux : MUX21_dr_gen 		--Switch to MTNCL Mux?
	generic map(bitwidth => 64*maxBitwidth)
	port map(A => Xt(64*maxBitwidth-1 downto 0),
		B => Ht(128*maxBitwidth-1 downto 64*maxBitwidth),
		S => layerSize.rail1,
		 Z => xh_oaat_in(128*maxBitwidth-1 downto 64*maxBitwidth)); 

xh_oaat_in(256*maxBitwidth-1 downto 128*maxBitwidth) <= Xt(128*maxBitwidth-1 downto 0);

--ADD Xh_Oaat MUXING
xh_OAAT : RCF_OAAT_out_all_in_RPT
	generic map(reset_count_upper_width => 8,
		bitwidth => maxBitwidth,
		numInputs => 2*maxLayerSize)
	port map(	 
		a => xh_oaat_in,
		reset_count_lower => const_acc_value,
		reset_count_upper => const63_127,
		RCF_width => layerBitwidth,
		layerSize => layerSize.rail1,
		layerIsInput => layerIsInput.rail1,
		prevLayerSize => prevLayerSize,
		sleep_in => sleep_in,
		reset => reset,
		ki => xh_oaat_ki,
		ko => xh_oaat_ko,
		sleep_out => xh_oaat_sleep_out,
		accumulate_reset => xh_oaat_acc_reset,
		lowerIsMax => xh_oaat_lowerIsMax,
		upperIsMax => xh_oaat_upperIsMax,
		count => xh_oaat_count,
		z => xh_oaat_out);

xh_ki_gate_gru : th22_a
	port map(a => zt_addr_mult_ko, 
		 b => rt_addr_mult_ko,
		z => xh_ki_gru); 

xh_ki_Mux : MUX21_A
	port map(A => xh_ki_gru,
		B => zt_addr_mult_ko,
		S => layerType.rail1,
		 Z => xh_oaat_ki);


--zt route--------------------------------------------------

zt_addr_mult_ko_gate : th22_a
	port map(a => zt_mult_of_acc_ko, 
		 b => zt_memAddress_R_ko,
		z => zt_addr_mult_ko); 


----------------ZT MEMORY-------------------

Zt_ko <= zt_memAddress_W_ko;

Zt_addressGen : addressGen
	generic map(Lower_count_size => 8,
		Upper_count_size => 8,
		Address_width => 12)
	port map(R_reset_count_lower => xh_oaat_count(7 downto 0),
		R_reset_count_upper => xh_oaat_count(15 downto 8),
		R_accumulate_reset_lower => xh_oaat_lowerIsMax,
		R_accumulate_reset_upper => xh_oaat_upperIsMax,		--UNUSED PORT
		R_LayerNumber => layerNumber,
		W_data => Zt_W,
		isInputLayer => layerIsInput,
		writeEn => writeEn,
		hSize => layerSize,
		reset => reset,
		R_sleep_in => xh_oaat_sleep_out,
		W_sleep_in => Zt_sleep_in,
		ki => Zt_weightMem_ko,
		R_ko => zt_memAddress_R_ko,
		W_ko => zt_memAddress_W_ko,
		sleep_out => zt_memAddress_sleep_out,
		z => Zt_address_out);


--NEW MEMORY DEVICE
Zt_weightMem : weightMemory_4Layers
	generic map(bitwidth => 16,
		clock_delay => 16,		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay => 48)		--ADD DELAY FOR INCREASED MEMORY DELAY
	port map(address => Zt_address_out(11 downto 0),
		layerNumber => Zt_address_out(13 downto 12),
		mem_data => Zt_address_out(29 downto 14),
		write_en => writeEn,
		reset => reset,
		ki => zt_mult_of_acc_ko,
		ko => Zt_weightMem_ko,
		sleep_in => zt_memAddress_sleep_out,
		sleep_out => Zt_weightMem_sleep_out,
		z => Zt_weightMem_out
	);
--NEW MEMORY DEVICE




----------------END ZT MEMORY--------------


zt_mult_of_accumulate : mult_of_accumulate_8_16
	generic map(counterWidth => 8)
	port map(a => xh_oaat_out,
		b => Zt_weightMem_out,
		RCF_width => layerBitwidth,
		reset_count => const_acc_value,
		reset => reset,
		sleep_in_a => xh_oaat_sleep_out,
		sleep_in_b => Zt_weightMem_sleep_out,
		trunc => trunc_zt,
		ki => zt_pre_bias_reg_in_ko,		
		ko => zt_mult_of_acc_ko,
		sleep_out => zt_mult_of_acc_sleep_out,
		z => zt_pre_bias_oaat_in);


--ADD OAAT_in and OAAT_out

zt_pre_bias_reg_in : RCF_OAAT_in_all_out
	generic map( bitwidth  => maxBitwidth,
		 numInputs => maxLayerSize,
		 counterWidth  => 7, --Log2 of numInputs
		 delay_amount => 6)
	port map(a  => zt_pre_bias_oaat_in,
		RCF_width => layerBitwidth,
		reset_count => const63_127(6 downto 0),
		sleep_in => zt_mult_of_acc_sleep_out,
		 reset => reset,
		 ki => zt_pre_bias_reg_out_ko,
		 ko => zt_pre_bias_reg_in_ko,
		 sleep_out => zt_pre_bias_reg_in_sleep_out,
		 z => zt_pre_bias_oaat_between);

zt_pre_bias_reg_out : RCF_OAAT_out_all_in_128
	generic map(bitwidth => maxBitwidth,
		numInputs => maxLayerSize)
	port map(	 
		a => zt_pre_bias_oaat_between,
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth,
		layerSize => layerSize.rail1,
		sleep_in => zt_pre_bias_reg_in_sleep_out,
		 reset => reset,
		 ki => zt_mult_of_ki,
		 ko => zt_pre_bias_reg_out_ko,
		 sleep_out => zt_pre_bias_reg_out_sleep_out,
		 accumulate_reset => zt_pre_bias_reg_out_acc_reset,
		 count => zt_pre_bias_reg_out_count,
		 z => zt_pre_bias);


--END ADD
zt_mult_of_ki_gate : th22_a
	port map(a => zt_bias_adder_ko, 
			 b => sht_bias_adder_ko,
			 z => zt_ko_grnn); 

zt_mult_of_ki_mux : MUX21_A
	port map(A => sht_mult_ko,
		B => zt_ko_grnn,
		S => layerType.rail1,
		 Z => zt_mult_of_ki);

zt_bias_adder : adder_8_16
	port map(a => zt_pre_bias,
		b => Zt_B,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => zt_pre_bias_reg_out_sleep_out,
		sleep_in_b => Zt_B_sleep_in,
		ki => zt_LUT_ko,
		ko => zt_bias_adder_ko,
		sleep_out => zt_bias_sleep_out,
		z  => zt_bias_out);



Zt_B_ko <= zt_bias_adder_ko;

zt_LUT_ki_gate : th22_a
	port map(a => htm1_zt_mult_ko, 
			 b => one_minus_zt_ko,
			 z => zt_LUT_ki); 

zt_LUT : LUT_sigmoid_8_16
	port map(a => zt_bias_out,
		RCF_width => layerBitwidth,
		sleep_in => zt_bias_sleep_out,
		 reset => reset,
		 ki => zt_LUT_ki,
		 ko => zt_LUT_ko,
		 sleep_out => zt_LUT_sleep_out,
		 z => zt);


htm1_for_zt_reg : RCF_OAAT_out_all_in_128
	generic map(bitwidth => maxBitwidth,
		numInputs => maxLayerSize)
	port map(	 
		a => Ht,
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth,
		layerSize => layerSize.rail1,
		sleep_in => sleep_in,
		 reset => reset,
		 ki => htm1_zt_mult_ko,
		 ko => htm1_for_zt_ko,
		 sleep_out => htm1_for_zt_sleep_out,
		 accumulate_reset => htm1_for_zt_acc_reset,
		 count => htm1_for_zt_count,
		 z => htm1_for_zt);

htm1_zt_mult : mult_8_16
	port map(a => htm1_for_zt,
		b => zt,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => htm1_for_zt_sleep_out,
		sleep_in_b => zt_LUT_sleep_out,
		trunc => trunc_htm1_zt,
		ki => ht_adder_ko,
		ko => htm1_zt_mult_ko,
		sleep_out => htm1_zt_sleep_out,
		z  => htm1_zt_out);

--end zt route--------------------------------------------

--1-zt route-----------------------------------------------
one_mux : MUX21_dr_gen
	generic map(bitwidth => maxBitwidth)
	port map(A => const1_8bit,
		B => const1_16bit,
		S => layerBitwidth,
		 Z => one_mux_out);

one_minus_ko_mux : MUX21_A
	port map(A => sht_mult_ko,
		B => zeta_mult_ko,
		S => layerType.rail1,
		 Z => one_minus_ki);

one_minus_zt_sub : one_sub_8_16_reverse
	port map(a => zt,
		b => One_mux_out,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in => zt_LUT_sleep_out,
		ki => one_minus_ki, 
		ko => one_minus_zt_ko,
		sleep_out => one_minus_zt_sleep_out,
		z  => one_minus_zt);

zeta_mult : one_mult_8_16
	port map(a => one_minus_zt,
		b => zeta,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in => one_minus_zt_sleep_out,
		trunc => trunc_zeta,
		ki => nu_adder_ko,
		ko => zeta_mult_ko,
		sleep_out => zeta_mult_sleep_out,
		z  => zeta_mult_out);

nu_adder : one_adder_8_16
	port map(a => zeta_mult_out,
		b => nu,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in => zeta_mult_sleep_out,
		ki => sht_mult_ko,
		ko => nu_adder_ko,
		sleep_out => nu_sleep_out,
		z  => nu_adder_out);

one_minus_z_mux : MUX21_dr_gen
	generic map(bitwidth => maxBitwidth)
	port map(A => one_minus_zt,
		B => nu_adder_out,
		S => layerType.rail1,
		 Z => one_minus_z_mux_out);


--end 1-zt route--------------------------------------------

--sht route-------------------------------------------------
rt_addr_mult_ko_gate : th22_a
	port map(a => rt_mult_of_acc_ko, 
		 b => rt_memAddress_R_ko,
		z => rt_addr_mult_ko); 

----------------RT MEMORY-------------------

Rt_ko <= rt_memAddress_W_ko;

Rt_addressGen : addressGen
	generic map(Lower_count_size => 8,
		Upper_count_size => 8,
		Address_width => 12)
	port map(R_reset_count_lower => xh_oaat_count(7 downto 0),
		R_reset_count_upper => xh_oaat_count(15 downto 8),
		R_accumulate_reset_lower => xh_oaat_lowerIsMax,
		R_accumulate_reset_upper => xh_oaat_upperIsMax,		--UNUSED PORT
		R_LayerNumber => layerNumber,
		W_data => Rt_W,
		isInputLayer => layerIsInput,
		writeEn => writeEn,
		hSize => layerSize,
		reset => reset,
		R_sleep_in => xh_oaat_sleep_out,
		W_sleep_in => Rt_sleep_in,
		ki => Rt_weightMem_ko,
		R_ko => rt_memAddress_R_ko,
		W_ko => rt_memAddress_W_ko,
		sleep_out => rt_memAddress_sleep_out,
		z => Rt_address_out);


--NEW MEMORY DEVICE
Rt_weightMem : weightMemory_4Layers
	generic map(bitwidth => 16,
		clock_delay => 16,		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay => 48)		--ADD DELAY FOR INCREASED MEMORY DELAY
	port map(address => Rt_address_out(11 downto 0),
		layerNumber => Rt_address_out(13 downto 12),
		mem_data => Rt_address_out(29 downto 14),
		write_en => writeEn,
		reset => reset,
		ki => rt_mult_of_acc_ko,
		ko => Rt_weightMem_ko,
		sleep_in => rt_memAddress_sleep_out,
		sleep_out => Rt_weightMem_sleep_out,
		z => Rt_weightMem_out
	);
--NEW MEMORY DEVICE

----------------END RT MEMORY--------------

rt_mult_of_acc_sleep_in_a_mux : MUX21_A 
	port map(A => '1',
		B => xh_oaat_sleep_out,
		S => layerType.rail0,
		 Z => rt_mult_of_acc_sleep_in_a); 

rt_mult_of_accumulate : mult_of_accumulate_8_16
	generic map(counterWidth => 8)
	port map(a => xh_oaat_out,
		b => Rt_weightMem_out,
		RCF_width => layerBitwidth,
		reset_count => const_acc_value,
		reset => reset,
		sleep_in_a => rt_mult_of_acc_sleep_in_a,
		sleep_in_b => Rt_weightMem_sleep_out,
		trunc => trunc_rt,
		ki => rt_LUT_ko,
		ko => rt_mult_of_acc_ko,
		sleep_out => rt_mult_of_acc_sleep_out,
		z => rt_pre_bias);



rt_bias_adder : adder_8_16
	port map(a => rt_pre_bias,
		b => Rt_B,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => rt_mult_of_acc_sleep_out,
		sleep_in_b => Rt_B_sleep_in,
		ki => rt_LUT_ko,
		ko => rt_bias_adder_ko,
		sleep_out => rt_bias_sleep_out,
		z  => rt_bias_out);

Rt_B_ko <= rt_bias_adder_ko;


rt_LUT : LUT_sigmoid_8_16
	port map(a => rt_bias_out,
		RCF_width => layerBitwidth,
		sleep_in => rt_bias_sleep_out,
		 reset => reset,
		 ki => rt_htm1_mult_ko,
		 ko => rt_LUT_ko,
		 sleep_out => rt_LUT_sleep_out,
		 z => rt);


htm1_for_rt_reg : RCF_OAAT_out_all_in_128
	generic map(bitwidth => maxBitwidth,
		numInputs => maxLayerSize)
	port map(	 
		a => Ht,
		reset_count => const63_127(6 downto 0),
		RCF_width => layerBitwidth,
		layerSize => layerSize.rail1,
		sleep_in => gen_comp_units_sleep_in,
		 reset => reset,
		 ki => rt_htm1_mult_ko,
		 ko => htm1_for_rt_ko,
		 sleep_out => htm1_for_rt_sleep_out,
		 accumulate_reset => htm1_for_rt_acc_reset,
		 count => htm1_for_rt_count,
		 z => htm1_rt);

rt_htm1_mult : mult_8_16
	port map(a => rt,
		b => htm1_rt,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => rt_LUT_sleep_out,
		sleep_in_b => htm1_for_rt_sleep_out,
		trunc => trunc_htm1_rt,
		ki => rt_htm1_reg_ko,
		ko => rt_htm1_mult_ko,
		sleep_out => rt_htm1_mult_sleep_out,
		z  => rt_htm1_mult_out);

rt_htm1_reg : RCF_OAAT_in_all_out
	generic map( bitwidth  => maxBitwidth,
		 numInputs => maxLayerSize,
		 counterWidth  => 7, --Log2 of numInputs
		 delay_amount => 6)
	port map(a  => rt_htm1_mult_out,
		RCF_width => layerBitwidth,
		reset_count => const63_127(6 downto 0),
		sleep_in => rt_htm1_mult_sleep_out,
		 reset => reset,
		 ki => sh_xh_oaat_ko,
		 ko => rt_htm1_reg_ko,
		 sleep_out => rt_htm1_reg_sleep_out,
		 z => rt_htm1_reg_out);

gen_comp_units_sleep_in_mux : MUX21_A 
	port map(A => '1',
		B => sleep_in,
		S => layerType.rail0,
		 Z => gen_comp_units_sleep_in); 

	gen_comp_units : for i in 0 to maxLayerSize-1 generate
		comp_z_a: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => Xt((i+1)*16-1 downto i*16),
			sel => layerBitwidth,
			ki => sh_xh_oaat_ko,
			rst => reset,
			sleep => gen_comp_units_sleep_in,
			ko => xt_sh_reg_tree(i));
	end generate;

	comp_tree : andtreem
		generic map(width => 64)
		port map(a => xt_sh_reg_tree(63 downto 0),
			 sleep => '0',
			 ko => xt_sh_reg_bottom64);

	comp_tree_a : andtreem
		generic map(width => 64)
		port map(a => xt_sh_reg_tree(127 downto 64),
			 sleep => '0',
			 ko => xt_sh_reg_lower64);

th22_bottom_lower : th22_a
	port map(a => xt_sh_reg_bottom64,
		 b => xt_sh_reg_lower64, 
		 z => bottom64_lower64); 
 

ko_mux : MUX21_A 
	port map(A => xt_sh_reg_bottom64,
		B => bottom64_lower64,
		S => layerSize.rail1,
		 Z => xt_sh_reg_ko); 

xt_sh_reg : regs_gen_null_res
	generic map(width => maxBitwidth*maxLayerSize)
   	port map(d => Xt,
		q => Xt_sh_out,
		reset => reset,
		sleep => xt_sh_reg_ko);

sh_xh_oaat_in(64*maxBitwidth-1 downto 0) <= rt_htm1_reg_out(64*maxBitwidth-1 downto 0);

sh_xh_oaat_in_mux : MUX21_dr_gen 
	generic map(bitwidth => 64*maxBitwidth)
	port map(A => Xt_sh_out(64*maxBitwidth-1 downto 0),
		B => rt_htm1_reg_out(128*maxBitwidth-1 downto 64*maxBitwidth),
		S => layerSize.rail1,
		 Z => sh_xh_oaat_in(128*maxBitwidth-1 downto 64*maxBitwidth)); 

sh_xh_oaat_in(256*maxBitwidth-1 downto 128*maxBitwidth) <= Xt_sh_out(128*maxBitwidth-1 downto 0);

sht_mult_sleep_in_gate : th22_a
	port map(a => xt_sh_reg_ko,
		 b => rt_htm1_reg_sleep_out, 
		 z => sht_mult_sleep_in); 

sh_xh_OAAT : RCF_OAAT_out_all_in_RPT
	generic map(reset_count_upper_width => 8,
		bitwidth => maxBitwidth,
		numInputs => 2*maxLayerSize)
	port map(	 
		a => sh_xh_oaat_in,
		reset_count_lower => const_acc_value,
		reset_count_upper => const63_127,
		RCF_width => layerBitwidth,
		layerSize => layerSize.rail1,
		layerIsInput => layerIsInput.rail1,
		prevLayerSize => prevLayerSize,
		sleep_in => sht_mult_sleep_in,
		reset => reset,
		ki => sht_addr_mult_ko,
		ko => sh_xh_oaat_ko,
		sleep_out => sh_xh_oaat_sleep_out,
		accumulate_reset => sh_xh_oaat_acc_reset,
		count => sh_xh_oaat_count,
		lowerIsMax => sh_xh_oaat_lowerIsMax,
		upperIsMax => sh_xh_oaat_upperIsMax,
		z => sh_xh_oaat_out);


sht_addr_mult_ko_gate : th22_a
	port map(a => sht_mult_of_acc_ko, 
		 b => sht_memAddress_R_ko,
		z => sht_addr_mult_ko); 

----------------SHT MEMORY-------------------

Sht_ko <= sht_memAddress_W_ko;

Sht_addressGen : addressGen
	generic map(Lower_count_size => 8,
		Upper_count_size => 8,
		Address_width => 12)
	port map(R_reset_count_lower => sh_xh_oaat_count(7 downto 0),
		R_reset_count_upper => sh_xh_oaat_count(15 downto 8),
		R_accumulate_reset_lower => sh_xh_oaat_lowerIsMax,
		R_accumulate_reset_upper => sh_xh_oaat_upperIsMax,		--UNUSED PORT
		R_LayerNumber => layerNumber,
		W_data => Sht_W,
		isInputLayer => layerIsInput,
		writeEn => writeEn,
		hSize => layerSize,
		reset => reset,
		R_sleep_in => sh_xh_oaat_sleep_out,
		W_sleep_in => Sht_sleep_in,
		ki => Sht_weightMem_ko,
		R_ko => Sht_memAddress_R_ko,
		W_ko => Sht_memAddress_W_ko,
		sleep_out => Sht_memAddress_sleep_out,
		z => Sht_address_out);


--NEW MEMORY DEVICE
Sht_weightMem : weightMemory_4Layers
	generic map(bitwidth => 16,
		clock_delay => 16,		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay => 48)		--ADD DELAY FOR INCREASED MEMORY DELAY
	port map(address => Sht_address_out(11 downto 0),
		layerNumber => Sht_address_out(13 downto 12),
		mem_data => Sht_address_out(29 downto 14),
		write_en => writeEn,
		reset => reset,
		ki => Sht_mult_of_acc_ko,
		ko => Sht_weightMem_ko,
		sleep_in => Sht_memAddress_sleep_out,
		sleep_out => Sht_weightMem_sleep_out,
		z => Sht_weightMem_out
	);
--NEW MEMORY DEVICE


----------------END RT MEMORY--------------


sht_mult_of_accumulate : mult_of_accumulate_8_16
	generic map(counterWidth => 8)
	port map(a => sh_xh_oaat_out,
		b => Sht_weightMem_out,
		RCF_width => layerBitwidth,
		reset_count => const_acc_value,
		reset => reset,
		sleep_in_a => sh_xh_oaat_sleep_out,
		sleep_in_b => Sht_weightMem_sleep_out,
		trunc => trunc_sht,
		ki => sht_bias_adder_ko,
		ko => sht_mult_of_acc_ko,
		sleep_out => sht_mult_of_acc_sleep_out,
		z => sht_pre_bias);

sht_pre_bias_mux : MUX21_dr_gen
	generic map(bitwidth => maxBitwidth)
	port map(A => sht_pre_bias,
		B => zt_pre_bias,
		S => layerType.rail1,
		 Z => sht_zt_mux_out); 

sht_bias_adder_sleep_mux : MUX21_A
	port map(A => sht_mult_of_acc_sleep_out,
		B => zt_pre_bias_reg_out_sleep_out,
		S => layerType.rail1,
		 Z => sht_zt_mux_sleep_out);

sht_bias_adder : adder_8_16
	port map(a => sht_zt_mux_out,
		b => Sht_B,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => sht_zt_mux_sleep_out,	
		sleep_in_b => Sht_B_sleep_in,
		ki => sht_LUT_ko,
		ko => sht_bias_adder_ko,
		sleep_out => sht_bias_sleep_out,
		z  => sht_bias_out);

Sht_B_ko <= sht_bias_adder_ko;

sht_LUT : LUT_tanh_8_16
	port map(a => sht_bias_out,
		RCF_width => layerBitwidth,
		sleep_in => sht_bias_sleep_out,
		 reset => reset,
		 ki => sht_mult_ko,
		 ko => sht_LUT_ko,
		 sleep_out => sht_LUT_sleep_out,
		 z => sht);

sht_sleep_mux : MUX21_A
	port map(A => one_minus_zt_sleep_out,
		B => nu_sleep_out,
		S => layerType.rail1,
		 Z => one_minus_z_mux_sleep_out);

sht_mult_inst : mult_8_16
	port map(a => one_minus_z_mux_out,
		b => sht,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => one_minus_z_mux_sleep_out,
		sleep_in_b => sht_LUT_sleep_out,
		trunc => trunc_ztm1_sht,
		ki => ht_adder_ko,
		ko => sht_mult_ko,
		sleep_out => sht_mult_sleep_out,
		z  => sht_mult_out);

--end sht route-------------------------------------------------------
ht_adder : adder_8_16
	port map(a => htm1_zt_out,
		b => sht_mult_out,
		RCF_width => layerBitwidth,
		reset => reset,
		sleep_in_a => htm1_zt_sleep_out,
		sleep_in_b => sht_mult_sleep_out,
		ki => output_reg_ko,
		ko => ht_adder_ko,
		sleep_out => ht_adder_sleep_out,
		z  => ht_adder_out);

ht_adder_out_bottom8_replace <= ht_adder_out(15 downto 8) & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0;
--8 to 16 bit convert-----------------------

mux16_sleep_sel_mux : MUX21_A 
	port map(A => ht_adder_sleep_out,
		B => '1',
		S => layerBitwidth,
		 Z => mux16_sleep); 

--gen_mux_in_16 : for i in 0 to 7 generate
--	mux_in_16(((i+1)*8)-1 downto i*8) <= ht_adder_out_bottom8_replace((i+8) downto i+1);
--end generate;

--	mux16 : mux_nto1_gen
--		generic map(bitwidth => 8,
--			numInputs => 8)
--	    port map(a => mux_in_16,
--			sel => trunc_bitchange,
--			 sleep => mux16_sleep,
--			 z => mux_out_16);

--output_mux_in_16 <= mux_out_16 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0;

convert_from_8_to_16 : convert_8_16
	port map(a => ht_adder_out_bottom8_replace,
		correct_sign => ht_adder_out_bottom8_replace(15),
		trunc => trunc_bitchange,
		sleep => mux16_sleep,
		z => output_mux_in_16
	);

output_mux_16 : MUX21_dr_gen
	generic map(bitwidth => maxBitwidth)
	port map(A => output_mux_in_16,
		B => ht_adder_out,
		S => layerBitwidth,
		 Z => output_reg_16_in); 

---------------------------------------

--16 to 8 bit convert-----------------------

mux8_sleep_sel_mux : MUX21_A 
	port map(A => '1',
		B => ht_adder_sleep_out,
		S => layerBitwidth,
		 Z => mux8_sleep); 


--gen_mux_in_8 : for i in 0 to 7 generate
--	mux_in_8(((i+1)*8)-1 downto i*8) <= ht_adder_out((i+8) downto i+1);
--end generate;

--	mux8 : mux_nto1_gen
--		generic map(bitwidth => 8,
--			numInputs => 8)
--	    port map(a => mux_in_8,
--			sel => trunc_bitchange,
--			 sleep => mux8_sleep,
--			 z => mux_out_8);

--output_mux_in_8 <= mux_out_8 & data0 & data0 & data0 & data0 & data0 & data0 & data0 & data0;

convert_from_16_to_8 : convert_16_8
	port map(a => ht_adder_out,
		correct_sign => ht_adder_out(15),
		trunc => trunc_bitchange,
		sleep => mux8_sleep,
		z => output_mux_in_8
	);

output_mux_8 : MUX21_dr_gen
	generic map(bitwidth => maxBitwidth)
	port map(A => ht_adder_out_bottom8_replace,
		B => output_mux_in_8,
		S => layerBitwidth,
		 Z => output_reg_8_in); 

---------------------------------------


output_reg_ko_gate : th22_a
	port map(a => output_reg_8_ko, 
		 b => output_reg_16_ko,
		z => output_reg_ko); 

output_reg_8 : RCF_OAAT_in_all_out
	generic map( bitwidth  => maxBitwidth,
		 numInputs  => maxLayerSize,
		 counterWidth  => 7, --Log2 of numInputs
		 delay_amount => 6)
	port map(a  => output_reg_8_in,
		RCF_width => '1',
		reset_count => const63_127(6 downto 0),
		sleep_in => ht_adder_sleep_out,
		 reset => reset,
		 ki => ki,
		 ko => output_reg_8_ko,
		 sleep_out => output_reg_8_sleep_out,
		 z => z_8);

output_reg_16 : RCF_OAAT_in_all_out
	generic map( bitwidth  => maxBitwidth,
		 numInputs  => maxLayerSize,
		 counterWidth  => 7, --Log2 of numInputs
		 delay_amount => 6)
	port map(a  => output_reg_16_in,
		RCF_width => '1',
		reset_count => const63_127(6 downto 0),
		sleep_in => ht_adder_sleep_out,
		 reset => reset,
		 ki => ki,
		 ko => output_reg_16_ko,
		 sleep_out => output_reg_16_sleep_out,
		 z => z_16);

output_reg_sleep_out_gate : th22_a
	port map(a => output_reg_8_sleep_out, 
		 b => output_reg_16_sleep_out,
		z => output_reg_sleep_out); 

sleep_out <= output_reg_sleep_out;
end arch_GRNN_layer_w_mem; 
