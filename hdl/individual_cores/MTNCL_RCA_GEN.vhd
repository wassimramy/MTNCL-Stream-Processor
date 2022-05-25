
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;

entity MTNCL_RCA_GEN is
generic(bitwidth: in integer := 4);
	port(
		input    	: in  dual_rail_logic_vector((2*bitwidth)-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		S   		: out dual_rail_logic_vector(bitwidth downto 0)
	);
end;

architecture arch of MTNCL_RCA_GEN is
	component HAm
		port(X, Y    : in  dual_rail_logic;
			 sleep   : in  std_logic;
			 COUT, S : out dual_rail_logic);
	end component;
	component FAm is
		port(
			CIN   : IN  dual_rail_logic;
			X     : IN  dual_rail_logic;
			Y     : IN  dual_rail_logic;
			sleep : in  std_logic;
			COUT  : OUT dual_rail_logic;
			S     : OUT dual_rail_logic);
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

	component th22d_a is
	port(a   : in  std_logic;
		 b   : in  std_logic;
		 rst : in  std_logic;
		 z   : out std_logic);
	end component;

	signal inputReg : dual_rail_logic_vector((2*bitwidth)-1 downto 0);
	signal carry : dual_rail_logic_vector(bitwidth-1 downto 0);
	signal sReg : dual_rail_logic_vector(bitwidth downto 0);
	signal ko_OutReg, koSig : std_logic;

begin
	-- Input Registers
	inReg : genregm 
		generic map(2*bitwidth)
		port map(input, koSig, inputReg);
	inComp : compm
		generic map(2*bitwidth)
		port map(input, ko_OutReg, rst, sleep, koSig);

	sleepOut <= ko_OutReg;
	ko <= koSig;
	sReg(bitwidth) <= carry(bitwidth-1);

	HAa : HAm port map(inputReg(0), inputReg(bitwidth), koSig, carry(0), sReg(0));

	FAGenmA : for i in 1 to bitwidth-1 generate
		FAa : FAm port map(inputReg(i), inputReg(i+bitwidth), carry(i - 1), koSig, carry(i), sReg(i));
	end generate;
	
	
	-- Output Register
	outReg : genregm 
		generic map(bitwidth+1)
		port map(sReg, ko_OutReg, S);
	outComp : compm
		generic map(bitwidth+1)
		port map(sReg, ki, rst, koSig, ko_OutReg);
	
end arch;
