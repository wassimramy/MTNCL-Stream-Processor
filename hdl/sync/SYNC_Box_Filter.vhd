
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;

entity SYNC_Box_Filter is
generic(bitwidth: in integer := 8);
	port(
		input    	: in  std_logic_vector((9*bitwidth)-1 downto 0);
		--clk  		: in std_logic;
		--reset  		: in std_logic;
		output   		: out std_logic_vector(bitwidth+3 downto 0)
	);
end;

architecture arch of SYNC_Box_Filter is

	component SYNC_RCA_GEN is
    generic(bitwidth: in integer := 8);
    port(
    				--clk : in std_logic;
						input    	: in  std_logic_vector(2*bitwidth-1 downto 0);
						--reset  		: in std_logic;
						S   			: out std_logic_vector((bitwidth) downto 0)
      );
  end component;

	component DFFRX1MTR_No_QN_gen is
	generic(bitwidth: in integer := 8);
		port(
			d   	: IN  std_logic_vector(bitwidth-1 downto 0);
			clk     : IN  std_logic;
			reset   : IN  std_logic;
			q     	: out std_logic_vector(bitwidth-1 downto 0));
	end component;	


	signal outputRCA_0_0, outputRCA_0_1, outputRCA_0_2, outputRCA_0_3 : std_logic_vector((bitwidth) downto 0);
	signal inputRCA_1_0, inputRCA_1_1 : std_logic_vector((2*bitwidth+1) downto 0);

	signal outputRCA_1_0, outputRCA_1_1 : std_logic_vector((bitwidth+1) downto 0);
	signal inputRCA_2_0 : std_logic_vector((2*bitwidth+4)-1 downto 0);

	signal outputRCA_2_0 : std_logic_vector((bitwidth+2) downto 0);
	signal outputRCA_3_0 : std_logic_vector((bitwidth+3) downto 0);

	
	signal inputRCA_3_0: std_logic_vector((2*bitwidth+6)-1 downto 0);

begin

 RCA_0_0: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth)
  port map(
  					--clk => clk,
				    input => input (2*bitwidth-1 downto 0*bitwidth) ,
				    --reset => reset,
				    S => outputRCA_0_0
    );

 RCA_0_1: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth)
  port map(
  					--clk => clk,
				    input => input (4*bitwidth-1 downto 2*bitwidth) ,
				    --reset => reset,
				    S => outputRCA_0_1
    );    

RCA_0_2: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth)
  port map(
  					--clk => clk,
				    input => input (6*bitwidth-1 downto 4*bitwidth) ,
				    --reset => reset,
				    S => outputRCA_0_2
    );  

RCA_0_3: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth)
  port map(
  					--clk => clk,
				    input => input (8*bitwidth-1 downto 6*bitwidth) ,
				    --reset => reset,
				    S => outputRCA_0_3
    );

RCA_1_0: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth+1)
  port map(
  					--clk => clk,
				    input => inputRCA_1_0 ,
				    --reset => reset,
				    S => outputRCA_1_0
    );

RCA_1_1: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth+1)
  port map(
  					--clk => clk,
				    input => inputRCA_1_1 ,
				    --reset => reset,
				    S => outputRCA_1_1
    );

inputRCA_1_0 <=   outputRCA_0_0 &   outputRCA_0_1;
inputRCA_1_1 <=   outputRCA_0_2 &   outputRCA_0_3;

RCA_2_0: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth+2)
  port map(
  					--clk => clk,
				    input => inputRCA_2_0 ,
				    --reset => reset,
				    S => outputRCA_2_0
    );

inputRCA_2_0 <=   outputRCA_1_0 &   outputRCA_1_1;

RCA_3_0: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth+3)
  port map(
  					--clk => clk,
				    input => inputRCA_3_0 ,
				    --reset => reset,
				    S => outputRCA_3_0
    );

inputRCA_3_0 <=   outputRCA_2_0 & "000" &  input(9*bitwidth-1 downto 8*bitwidth);
output <= outputRCA_3_0;
--output <= outputRCA_3_0 (bitwidth-1 downto 0);
end arch;
