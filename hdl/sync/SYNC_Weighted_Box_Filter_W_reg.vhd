
-----------------------------------------
-- Definition of Hybrid Carry Look Ahead(CLA)
-- and Ripple Carry Adder(RCA) 4 Bits
-----------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MTNCL_gates.all;
use work.ncl_signals.all;

entity SYNC_Weighted_Box_Filter_W_reg is
generic(bitwidth: in integer := 8);
	port(
		input    	: in  std_logic_vector((bitwidth)-1 downto 0);
		clk  		: in std_logic;
		reset  		: in std_logic;
		output   		: out std_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of SYNC_Weighted_Box_Filter_W_reg is

	component SYNC_Weighted_Box_Filter is
    generic(bitwidth: in integer := 8);
    port(
						input    	: in  std_logic_vector(9*bitwidth-1 downto 0);
						output   			: out std_logic_vector(bitwidth-1 downto 0)
      );
  	end component;

  	component shiftRegister is
    generic(bitwidth: in integer := 8);
    port(
			clk 	: in std_logic;
			D    	: in  std_logic;
			reset 	: in std_logic;
			Q   	: out std_logic_vector(bitwidth-1 downto 0)
      );
  	end component;

component  SYNC_Counter is
    generic(bitwidth: in integer := 8; delay: in integer := 50);
    port(
    	clk : in std_logic;
    	hold : in std_logic;
		limit    	: in  std_logic_vector(bitwidth-1 downto 0);
		reset  		: in std_logic;
		clk_0  		: out std_logic;
		clk_1  		: out std_logic;
		count   	: out std_logic_vector((bitwidth-1) downto 0)
      );
  end component;

component DFFRX1MTR_No_QN is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic);
end component;

	signal outputSR, inputSBF: std_logic_vector((9*(bitwidth))-1 downto 0);
	signal clk_out, clk_1, hold: std_logic;
	signal const_9, count: std_logic_vector(bitwidth-1 downto 0);
	signal outputReg: std_logic_vector(bitwidth-1 downto 0);


begin

const_9 <= "00001001";
hold <= '0';
sync_counter_instance : SYNC_Counter
 generic map(bitwidth => bitwidth, delay => 40)
  port map(
  					clk => clk,
				    hold => hold,
				    limit => const_9,
				    reset => reset,
				    clk_0 => clk_out,
				    clk_1 => clk_1,
				    count => count
    );

first_stage_gen: for i in 0 to bitwidth-1 generate
			shift_register_i : shiftRegister
			generic map(	bitwidth => 9 )
				port map(
					clk => clk,
					D => input(i),
					reset => reset,
					Q => outputSR((i+1)*9-1 downto i*9));
		end generate;	

first_assign_i: for i in 0 to 8 generate
	first_assign_j: for j in 0 to bitwidth-1 generate
			inputSBF ((i)*bitwidth+j) <= outputSR(i+j*9);
	end generate;
end generate;			

 sync_box_filter_instance: SYNC_Weighted_Box_Filter
 generic map(bitwidth => bitwidth)
  port map(
				    input => inputSBF,
				    output => outputReg
    );

output_gen: for i in 0 to bitwidth-1 generate
			input_reg : DFFRX1MTR_No_QN 
				port map(
					D => outputReg(i),
					clk => clk_out,
					rst => reset,
					Q => output(i));	
end generate;

end arch;
