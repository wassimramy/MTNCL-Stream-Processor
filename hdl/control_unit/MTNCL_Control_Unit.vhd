
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

entity MTNCL_Control_Unit is
	generic(
				bitwidth 		: in integer := 8; 
				addresswidth	: in integer := 12; 
				clock_delay 	: in integer := 16; 
				mem_delay		: in integer := 48; 
				numberOfShades	: in integer := 256; 
				shadeBitwidth 	: in integer := 12; 
				numberOfPixels	: in integer := 4096; 
				opCodeBitwidth 	: in integer := 4

			);
	port(
				opCode			: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
				input    		: in  dual_rail_logic_vector(bitwidth-1 downto 0);
				ki	 			: in std_logic;
				sleep 			: in  std_logic;
				rst  			: in std_logic;
				sleepOut 		: out std_logic;
				ko 	     		: out std_logic;
				output   		: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_Control_Unit is

	  component MTNCL_Histogram_Equalization is
	    generic(
					bitwidth: in integer := 4; 
					addresswidth: in integer := 12; 
					clock_delay: in integer := 12; 
					mem_delay: in integer := 12; 
					numberOfShades: in integer := 256; 
					shadeBitwidth: in integer := 12; 
					numberOfPixels: in integer := 4096
	    		);
	    port(
					input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
					ki	 	: in std_logic;
					sleep 		: in  std_logic;
					rst  		: in std_logic;
					sleepOut 	: out std_logic;
					ko 	     	: out std_logic;
					output   	: out dual_rail_logic_vector((bitwidth)-1 downto 0)
	      );
	  end component;

	  component MTNCL_SF_Core_Top_Level is
	    generic(
	    			bitwidth: in integer := 4; 
	    			addresswidth : in integer := 12; 
	    			clock_delay : in integer := 16; 
	    			mem_delay : integer := 48
	    		);
	    port(
					input : in dual_rail_logic_vector(bitwidth-1 downto 0);
					reset : in std_logic;
					ki : in std_logic;
					id : in dual_rail_logic;
					parallelism_en : in dual_rail_logic;
					ko : out std_logic;
					sleep_in : in std_logic;
					sleep_out : out std_logic;
					output : out dual_rail_logic_vector(bitwidth-1 downto 0)
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

component mux_nto1_sr_gen is
	generic(
		bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			z: out std_logic_vector(bitwidth-1 downto 0));
	end component;

	signal data_0,data_1		: dual_rail_logic;

	signal inputHEQMUX, inputSFMUX: dual_rail_logic_vector(2*bitwidth-1 downto 0);
	signal globalOutput: dual_rail_logic_vector(4*bitwidth-1 downto 0);
	signal inputHEQ, inputSF, outputSF, outputHEQ: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal sleep_SF, sleep_HEQ, sleepOut_HEQ, sleepOut_SF: std_logic;
	signal ki_SF, ki_HEQ, ko_HEQ, ko_SF: std_logic;
	signal sleep_global_00, sleep_global_01: std_logic;
	signal ko_global_00, ko_global_01: std_logic;
	signal ki_xor: std_logic;

	signal choose_ki_HEQ_output : std_logic_vector (0 downto 0);
	signal choose_ki_HEQ_input : std_logic_vector (3 downto 0);
	signal choose_ki_HEQ_select : std_logic_vector (1 downto 0);
begin

	--set data_0 & data_1 for padding
	data_0.RAIL0 <= '1';
	data_0.RAIL1 <= '0';

	data_1.RAIL0 <= '0';
	data_1.RAIL1 <= '1';


	mtncl_sf_core_instance: MTNCL_SF_Core_Top_Level
 		generic map(
 						bitwidth => bitwidth, 
 						addresswidth => addresswidth,  
 						clock_delay => clock_delay, 
 						mem_delay => mem_delay
 					)
  		port map(
				input 			=> inputSF,
				ki 				=> ki_SF,
				sleep_in 		=> sleep_SF,
				reset 			=> rst,
				id 				=> opCode(3),
				parallelism_en 	=> opCode(2),
				ko 				=> ko_SF,
				output 			=> outputSF,
				sleep_out 		=> sleepOut_SF
    		);

	mtncl_heq_core_instance: MTNCL_Histogram_Equalization
 		generic map(
	 					bitwidth => bitwidth, 
	 					addresswidth => addresswidth, 
						clock_delay => clock_delay, 
						mem_delay => mem_delay, 
	 					numberOfShades => numberOfShades,  
	 					shadeBitwidth =>shadeBitwidth, 
	 					numberOfPixels => numberOfPixels
 					)
  		port map(
    				input => inputHEQ,
					ki => ki_HEQ,
					sleep => sleep_HEQ,
    				rst => rst,
    				ko => ko_HEQ,
    				output => outputHEQ,
    				sleepOut => sleepOut_HEQ
    		);

	--Generate inputHEQ
	inputHEQMUX <= input & outputSF;
  	heq_input: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => 2)
 	port map(
    		a =>inputHEQMUX,
    		sel => opCode(0 downto 0),
    		sleep => '0',
    		z => inputHEQ);

	--Generate inputSF
	inputSFMUX <= outputHEQ & input;
  	SF_input: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => 2)
 	port map(
    		a =>inputSFMUX,
    		sel => opCode(0 downto 0),
    		sleep => '0',
    		z => inputSF);

	--Generate sleep_SF
	SF_sleep : MUX21_A 
		port map(
			A => sleep, 
			B => sleepOut_HEQ,
			S => opCode(0).RAIL1,
			Z => sleep_SF);

	--Generate ki_xor
	generate_ki_xor : MUX21_A 
		port map(
			A => opCode(0).RAIL1, 
			B => opCode(0).RAIL0,
			S => opCode(1).RAIL1,
			Z => ki_xor);

	--Generate ki_SF
	SF_ki : MUX21_A 
		port map(
			A => ki, 
			B => ko_HEQ,
			--S => opCode(1).RAIL1,
			S => ki_xor,
			Z => ki_SF);

	--Generate sleep_HEQ
	HEQ_sleep : MUX21_A 
		port map(
			A => sleepOut_SF, 
			B => sleep,
			S => opCode(0).RAIL1,
			Z => sleep_HEQ);

	choose_ki_HEQ_input <= ko_SF & ki & ki & '1';
	choose_ki_HEQ_select <= opCode(1).RAIL1 & opCode(0).RAIL1;
	choose_ki_HEQ : mux_nto1_sr_gen
	generic map(bitwidth => 1, numInputs => 4)
		port map(
			a => choose_ki_HEQ_input,
			sel => choose_ki_HEQ_select,
			z => choose_ki_HEQ_output);	

			ki_HEQ <= choose_ki_HEQ_output(0);
	--Generate ki_HEQ
	--HEQ_ki : MUX21_A 
	--	port map(
	--		A => ki,
	--		B => ko_SF,
	--		S => opCode(0).RAIL1,
	--		Z => ki_HEQ);

	--Generate Global output
	globalOutput <= outputSF & outputHEQ & outputHEQ & outputSF;
  	global_output: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => 4)
 	port map(
    		a =>globalOutput,
    		sel => opCode(1 downto 0),
    		sleep => '0',
    		z => output);

	--Generate Global sleepOut
	global_sleepOut_00 : MUX21_A 
		port map(
			A => sleepOut_SF, 
			B => sleepOut_HEQ,
			S => opCode(0).RAIL1,
			Z => sleep_global_00);

	global_sleepOut_01 : MUX21_A 
		port map(
			A => sleepOut_HEQ, 
			B => sleepOut_SF,
			S => opCode(0).RAIL1,
			Z => sleep_global_01);

	global_sleepOut_10 : MUX21_A 
		port map(
			A => sleep_global_00, 
			B => sleep_global_01,
			S => opCode(1).RAIL1,
			Z => sleepOut);

	--Generate Global ko
	global_ko_00 : MUX21_A 
		port map(
			A => ko_SF, 
			B => ko_HEQ,
			S => opCode(0).RAIL1,
			Z => ko_global_00);

	global_ko_01 : MUX21_A 
		port map(
			A => ko_SF, 
			B => ko_HEQ,
			S => opCode(0).RAIL1,
			Z => ko_global_01);

	global_ko_10 : MUX21_A 
		port map(
			A => ko_global_00, 
			B => ko_global_01,
			S => opCode(1).RAIL1,
			Z => ko);

end arch;
