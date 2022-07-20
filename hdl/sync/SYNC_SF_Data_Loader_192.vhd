
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

entity SYNC_SF_Data_Loader_192 is
generic(bitwidth: in integer := 8);
	port(
		input    			: in  std_logic_vector((bitwidth)-1 downto 0);
		clk  				: in std_logic;
		reset  				: in std_logic;
		parallelism_en  	: in std_logic;
		id  				: in std_logic;
		clk_out  			: out std_logic;
		output   			: out std_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of SYNC_SF_Data_Loader_192 is



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
    generic(bitwidth: in integer := 8; delay: integer := 50);
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

	component mux_nto1_sr_gen is
	generic(
		bitwidth: integer := 4;
		numInputs : integer := 4);
    		port(
			a: in std_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in std_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			z: out std_logic_vector(bitwidth-1 downto 0));
	end component;

	component and2a_tree_gen is
		generic(numInputs : integer := 4);
	    port(
			a: in std_logic_vector((numInputs)-1 downto 0);
			z: out std_logic);
	end component;

	component SYNC_RCA_GEN is
    generic(bitwidth: in integer := 8);
    port(
			input    	: in  std_logic_vector(2*bitwidth-1 downto 0);
			S   			: out std_logic_vector((bitwidth) downto 0)
      );
 	end component;

 	component BUFFER_C is 
	port(A: in std_logic; 
		 Z: out std_logic); 
	end component; 

component MUX21_A is 
		port(
			A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			Z: out std_logic); 
end component; 

component or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component;

component and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end component; 

	signal outputSR, inputMUX, inputMUX_mirrored: std_logic_vector((192*(bitwidth))-1 downto 0);
	signal inputMUX_w_pad: std_logic_vector((4356*(bitwidth))-1 downto 0);
	signal clk_0_0, clk_0_1, hold: std_logic;
	signal const_4096, count_0: std_logic_vector(12 downto 0);
	signal const_2110, const_1055, count_1, reset_count: std_logic_vector(12 downto 0);
	signal choose_reset_count : std_logic_vector(2*13-1 downto 0);
	signal hold_1, clk_1_0, clk_1_1, sync_counter_instance_1_clk, sync_counter_instance_2_reset, box_filter_instance_reset: std_logic;
	signal const_9, count_2: std_logic_vector(12 downto 0);
	signal hold_2, clk_2_0, clk_2_1: std_logic;
	signal const_65, count_3, not_const_64, const_64: std_logic_vector(12 downto 0);
	signal clk_3_0, clk_3_1: std_logic;
	signal const_66, count_4, not_const_65: std_logic_vector(12 downto 0);
	signal clk_4_0, clk_4_1: std_logic;
	signal output_pixel_a, output_pixel_b: std_logic_vector(bitwidth-1 downto 0);
	signal inputRCA: std_logic_vector(18*13-1 downto 0);
	signal address : std_logic_vector((9*(14)-1) downto 0);
	signal chosen_address, address_3 : std_logic_vector(13 downto 0);
	signal and2a_input_64, and2a_input_65 : std_logic_vector (12 downto 0);
	signal and2a_output_64, and2a_output_65, clk_box_filter, clk_box_filter_1, clk_box_filter_0, clk_sync_counter_3: std_logic;

	signal choose_pixel_a_input, choose_pixel_b_input : std_logic_vector (2244*bitwidth-1 downto 0);
	signal input_mux_a_select, choose_reset_count_select : std_logic_vector (0 downto 0);
	signal input_mux_b_select : std_logic_vector (1 downto 0);
	signal input_mux_b : std_logic_vector (4*2244*bitwidth-1 downto 0);
	signal input_mux_a : std_logic_vector (2*2244*bitwidth-1 downto 0);

begin
const_4096 <= "0000011000000";
hold <= '1';
sync_counter_instance : SYNC_Counter
 generic map(bitwidth => 13, delay => 0)
  port map(
  					clk => clk,
				    hold => hold,
				    limit => const_4096,
				    reset => reset,
				    clk_0 => clk_0_0,
				    clk_1 => clk_0_1,
				    count => count_0
    );

first_stage_gen: for i in 0 to bitwidth-1 generate
			shift_register_i : shiftRegister
			generic map(	bitwidth => 192 )
				port map(
					clk => clk_0_1,
					D => input(i),
					reset => reset,
					Q => outputSR((i+1)*192-1 downto i*192));
end generate;	

first_assign_i: for i in 0 to 191 generate
	first_assign_j: for j in 0 to bitwidth-1 generate
			inputMUX ((i)*bitwidth+j) <= outputSR(i+j*192);
	end generate;
end generate;			

first_assign_mirrored: for i in 0 to 191 generate
	inputMUX_mirrored ((192-i)*bitwidth-1 downto (191-i)*bitwidth) <= inputMUX((i+1)*bitwidth-1 downto i*bitwidth);
end generate;

	generate_sleep_select_0 : for i in 0 to 527 generate
		inputMUX_w_pad(i) <= '0';
	end generate;

	generate_sleep_select_1 : for i in 1 to 3 generate
		generate_sleep_select_2 : for j in 1 to 64 generate
			inputMUX_w_pad(i*66*bitwidth+j*bitwidth+bitwidth-1 downto i*66*bitwidth+j*bitwidth) <= inputMUX_mirrored ((i-1)*64*bitwidth+(j-1)*bitwidth+bitwidth-1 downto (i-1)*64*bitwidth+(j-1)*bitwidth);
		end generate;
	end generate;

	generate_sleep_select_3 : for i in 1 to 64 generate
		generate_sleep_select_4 : for j in 1 to 16 generate
			inputMUX_w_pad(i*66*bitwidth-bitwidth-1+j) <= '0';
		end generate;
	end generate;

	generate_sleep_select_6 : for i in 34312 to 34847 generate
		inputMUX_w_pad(i) <= '0';
	end generate;

choose_pixel_a : mux_nto1_sr_gen
	generic map(bitwidth => bitwidth, numInputs => 263)
		port map(
			a => inputMUX_w_pad(263*bitwidth-1 downto 0),
			sel => chosen_address (8 downto 0),
			z => output_pixel_a);	

const_2110 <= "0100000111110";
const_1055 <= "0010000011111";

choose_reset_count_select(0) <= parallelism_en;
choose_reset_count <= const_1055 & const_2110;
choose_reset_count_gen : mux_nto1_sr_gen
	generic map(bitwidth => 13, numInputs => 2)
		port map(
			a => choose_reset_count,
			sel => choose_reset_count_select(0 downto 0),
			z => reset_count);

hold_1 <= '1';
sync_counter_instance_1 : SYNC_Counter
 generic map(bitwidth => 13, delay => 0)
  port map(
  					clk => clk_2_0,
				    hold => hold_1,
				    limit => reset_count,
				    reset => reset,
				    clk_0 => clk_1_0,
				    clk_1 => clk_1_1,
				    count => count_1
   );


   	--0
	inputRCA(2*(13)-1 downto 1*(13)) 	<= "0000000000000";
	-- 1
	inputRCA(4*(13)-1 downto 3*(13)) 	<= "000000000000" & '1';
	-- 2
	inputRCA(6*(13)-1 downto 5*(13)) 	<= "00000000000" & '1' & '0';
	-- 66
	inputRCA(8*(13)-1 downto 7*(13)) 	<= "000000" & '1' & "0000" & '1' & '0';
	-- 67
	inputRCA(10*(13)-1 downto 9*(13)) 	<= "000000" & '1' & "0000" & "11";
	-- 68
	inputRCA(12*(13)-1 downto 11*(13)) <= "000000" & '1' & "000" & '1' & "00";
	-- 132
	inputRCA(14*(13)-1 downto 13*(13)) <= "00000" & '1' & "0000" & '1' & "00";
	-- 133
	inputRCA(16*(13)-1 downto 15*(13)) <= "00000" & '1' & "0000" & '1' & '0' & '1';
	-- 134
	inputRCA(18*(13)-1 downto 17*(13)) <= "00000" & '1' & "0000" & "11" & '0';

	--Prepare the inputs for the RCAs
	generate_count_1 : for i in 0 to 8 generate
		inputRCA((2*(i)+1)*(13)-1 downto i*2*(13)) <= count_1(12 downto 0) ;
	end generate;

generate_address : for i in 0 to 8 generate

	RCA_Rounding_Checker: SYNC_RCA_GEN
	generic map(bitwidth => 13)
	  port map(
			    input => inputRCA(((i+1)*2)*(13)-1 downto (i*2)*(13)) ,
			    S => address((i+1)*(13)+i downto (i)*(14))
	    ); 		

	end generate;

address_3 <= address((3+1)*(13)+3 downto (3)*(14));

choose_address : mux_nto1_sr_gen
	generic map(bitwidth => 14, numInputs => 9)
		port map(
			a => address,
			sel => count_2 (3 downto 0),
			z => chosen_address);

const_9 <= "0000000001001";
hold_2 <= '0';
sync_counter_instance_2 : SYNC_Counter
 generic map(bitwidth => 13, delay => 0)
  port map(
  					clk => clk_0_0,
				    hold => hold_2,
				    limit => const_9,
				    reset => reset,
				    clk_0 => clk_2_0,
				    clk_1 => clk_2_1,
				    count => count_2
   );

const_65 <= "0000001000001";
const_64 <= "0000001000000";
not_const_64 <= "1111110111111";

sync_counter_instance_3 : SYNC_Counter
 generic map(bitwidth => 13, delay => 0)
  port map(
  					clk => clk_sync_counter_3,
				    hold => hold_2,
				    limit => const_65,
				    reset => reset,
				    clk_0 => clk_3_0,
				    clk_1 => clk_3_1,
				    count => count_3
   );

clk_sync_counter_3_gen : or2_a 
	port map(
		A => and2a_output_65, 
		B => clk_2_0,
		Z => clk_sync_counter_3);

const64_xnor_output: for i in 0 to 12 generate
	const64_xnor : MUX21_A 
	port map(
		B => const_64(i), 
		A => not_const_64(i),
		S => count_3(i),
		Z => and2a_input_64(i));
end generate;

and2a_counter_tree_64 : and2a_tree_gen
generic map(numInputs => 13 )
	port map(
		a => and2a_input_64,
		z => and2a_output_64);

const_66 <= "0000001000010";
not_const_65 <= "1111110111110";

sync_counter_instance_4 : SYNC_Counter
 generic map(bitwidth => 13, delay => 0)
  port map(
  					clk => clk_2_0,
				    hold => hold_2,
				    limit => const_66,
				    reset => reset,
				    clk_0 => clk_4_0,
				    clk_1 => clk_4_1,
				    count => count_4
   );

const65_xnor_output: for i in 0 to 12 generate
	const65_xnor : MUX21_A 
	port map(
		B => const_65(i), 
		A => not_const_65(i),
		S => count_4(i),
		Z => and2a_input_65(i));
end generate;

and2a_counter_tree_65 : and2a_tree_gen
generic map(numInputs => 13 )
	port map(
		a => and2a_input_65,
		z => and2a_output_65);

clk_box_filter_gen_0 : or2_a 
	port map(
		A => clk_2_1, 
		B => and2a_output_64,
		Z => clk_box_filter_0);

clk_box_filter_gen_1 : or2_a 
	port map(
		A => and2a_output_65, 
		B => and2a_output_64,
		Z => clk_box_filter_1);

clk_box_filter_gen_2 : or2_a 
	port map(
		A => clk_box_filter_0, 
		B => clk_box_filter_1,
		Z => clk_box_filter);

output (bitwidth-1 downto 0) <= output_pixel_a;
clk_out <= clk_box_filter;


end arch;
