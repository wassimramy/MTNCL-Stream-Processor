
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_Shade_Counter is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256; shadeBitwidth: in integer := 12);
	port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		--ki	 		: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		image_stored: out std_logic;
		output   	: out dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0)
	);
end;

architecture arch of MTNCL_Shade_Counter is

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
	end component;

	component counter_selfReset_mod_inc is
		generic(width: integer);
		port(	 
			increment: in dual_rail_logic_vector(width-1 downto 0);
			sleep_in: in std_logic;
			reset: in std_logic;
			ki: in std_logic;
			ko: out std_logic;
			sleep_out: out std_logic;
			z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component counter_selfReset is
		generic(width: integer);
		port(	reset_count: in dual_rail_logic_vector(width-1 downto 0);
			sleep_in: in std_logic;
		 	reset: in std_logic;
		 	ki: in std_logic;
		 	ko: out std_logic;
		 	sleep_out: out std_logic;
		 	accumulate_reset: out dual_rail_logic;
		 	z: out dual_rail_logic_vector(width-1 downto 0));
	end component;	

	component th22d_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			rst: in std_logic;
			z: out std_logic);
	end component;

	component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
	end component; 

	component th12nm_a is
		port(
			a : in std_logic;
			b : in std_logic;
			rst : in std_logic;
			s : in std_logic;
			z : out std_logic);
	end component;

	component decoder_gen is
		generic(bitwidth: integer);
		port(a: in dual_rail_logic_vector(bitwidth-1 downto 0);
			sleep : in std_logic;
			z : out dual_rail_logic_vector(2**bitwidth-1 downto 0));
	end component;

	component th22d_a is
	port(a   : in  std_logic;
		 b   : in  std_logic;
		 rst : in  std_logic;
		 z   : out std_logic);
	end component;

	component genregm is
	generic(width : in integer := 4);
	port(a     : IN  dual_rail_logic_vector(width-1 downto 0);
		 s : in  std_logic;
		 z     : out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component compm is
		generic(width : in integer := 4);
		port(a              : IN  dual_rail_logic_vector(width-1 downto 0);
			 ki, rst, sleep : in  std_logic;
			 ko             : OUT std_logic);
	end component;
	
	signal increments	: dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0);
	signal outputReg	: dual_rail_logic_vector((numberOfShades*shadeBitwidth)-1 downto 0);
	signal inputReg	: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal data_0,data_1		: dual_rail_logic;
	signal sleep_1, ko_1, ko_2, ko_3, ki_global: std_logic;
	signal decoder_output	: dual_rail_logic_vector(2**bitwidth-1 downto 0);
	signal counters_sleep_out, counters_ko: std_logic_vector (numberOfShades-1 downto 0);

	signal reset_count, global_count: dual_rail_logic_vector (shadeBitwidth downto 0);
	signal accRes		: dual_rail_logic;
	signal counter_ko, counter_sleep_out, accRes_temp, accRes_perm, sleep_in, ki_1: std_logic;

begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	generate_4096 : for i in 0 to shadeBitwidth-1 generate
		reset_count(i) <= data_1;
	end generate;
	reset_count(shadeBitwidth) <= data_0;

	--Set the block's global ko
	ko <= ko_1;

	ko_image_load_inv_generate : inv_a 
		port map(a => ko_1,
			 z => ki_global);

		generate_global_sleep_in : MUX21_A 
		port map(
			A => sleep,
			B => '0',
			S => accRes_perm,
			Z => sleep_in);

	-- Input Registers
	inReg : genregm 
		generic map(bitwidth)
		port map(input, ko_1, inputReg);

	inComp : compm
		generic map(bitwidth)
		port map(input, ko_3, rst, sleep_in, ko_1);

	--This tree will generate the global ko coming from the counter and fed to the input registers.
	th22d_counter_tree : th22d_tree_gen
	generic map(numInputs => numberOfShades )
		port map(
			a => counters_ko,
			rst => rst,
			z => ko_3);

	--This decoder will decide which counter to increment and which one to stay the same.
	--Never change the DECODER setting. Any change will cause the adder in th ecounter to mess up.
	decoder : decoder_gen
	generic map(bitwidth => bitwidth)
	port map(a => inputReg,
		sleep => '0',
		z => decoder_output);

	--This block sets the increments fed into the counters to make sure the intended counter to increment while the others stay the same.
	setting_increments_i : for i in 0 to numberOfShades-1 generate
		setting_increments_j : for j in 1 to shadeBitwidth-1 generate
			increments(i*shadeBitwidth+j) <= data_0;
		end generate;
		increments(i*shadeBitwidth) <= decoder_output(i);
	end generate;

	--This block generates the counters to 
	generate_counters : for i in 0 to numberOfShades-1 generate
	count_unit : counter_selfReset_mod_inc
		generic map(width => shadeBitwidth)
		port map(
			 increment => increments(((i+1)*shadeBitwidth)-1 downto i*shadeBitwidth),
			 sleep_in => ko_1,
			 reset => rst,
			 ki => ko_2,
			 ko => counters_ko(i),
			 sleep_out => counters_sleep_out(i),
			 z => outputReg(((i+1)*shadeBitwidth)-1 downto i*shadeBitwidth));
	end generate;

	counter_memWriteAddress : counter_selfReset
		generic map(width => shadeBitwidth+1)
		port map(reset_count => reset_count,
			sleep_in => ko_1,
		 	reset => rst,
		 	ki => ko_2,
		 	ko => counter_ko,
		 	sleep_out => counter_sleep_out,
		 	accumulate_reset => accRes,
		 	z => global_count);

	--This block generates the global sleep from the counters fed to the output registers 
	th22d_counter_tree_sleep : th22d_tree_gen
	generic map(numInputs => numberOfShades )
		port map(
			a => counters_sleep_out,
			rst => rst,
			z => sleep_1);

	-- Output Register
	outReg : genregm 
		generic map(numberOfShades*shadeBitwidth)
		port map(outputReg, ko_2, output);

	outComp : compm
		generic map(numberOfShades*shadeBitwidth)
		port map(outputReg, ki_1, rst, sleep_1, ko_2);

	--Set the block's global sleepOut
	--sleepOut <= ko_2;

	generate_image_loaded : th12nm_a
		port map(a => accRes.rail1,
			b => accRes_temp,
			rst => rst,
			s => '0',
			z => accRes_temp);

	accRes_perm <= accRes_temp;
	image_stored <= accRes_temp;
		generate_global_sleep_out : MUX21_A 
		port map(
			A => '1',
			B => ko_2,
			S => accRes_perm,
			Z => sleepOut);

		generate_global_ki : MUX21_A 
		port map(
			A => ki_global,
			B => '1',
			S => accRes_perm,
			Z => ki_1);

end arch;
