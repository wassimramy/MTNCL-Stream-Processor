--MEANT TO BE COPIED/CHANGED FOR SPECIFIC SRAM INSTANCES
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity sram_4096w_8b_8m_wrapper is
	generic(bitwidth : integer := 8;
		addresswidth : integer := 12;
		clock_delay : integer := 16;		--ADD DELAY FOR INCREASED SETUP TIMES
		mem_delay : integer := 48);		--ADD DELAY FOR INCREASED MEMORY DELAY
	port(
		address : in std_logic_vector(addresswidth-1 downto 0);
		mem_data : in std_logic_vector(bitwidth-1 downto 0);
		--address : in dual_rail_logic_vector(addresswidth-1 downto 0);
		--mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
		write_en : in dual_rail_logic;
		reset : in std_logic;
		ki : in std_logic;
		ko : out std_logic;
		sleep_in : in std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end sram_4096w_8b_8m_wrapper;



architecture arch_sram_4096w_8b_8m_wrapper of sram_4096w_8b_8m_wrapper is 

--SRAM declaration
	component sram_4096w_8b_8m is
		port( Q: out std_logic_vector(bitwidth-1 downto 0);
			CLK: in std_logic;
			CEN: in std_logic;
			WEN: in std_logic;
			A : in std_logic_vector(addresswidth-1 downto 0);
			D : in std_logic_vector(bitwidth-1 downto 0);
			EMA: in std_logic_vector(2 downto 0);
			RETN: in std_logic);
	end component;

	component SDC_w_EN is
		generic(bitwidth : integer);
		port(a : in std_logic_vector(bitwidth-1 downto 0);
			en : in std_logic;
			sleep : std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;


	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;


	component or2_a is
		port(a, b : in  std_logic;
			 z : out std_logic);
	end component;

	component and2_a is
		port(a, b : in  std_logic;
			 z : out std_logic);
	end component;

	component th22m_en_gen is
		generic(bitwidth : integer);
		port(a : in dual_rail_logic_vector(bitwidth-1 downto 0);
			en : in std_logic;
			sleep : std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;

	component BUFFER_A is 
		port(A: in std_logic; 
			 Z: out std_logic); 
	end component; 




signal sdc_out, reg_out_out : dual_rail_logic_vector(bitwidth downto 0);
signal en_gen_out : dual_rail_logic_vector(bitwidth-1 downto 0);

signal mem_data_out : std_logic_vector(bitwidth-1 downto 0);
signal mem_en, sdc_en, delay_sleep, not_sleep, not_write, comp_ki, comp_out  : std_logic;

signal pre_delay_sleep : std_logic_vector(clock_delay downto 0);
signal pre_sdc_en : std_logic_vector(mem_delay downto 0);
signal ko_pre_delay : std_logic_vector(clock_delay+mem_delay downto 0);

begin 



	delay_sleep0_gate : BUFFER_A
		port map(A => sleep_in,
			Z => mem_en);

	delay_sleep1_gate : BUFFER_A 
		port map(A => mem_en,
			 Z => pre_delay_sleep(0));

gen_pre_delay_sleep : for i in 0 to clock_delay-1 generate
	delay_sleep_gate_i : BUFFER_A
		port map(A => pre_delay_sleep(i),
			Z => pre_delay_sleep(i+1));
end generate;
	delay_sleep2_gate : BUFFER_A 
		port map(A => pre_delay_sleep(clock_delay),
			 Z => delay_sleep);

	inv_sleep : inv_a 
		port map(a => delay_sleep,
			 z => not_sleep);

	delay_not_sleep_gate : BUFFER_A 
		port map(A => not_sleep,
			 Z => pre_sdc_en(0));

gen_delay_not_sleep_gate : for i in 0 to mem_delay-1 generate
	pre_sdc_en_gate_i : BUFFER_A
		port map(A => pre_sdc_en(i),
			Z => pre_sdc_en(i+1));
	end generate;

	delay_not_sleep_gate2 : BUFFER_A 
		port map(A => pre_sdc_en(mem_delay),
			 Z => sdc_en);
--SRAM instantiation
memory_4096w_8b_8m: sram_4096w_8b_8m
	port map( Q => mem_data_out,
		CLK => not_sleep,
		CEN => mem_en,
		WEN => write_en.rail0,
		A => address,
		D => mem_data,
		EMA => "000",
		RETN => '1');


converter : SDC_w_EN
	generic map(bitwidth => bitwidth)
	port map(a => mem_data_out,
		en => sdc_en,
		sleep => sleep_in,
		z => sdc_out(bitwidth downto 1));

sdc_out(0) <= write_en;

	comp_unit: compm
		generic map(width => bitwidth+1)
		port map(
			a => sdc_out,
			ki => comp_ki,
			rst => reset,
			sleep => sleep_in,
			ko => comp_out);

	reg_out: regs_gen_null_res
		generic map(width => bitwidth+1)
		port map(
			d => sdc_out,
			q => reg_out_out,
			reset => reset,
			sleep => comp_out);

	inv_i : inv_a
		port map(a => reg_out_out(0).rail1,
			z => not_write);

	and_i : and2_a
		port map(a => not_write,
			b => ki,
			z => comp_ki);

	enable_gen : th22m_en_gen 
		generic map(bitwidth => bitwidth)
		port map(a => reg_out_out(bitwidth downto 1),
			en => reg_out_out(0).rail0,
			sleep => comp_out,
			z => en_gen_out);

--ko <= comp_out;
ko <= ko_pre_delay(clock_delay+mem_delay);

	delay_ko_gate : BUFFER_A
		port map(A => comp_out,
			Z => ko_pre_delay(0));

gen_pre_delay_ko : for i in 0 to clock_delay+mem_delay-1 generate
	delay_ko_gate_i : BUFFER_A
		port map(A => ko_pre_delay(i),
			Z => ko_pre_delay(i+1));
end generate;
sleep_out <= comp_out;

z <= en_gen_out(bitwidth-1 downto 0);

end arch_sram_4096w_8b_8m_wrapper; 
