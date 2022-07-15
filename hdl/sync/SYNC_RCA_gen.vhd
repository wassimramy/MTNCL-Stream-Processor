
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;

entity SYNC_RCA_GEN is
generic(bitwidth: in integer := 8);
	port(
		input    	: in  std_logic_vector((2*bitwidth)-1 downto 0);
		--clk  		: in std_logic;
		--reset  		: in std_logic;
		S   		: out std_logic_vector(bitwidth downto 0)
	);
end;

architecture arch of SYNC_RCA_GEN is

	component HA
		port(X, Y    : in  std_logic;
			 COUT, S : out std_logic);
	end component;

	component FA is
		port(
			CIN   : IN  std_logic;
			X     : IN  std_logic;
			Y     : IN  std_logic;
			COUT  : OUT std_logic;
			S     : OUT std_logic);
	end component;

	component DFFRX1MTR_No_QN_gen is
	generic(bitwidth: in integer := 8);
		port(
			d   	: IN  std_logic_vector(bitwidth-1 downto 0);
			clk     : IN  std_logic;
			reset   : IN  std_logic;
			q     	: out std_logic_vector(bitwidth-1 downto 0));
	end component;	


	signal inputReg : std_logic_vector((2*bitwidth)-1 downto 0);
	signal carry : std_logic_vector(bitwidth-1 downto 0);
	signal sReg : std_logic_vector(bitwidth downto 0);

begin

	--input_register : DFFRX1MTR_No_QN_gen 
	--generic map(bitwidth => 2*bitwidth)
	--port map(
	--			d => input,
	--			clk => clk,
	--			reset => reset,
	--			q => inputReg);

	sReg(bitwidth) <= carry(bitwidth-1);

	HAa : HA port map(X => inputReg(0), Y => inputReg(bitwidth), COUT => carry(0), S => sReg(0));

	FAGenmA : for i in 1 to bitwidth-1 generate
		FAa : FA port map(X => inputReg(i), Y => inputReg(i+bitwidth), CIN => carry(i - 1), COUT => carry(i), S => sReg(i));
	end generate;
	
	inputReg <= input;
	S <= sReg;

	--output_register : DFFRX1MTR_No_QN_gen 
	--generic map(bitwidth => bitwidth+1)
	--port map(
	--			d => sReg,
	--			clk => clk,
	--			reset => reset,
	--			q => S);

end arch;
