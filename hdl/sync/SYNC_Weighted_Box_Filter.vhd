
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;

entity SYNC_Weighted_Box_Filter is
generic(bitwidth: in integer := 8);
	port(
		input    	: in  std_logic_vector((9*bitwidth)-1 downto 0);
		output   		: out std_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of SYNC_Weighted_Box_Filter is

	component SYNC_Box_Filter is
    generic(bitwidth: in integer := 8);
    port(
			input    	: in  std_logic_vector(9*bitwidth-1 downto 0);
			output   			: out std_logic_vector(bitwidth+3 downto 0)
      );
  	end component;

	component SYNC_RCA_GEN is
    generic(bitwidth: in integer := 8);
    port(
			input    	: in  std_logic_vector(2*bitwidth-1 downto 0);
			S   			: out std_logic_vector((bitwidth) downto 0)
      );
 	end component;

	signal inputSBF: std_logic_vector((9*(bitwidth+2))-1 downto 0);
	signal outputSBF: std_logic_vector(bitwidth+2+3 downto 0);
	signal inputRCA: std_logic_vector(2*bitwidth-1 downto 0);
	signal outputRCA: std_logic_vector(bitwidth downto 0);

begin

inputSBF <= "00" & input (9*bitwidth-1 downto 8*bitwidth) &
	'0' & input (8*bitwidth-1 downto 7*bitwidth) & '0' &
	"00" & input (7*bitwidth-1 downto 6*bitwidth) &
	'0' & input (6*bitwidth-1 downto 5*bitwidth) & '0' &
	input (5*bitwidth-1 downto 4*bitwidth) & "00" &
	'0' & input (4*bitwidth-1 downto 3*bitwidth) & '0' &
	"00" & input (3*bitwidth-1 downto 2*bitwidth) &
	'0' & input (2*bitwidth-1 downto 1*bitwidth) & '0' &
	"00" & input (1*bitwidth-1 downto 0*bitwidth) ;

 sync_box_filter_instance: SYNC_Box_Filter
 generic map(bitwidth => bitwidth+2)
  port map(
		    input => inputSBF,
		    output => outputSBF
    );

inputRCA <= "0000000" & outputSBF (3) & outputSBF (11 downto 4);
RCA_Rounding_Checker: SYNC_RCA_GEN
 generic map(bitwidth => bitwidth)
  port map(
		    input => inputRCA ,
		    S => outputRCA
    );    
output <= outputRCA (bitwidth-1 downto 0);
end arch;
