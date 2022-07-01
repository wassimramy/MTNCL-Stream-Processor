--Created by
--Special purpose register
--Takes M N-bit values as a single vector input
--Outputs each one, in order (starting with the value taking up the least significant bits)
--Main register returns to null after the last value has been output


library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;
use work.tree_funcs.all;
use ieee.math_real.all;


entity RCF_OAAT_out_all_in_128_RPT is
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
		 count: out dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))+reset_count_upper_width-1 downto 0);
		 z: out dual_rail_logic_vector(bitwidth-1 downto 0));
end RCF_OAAT_out_all_in_128_RPT;

architecture arch_RCF_OAAT_out_all_in_128_RPT of RCF_OAAT_out_all_in_128_RPT is
	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;

	component or3_a is
		port(
			a,b,c: in std_logic;
			z: out std_logic);
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

	component mux_nto1_gen is
		generic(bitwidth: in integer ;
			numInputs : integer := 64);
    	port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 	sleep: in std_logic;
		 	z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

--width of the counter = width of mux select (I believe).
component TwoPhaseCounter is
	generic(width_lower: integer;
		width_upper: integer);
	port(	
		reset_count_lower: in dual_rail_logic_vector(width_lower-1 downto 0);
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

	component th22d_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 rst: in std_logic; 
			 z: out std_logic); 
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

component xor2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

component MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end component; 

component or2_a is 
	port(a,b: in std_logic; 
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

signal Output_Data_from_Registers_to_Mux: dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
signal Output_Data_from_Mux_to_Registers: dual_rail_logic_vector((bitwidth)-1 downto 0);

signal Output_Count_from_Counter_to_Mux: dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))+reset_count_upper_width-1 downto 0);
signal Output_Count_from_Registers: dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);

signal Output_Accumulate_Reset_Upper_from_Counter_to_Register: dual_rail_logic;
signal Output_Accumulate_Reset_Upper_from_Register: dual_rail_logic;
signal Output_Accumulate_Reset_Lower_from_Counter_to_Register: dual_rail_logic;
signal Output_Accumulate_Reset_Lower_from_Register, Output_Accumulate_Reset_UpperMax_from_Counter_to_Register : dual_rail_logic;

signal Output_KO_from_Or_to_compm: std_logic;
signal Output_KO_from_compm_to_Counter: std_logic;
signal Output_KO_from_compm_to_First_Stage: std_logic;

signal Output_Sleep_Out_from_Counter_to_compm, Output_KO_from_compm_to_Counter_a, Output_KO_from_compm_to_Counter_b: std_logic;

signal dummy_ko, Output_KO_from_compm_to_First_Stage_bottom64, Output_KO_from_compm_to_First_Stage_lower64, Output_KO_from_compm_to_First_Stage_upper64, Output_KO_from_compm_to_First_Stage_top64 : std_logic;

signal bottom64_65, bottom64_lower64, bottom64_lower64_upper64, bottom64_lower64_upper64_top64, bottom64_lower64_129, inputLayer_65_129, layerSize_or_prevLayerSize, layerSize_xor_prevLayerSize, layer_128_256, layer_192 : std_logic;

signal Count_and_Accumulate_Reset_to_Register: dual_rail_logic_vector(reset_count_upper_width + integer(ceil(log2(real(numInputs))))+2 downto 0);
signal Count_and_Accumulate_Reset_from_Register: dual_rail_logic_vector(reset_count_upper_width + integer(ceil(log2(real(numInputs))))+2 downto 0);
signal Count_and_Accumulate_Reset_and_Data_for_compm: dual_rail_logic_vector(bitwidth + reset_count_upper_width + integer(ceil(log2(real(numInputs))))+2 downto 0);

signal Output_KO_from_compm_to_First_Stage_tree : std_logic_vector(numInputs-1 downto 0);
begin

		Data_Register_to_Mux : regs_gen_null_res
			generic map(	width => numInputs*bitwidth )
				port map(
					d => a,
					q => Output_Data_From_Registers_to_Mux,
					reset => reset,
					sleep => Output_KO_from_compm_to_First_Stage);

		TwoPhaseCounter_instance : TwoPhaseCounter
			generic map(	width_upper => reset_count_upper_width, 
					width_lower => integer(ceil(log2(real(numInputs)))))
				port map(
					reset_count_lower => reset_count_lower,
					reset_count_upper => reset_count_upper,
					sleep_in => Output_KO_from_compm_to_First_Stage,
					reset => reset,
					ki => Output_KO_from_compm_to_Counter,
					ko => dummy_ko,
					sleep_out => Output_Sleep_Out_from_Counter_to_compm,
					upper_is_max => Output_Accumulate_Reset_UpperMax_from_Counter_to_Register,
					accumulate_reset_lower => Output_Accumulate_Reset_Lower_from_Counter_to_Register,
					accumulate_reset_upper => Output_Accumulate_Reset_Upper_from_Counter_to_Register,
					z => Output_Count_From_Counter_to_Mux);

		mux_nto1_gen_instance : mux_nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs)
				port map(
					a => Output_Data_From_Registers_to_Mux,
					sel => Output_Count_From_Counter_to_Mux(6 downto 0),
					sleep => Output_KO_from_compm_to_First_Stage,
					z => Output_Data_from_Mux_to_Registers);

		Count_and_Accumulate_Reset_to_Register <= Output_Count_From_Counter_to_Mux & Output_Accumulate_Reset_UpperMax_from_Counter_to_Register & Output_Accumulate_Reset_Lower_from_Counter_to_Register & Output_Accumulate_Reset_Upper_from_Counter_to_Register;
		accumulate_reset <= Count_and_Accumulate_Reset_from_Register(0);
		lowerIsMax <= Count_and_Accumulate_Reset_from_Register(1);
		upperIsMax <= Count_and_Accumulate_Reset_from_Register(2);
		count <= Count_and_Accumulate_Reset_from_Register(reset_count_upper_width + integer(ceil(log2(real(numInputs))))+2 downto 3);
		Count_Register_from_Counter : regs_gen_null_res
			generic map(	width => reset_count_upper_width + integer(ceil(log2(real(numInputs))))+3)
				port map(
					d => Count_and_Accumulate_Reset_to_Register,
					q => Count_and_Accumulate_Reset_from_Register,
					reset => reset,
					sleep => Output_KO_from_compm_to_Counter);

		Data_Register_from_Mux : regs_gen_null_res
			generic map(	width => bitwidth)
				port map(
					d => Output_Data_from_Mux_to_Registers,
					q => z,
					reset => reset,
					sleep => Output_KO_from_compm_to_Counter);
		Count_and_Accumulate_Reset_and_Data_for_compm <= Output_Data_from_Mux_to_Registers & Output_Count_From_Counter_to_Mux &  Output_Accumulate_Reset_UpperMax_from_Counter_to_Register & Output_Accumulate_Reset_Lower_from_Counter_to_Register & Output_Accumulate_Reset_Upper_from_Counter_to_Register;
		compm_instance_0_a : compm
			generic map(	width => reset_count_upper_width + integer(ceil(log2(real(numInputs))))+3)
				port map(
					a => Count_and_Accumulate_Reset_and_Data_for_compm(reset_count_upper_width + integer(ceil(log2(real(numInputs))))+2 downto 0),
					ki => ki,
					rst => reset,
					sleep => Output_Sleep_Out_from_Counter_to_compm,
					ko => Output_KO_from_compm_to_Counter_a);

			comp_z_a: compm_half_sel
			generic map(half_width => 8)
				port map(
					a => Output_Data_from_Mux_to_Registers,
					sel => RCF_width,
					ki => ki,
					rst => reset,
					sleep => Output_Sleep_Out_from_Counter_to_compm,
					ko => Output_KO_from_compm_to_Counter_b);

	Output_KO_from_compm_to_Counter_calc : th22d_a
		port map(a => Output_KO_from_compm_to_Counter_a,
			 b => Output_KO_from_compm_to_Counter_b,
			 rst => reset,
			 z => Output_KO_from_compm_to_Counter);

	gen_comp_units : for i in 0 to numInputs-1 generate
		comp_z_a: compm_half_sel
		generic map(half_width => 8)
		port map(
			a => a((i+1)*16-1 downto i*16),
			sel => RCF_width,
			ki => Output_KO_from_Or_to_compm,
			rst => reset,
			sleep => sleep_in,
			ko => Output_KO_from_compm_to_First_Stage_tree(i));
	end generate;

	comp_tree : ortreem
		generic map(width => 64)
		port map(a => Output_KO_from_compm_to_First_Stage_tree(63 downto 0),
			 sleep => '0',
			 ko => Output_KO_from_compm_to_First_Stage_bottom64);

	comp_tree_a : ortreem
		generic map(width => 64)
		port map(a => Output_KO_from_compm_to_First_Stage_tree(127 downto 64),
			 sleep => '0',
			 ko => Output_KO_from_compm_to_First_Stage_lower64);

th22_bottom_lower : th22_a
	port map(a => Output_KO_from_compm_to_First_Stage_bottom64,
		 b => Output_KO_from_compm_to_First_Stage_lower64, 
		 z => bottom64_lower64); 
 

ko_mux : MUX21_A 
	port map(A => Output_KO_from_compm_to_First_Stage_bottom64,
		B => bottom64_lower64,
		S => layerSize,
		 Z => Output_KO_from_compm_to_First_Stage); 

		KO_Generation_Or_instance : or3_a
				port map(
					a => Count_and_Accumulate_Reset_from_Register(0).rail0,
					b => Output_Accumulate_Reset_Upper_from_Counter_to_Register.rail0,
					c => Output_KO_from_compm_to_Counter,
					z => Output_KO_from_Or_to_compm);

		sleep_out <= Output_KO_from_compm_to_Counter;
		ko <= Output_KO_from_compm_to_First_Stage;
		--accumulate_reset <= Output_Accumulate_Reset_from_Register;

end arch_RCF_OAAT_out_all_in_128_RPT;
