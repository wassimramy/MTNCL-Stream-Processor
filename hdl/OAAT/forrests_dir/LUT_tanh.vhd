--instances tanh_rom and the LUT_tanh_wrapper seperately 
-- date         version       description
-- 5.6.2022       1.0          changed from LUT_tanh and instance LUT_tanh_wrapper and ROM(tanh_rom) 
--                             kept entity name, architecture name 
--                             added signals for ROM connections; 
--                             replace most of the wrapper logic with component LUT_tanh_wrapper
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity LUT_tanh is
	generic(bitwidth : integer := 16;
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
end LUT_tanh;



architecture arch_LUT_tanh of LUT_tanh is 

-- wrapper declaration
component LUT_tanh_wrapper is
	generic(bitwidth : integer := 16;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 109);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(address : in dual_rail_logic_vector(bitwidth-1 downto 0);
		sleep_in : in std_logic;
		reset : in std_logic;
		ki : in std_logic;
		sleep_out : out std_logic;
		ko : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0);
		---ROM ports-------
		Q:   in  std_logic_vector(15 downto 0);
		CLK: out std_logic;
		CEN: out std_logic;
		A :  out std_logic_vector(8 downto 0)
	);
end component;

--ROM Declaration
	component tanh_rom is
		port( Q: out std_logic_vector(15 downto 0);
			CLK: in std_logic;
			CEN: in std_logic;
			A : in std_logic_vector(8 downto 0);
			EMA: in std_logic_vector(2 downto 0));
	end component;

--	component SDC_w_EN is
--		generic(bitwidth : integer);
--		port(a : in std_logic_vector(bitwidth-1 downto 0);
--			en : in std_logic;
--			sleep : std_logic;
--			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
--	end component;
--
--
--	component regs_gen_null_res is
--		generic(width: integer);
--		port(d: in dual_rail_logic_vector(width-1 downto 0);
--			q: out dual_rail_logic_vector(width-1 downto 0);
--			reset: in std_logic;
--			sleep: in std_logic);
--	end component;
--
--	component compm is
--		generic(width: in integer := 4);
--		port(a: IN dual_rail_logic_vector(width-1 downto 0);
--			ki, rst, sleep: in std_logic;
--			ko: OUT std_logic);
--	end component;
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
--	component BUFFER_A is 
--		port(A: in std_logic; 
--			 Z: out std_logic); 
--	end component; 
--
--
--signal mem_data_out : std_logic_vector(bitwidth-1 downto 0);
--signal address_sr : std_logic_vector(8 downto 0);
--signal delay_sleep, not_sleep, sdc_en : std_logic;
--signal pre_delay_sleep : std_logic_vector(clock_delay downto 0);
--signal pre_sdc_en : std_logic_vector(mem_delay downto 0);
--signal input_reg_sleep, comp_out_out : std_logic;
--
--signal input_reg_out, reg_out_in : dual_rail_logic_vector(bitwidth-1 downto 0);

  signal Q: std_logic_vector(15 downto 0);
  signal CLK:  std_logic;
  signal CEN:  std_logic;
  signal A :  std_logic_vector(8 downto 0);


begin 

tanh_wrapper: LUT_tanh_wrapper 
	generic map (bitwidth    => bitwidth,   
		         clock_delay => clock_delay,		--ADD DELAY FOR INCREASED SETUP TIMES
		         mem_delay   => mem_delay  )		--ADD DELAY FOR INCREASED MEMORY DELAY
	port map (address   => address,
		      sleep_in  => sleep_in,
		      reset     => reset,
		      ki        => ki,
		      sleep_out => sleep_out,
		      ko        => ko,
		      z         => z,
		      ---ROM ports-------
		      Q   => Q,  
		      CLK => CLK,
		      CEN => CEN,
		      A   => A  
	);


--ROM Instantiation
memory : tanh_rom
	port map( Q   => Q,   
		      CLK => CLK,
		      CEN => CEN,
		      A   => A,  
		      EMA => "000");


--ko <= input_reg_sleep;
--
--	comp_in: compm
--		generic map(width => bitwidth)
--		port map(
--			a => address,
--			ki => comp_out_out,
--			rst => reset,
--			sleep => sleep_in,
--			ko => input_reg_sleep);
--
--	input_reg: regs_gen_null_res
--		generic map(width => bitwidth)
--		port map(
--			d => address,
--			q => input_reg_out,
--			reset => reset,
--			sleep => input_reg_sleep);
--
--
--generate_address : for i in 0 to 8 generate
--	address_sr(i) <= input_reg_out(i+7).rail1;
--end generate;
--
--	delay_sleep1_gate : BUFFER_A 
--		port map(A => input_reg_sleep,
--			 Z => pre_delay_sleep(0));
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
--
----ROM Instantiation
--memory : tanh_rom
--	port map( Q => mem_data_out,
--		CLK => not_sleep,
--		CEN => input_reg_sleep,
--		A => address_sr,
--		EMA => "000");
--
--converter : SDC_w_EN
--	generic map(bitwidth => bitwidth)
--	port map(a => mem_data_out,
--		en => sdc_en,
--		sleep => input_reg_sleep,
--		z => reg_out_in);
--
--	comp_out: compm
--		generic map(width => bitwidth)
--		port map(
--			a => reg_out_in,
--			ki => ki,
--			rst => reset,
--			sleep => input_reg_sleep,
--			ko => comp_out_out);
--
--	reg_out: regs_gen_null_res
--		generic map(width => bitwidth)
--		port map(
--			d => reg_out_in,
--			q => z,
--			reset => reset,
--			sleep => comp_out_out);
--
--sleep_out <= comp_out_out;


end arch_LUT_tanh; 
