
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;
use ieee.math_real.all;

entity MTNCL_Control_Unit_Top_Level is
	generic(
				bitwidth 		: in integer := 8; 
				addresswidth	: in integer := 12; 
				clock_delay 	: in integer := 16; 
				mem_delay		: in integer := 48; 
				numberOfShades	: in integer := 256; 
				shadeBitwidth 	: in integer := 12; 
				numberOfPixels	: in integer := 4096; 
				opCodeBitwidth 	: in integer := 3

			);
	port(
				opCode		: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
				input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
				ki	 			: in std_logic;
				sleep 		: in  std_logic;
				rst  			: in std_logic;
				sleepOut 	: out std_logic;
				ko 	     	: out std_logic;
				output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_Control_Unit_Top_Level is

  component MTNCL_Control_Unit is
    generic(
					bitwidth 		: in integer := 4; 
					addresswidth	: in integer := 12; 
					clock_delay 	: in integer := 16; 
					mem_delay		: in integer := 48; 
					numberOfShades	: in integer := 256; 
					shadeBitwidth 	: in integer := 12; 
					numberOfPixels	: in integer := 4096; 
					opCodeBitwidth 	: in integer := 2
    );
    
    port(
					opCode    	: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
					input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
					ki	 		: in std_logic;
					sleep 		: in  std_logic;
					rst  		: in std_logic;
					sleepOut 	: out std_logic;
					ko 	     	: out std_logic;
					output   	: out dual_rail_logic_vector((bitwidth)-1 downto 0)
      );
  end component;

	component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
	end component; 

	component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a 		: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel 	: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			sleep 	: in std_logic;
			z 		: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;



	signal data_0,data_1		: dual_rail_logic;
	--signal reset_count, roundedPixelRegister	: dual_rail_logic_vector(bitwidth-1 downto 0);
	--signal reset_count_plus_one	: dual_rail_logic_vector(shadeBitwidth downto 0);

	signal inputHEQMUX, inputSFMUX: dual_rail_logic_vector(2*bitwidth-1 downto 0);
	signal globalOutput: dual_rail_logic_vector(2*bitwidth-1 downto 0);
	signal inputHEQ, inputSF, outputSF, outputHEQ: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal sleep_SF, sleep_HEQ, sleepOut_HEQ, sleepOut_SF: std_logic;
	signal ki_SF, ki_HEQ, ko_HEQ, ko_SF: std_logic;
	signal sleep_global_00, sleep_global_01: std_logic;
	signal ko_global_00, ko_global_01: std_logic;
	signal ki_xor: std_logic;

begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';

	--setting_reset_count : for i in 0 to bitwidth-1 generate
	--	reset_count(i) <= data_1 ;
	--end generate;

	--setting_reset_count_plus_one : for i in 0 to shadeBitwidth-1 generate
	--	reset_count_plus_one(i) <= data_0 ;
	--end generate;
	--reset_count_plus_one(shadeBitwidth) <= data_1 ;


 node_1_instance: MTNCL_Control_Unit
 generic map(
						bitwidth 				=> bitwidth, 
						addresswidth 		=> addresswidth, 
						clock_delay 		=> clock_delay, 
						mem_delay 			=> mem_delay, 
						numberOfShades 	=> numberOfShades,  
						shadeBitwidth 	=> shadeBitwidth, 
						numberOfPixels 	=> numberOfPixels, 
						opCodeBitwidth 	=> opCodeBitwidth-1
						)

  port map(
					    opCode 		=> opCode(opCodeBitwidth-2 downto 0),
					    input 		=> input,
					    ki 				=> ki_node_1,
					    sleep 		=> sleep_in_node_1,
					    rst 			=> reset,
					    ko 				=> ko_node_1,
					    output 		=> output_node_1,
					    sleepOut 	=> sleep_out_node_1
    );

 node_2_instance: MTNCL_Control_Unit
 generic map(
						bitwidth 				=> bitwidth, 
						addresswidth 		=> addresswidth, 
						clock_delay 		=> clock_delay, 
						mem_delay 			=> mem_delay, 
						numberOfShades 	=> numberOfShades,  
						shadeBitwidth 	=> shadeBitwidth, 
						numberOfPixels 	=> numberOfPixels, 
						opCodeBitwidth 	=> opCodeBitwidth-1
						)

  port map(
					    opCode 		=> opCode(opCodeBitwidth-2 downto 0),
					    input 		=> input,
					    ki 				=> ki_node_2,
					    sleep 		=> sleep_in_node_2,
					    rst 			=> reset,
					    ko 				=> ko_node_2,
					    output 		=> output_node_2,
					    sleepOut 	=> sleep_out_node_2
    );

	--Generate sleep_in_node_1
	generate_sleep_in_node_1 : MUX21_A 
		port map(
			A => sleep, 
			B => '1',
			S => opCode(2).RAIL1,
			Z => sleep_in_node_1);

	--Generate sleep_in_node_2
	generate_sleep_in_node_2 : MUX21_A 
		port map(
			A => '1', 
			B => sleep,
			S => opCode(2).RAIL1,
			Z => sleep_in_node_2);

	--Generate ko
	generate_global_ko : MUX21_A 
		port map(
			A => ko_node_1, 
			B => ko_node_2,
			S => opCode(2).RAIL1,
			Z => ko);

	--Generate sleep_out
	generate_global_sleep_out : MUX21_A 
		port map(
			A => sleep_out_node_1,
			B => sleep_out_node_2,
			S => opCode(2).RAIL1,
			Z => sleepOut);

	--Generate ki_HEQ
	--HEQ_ki : MUX21_A 
	--	port map(
	--		A => ki,
	--		B => ko_SF,
	--		S => opCode(0).RAIL1,
	--		Z => ki_HEQ);

	--Generate Global output
	globalOutput <= output_node_2 & output_node_1;
  	global_output: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => 2)
 	port map(
    		a =>globalOutput,
    		sel => opCode(2 downto 2),
    		sleep => '0',
    		z => output);


end arch;
