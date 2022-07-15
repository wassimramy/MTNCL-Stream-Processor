
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

entity MTNCL_Image_Reconstructor is
generic(bitwidth: in integer := 8; numberOfShades: in integer := 256);
	port(
		input    	: in  dual_rail_logic_vector((numberOfShades)*bitwidth-1 downto 0);
		pixel    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_Image_Reconstructor is

	component mux_nto1_gen is
	generic(bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			sleep: in std_logic;
			z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

  component MTNCL_RCA_GEN is
	generic(bitwidth : in integer := 4);
	port(
		input    	: in  dual_rail_logic_vector((2*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector(bitwidth downto 0));
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

component regs_gen_null_res_w_compm is
		generic(width: in integer := bitwidth);
		port(
				d: in dual_rail_logic_vector(width-1 downto 0);
				reset: in std_logic;
				sleep_in: in std_logic;
				ki: in std_logic;
				sleep_out: out std_logic;
				ko: out std_logic;
				q: out dual_rail_logic_vector(width-1 downto 0)
			);
	end component;

	signal pixelRegister	: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal inputRegister: dual_rail_logic_vector((numberOfShades)*bitwidth-1 downto 0);
	signal data_0,data_1		: dual_rail_logic_vector (0 downto 0);
	signal ko_OutReg	 	: std_logic;
begin

	--set data_0 & data_1 for padding
	data_0(0).RAIL0 <= '1';
	data_0(0).RAIL1 <= '0';

	data_1(0).RAIL0 <= '0';
	data_1(0).RAIL1 <= '1';

inputRegister <= input (bitwidth-1 downto 0) & input ((numberOfShades)*bitwidth-1 downto bitwidth);
	--The mux in charge of mapping the old shade to the new shade
  	choose_the_new_value: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => numberOfShades)
 	port map(
    		a => inputRegister ((numberOfShades)*bitwidth-1 downto 0*bitwidth),
    		sel => pixel(bitwidth-1 downto 0),
    		sleep => sleep,
    		z => pixelRegister);

outReg : genregm 
		generic map(bitwidth)
		port map(pixelRegister, ko_OutReg, output);
	outComp : compm
		generic map(bitwidth)
		port map(pixelRegister, ki, rst, sleep, ko_OutReg);

ko <= ko_OutReg;
sleepOut <= ko_OutReg;
end arch;
