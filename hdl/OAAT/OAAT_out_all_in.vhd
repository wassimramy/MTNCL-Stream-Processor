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


entity OAAT_out_all_in is
	generic(bitwidth: integer := 12;
		numInputs : integer := 256);
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
end OAAT_out_all_in;

architecture arch_OAAT_out_all_in of OAAT_out_all_in is
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

	component mux_nto1_gen is
		generic(bitwidth: in integer ;
			numInputs : integer := 64);
    	port(a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
		 	sleep: in std_logic;
		 	z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

--width of the counter = width of mux select (I believe).
	component counter_selfReset is
		generic(width: in integer);
		port(	 
			reset_count: in dual_rail_logic_vector(width-1 downto 0);
			sleep_in: in std_logic;
			 reset: in std_logic;
			 ki: in std_logic;
			 ko: out std_logic;
			 sleep_out: out std_logic;
			 accumulate_reset: out dual_rail_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

signal Output_Data_from_Registers_to_Mux: dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
signal Output_Data_from_Mux_to_Registers: dual_rail_logic_vector((bitwidth)-1 downto 0);

signal Output_Count_from_Counter_to_Mux: dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
signal Output_Count_from_Registers: dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);

signal Output_Accumulate_Reset_from_Counter_to_Register: dual_rail_logic;
signal Output_Accumulate_Reset_from_Register: dual_rail_logic;

signal Output_KO_from_Or_to_compm: std_logic;
signal Output_KO_from_compm_to_Counter: std_logic;
signal Output_KO_from_compm_to_First_Stage: std_logic;

signal Output_Sleep_Out_from_Counter_to_compm: std_logic;

signal dummy_ko : std_logic;

signal Count_and_Accumulate_Reset_to_Register: dual_rail_logic_vector(integer(ceil(log2(real(numInputs)))) downto 0);
signal Count_and_Accumulate_Reset_from_Register: dual_rail_logic_vector(integer(ceil(log2(real(numInputs)))) downto 0);
signal Count_and_Accumulate_Reset_and_Data_for_compm: dual_rail_logic_vector(bitwidth + integer(ceil(log2(real(numInputs)))) downto 0);
begin

		Data_Register_to_Mux : regs_gen_null_res
			generic map(	width => numInputs*bitwidth )
				port map(
					d => a,
					q => Output_Data_From_Registers_to_Mux,
					reset => reset,
					sleep => Output_KO_from_compm_to_First_Stage);

		counter_selfReset_instance : counter_selfReset
			generic map(	width => integer(ceil(log2(real(numInputs)))))
				port map(
					reset_count => reset_count,
					sleep_in => Output_KO_from_compm_to_First_Stage,
					reset => reset,
					ki => Output_KO_from_compm_to_Counter,
					ko => dummy_ko,
					sleep_out => Output_Sleep_Out_from_Counter_to_compm,
					accumulate_reset => Output_Accumulate_Reset_from_Counter_to_Register,
					z => Output_Count_From_Counter_to_Mux);

		mux_nto1_gen_instance : mux_nto1_gen
			generic map(	bitwidth => bitwidth, numInputs => numInputs)
				port map(
					a => Output_Data_From_Registers_to_Mux,
					sel => Output_Count_From_Counter_to_Mux,
					sleep => Output_KO_from_compm_to_First_Stage,
					z => Output_Data_from_Mux_to_Registers);

		Count_and_Accumulate_Reset_to_Register <= Output_Count_From_Counter_to_Mux &  Output_Accumulate_Reset_from_Counter_to_Register;
		accumulate_reset <= Count_and_Accumulate_Reset_from_Register(0);
		count <= Count_and_Accumulate_Reset_from_Register(integer(ceil(log2(real(numInputs)))) downto 1);
		Count_Register_from_Counter : regs_gen_null_res
			generic map(	width => integer(ceil(log2(real(numInputs))))+1)
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
		Count_and_Accumulate_Reset_and_Data_for_compm <= Output_Data_from_Mux_to_Registers & Output_Count_From_Counter_to_Mux &  Output_Accumulate_Reset_from_Counter_to_Register;
		compm_instance_0 : compm
			generic map(	width => bitwidth + integer(ceil(log2(real(numInputs))))+1)
				port map(
					a => Count_and_Accumulate_Reset_and_Data_for_compm,
					ki => ki,
					rst => reset,
					sleep => Output_Sleep_Out_from_Counter_to_compm,
					ko => Output_KO_from_compm_to_Counter);

		compm_instance_1 : compm
			generic map(	width => numInputs*bitwidth)
				port map(
					a => a,
					ki => Output_KO_from_Or_to_compm,
					rst => reset,
					sleep => sleep_in,
					ko => Output_KO_from_compm_to_First_Stage);

		KO_Generation_Or_instance : or3_a
				port map(
					a => Count_and_Accumulate_Reset_from_Register(0).rail0,
					b => Output_Accumulate_Reset_from_Counter_to_Register.rail0,
					c => Output_KO_from_compm_to_Counter,
					z => Output_KO_from_Or_to_compm);

		sleep_out <= Output_KO_from_compm_to_Counter;
		ko <= Output_KO_from_compm_to_First_Stage;
		--accumulate_reset <= Output_Accumulate_Reset_from_Register;

end arch_OAAT_out_all_in;
