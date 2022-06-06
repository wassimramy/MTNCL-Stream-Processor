
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
					bitwidth 				: in integer := 4; 
					addresswidth		: in integer := 12; 
					clock_delay 		: in integer := 16; 
					mem_delay				: in integer := 48; 
					numberOfShades	: in integer := 256; 
					shadeBitwidth 	: in integer := 12; 
					numberOfPixels	: in integer := 4096; 
					opCodeBitwidth 	: in integer := 4
    );
    
    port(
					opCode    	: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
					input    		: in  dual_rail_logic_vector(bitwidth-1 downto 0);
					ki	 				: in std_logic;
					sleep 			: in  std_logic;
					rst  				: in std_logic;
					sleepOut 		: out std_logic;
					ko 	     		: out std_logic;
					output   		: out dual_rail_logic_vector((bitwidth)-1 downto 0)
      );
  end component;

	component MTNCL_CU_Data_Output is
		generic(
			bitwidth 			: integer := bitwidth;
			addresswidth 	: integer := addresswidth;
			clock_delay 	: integer := clock_delay;
			mem_delay 		: integer := mem_delay
			);
		port(
				pixel : in dual_rail_logic_vector(2*bitwidth-1 downto 0);
				reset : in std_logic;
				ki : in std_logic;
				parallelism_en 	: in dual_rail_logic;
				ko : out std_logic;
				sleep_in : in std_logic;
				sleep_out : out std_logic;
				z : out dual_rail_logic_vector(bitwidth-1 downto 0)
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
	signal input_main_memory: dual_rail_logic_vector(2*bitwidth-1 downto 0);
	signal op_code_node_1, op_code_node_2: dual_rail_logic_vector(opCodeBitwidth downto 0);
	signal sleep_out_node_1, sleep_out_node_2, ko_node_1, ko_node_2, ko_main_memory, sleep_in_node_2: std_logic;


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

	op_code_node_1 <= data_0 & opCode(opCodeBitwidth-1 downto 0);
 node_1_instance: MTNCL_Control_Unit
 generic map(
						bitwidth 				=> bitwidth, 
						addresswidth 		=> addresswidth, 
						clock_delay 		=> clock_delay, 
						mem_delay 			=> mem_delay, 
						numberOfShades 	=> numberOfShades,  
						shadeBitwidth 	=> shadeBitwidth, 
						numberOfPixels 	=> numberOfPixels, 
						opCodeBitwidth 	=> opCodeBitwidth+1
						)

  port map(
					    opCode 		=> op_code_node_1,
					    input 		=> input,
					    ki 				=> ko_main_memory,
					    sleep 		=> sleep,
					    rst 			=> rst,
					    --ko 				=> ko_node_1,
					    ko 				=> ko,
					    output 		=> input_main_memory (bitwidth-1 downto 0),
					    sleepOut 	=> sleep_out_node_1
    );

	op_code_node_2 <= data_1 & opCode(opCodeBitwidth-1 downto 0);
 node_2_instance: MTNCL_Control_Unit
 generic map(
						bitwidth 				=> bitwidth, 
						addresswidth 		=> addresswidth, 
						clock_delay 		=> clock_delay, 
						mem_delay 			=> mem_delay, 
						numberOfShades 	=> numberOfShades,  
						shadeBitwidth 	=> shadeBitwidth, 
						numberOfPixels 	=> numberOfPixels, 
						opCodeBitwidth 	=> opCodeBitwidth+1
						)

  port map(
					    opCode 		=> op_code_node_2,
					    input 		=> input,
					    ki 				=> ko_main_memory,
					    sleep 		=> sleep_in_node_2,
					    rst 			=> rst,
					    ko 				=> ko_node_2,
					    output 		=> input_main_memory (2*bitwidth-1 downto bitwidth),
					    sleepOut 	=> sleep_out_node_2
    );

	--Generate sleep_node_2
	generate_sleep_in_node_2 : MUX21_A 
		port map(
			A => '1', 
			B => sleep,
			S => op_code_node_2(opCodeBitwidth-1).rail1,
			Z => sleep_in_node_2);

	main_memory_instance : MTNCL_CU_Data_Output
		generic map(bitwidth => bitwidth,
					addresswidth => addresswidth)
		port map(
				pixel 					=> input_main_memory,
				reset 					=> rst,
				ki 							=> ki,
				parallelism_en 	=> opCode (2),
				sleep_in 				=> sleep_out_node_1,
				ko 							=> ko_main_memory,
				sleep_out 			=> sleepOut,
				z 							=> output
	);

end arch;
