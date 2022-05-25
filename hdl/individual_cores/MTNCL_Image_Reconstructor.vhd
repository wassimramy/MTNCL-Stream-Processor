
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
generic(bitwidth: in integer := 4; numberOfShades: in integer := 256);
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

  component MTNCL_Rounding_Checker is
    generic(bitwidth: in integer := 4);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		sel		: in  dual_rail_logic_vector(0 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)      );
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
	
	signal kos, sleeps: std_logic_vector (2 downto 0);
	signal pixelRegister, outputReg	: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal newShadeValues, newShadeValuesReg: dual_rail_logic_vector(257*8-1 downto 0);
	signal data_0,data_1		: dual_rail_logic_vector (0 downto 0);
begin

	--set data_0 & data_1 for padding
	data_0(0).RAIL0 <= '1';
	data_0(0).RAIL1 <= '0';

	data_1(0).RAIL0 <= '0';
	data_1(0).RAIL1 <= '1';

	--Set the block's global ko
	ko <= kos(0);

	--Add one to the old pixel value to map to the right value
	add_one : MTNCL_Rounding_Checker
	generic map(bitwidth)
	port map(input => pixel,
		sel => data_1(0 downto 0), 
		ki => kos(1), 
		sleep => sleep, 
		rst => rst, 
		sleepOut => sleeps(0),
		ko => kos(0), 
		output => pixelRegister);

	--Concat the new shades with the pixel to control the ko
	newShadeValues((numberOfShades+1)*bitwidth-1 downto 0) <= pixelRegister & input;

	-- Input Registers
	inReg : genregm 
		generic map((numberOfShades+1)*bitwidth)
		port map(newShadeValues,  kos(1), newShadeValuesReg);
	inComp : compm
		generic map((numberOfShades+1)*bitwidth)
		port map(newShadeValues, kos(2), rst,  sleeps(0),  kos(1));

	--The mux in charge of mapping the old shade to the new shade
  	choose_the_new_value: mux_nto1_gen
	generic map(bitwidth => bitwidth,
		numInputs => numberOfShades)
 	port map(
    		a => newShadeValuesReg(numberOfShades*bitwidth-1 downto 0),
    		sel => newShadeValuesReg((numberOfShades+1)*bitwidth-1 downto numberOfShades*bitwidth),
    		sleep => kos(1),
    		z => outputReg);

	-- Output Registers
	outReg : genregm 
		generic map(bitwidth)
		port map(outputReg,  kos(2), output);
	outComp : compm
		generic map(bitwidth)
		port map(outputReg, ki, rst, kos(1),  kos(2));

	--Set the block's global sleepOut
	sleepOut <= kos(2);

end arch;
