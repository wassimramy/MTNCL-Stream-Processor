

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity flashToMemGRNN is
	generic(bitwidth : integer := 16);
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
end flashToMemGRNN;



architecture arch_flashToMemGRNN of flashToMemGRNN is 

component BUFFER_A is 
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

component th22m_a is
	port(a : in std_logic;
		b : in std_logic;
		s : in std_logic;
		z : out std_logic);
end component;


component inv_a is
	port(a : in std_logic;
		z : out std_logic);
end component;

component MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end component; 

	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;

	component regs_gen_zero_res is
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

component th22m_en_gen is
	generic(bitwidth : integer);
	port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
		en : in std_logic;
		sleep : std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0));
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

component thxor0m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic;
		 s: in std_logic; 
		 z: out std_logic ); 
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

signal clk_temp, ZtDone_not, kiMux1_out, RtXorZt, kiMux2_out, ShtXorRt, kiMux3_out, Zt_BXorSht, kiMux4_out, kiMux5_out, kiMux6_out, kiMux7_out, kiMux8_out, Rt_BXorZt_B, Sht_BXorRt_B, ZetaNuXorSht_B, FCXorZetaNu, comp_ki, ZtMatch, ZtDone, RtMatch, RtDone, RtDone_not, comp_a_out, ShtMatch, ShtDone, ShtDone_not, Zt_BDone, Zt_BMatch, Zt_BDone_not, Rt_BMatch, Rt_BDone, Rt_BDone_not, Sht_BMatch, Sht_BDone, Sht_BDone_not, ZetaNuMatch, ZetaNuDone, ZetaNuDone_not, FCMatch, FCDone, FCDone_not, ZtNotMatch, ZtMatchIsData, zt_sleep_sel, RtNotMatch, RtMatchIsData, rt_sleep_sel, ShtNotMatch, ShtMatchIsData, sht_sleep_sel, Zt_BNotMatch, Zt_BMatchIsData, zt_b_sleep_sel, Rt_BNotMatch, Rt_BMatchIsData, rt_b_sleep_sel, Sht_BNotMatch, Sht_BMatchIsData, sht_b_sleep_sel, ZetaNuNotMatch, ZetaNuMatchIsData, ZetaNu_sleep_sel, FCNotMatch, FCMatchIsData, FC_sleep_sel : std_logic;
signal shift_reg_out : std_logic_vector(15 downto 0);
signal reg_a_in, reg_a_out : dual_rail_logic_vector(35 downto 0);
signal accumulate_reset, data0, data1, Zt_data_sel, Rt_data_sel, Sht_data_sel, Zt_B_data_sel, Rt_B_data_sel, Sht_B_data_sel, ZetaNu_data_sel, FC_data_sel : dual_rail_logic;
signal Zt_data_en_out, Rt_data_en_out, Sht_data_en_out, Zt_B_data_en_out, const_0, Rt_B_data_en_out, Sht_B_data_en_out, ZetaNu_data_en_out, FC_data_en_out : dual_rail_logic_vector(15 downto 0);
signal counter_bits : dual_rail_logic_vector(16 downto 0);
signal const_14466, const_28930, const_43394, const_43906, const_44418, const_44930, const_44938, const_45196, count_equal_Zt, count_equal_Rt, count_equal_Sht, count_equal_Zt_B, count_equal_Rt_B, count_equal_Sht_B, count_equal_ZetaNu, count_equal_FC  : dual_rail_logic_vector(15 downto 0);
signal and_tree_in_Zt, or_tree_in_Zt, and_tree_in_Rt, or_tree_in_Rt, and_tree_in_Sht, or_tree_in_Sht, and_tree_in_Zt_B, or_tree_in_Zt_B, and_tree_in_Rt_B, or_tree_in_Rt_B, and_tree_in_Sht_B, or_tree_in_Sht_B, and_tree_in_ZetaNu, or_tree_in_ZetaNu, and_tree_in_FC, or_tree_in_FC : std_logic_vector(15 downto 0);


begin 


data0.rail0 <= '1';
data0.rail1 <= '0';
data1.rail0 <= '0';
data1.rail1 <= '1';

const_14466(0) <= data0;
const_14466(1) <= data1;
const_14466(2) <= data0;
const_14466(3) <= data0;
const_14466(4) <= data0;
const_14466(5) <= data0;
const_14466(6) <= data0;
const_14466(7) <= data1;
const_14466(8) <= data0;
const_14466(9) <= data0;
const_14466(10) <= data0;
const_14466(11) <= data1;
const_14466(12) <= data1;
const_14466(13) <= data1;
const_14466(14) <= data0;
const_14466(15) <= data0;


const_28930(0) <= data0;
const_28930(1) <= data1;
const_28930(2) <= data0;
const_28930(3) <= data0;
const_28930(4) <= data0;
const_28930(5) <= data0;
const_28930(6) <= data0;
const_28930(7) <= data0;
const_28930(8) <= data1;
const_28930(9) <= data0;
const_28930(10) <= data0;
const_28930(11) <= data0;
const_28930(12) <= data1;
const_28930(13) <= data1;
const_28930(14) <= data1;
const_28930(15) <= data0;


const_43394(0) <= data0;
const_43394(1) <= data1;
const_43394(2) <= data0;
const_43394(3) <= data0;
const_43394(4) <= data0;
const_43394(5) <= data0;
const_43394(6) <= data0;
const_43394(7) <= data1;
const_43394(8) <= data1;
const_43394(9) <= data0;
const_43394(10) <= data0;
const_43394(11) <= data1;
const_43394(12) <= data0;
const_43394(13) <= data1;
const_43394(14) <= data0;
const_43394(15) <= data1;



const_43906(0) <= data0;
const_43906(1) <= data1;
const_43906(2) <= data0;
const_43906(3) <= data0;
const_43906(4) <= data0;
const_43906(5) <= data0;
const_43906(6) <= data0;
const_43906(7) <= data1;
const_43906(8) <= data1;
const_43906(9) <= data1;
const_43906(10) <= data0;
const_43906(11) <= data1;
const_43906(12) <= data0;
const_43906(13) <= data1;
const_43906(14) <= data0;
const_43906(15) <= data1;




const_44418(0) <= data0;
const_44418(1) <= data1;
const_44418(2) <= data0;
const_44418(3) <= data0;
const_44418(4) <= data0;
const_44418(5) <= data0;
const_44418(6) <= data0;
const_44418(7) <= data1;
const_44418(8) <= data1;
const_44418(9) <= data0;
const_44418(10) <= data1;
const_44418(11) <= data1;
const_44418(12) <= data0;
const_44418(13) <= data1;
const_44418(14) <= data0;
const_44418(15) <= data1;


const_44930(0) <= data0;
const_44930(1) <= data1;
const_44930(2) <= data0;
const_44930(3) <= data0;
const_44930(4) <= data0;
const_44930(5) <= data0;
const_44930(6) <= data0;
const_44930(7) <= data1;
const_44930(8) <= data1;
const_44930(9) <= data1;
const_44930(10) <= data1;
const_44930(11) <= data1;
const_44930(12) <= data0;
const_44930(13) <= data1;
const_44930(14) <= data0;
const_44930(15) <= data1;



const_44938(0) <= data0;
const_44938(1) <= data1;
const_44938(2) <= data0;
const_44938(3) <= data1;
const_44938(4) <= data0;
const_44938(5) <= data0;
const_44938(6) <= data0;
const_44938(7) <= data1;
const_44938(8) <= data1;
const_44938(9) <= data1;
const_44938(10) <= data1;
const_44938(11) <= data1;
const_44938(12) <= data0;
const_44938(13) <= data1;
const_44938(14) <= data0;
const_44938(15) <= data1;


const_45196(0) <= data0;
const_45196(1) <= data0;
const_45196(2) <= data1;
const_45196(3) <= data1;
const_45196(4) <= data0;
const_45196(5) <= data0;
const_45196(6) <= data0;
const_45196(7) <= data1;
const_45196(8) <= data0;
const_45196(9) <= data0;
const_45196(10) <= data0;
const_45196(11) <= data0;
const_45196(12) <= data1;
const_45196(13) <= data1;
const_45196(14) <= data0;
const_45196(15) <= data1;


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

reg_a_in <= count_in & data_in;

	comp_a: compm
		generic map(width => bitwidth+20)
		port map(
			a => reg_a_in,
			ki => comp_ki,
			rst => reset,
			sleep => sleep_in,
			ko => comp_a_out);

	reg_a: regs_gen_null_res
		generic map(width => bitwidth+20)
		port map(
			d => reg_a_in,
			q => reg_a_out,
			reset => reset,
			sleep => comp_a_out);

kiMux1 : MUX21_A 
	port map(A => mem_data_ko_Zt, 
		B => mem_data_ko_Rt,
		S => ZtDone,
		 Z => kiMux1_out);

kiMux2 : MUX21_A 
	port map(A => kiMux1_out, 
		B => mem_data_ko_Sht,
		S => RtDone,
		 Z => kiMux2_out);

kiMux3 : MUX21_A 
	port map(A => kiMux2_out, 
		B => mem_data_ko_Zt_B,
		S => ShtDone,
		 Z => kiMux3_out);

kiMux4 : MUX21_A 
	port map(A => kiMux3_out, 
		B => mem_data_ko_Rt_B,
		S => Zt_BDone,
		 Z => kiMux4_out);

kiMux5 : MUX21_A 
	port map(A => kiMux4_out, 
		B => mem_data_ko_Sht_B,
		S => Rt_BDone,
		 Z => kiMux5_out);

kiMux6 : MUX21_A 
	port map(A => kiMux5_out, 
		B => mem_data_ko_ZetaNu,
		S => Sht_BDone,
		 Z => kiMux6_out);

kiMux7 : MUX21_A 
	port map(A => kiMux6_out, 
		B => mem_data_ko_FC,
		S => ZetaNuDone,
		 Z => kiMux7_out);

kiMux9 : MUX21_A 
	port map(A => kiMux7_out, 
		B => '1',
		S => inputReady,
		 Z => comp_ki);

generate_xor_Zt: for i in 0 to 15 generate

	thxor_i_Zt	: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_14466(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_14466(i).rail0,
			s => comp_a_out,
			z => count_equal_Zt(i).rail1);

	thxnor_i_Zt: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_14466(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_14466(i).rail0,
			s => comp_a_out,
			z => count_equal_Zt(i).rail0);

	end generate;

	generate_tree_sigs_Zt : for i in 0 to 15 generate
		and_tree_in_Zt(i) <= count_equal_Zt(i).rail1;
		or_tree_in_Zt(i) <= count_equal_Zt(i).rail0;
	
	end generate;

	and_tree_Zt : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_Zt,
			sleep => comp_a_out,
			ko => ZtMatch);

	or_tree_Zt : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_Zt,
			sleep => comp_a_out,
			ko => ZtNotMatch);


ztMatch_isData_gate : th12nm_a
	port map(a => ZtMatch,
		b => ZtNotMatch,
		rst => reset,
		s => comp_a_out,
		z => ZtMatchIsData);

zt_sleep_sel_gate : th22m_a
	port map(a => ZtNotMatch,
		b => ZtDone_not,
		s => comp_a_out,
		z => zt_sleep_sel);


ZtDone_gate : th12nm_a
	port map(a => ZtMatch,
		b => ZtDone,
		rst => reset,
		s => '0',
		z => ZtDone);

inv_ZtDone_gate : inv_a
	port map(a => ZtDone,
		z => ZtDone_not);

Zt_data_sel.rail1 <= ZtDone;
Zt_data_sel.rail0 <= ZtDone_not;

Zt_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => ZtDone_not,
		sleep => comp_a_out,
		z => Zt_data_en_out);

Zt_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => zt_sleep_sel,
		 Z => mem_data_sleep_in_Zt);

Zt_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => Zt_data_en_out,
	 	 b => const_0,
		sel => Zt_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_Zt);

generate_xor_Rt: for i in 0 to 15 generate

	thxor_i_Rt : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_28930(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_28930(i).rail0,
			s => comp_a_out,
			z => count_equal_Rt(i).rail1);

	thxnor_i_Rt: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_28930(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_28930(i).rail0,
			s => comp_a_out,
			z => count_equal_Rt(i).rail0);

	end generate;

	generate_tree_sigs_Rt : for i in 0 to 15 generate
		and_tree_in_Rt(i) <= count_equal_Rt(i).rail1;
		or_tree_in_Rt(i) <= count_equal_Rt(i).rail0;
	
	end generate;

	and_tree_Rt : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_Rt,
			sleep => comp_a_out,
			ko => RtMatch);

	or_tree_Rt : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_Rt,
			sleep => comp_a_out,
			ko => RtNotMatch);


rtMatch_isData_gate : th12nm_a
	port map(a => RtMatch,
		b => RtNotMatch,
		rst => reset,
		s => comp_a_out,
		z => RtMatchIsData);

rt_sleep_sel_gate : th22m_a
	port map(a => RtNotMatch,
		b => RtXorZt,
		s => comp_a_out,
		z => rt_sleep_sel);


RtDone_gate : th12nm_a
	port map(a => RtMatch,
		b => RtDone,
		rst => reset,
		s => '0',
		z => RtDone);

inv_RtDone_gate : inv_a
	port map(a => RtDone,
		z => RtDone_not);

Rt_data_sel.rail1 <= RtDone;
Rt_data_sel.rail0 <= RtDone_not;

RtXorZt_gate : thxor0m_a
	port map(a => ZtDone,
		 b => RtDone_not, 
		 c => ZtDone_not, 
		 d => RtDone,
		 s => comp_a_out, 
		 z => RtXorZt); 

Rt_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => RtXorZt,
		sleep => comp_a_out,
		z => Rt_data_en_out);

Rt_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => rt_sleep_sel,
		 Z => mem_data_sleep_in_Rt);

Rt_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => Rt_data_en_out,
	 	 b => const_0,
		sel => Rt_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_Rt);

generate_xor_Sht: for i in 0 to 15 generate

	thxor_i_Sht : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_43394(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_43394(i).rail0,
			s => comp_a_out,
			z => count_equal_Sht(i).rail1);

	thxnor_i_Sht: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_43394(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_43394(i).rail0,
			s => comp_a_out,
			z => count_equal_Sht(i).rail0);

	end generate;

	generate_tree_sigs_Sht : for i in 0 to 15 generate
		and_tree_in_Sht(i) <= count_equal_Sht(i).rail1;
		or_tree_in_Sht(i) <= count_equal_Sht(i).rail0;
	
	end generate;

	and_tree_Sht : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_Sht,
			sleep => comp_a_out,
			ko => ShtMatch);


	or_tree_Sht : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_Sht,
			sleep => comp_a_out,
			ko => ShtNotMatch);


shtMatch_isData_gate : th12nm_a
	port map(a => ShtMatch,
		b => ShtNotMatch,
		rst => reset,
		s => comp_a_out,
		z => ShtMatchIsData);

sht_sleep_sel_gate : th22m_a
	port map(a => ShtNotMatch,
		b => ShtXorRt,
		s => comp_a_out,
		z => sht_sleep_sel);


ShtDone_gate : th12nm_a
	port map(a => ShtMatch,
		b => ShtDone,
		rst => reset,
		s => '0',
		z => ShtDone);

inv_ShtDone_gate : inv_a
	port map(a => ShtDone,
		z => ShtDone_not);

Sht_data_sel.rail1 <= ShtDone;
Sht_data_sel.rail0 <= ShtDone_not;

ShtXorRt_gate : thxor0m_a
	port map(	 a => RtDone,
		 b => ShtDone_not, 
		 c => RtDone_not, 
		 d => ShtDone,
		 s => comp_a_out, 
		 z => ShtXorRt); 

Sht_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => ShtXorRt,
		sleep => comp_a_out,
		z => Sht_data_en_out);

Sht_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => sht_sleep_sel,
		 Z => mem_data_sleep_in_Sht);

Sht_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => Sht_data_en_out,
	 	 b => const_0,
		sel => Sht_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_Sht);

generate_xor_Zt_B: for i in 0 to 15 generate

	thxor_i_Zt_B : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_43906(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_43906(i).rail0,
			s => comp_a_out,
			z => count_equal_Zt_B(i).rail1);

	thxnor_i_Zt_B: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_43906(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_43906(i).rail0,
			s => comp_a_out,
			z => count_equal_Zt_B(i).rail0);

	end generate;

	generate_tree_sigs_Zt_B : for i in 0 to 15 generate
		and_tree_in_Zt_B(i) <= count_equal_Zt_B(i).rail1;
		or_tree_in_Zt_B(i) <= count_equal_Zt_B(i).rail0;
	
	end generate;

	and_tree_Zt_B : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_Zt_B,
			sleep => comp_a_out,
			ko => Zt_BMatch);

	or_tree_Zt_B : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_Zt_B,
			sleep => comp_a_out,
			ko => Zt_BNotMatch);


zt_bMatch_isData_gate : th12nm_a
	port map(a => Zt_BMatch,
		b => Zt_BNotMatch,
		rst => reset,
		s => comp_a_out,
		z => Zt_BMatchIsData);

Zt_b_sleep_sel_gate : th22m_a
	port map(a => Zt_BNotMatch,
		b => Zt_BXorSht,
		s => comp_a_out,
		z => zt_B_sleep_sel);


Zt_BDone_gate : th12nm_a
	port map(a => Zt_BMatch,
		b => Zt_BDone,
		rst => reset,
		s => '0',
		z => Zt_BDone);

inv_Zt_BDone_gate : inv_a
	port map(a => Zt_BDone,
		z => Zt_BDone_not);

Zt_B_data_sel.rail1 <= Zt_BDone;
Zt_B_data_sel.rail0 <= Zt_BDone_not;

Zt_BXorSht_gate : thxor0m_a
	port map(	 a => ShtDone,
		 b => Zt_BDone_not, 
		 c => ShtDone_not, 
		 d => Zt_BDone,
		 s => comp_a_out, 
		 z => Zt_BXorSht); 

Zt_B_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => Zt_BXorSht,
		sleep => comp_a_out,
		z => Zt_B_data_en_out);

Zt_B_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => zt_B_sleep_sel,
		 Z => mem_data_sleep_in_Zt_B);

Zt_B_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => Zt_B_data_en_out,
	 	 b => const_0,
		sel => Zt_B_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_Zt_B);

generate_xor_Rt_B: for i in 0 to 15 generate

	thxor_i_Rt_B : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_44418(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_44418(i).rail0,
			s => comp_a_out,
			z => count_equal_Rt_B(i).rail1);

	thxnor_i_Rt_B: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_44418(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_44418(i).rail0,
			s => comp_a_out,
			z => count_equal_Rt_B(i).rail0);

	end generate;

	generate_tree_sigs_Rt_B : for i in 0 to 15 generate
		and_tree_in_Rt_B(i) <= count_equal_Rt_B(i).rail1;
		or_tree_in_Rt_B(i) <= count_equal_Rt_B(i).rail0;
	
	end generate;

	and_tree_Rt_B : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_Rt_B,
			sleep => comp_a_out,
			ko => Rt_BMatch);

	or_tree_Rt_B : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_Rt_B,
			sleep => comp_a_out,
			ko => Rt_BNotMatch);


rt_bMatch_isData_gate : th12nm_a
	port map(a => Rt_BMatch,
		b => Rt_BNotMatch,
		rst => reset,
		s => comp_a_out,
		z => Rt_BMatchIsData);

Rt_b_sleep_sel_gate : th22m_a
	port map(a => Rt_BNotMatch,
		b => Rt_BXorZt_B,
		s => comp_a_out,
		z => rt_B_sleep_sel);

Rt_BDone_gate : th12nm_a
	port map(a => Rt_BMatch,
		b => Rt_BDone,
		rst => reset,
		s => '0',
		z => Rt_BDone);

inv_Rt_BDone_gate : inv_a
	port map(a => Rt_BDone,
		z => Rt_BDone_not);

Rt_B_data_sel.rail1 <= Rt_BDone;
Rt_B_data_sel.rail0 <= Rt_BDone_not;

Rt_BXorZt_B_gate : thxor0m_a
	port map(	 a => Zt_BDone,
		 b => Rt_BDone_not, 
		 c => Zt_BDone_not, 
		 d => Rt_BDone,
		 s => comp_a_out, 
		 z => Rt_BXorZt_B); 

Rt_B_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => Rt_BXorZt_B,
		sleep => comp_a_out,
		z => Rt_B_data_en_out);

Rt_B_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => rt_B_sleep_sel,
		 Z => mem_data_sleep_in_Rt_B);

Rt_B_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => Rt_B_data_en_out,
	 	 b => const_0,
		sel => Rt_B_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_Rt_B);

generate_xor_Sht_B: for i in 0 to 15 generate

	thxor_i_Sht_B : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_44930(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_44930(i).rail0,
			s => comp_a_out,
			z => count_equal_Sht_B(i).rail1);

	thxnor_i_Sht_B: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_44930(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_44930(i).rail0,
			s => comp_a_out,
			z => count_equal_Sht_B(i).rail0);

	end generate;

	generate_tree_sigs_Sht_B : for i in 0 to 15 generate
		and_tree_in_Sht_B(i) <= count_equal_Sht_B(i).rail1;
		or_tree_in_Sht_B(i) <= count_equal_Sht_B(i).rail0;
	
	end generate;

	and_tree_Sht_B : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_Sht_B,
			sleep => comp_a_out,
			ko => Sht_BMatch);

	or_tree_Sht_B : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_Sht_B,
			sleep => comp_a_out,
			ko => Sht_BNotMatch);


sht_bMatch_isData_gate : th12nm_a
	port map(a => Sht_BMatch,
		b => Sht_BNotMatch,
		rst => reset,
		s => comp_a_out,
		z => Sht_BMatchIsData);

Sht_b_sleep_sel_gate : th22m_a
	port map(a => Sht_BNotMatch,
		b => Sht_BXorRt_B,
		s => comp_a_out,
		z => sht_B_sleep_sel);


Sht_BDone_gate : th12nm_a
	port map(a => Sht_BMatch,
		b => Sht_BDone,
		rst => reset,
		s => '0',
		z => Sht_BDone);

inv_Sht_BDone_gate : inv_a
	port map(a => Sht_BDone,
		z => Sht_BDone_not);

Sht_B_data_sel.rail1 <= Sht_BDone;
Sht_B_data_sel.rail0 <= Sht_BDone_not;

Sht_BXorRt_B_gate : thxor0m_a
	port map(	 a => Rt_BDone,
		 b => Sht_BDone_not, 
		 c => Rt_BDone_not, 
		 d => Sht_BDone,
		 s => comp_a_out, 
		 z => Sht_BXorRt_B); 

Sht_B_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => Sht_BXorRt_B,
		sleep => comp_a_out,
		z => Sht_B_data_en_out);

Sht_B_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => sht_B_sleep_sel,
		 Z => mem_data_sleep_in_Sht_B);

Sht_B_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => Sht_B_data_en_out,
	 	 b => const_0,
		sel => Sht_B_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_Sht_B);

generate_xor_ZetaNu: for i in 0 to 15 generate

	thxor_i_ZetaNu : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_44938(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_44938(i).rail0,
			s => comp_a_out,
			z => count_equal_ZetaNu(i).rail1);

	thxnor_i_ZetaNu: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_44938(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_44938(i).rail0,
			s => comp_a_out,
			z => count_equal_ZetaNu(i).rail0);

	end generate;

	generate_tree_sigs_ZetaNu : for i in 0 to 15 generate
		and_tree_in_ZetaNu(i) <= count_equal_ZetaNu(i).rail1;
		or_tree_in_ZetaNu(i) <= count_equal_ZetaNu(i).rail0;
	
	end generate;

	and_tree_ZetaNu : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_ZetaNu,
			sleep => comp_a_out,
			ko => ZetaNuMatch);

	or_tree_ZetaNu : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_ZetaNu,
			sleep => comp_a_out,
			ko => ZetaNuNotMatch);


ZetaNuMatch_isData_gate : th12nm_a
	port map(a => ZetaNuMatch,
		b => ZetaNuNotMatch,
		rst => reset,
		s => comp_a_out,
		z => ZetaNuMatchIsData);

ZetaNu_sleep_sel_gate : th22m_a
	port map(a => ZetaNuNotMatch,
		b => ZetaNuXorSht_B,
		s => comp_a_out,
		z => ZetaNu_sleep_sel);

ZetaNuDone_gate : th12nm_a
	port map(a => ZetaNuMatch,
		b => ZetaNuDone,
		rst => reset,
		s => '0',
		z => ZetaNuDone);

inv_ZetaNuDone_gate : inv_a
	port map(a => ZetaNuDone,
		z => ZetaNuDone_not);

ZetaNu_data_sel.rail1 <= ZetaNuDone;
ZetaNu_data_sel.rail0 <= ZetaNuDone_not;

ZetaNuXorSht_B_gate : thxor0m_a
	port map(	 a => Sht_BDone,
		 b => ZetaNuDone_not, 
		 c => Sht_BDone_not, 
		 d => ZetaNuDone,
		 s => comp_a_out, 
		 z => ZetaNuXorSht_B); 

ZetaNu_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => ZetaNuXorSht_B,
		sleep => comp_a_out,
		z => ZetaNu_data_en_out);

ZetaNu_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => ZetaNu_sleep_sel,
		 Z => mem_data_sleep_in_ZetaNu);

ZetaNu_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => ZetaNu_data_en_out,
	 	 b => const_0,
		sel => ZetaNu_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_ZetaNu);

generate_xor_FC: for i in 0 to 15 generate

	thxor_i_FC : thxor0m_a
		port map(
			a => reg_a_out(i+20).rail1,
			b => const_45196(i).rail1,
			c => reg_a_out(i+20).rail0,
			d => const_45196(i).rail0,
			s => comp_a_out,
			z => count_equal_FC(i).rail1);

	thxnor_i_FC: thxor0m_a
		port map(
			a => reg_a_out(i+20).rail0,
			b => const_45196(i).rail1,
			c => reg_a_out(i+20).rail1,
			d => const_45196(i).rail0,
			s => comp_a_out,
			z => count_equal_FC(i).rail0);

	end generate;

	generate_tree_sigs_FC : for i in 0 to 15 generate
		and_tree_in_FC(i) <= count_equal_FC(i).rail1;
		or_tree_in_FC(i) <= count_equal_FC(i).rail0;
	
	end generate;

	and_tree_FC : andtreem
		generic map(width => 16)
		port map(
			a => and_tree_in_FC,
			sleep => comp_a_out,
			ko => FCMatch);

	or_tree_FC : ortreem
		generic map(width => 16)
		port map(
			a => or_tree_in_FC,
			sleep => comp_a_out,
			ko => FCNotMatch);


FCMatch_isData_gate : th12nm_a
	port map(a => FCMatch,
		b => FCNotMatch,
		rst => reset,
		s => comp_a_out,
		z => FCMatchIsData);

FC_sleep_sel_gate : th22m_a
	port map(a => FCNotMatch,
		b => FCXorZetaNu,
		s => comp_a_out,
		z => FC_sleep_sel);

FCDone_gate : th12nm_a
	port map(a => FCMatch,
		b => FCDone,
		rst => reset,
		s => '0',
		z => FCDone);

inv_FCDone_gate : inv_a
	port map(a => FCDone,
		z => FCDone_not);

fc_data_sel.rail1 <= FCDone;
fc_data_sel.rail0 <= FCDone_not;

FCXorZetaNu_gate : thxor0m_a
	port map(	 a => ZetaNuDone,
		 b => FCDone_not, 
		 c => ZetaNuDone_not, 
		 d => FCDone,
		 s => comp_a_out, 
		 z => FCXorZetaNu); 

fc_data_en_gen : th22m_en_gen
	generic map(bitwidth => bitwidth)
	port map(a => reg_a_out(bitwidth-1 downto 0),
		en => FCXorZetaNu,
		sleep => comp_a_out,
		z => fc_data_en_out);

fc_sleep_sel_mux : MUX21_A 
	port map(A => '1', 
		B => comp_a_out,
		S => FC_sleep_sel,
		 Z => mem_data_sleep_in_fc);

fc_data_mux : mux_21_gen_nic
	generic map(width => bitwidth)
    port map(a => fc_data_en_out,
	 	 b => const_0,
		sel => fc_data_sel,
		 sleep => comp_a_out,
		 z => mem_data_fc);

ko <= comp_a_out;

end arch_flashToMemGRNN; 
