--instances SRAMs and the weightMemory_4Layers_wrapper seperately 
-- date         version       description
-- 5.6.2022       1.0          changed from weightMemory_4Layers and instance weightMemory_4Layers_wrapper and SRAMs(sram2176x16 sram4096x16) 
--                             kept entity name, architecture name 
--                             added signals for SRAM connections; 
--                             replace most of the wrapper logic with component weightMemory_4Layers_wrapper
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity weightMemory_4Layers is
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
end weightMemory_4Layers;

architecture arch_weightMemory_4Layers of weightMemory_4Layers is 
-- wrapper declaration
   component weightMemory_4Layers_wrapper is
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
		z : out dual_rail_logic_vector(bitwidth-1 downto 0);
		--added SRAM ports
		------memory_0---sram2176x16-------
		Q_0:   in  std_logic_vector(15 downto 0);
		CLK_0: out std_logic;
		CEN_0: out std_logic;
		WEN_0: out std_logic;
		A_0 :  out std_logic_vector(11 downto 0);
		D_0 :  out std_logic_vector(15 downto 0);
		
		------memory_1---sram4096x16-------
		Q_1:   in  std_logic_vector(15 downto 0);
		CLK_1: out std_logic;
		CEN_1: out std_logic;
		WEN_1: out std_logic;
		A_1 :  out std_logic_vector(11 downto 0);
		D_1 :  out std_logic_vector(15 downto 0); 		
		
		------memory_2---sram4096x16-------
		Q_2:   in  std_logic_vector(15 downto 0);
		CLK_2: out std_logic;
		CEN_2: out std_logic;
		WEN_2: out std_logic;
		A_2 :  out std_logic_vector(11 downto 0);
		D_2 :  out std_logic_vector(15 downto 0); 	
		
		------memory_3---sram4096x16-------
		Q_3:   in  std_logic_vector(15 downto 0);
		CLK_3: out std_logic;
		CEN_3: out std_logic;
		WEN_3: out std_logic;
		A_3 :  out std_logic_vector(11 downto 0);
		D_3 :  out std_logic_vector(15 downto 0) 			
		
	);
   end component;
	
--SRAM declaration
	component sram2176x16 is
		port( Q: out std_logic_vector(15 downto 0);
			CLK: in std_logic;
			CEN: in std_logic;
			WEN: in std_logic;
			A : in std_logic_vector(11 downto 0);
			D : in std_logic_vector(15 downto 0);
			EMA: in std_logic_vector(2 downto 0);
			RETN: in std_logic);
	end component;

--	component SDC_w_EN is
--		generic(bitwidth : integer);
--		port(a : in std_logic_vector(bitwidth-1 downto 0);
--			en : in std_logic;
--			sleep : std_logic;
--			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
--	end component;
--
--	component regs_gen_null_res is
--		generic(width: integer);
--		port(d: in dual_rail_logic_vector(width-1 downto 0);
--			q: out dual_rail_logic_vector(width-1 downto 0);
--			reset: in std_logic;
--			sleep: in std_logic);
--	end component;
--
--
--	component inv_a is
--		port(a : in  std_logic;
--			 z : out std_logic);
--	end component;
--
--
--	component or2_a is
--		port(a, b : in  std_logic;
--			 z : out std_logic);
--	end component;
--
--	component and2_a is
--		port(a, b : in  std_logic;
--			 z : out std_logic);
--	end component;
--
--	component th22m_en_gen is
--		generic(bitwidth : integer);
--		port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
--			en : in std_logic;
--			sleep : std_logic;
--			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
--	end component;
--
--	component compm is
--		generic(width: in integer := 4);
--		port(a: IN dual_rail_logic_vector(width-1 downto 0);
--			ki, rst, sleep: in std_logic;
--			ko: OUT std_logic);
--	end component;
--
--	component BUFFER_A is 
--		port(A: in std_logic; 
--			 Z: out std_logic); 
--	end component; 

	component sram4096x16 is
		port( Q: out std_logic_vector(15 downto 0);
			CLK: in std_logic;
			CEN: in std_logic;
			WEN: in std_logic;
			A : in std_logic_vector(11 downto 0);
			D : in std_logic_vector(15 downto 0);
			EMA: in std_logic_vector(2 downto 0);
			RETN: in std_logic);
	end component;

--	component mux_21_gen_nic is
--		generic(width: integer);
--	    port(a: in dual_rail_logic_vector(width-1 downto 0);
--		 	 b: in dual_rail_logic_vector(width-1 downto 0);
--			sel: in dual_rail_logic;
--			 sleep: in std_logic;
--			 z: out dual_rail_logic_vector(width-1 downto 0));
--	end component;

--signal sdc_out_0, sdc_out_1, sdc_out_2, sdc_out_3, reg_out_out, mem_mux_01_out, mem_mux_23_out, mem_mux_out : dual_rail_logic_vector(bitwidth downto 0);
--signal en_gen_out : dual_rail_logic_vector(bitwidth-1 downto 0);
--signal mem_data_layerNumber_address, reg_in_out : dual_rail_logic_vector(12+2+15 downto 0);
--
--signal mem_data_out_0, mem_data_out_1, mem_data_out_2, mem_data_out_3 : std_logic_vector(bitwidth-1 downto 0);
--signal address_sr : std_logic_vector(11 downto 0);
--signal data_sr : std_logic_vector(bitwidth-1 downto 0);
--signal mem_en, sdc_en, sdc_en_0, sdc_en_1, sdc_en_2, sdc_en_3, delay_sleep, not_sleep, not_write, comp_ki, comp_out_out, comp_in_out, mem_0_clock, mem_1_clock, mem_2_clock, mem_3_clock, layerNumber_0, layerNumber_1, layerNumber_2, layerNumber_3  : std_logic;
--
--signal pre_delay_sleep : std_logic_vector(clock_delay downto 0);
--signal pre_sdc_en : std_logic_vector(mem_delay downto 0);
 signal Q_0, Q_1, Q_2, Q_3: std_logic_vector(15 downto 0);
 signal CLK_0, CLK_1, CLK_2, CLK_3: std_logic;
 signal CEN_0, CEN_1, CEN_2, CEN_3: std_logic;
 signal WEN_0, WEN_1, WEN_2, WEN_3: std_logic;
 signal A_0, A_1, A_2, A_3:  std_logic_vector(11 downto 0);
 signal D_0, D_1, D_2, D_3:  std_logic_vector(15 downto 0); 
 
begin 

 sram_wrapper: weightMemory_4Layers_wrapper 
	generic map(bitwidth    => bitwidth,
		        clock_delay => clock_delay,		--ADD DELAY FOR INCREASED SETUP TIMES
		        mem_delay   => mem_delay)		--ADD DELAY FOR INCREASED MEMORY DELAY
	port map (address 	=>address ,
		 layerNumber=>layerNumber,
		 mem_data 	=>mem_data ,
		 write_en 	=>write_en ,
		 reset 		=>reset ,
		 ki 		=>ki ,
		 ko 		=>ko ,
		 sleep_in 	=>sleep_in ,
		 sleep_out 	=>sleep_out,
		 z 			=>z ,
		--added SRAM ports
		------memory_0---sram2176x16-------
		Q_0   => Q_0  ,
		CLK_0 => CLK_0,
		CEN_0 => CEN_0,
		WEN_0 => WEN_0,
		A_0   => A_0  ,
		D_0   => D_0  ,
		
		------memory_1---sram4096x16-------
		Q_1   => Q_1  ,
		CLK_1 => CLK_1,
		CEN_1 => CEN_1,
		WEN_1 => WEN_1,
		A_1   => A_1  ,
		D_1   => D_1  ,		
		
		------memory_2---sram4096x16-------
		Q_2   => Q_2  ,
		CLK_2 => CLK_2,
		CEN_2 => CEN_2,
		WEN_2 => WEN_2,
		A_2   => A_2  ,
		D_2   => D_2  ,	
		
		------memory_3---sram4096x16-------
		Q_3   => Q_3  ,
		CLK_3 => CLK_3,
		CEN_3 => CEN_3,
		WEN_3 => WEN_3,
		A_3   => A_3  ,
		D_3   => D_3  		
		
	);
	
--SRAM instantiation
memory_0 : sram2176x16
	port map( Q    => Q_0  ,
			  CLK  => CLK_0,
			  CEN  => CEN_0,
			  WEN  => WEN_0,
			  A    => A_0  ,
			  D    => D_0  ,
			  EMA  => "000",
			  RETN => '1');

memory_1 : sram4096x16
	port map( Q    => Q_1  ,
			  CLK  => CLK_1,
			  CEN  => CEN_1,
			  WEN  => WEN_1,
			  A    => A_1  ,
			  D    => D_1  ,
			  EMA  => "000",
			  RETN => '1');

memory_2 : sram4096x16
	port map( Q    => Q_2  ,
			  CLK  => CLK_2,
			  CEN  => CEN_2,
			  WEN  => WEN_2,
			  A    => A_2  ,
			  D    => D_2  ,
			  EMA  => "000",
			  RETN => '1');

memory_3 : sram4096x16
	port map( Q    => Q_3  ,
			  CLK  => CLK_3,
			  CEN  => CEN_3,
			  WEN  => WEN_3,
			  A    => A_3  ,
			  D    => D_3  ,	
			  EMA  => "000",
			  RETN => '1');

--mem_data_layerNumber_address <= mem_data & layerNumber & address;
--
--	comp_unit_in: compm
--		generic map(width => bitwidth+12+2)
--		port map(
--			a => mem_data_layerNumber_address,
--			ki => comp_out_out,
--			rst => reset,
--			sleep => sleep_in,
--			ko => comp_in_out);
--
--	reg_in: regs_gen_null_res
--		generic map(width => bitwidth+12+2)
--		port map(
--			d => mem_data_layerNumber_address,
--			q => reg_in_out,
--			reset => reset,
--			sleep => comp_in_out);
--
--	layerNumber_0_gate : and2_a
--		port map(A => reg_in_out(12).rail0,
--			 B => reg_in_out(13).rail0,
--			 Z => layerNumber_0); 
--	layerNumber_1_gate : and2_a
--		port map(A => reg_in_out(12).rail1,
--			 B => reg_in_out(13).rail0,
--			 Z => layerNumber_1); 
--	layerNumber_2_gate : and2_a
--		port map(A => reg_in_out(12).rail0,
--			 B => reg_in_out(13).rail1,
--			 Z => layerNumber_2); 
--	layerNumber_3_gate : and2_a
--		port map(A => reg_in_out(12).rail1,
--			 B => reg_in_out(13).rail1,
--			 Z => layerNumber_3); 
--
--
--generate_address : for i in 0 to 11 generate
--	address_sr(i) <= reg_in_out(i).rail1;
--end generate;
--
--generate_data : for i in 0 to bitwidth-1 generate
--	data_sr(i) <= reg_in_out(i+12+2).rail1;
--end generate;
--
--	delay_sleep0_gate : BUFFER_A
--		port map(A => comp_in_out,
--			Z => mem_en);
--
--	delay_sleep1_gate : BUFFER_A 
--		port map(A => mem_en,
--			 Z => pre_delay_sleep(0));
--
--gen_pre_delay_sleep : for i in 0 to clock_delay-1 generate
--	delay_sleep_gate_i : BUFFER_A
--		port map(A => pre_delay_sleep(i),
--			Z => pre_delay_sleep(i+1));
--end generate;
--	delay_sleep2_gate : BUFFER_A 
--		port map(A => pre_delay_sleep(clock_delay),
--			 Z => delay_sleep);
--
--	inv_sleep : inv_a 
--		port map(a => delay_sleep,
--			 z => not_sleep);
--
--	clock_0_gate : and2_a
--		port map(A => not_sleep,
--			 B => layerNumber_0,
--			 Z => mem_0_clock); 
--	clock_1_gate : and2_a
--		port map(A => not_sleep,
--			 B => layerNumber_1,
--			 Z => mem_1_clock); 
--	clock_2_gate : and2_a
--		port map(A => not_sleep,
--			 B => layerNumber_2,
--			 Z => mem_2_clock); 
--	clock_3_gate : and2_a
--		port map(A => not_sleep,
--			 B => layerNumber_3,
--			 Z => mem_3_clock); 
--
--	delay_not_sleep_gate : BUFFER_A 
--		port map(A => not_sleep,
--			 Z => pre_sdc_en(0));
--gen_delay_not_sleep_gate : for i in 0 to mem_delay-1 generate
--	pre_sdc_en_gate_i : BUFFER_A
--		port map(A => pre_sdc_en(i),
--			Z => pre_sdc_en(i+1));
--	end generate;
--
--	delay_not_sleep_gate2 : BUFFER_A 
--		port map(A => pre_sdc_en(mem_delay),
--			 Z => sdc_en);
----SRAM instantiation
--memory_0 : sram2176x16
--	port map( Q => mem_data_out_0,
--		CLK => mem_0_clock,
--		CEN => mem_en,
--		WEN => write_en.rail0,
--		A => address_sr,
--		D => data_sr,
--		EMA => "000",
--		RETN => '1');
--
--memory_1 : sram4096x16
--	port map( Q => mem_data_out_1,
--		CLK => mem_1_clock,
--		CEN => mem_en,
--		WEN => write_en.rail0,
--		A => address_sr,
--		D => data_sr,
--		EMA => "000",
--		RETN => '1');
--
--memory_2 : sram4096x16
--	port map( Q => mem_data_out_2,
--		CLK => mem_2_clock,
--		CEN => mem_en,
--		WEN => write_en.rail0,
--		A => address_sr,
--		D => data_sr,
--		EMA => "000",
--		RETN => '1');
--
--memory_3 : sram4096x16
--	port map( Q => mem_data_out_3,
--		CLK => mem_3_clock,
--		CEN => mem_en,
--		WEN => write_en.rail0,
--		A => address_sr,
--		D => data_sr,
--		EMA => "000",
--		RETN => '1');
--
--
--	sdc_0_gate : and2_a
--		port map(A => sdc_en,
--			 B => layerNumber_0,
--			 Z => sdc_en_0); 
--	sdc_1_gate : and2_a
--		port map(A => sdc_en,
--			 B => layerNumber_1,
--			 Z => sdc_en_1); 
--	sdc_2_gate : and2_a
--		port map(A => sdc_en,
--			 B => layerNumber_2,
--			 Z => sdc_en_2); 
--	sdc_3_gate : and2_a
--		port map(A => sdc_en,
--			 B => layerNumber_3,
--			 Z => sdc_en_3); 
--
--converter_0 : SDC_w_EN
--	generic map(bitwidth => bitwidth)
--	port map(a => mem_data_out_0,
--		en => sdc_en_0,
--		sleep => comp_in_out,
--		z => sdc_out_0(bitwidth downto 1));
--
--converter_1 : SDC_w_EN
--	generic map(bitwidth => bitwidth)
--	port map(a => mem_data_out_1,
--		en => sdc_en_1,
--		sleep => comp_in_out,
--		z => sdc_out_1(bitwidth downto 1));
--
--converter_2 : SDC_w_EN
--	generic map(bitwidth => bitwidth)
--	port map(a => mem_data_out_2,
--		en => sdc_en_2,
--		sleep => comp_in_out,
--		z => sdc_out_2(bitwidth downto 1));
--
--converter_3 : SDC_w_EN
--	generic map(bitwidth => bitwidth)
--	port map(a => mem_data_out_3,
--		en => sdc_en_3,
--		sleep => comp_in_out,
--		z => sdc_out_3(bitwidth downto 1));
--
--sdc_out_0(0) <= write_en;
--sdc_out_1(0) <= write_en;
--sdc_out_2(0) <= write_en;
--sdc_out_3(0) <= write_en;
--
--mem_mux_01 : mux_21_gen_nic
--	generic map(width => bitwidth+1)
--    	port map(a => sdc_out_0,
--	 	 b => sdc_out_1,
--		sel => reg_in_out(12),
--		 sleep => comp_in_out,
--		 z => mem_mux_01_out);
--
--zmem_mux_23 : mux_21_gen_nic
--	generic map(width => bitwidth+1)
--    	port map(a => sdc_out_2,
--	 	 b => sdc_out_3,
--		sel => reg_in_out(12),
--		 sleep => comp_in_out,
--		 z => mem_mux_23_out);
--
--mem_mux : mux_21_gen_nic
--	generic map(width => bitwidth+1)
--    	port map(a => mem_mux_01_out,
--	 	 b => mem_mux_23_out,
--		sel => reg_in_out(13),
--		 sleep => comp_in_out,
--		 z => mem_mux_out);
--
--
--	comp_unit: compm
--		generic map(width => bitwidth+1)
--		port map(
--			a => mem_mux_out,
--			ki => comp_ki,
--			rst => reset,
--			sleep => comp_in_out,
--			ko => comp_out_out);
--
--	reg_out: regs_gen_null_res
--		generic map(width => bitwidth+1)
--		port map(
--			d => mem_mux_out,
--			q => reg_out_out,
--			reset => reset,
--			sleep => comp_out_out);
--
--	inv_i : inv_a
--		port map(a => reg_out_out(0).rail1,
--			z => not_write);
--
--	and_i : and2_a
--		port map(a => not_write,
--			b => ki,
--			z => comp_ki);
--
--	enable_gen : th22m_en_gen 
--		generic map(bitwidth => bitwidth)
--		port map(a => reg_out_out(bitwidth downto 1),
--			en => reg_out_out(0).rail0,
--			sleep => comp_out_out,
--			z => en_gen_out);
--
--ko <= comp_in_out;
--sleep_out <= comp_out_out;
--
--z <= en_gen_out(bitwidth-1 downto 0);

end arch_weightMemory_4Layers; 
