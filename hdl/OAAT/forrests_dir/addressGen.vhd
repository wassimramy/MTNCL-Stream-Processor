
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.NCL_signals.all;

entity addressGen is
	generic(Lower_count_size : integer := 8;
		Upper_count_size : integer := 8;
		Address_width : integer := 12);
	port(R_reset_count_lower : dual_rail_logic_vector(Lower_count_size-1 downto 0);
		R_reset_count_upper : dual_rail_logic_vector(Upper_count_size-1 downto 0);
		R_accumulate_reset_lower : in dual_rail_logic;
		R_accumulate_reset_upper : in dual_rail_logic;
		R_LayerNumber : in dual_rail_logic_vector(1 downto 0);
		W_data : in dual_rail_logic_vector(15 downto 0);
		isInputLayer : in dual_rail_logic;
		writeEn : in dual_rail_logic;
		hSize : in dual_rail_logic;
		reset : in std_logic;
		R_sleep_in : in std_logic;
		W_sleep_in : in std_logic;
		ki : in std_logic;
		R_ko : out std_logic;
		W_ko : out std_logic;
		sleep_out : out std_logic;
		z : out dual_rail_logic_vector(Address_width+1+16 downto 0));
end addressGen;


architecture behavioral of addressGen is


	component subtractor_gen is
		generic(width: integer := 8);
		port(a: in dual_rail_logic_vector(width-1 downto 0);
			 b: in dual_rail_logic_vector(width-1 downto 0);
			 sleep: in std_logic;
			 diff: out dual_rail_logic_vector(width-1 downto 0);
			 bout: out dual_rail_logic);
	end component;

	component mux_21_nic is
	    port(a: in dual_rail_logic;
		 	 b: in dual_rail_logic;
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic);
	end component;

	component mux_21_gen_nic is
		generic(width: integer);
	    port(a: in dual_rail_logic_vector(width-1 downto 0);
		 	 b: in dual_rail_logic_vector(width-1 downto 0);
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component mux_21_gen is
		generic(width: integer);
	    port(a: in dual_rail_logic_vector(width-1 downto 0);
		 	 b: in dual_rail_logic_vector(width-1 downto 0);
			sel: in dual_rail_logic;
			 sleep: in std_logic;
			 z: out dual_rail_logic_vector(width-1 downto 0));
	end component;

	component regs_gen_null_res is
		generic(width: integer);
		port(d: in dual_rail_logic_vector(width-1 downto 0);
			q: out dual_rail_logic_vector(width-1 downto 0);
			reset: in std_logic;
			sleep: in std_logic);
	end component;

	component compm is
		generic(width: in integer := 4);
		port(a: IN dual_rail_logic_vector(width-1 downto 0);
			ki, rst, sleep: in std_logic;
			ko: OUT std_logic);
	end component;

	component MUX21_A is 
		port(A: in std_logic; 
			B: in std_logic;
			S: in std_logic;
			 Z: out std_logic); 
	end component; 

	component memWriteCounter is
		port(	sleep_in: in std_logic;
			reset: in std_logic;
			ki: in std_logic;
			ko: out std_logic;
			sleep_out: out std_logic;
			upper_is_max : out dual_rail_logic;
			accumulate_reset_lower: out dual_rail_logic;
			accumulate_reset_upper: out dual_rail_logic;
			z: out dual_rail_logic_vector(4+12-1 downto 0));
	end component;

	component th22_a is 
		port(a: in std_logic; 
			 b: in std_logic; 
			 z: out std_logic); 
	end component; 



signal sub_out : dual_rail_logic_vector(3 downto 0);
signal W_address, W_input_address, W_non_input_address, W_input_h128_address, W_input_h64_address, R_input_non_reset_address, R_input_reset_address, R_non_input_address, R_input_address, R_address : dual_rail_logic_vector(Address_width-1 downto 0);
signal W_address_writeEn, WriteEn_Address_out : dual_rail_logic_vector(Address_width downto 0);
signal address_out_out, address_out, R_address_out, W_address_out, memData_LayerNumber_W_address : dual_rail_logic_vector(Address_width+1+16 downto 0);
signal LayerNumber_R_address : dual_rail_logic_vector(Address_width+1 downto 0);
signal LayerNumber_W_address : dual_rail_logic_vector(15 downto 0);
signal data0 : dual_rail_logic;
signal comp_out_out, R_reg_sleep, W_reg_sleep, address_sleep, counter_ko, counter_sleep_out, W_reg_sleep_in, W_reg_sleep_a, W_reg_sleep_b : std_logic;

signal accResLow, accResUpper, upperIsMax : dual_rail_logic;

begin
data0.rail0 <= '1';
data0.rail1 <= '0';

--READ ADDRESS GENERATION
	subtractor : subtractor_gen
		generic map(width => 3)
    		port map(a => R_reset_count_lower(2 downto 0),
	 		 b => R_reset_count_upper(2 downto 0),
			 sleep => R_sleep_in,
			 diff => sub_out(2 downto 0),
			 bout => sub_out(3));

R_non_input_address <= R_reset_count_upper(6 downto 3) & R_reset_count_lower(7 downto 3) & sub_out(2 downto 0);
R_input_non_reset_address <= R_accumulate_reset_lower & R_reset_count_upper(6 downto 3) & R_reset_count_lower(6 downto 3) & sub_out(2 downto 0);
R_input_reset_address <=  R_accumulate_reset_lower & data0 & data0 & data0 & data0 & R_reset_count_upper(6 downto 0);

	R_reset_mux : mux_21_gen
		generic map(width => Address_width)
	    port map(a => R_input_non_reset_address,
		 	 b => R_input_reset_address,
			sel => R_accumulate_reset_lower,
			 sleep => R_sleep_in,
			 z => R_input_address);

	R_Input_layer_mux : mux_21_gen
		generic map(width => Address_width)
	    port map(a => R_non_input_address,
		 	 b => R_input_address,
			sel => isInputLayer,
			 sleep => R_sleep_in,
			 z => R_address);

	comp_in_R: compm
		generic map(width => Address_width+2)
		port map(
			a => LayerNumber_R_address,
			ki => comp_out_out,
			rst => reset,
			sleep => R_sleep_in,
			ko => R_reg_sleep);
R_ko <= R_reg_sleep;
LayerNumber_R_address <= R_LayerNumber & R_address;
	R_reg: regs_gen_null_res
		generic map(width => Address_width+2)
		port map(
			d => LayerNumber_R_address,
			q => R_address_out(Address_width+1 downto 0),
			reset => reset,
			sleep => R_reg_sleep);

gen_R_addressData : for i in 0 to 15 generate
R_address_out(i+Address_width+2) <= data0;

end generate;

--END RESET ADDRESS GEN

--WRITE ADDRESS GENERATION

	counter_memWriteAddress : memWriteCounter
		port map(sleep_in => W_sleep_in,
			reset => reset,
			ki => W_reg_sleep,
			ko => counter_ko,
			sleep_out => counter_sleep_out,
			upper_is_max => upperIsMax,
			accumulate_reset_lower => accResLow,
			accumulate_reset_upper => accResUpper,
			z => LayerNumber_W_address);

W_reg_sleep_in_gate : th22_a
	port map(a => W_sleep_in, 
			 b => counter_sleep_out,
			 z => W_reg_sleep_in); 

	comp_in_W_a: compm
		generic map(width => 16)
		port map(
			a => LayerNumber_W_address,
			ki => comp_out_out,
			rst => reset,
			sleep => W_reg_sleep_in,
			ko => W_reg_sleep_a);

	comp_in_W_b: compm
		generic map(width => 16)
		port map(
			a => W_data,
			ki => comp_out_out,
			rst => reset,
			sleep => W_reg_sleep_in,
			ko => W_reg_sleep_b);

comp_in_W_gate : th22_a
	port map(a => W_reg_sleep_a, 
			 b => W_reg_sleep_b,
			 z => W_reg_sleep); 

W_ko <= W_reg_sleep;
memData_LayerNumber_W_address <= W_data & LayerNumber_W_address(13 downto 0);

	W_reg: regs_gen_null_res
		generic map(width => Address_width+2+16)
		port map(
			d => memData_LayerNumber_W_address,
			q => W_address_out,
			reset => reset,
			sleep => W_reg_sleep);

--END WRITE ADDRESS GEN

--OUTPUT GENERATION

	address_sleep_mux : MUX21_A
		port map(A => R_reg_sleep, 
			B => W_reg_sleep,
			S => writeEn.rail1,
			 Z => address_sleep); 

	address_out_mux : mux_21_gen_nic
		generic map(width => Address_width+2+16)
	    port map(a => R_address_out,
		 	 b => W_address_out,
			sel => writeEn,
			 sleep => address_sleep,
			 z => address_out);

	comp_out: compm
		generic map(width => Address_width+2+16)
		port map(
			a => address_out,
			ki => ki,
			rst => reset,
			sleep => address_sleep,
			ko => comp_out_out);

	out_reg: regs_gen_null_res
		generic map(width => Address_width+2+16)
		port map(
			d => address_out,
			q => address_out_out,
			reset => reset,
			sleep => comp_out_out);

z <= address_out_out;
sleep_out <= comp_out_out;

end behavioral;
