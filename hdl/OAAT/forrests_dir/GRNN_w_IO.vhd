

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;
use ieee.math_real.all;

entity GRNN_w_IO is
	generic(maxBitwidth : integer := 16;
		maxLayerSize : integer := 128);
	port(	
		--Configuration Ports
		numberLayers	: in std_logic_vector(1 downto 0);
		inputWidth	: in std_logic_vector(7 downto 0);
		layerBitwidth 	: in std_logic_vector(3 downto 0);
		layerSize 	: in std_logic_vector(3 downto 0);
		layerType 	: in std_logic_vector(3 downto 0);
		fcNumberLayers	: in std_logic;
		fcLayerBitwidth	: in std_logic;
		--prevLayerSize 	: in std_logic_vector(3 downto 0);

		trunc_zt 	: in std_logic_vector(11 downto 0);
		trunc_htm1_zt 	: in std_logic_vector(11 downto 0);
		trunc_zeta 	: in std_logic_vector(11 downto 0);
		trunc_rt 	: in std_logic_vector(11 downto 0);
		trunc_htm1_rt 	: in std_logic_vector(11 downto 0);
		trunc_sht 	: in std_logic_vector(11 downto 0);
		trunc_ztm1_sht 	: in std_logic_vector(11 downto 0);
		trunc_bitchange : in std_logic_vector(8 downto 0);
		trunc_fc 	: in std_logic_vector(2 downto 0);

		configDataRequest : out std_logic;
		configDataReady : in std_logic;

		--Primary Layer Inputs
		Xt 		: in std_logic_vector(maxBitwidth-1 downto 0);
		reset 		: in std_logic;
		inDataReady 	: in std_logic;
		outDataReceived	: in std_logic;

		--Flash Ports
		DO 		: in std_logic;
		cs 		: out std_logic;
		clk		: out std_logic;
		DIO 		: out std_logic;


		--Primary Layer Outputs
		outDataIsReady 	: out std_logic;
		dataRequest	: out std_logic;
		z 		: out std_logic_vector(maxBitwidth-1 downto 0)
	);
end GRNN_w_IO;

architecture arch_GRNN_w_IO of GRNN_w_IO is 


component flashAccessGRNN is
	generic(bitwidth : integer);
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
end component;


component flashToMemGRNN is
	generic(bitwidth : integer);
	port( 
		count_in : in dual_rail_logic_vector(19 downto 0);
		data_in : in dual_rail_logic_vector(bitwidth-1 downto 0);
		reset : in std_logic;
		sleep_in : in std_logic;

		mem_data_ko_Zt : in std_logic;
		mem_data_Zt : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_Zt : out std_logic;

		mem_data_ko_Rt : in std_logic;
		mem_data_Rt : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_Rt : out std_logic;

		mem_data_ko_Sht : in std_logic;
		mem_data_Sht : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_Sht : out std_logic;

		mem_data_ko_Zt_B : in std_logic;
		mem_data_Zt_B : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_Zt_B : out std_logic;

		mem_data_ko_Rt_B : in std_logic;
		mem_data_Rt_B : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_Rt_B : out std_logic;

		mem_data_ko_Sht_B : in std_logic;
		mem_data_Sht_B : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_Sht_B : out std_logic;

		mem_data_ko_ZetaNu : in std_logic;
		mem_data_ZetaNu : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_ZetaNu : out std_logic;

		mem_data_ko_FC : in std_logic;
		mem_data_FC : out dual_rail_logic_vector(bitwidth-1 downto 0);
		mem_data_sleep_in_FC : out std_logic;

		inputReady : in std_logic;
		ko : out std_logic
	);
end component;

component GRNN_control_w_mem is
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
end component;

component RCF_GRNN_fc_layer is
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
end component;

component inv_a is
	port(a : in std_logic;
		z : out std_logic);
end component;

component reg_gen is
	generic(width : integer := 16);
	port(
		D   : in  std_logic_vector(width - 1 downto 0);
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic_vector(width - 1 downto 0));
end component;

component SDC_w_EN is
	generic(bitwidth : integer);
	port(a : in std_logic_vector(bitwidth-1 downto 0);
		en : in std_logic;
		sleep : std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
end component;

component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 


component BUFFER_C is 
	port(A: in std_logic; 
		Z: out std_logic); 
end component; 

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

	component MUX21_A is 
		port(A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			 Z: out std_logic); 
	end component; 



signal flashKi, flashSleep, inputReady, mem_data_ko_zt, mem_data_sleep_in_Zt, mem_data_ko_rt, mem_data_sleep_in_Rt, mem_data_ko_sht, mem_data_sleep_in_Sht, mem_data_ko_zt_B, mem_data_sleep_in_Zt_B, mem_data_ko_rt_B, mem_data_sleep_in_Rt_B, mem_data_ko_sht_B, mem_data_sleep_in_Sht_B, mem_data_ko_ZetaNu, mem_data_sleep_in_ZetaNu, mem_data_ko_FC, mem_data_sleep_in_FC, MainSleepIn, MainKo, sdc_en, configSleepIn, configDataReady_delay, configDataRequest_temp, ZetaNuSleepOut, fcKo, MainConfigKo, sleepOutGRNN, notOutDataReceived, notOutDataIsReady, dataRequest_temp : std_logic;

signal prevLayerSize, layerIsInput, nextLayerBitwidth : std_logic_vector(3 downto 0);

signal trunc_bitchange_3 : std_logic_vector(2 downto 0);

signal a_sr : std_logic_vector(maxBitwidth-1 downto 0);

signal writeEn, data0, data1, X_fill_data : dual_rail_logic;

signal const7 : dual_rail_logic_vector(2 downto 0);

signal flashData, mem_data_Zt, mem_data_Rt, mem_data_Sht, mem_data_Zt_B, mem_data_Rt_B, mem_data_Sht_B, mem_data_ZetaNu, mem_data_FC, MainXt, z_dr, const_0 : dual_rail_logic_vector(maxBitwidth-1 downto 0);

signal flashCount : dual_rail_logic_vector(19 downto 0);

signal configPorts, configBitsIn_sr : std_logic_vector(134 downto 0);

signal configBitsIn, configBits : dual_rail_logic_vector(134 downto 0);

signal ZetaNu : dual_rail_logic_vector(8*maxBitwidth-1 downto 0);

signal MainOut, Xt_Fill : dual_rail_logic_vector((maxLayerSize*maxBitwidth)-1 downto 0);

signal data_out_ready_pre : std_logic_vector(8 downto 0);


begin 


data0.rail0 <= '1';
data0.rail1 <= '0';
data1.rail0 <= '0';
data1.rail1 <= '1';

const7(0) <= data1;
const7(1) <= data1;
const7(2) <= data1;

const_0(0) <= data0;
const_0(1) <= data0;
const_0(2) <= data0;
const_0(3) <= data0;
const_0(4) <= data0;
const_0(5) <= data0;
const_0(6) <= data0;
const_0(7) <= data0;
const_0(8) <= data0;
const_0(9) <= data0;
const_0(10) <= data0;
const_0(11) <= data0;
const_0(12) <= data0;
const_0(13) <= data0;
const_0(14) <= data0;
const_0(15) <= data0;


flashAccess : flashAccessGRNN
	generic map(bitwidth => maxBitwidth)
	port map( 
		ki => flashKi,
		reset => reset,
		DO => DO,
		cs => cs,
		clk => clk,
		DIO => DIO,
		sleep_out => flashSleep,
		inputReady => inputReady,
		count_out => flashCount,
		z => flashData
	);

writeEn.rail0 <= inputReady;
inputReady_inverter : inv_a
	port map(a => writeEn.rail0,
		z => writeEn.rail1);



flashToMem : flashToMemGRNN
	generic map(bitwidth => maxBitwidth)
	port map( 
		count_in => flashCount,
		data_in => flashData,
		reset => reset,
		sleep_in => flashSleep,

		mem_data_ko_Zt => mem_data_ko_Zt,
		mem_data_Zt => mem_data_Zt,
		mem_data_sleep_in_Zt => mem_data_sleep_in_Zt,

		mem_data_ko_Rt => mem_data_ko_Rt,
		mem_data_Rt => mem_data_Rt,
		mem_data_sleep_in_Rt => mem_data_sleep_in_Rt,

		mem_data_ko_Sht => mem_data_ko_Sht,
		mem_data_Sht => mem_data_Sht,
		mem_data_sleep_in_Sht => mem_data_sleep_in_Sht,

		mem_data_ko_Zt_B => mem_data_ko_Zt_B,
		mem_data_Zt_B => mem_data_Zt_B,
		mem_data_sleep_in_Zt_B => mem_data_sleep_in_Zt_B,

		mem_data_ko_Rt_B => mem_data_ko_Rt_B,
		mem_data_Rt_B => mem_data_Rt_B,
		mem_data_sleep_in_Rt_B => mem_data_sleep_in_Rt_B,

		mem_data_ko_Sht_B => mem_data_ko_Sht_B,
		mem_data_Sht_B => mem_data_Sht_B,
		mem_data_sleep_in_Sht_B => mem_data_sleep_in_Sht_B,

		mem_data_ko_ZetaNu => mem_data_ko_ZetaNu,
		mem_data_ZetaNu => mem_data_ZetaNu,
		mem_data_sleep_in_ZetaNu => mem_data_sleep_in_ZetaNu,

		mem_data_ko_FC => mem_data_ko_FC,
		mem_data_FC => mem_data_FC,
		mem_data_sleep_in_FC => mem_data_sleep_in_FC,

		inputReady => inputReady,
		ko => flashKi
	);

--DATA IO--------------------
sdc_en_gate : and2_a
	port map(a => inputReady,
		b => inDataReady,
		z => sdc_en);

sleep_in_gate : inv_a
	port map(a => sdc_en,
		z => MainSleepIn);

ko_gate : and2_a
	port map(a => inputReady,
		b => Mainko,
		z => dataRequest_temp);

dataRequest <= dataRequest_temp;

input_reg : reg_gen
	generic map(width => maxBitwidth)
	port map(
		D => Xt,
		clk => inDataReady,
		rst => reset,
		Q => a_sr);

sdc_Xt : SDC_w_EN
	generic map(bitwidth => maxBitwidth)
	port map(a => a_sr,
		en => sdc_en,
		sleep => MainSleepIn,
		z => MainXt);

Xt_fill(maxBitwidth-1 downto 0) <= MainXt;

	x_fill_data0_mux : MUX21_A
		port map(A => '0',
			B => '1',
			S => dataRequest_temp,
		 	Z => X_fill_data.rail0);

X_fill_data.rail1 <= '0';

gen_xt_fill : for i in maxBitwidth to maxLayerSize*maxBitwidth-1 generate
	Xt_fill(i) <= X_fill_data;
end generate;

 ---------------------------------------

------CONFIG IO---------------------------

config_sleep_in_gate : inv_a
	port map(a => configDataReady,
		z => configSleepIn);

prevLayerSize(0) <= '0';
prevLayerSize(1) <= layerSize(0);
prevLayerSize(2) <= layerSize(1);
prevLayerSize(3) <= layerSize(2);
layerIsInput(0) <= '1';
layerIsInput(1) <= '0';
layerIsInput(2) <= '0';
layerIsInput(3) <= '0';
nextLayerBitwidth(0) <= layerBitwidth(1);
nextLayerBitwidth(1) <= layerBitwidth(2);
nextLayerBitwidth(2) <= layerBitwidth(3);
nextLayerBitwidth(3) <= layerBitwidth(3);
trunc_bitchange_3(0) <= '1';
trunc_bitchange_3(1) <= '1';
trunc_bitchange_3(2) <= '1';


configPorts <= nextLayerBitwidth & trunc_bitchange_3 & trunc_bitchange & fcLayerBitwidth & fcNumberLayers & trunc_fc & trunc_ztm1_sht & trunc_sht & trunc_htm1_rt & trunc_rt & trunc_zeta & trunc_htm1_zt & trunc_zt & prevLayerSize & layerIsInput & layerType & layerSize & layerBitwidth & inputWidth & numberLayers;

config_input_reg : reg_gen
	generic map(width => 135)
	port map(
		D => configPorts,
		clk => configDataReady,
		rst => reset,
		Q => configBitsIn_sr);

	delay_configEn_gate : BUFFER_C 
		port map(A => configDataReady,
			 Z => configDataReady_delay);


sdc_config : SDC_w_EN
	generic map(bitwidth => 135)
	port map(a => configBitsIn_sr,
		en => configDataReady_delay,
		sleep => configSleepIn,
		z => configBitsIn);

	comp_config: compm
		generic map(width => 135)
		port map(
			a => configBitsIn,
			ki => '1',
			rst => reset,
			sleep => configSleepIn,
			ko => configDataRequest_temp);

configDataRequest <= configDataRequest_temp;
	reg_config: regs_gen_null_res
		generic map(width => 135)
		port map(
			d => configBitsIn,
			q => configBits,
			reset => reset,
			sleep => configDataRequest_temp);

ZetaNu_in_reg : OAAT_in_all_out
	generic map( bitwidth => 16,
		 numInputs => 8,
		 counterWidth => 3, --Log2 of numInputs
		 delay_amount => 6)
	port map(a => mem_data_ZetaNu,
		reset_count => const7,
		sleep_in => mem_data_sleep_in_ZetaNu,
		 reset => reset,
		 ki => '1',
		 ko => mem_data_ko_ZetaNu,
		 sleep_out => ZetaNuSleepOut,
		 z => ZetaNu);


------------------------------------------

GRNN_Main : GRNN_control_w_mem
	generic map(maxBitwidth => maxBitwidth,
		maxLayerSize => maxLayerSize)
	port map(	
		--Configuration Ports
		numberLayers	=> configBits(1 downto 0),
		inputWidth	=> configBits(9 downto 2),
		layerBitwidth 	=> configBits(13 downto 10),
		layerSize 	=> configBits(17 downto 14),
		layerType 	=> configBits(21 downto 18),
		layerIsInput 	=> configBits(25 downto 22),
		prevLayerSize 	=> configBits(29 downto 26),
		nextLayerBitwidth => configBits(134 downto 131),

		trunc_zt => configBits(41 downto 30),
		trunc_htm1_zt => configBits(53 downto 42),
		trunc_zeta => configBits(65 downto 54),
		trunc_rt => configBits(77 downto 66),
		trunc_htm1_rt => configBits(89 downto 78),
		trunc_sht => configBits(101 downto 90),
		trunc_ztm1_sht => configBits(113 downto 102),
		trunc_bitchange => configBits(130 downto 119),

		config_ko => MainConfigKo,
		config_sleep_in => '0',

		--Layer Constants
		zeta		=> ZetaNu(4*maxBitwidth-1 downto 0),
		nu		=> ZetaNu(8*maxBitwidth-1 downto 4*maxBitwidth),

		--Primary Layer Inputs
		Xt => Xt_Fill,
		reset => reset,
		sleep_in => MainSleepIn,
		ki => fcKo,

		--Bias Ports
		Zt_B_in => mem_data_Zt_B,
		Zt_B_in_sleep_in => mem_data_sleep_in_Zt_B,
		Zt_B_in_ko => mem_data_ko_Zt_B,

		Rt_B_in => mem_data_Rt_B,
		Rt_B_in_sleep_in => mem_data_sleep_in_Rt_B,
		Rt_B_in_ko => mem_data_ko_Rt_B,

		Sht_B_in => mem_data_Sht_B,
		Sht_B_in_sleep_in => mem_data_sleep_in_Sht_B,
		Sht_B_in_ko => mem_data_ko_Sht_B,

		--Memory Ports
		Zt_W => mem_data_Zt,
		Zt_sleep_in => mem_data_sleep_in_Zt,
		Zt_ko => mem_data_ko_Zt,

		Rt_W => mem_data_Rt,
		Rt_sleep_in => mem_data_sleep_in_Rt,
		Rt_ko => mem_data_ko_Rt,

		Sht_W => mem_data_Sht,
		Sht_sleep_in => mem_data_sleep_in_Sht,
		Sht_ko => mem_data_ko_Sht,

		writeEn => writeEn,

		--Primary Layer Outputs
		sleep_out => sleepOutGRNN,
		ko => Mainko,
		z => MainOut
	);

fc_layer : RCF_GRNN_fc_layer
	generic map(maxBitwidth => maxBitwidth,
		maxLayerSize => maxLayerSize)
	port map(	
		--Configuration Ports
		numberLayers	=> configBits(117),
		layerBitwidth 	=> configBits(118),
		layerSize 	=> configBits(17),

		trunc_fc => configBits(116 downto 114),

		--Primary Layer Inputs
		Xt => MainOut,
		reset => reset,
		sleep_in => sleepOutGRNN,
		ki => notOutDataReceived,

		FC_W_in => mem_data_FC,
		FC_in_sleep_in => mem_data_sleep_in_FC,
		FC_in_ko => mem_data_ko_FC,

		--Primary Layer Outputs
		sleep_out => notOutDataIsReady,
		ko => fcKo,
		z => z_dr
	);

z_gen : for i in 0 to maxBitwidth-1 generate
	z(i) <= z_dr(i).rail1;
end generate;

data_out_ready_gate : inv_a
	port map(a => notOutDataIsReady,
		z => data_out_ready_pre(0));


gen_data_out_ready_delay : for i in 0 to 7 generate
	delay_data_out_ready_gate_i : BUFFER_C
		port map(A => data_out_ready_pre(i),
			Z => data_out_ready_pre(i+1));
end generate;
	delay_sleep2_gate : BUFFER_C 
		port map(A => data_out_ready_pre(8),
			 Z => outDataIsReady);

dataReceived_gate : inv_a
	port map(a => outDataReceived,
		z => notOutDataReceived);



end arch_GRNN_w_IO; 
