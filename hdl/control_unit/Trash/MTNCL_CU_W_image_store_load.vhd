
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

entity MTNCL_CU_W_image_store_load is
generic(
			bitwidth: in integer := 4; 
			addresswidth: in integer := 12; 
			clock_delay: in integer := 12; 
			mem_delay: in integer := 12; 
			numberOfShades: in integer := 256; 
			shadeBitwidth: in integer := 12; 
			numberOfPixels: in integer := 4096; 
			opCodeBitwidth: in integer := 2
			);

	port(

		--Input for the control unit
		opCode		: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);

		--Inputs for the image_load_store
		mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
		read_address : in dual_rail_logic_vector(addresswidth-1 downto 0);
		write_en : in dual_rail_logic;
		standard_read_en: in dual_rail_logic;
		parallelism_en : in dual_rail_logic;

		ki	 		: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_CU_W_image_store_load is

	component image_store_load is
		generic(
			bitwidth : integer := bitwidth;
			addresswidth : integer := addresswidth;
			clock_delay : integer := clock_delay;		--ADD DELAY FOR INCREASED SETUP TIMES
			mem_delay : integer := mem_delay);		--ADD DELAY FOR INCREASED MEMORY DELAY
		port(

			mem_data : in dual_rail_logic_vector(bitwidth-1 downto 0);
			read_address : in dual_rail_logic_vector(addresswidth-1 downto 0);
			write_en : in dual_rail_logic;
			standard_read_en : in dual_rail_logic;
			parallelism_en : in dual_rail_logic;
			reset : in std_logic;
			ki : in std_logic;
			ko : out std_logic;
			sleep_in : in std_logic;
			sleep_out : out std_logic;
			image_loaded : out std_logic;
			image_stored : out std_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0)
			);
	end component;

  component MTNCL_Control_Unit is
    generic(
    			bitwidth: in integer := 4; 
    			numberOfShades: in integer := 256; 
    			shadeBitwidth: in integer := 12; 
    			numberOfPixels: in integer := 4096; 
    			opCodeBitwidth: in integer := 2
    			);
    port(

		opCode    	: in  dual_rail_logic_vector(opCodeBitwidth-1 downto 0);
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth)-1 downto 0)
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
			a: in dual_rail_logic_vector((numInputs*bitwidth)-1 downto 0);
			sel: in dual_rail_logic_vector(integer(ceil(log2(real(numInputs))))-1 downto 0);
			sleep: in std_logic;
			z: out dual_rail_logic_vector(bitwidth-1 downto 0));
	end component;

	component inv_a is 
		port(a: in std_logic; 
			 z: out std_logic); 
	end component; 


	--signal data_0,data_1		: dual_rail_logic;
	--signal reset_count, roundedPixelRegister	: dual_rail_logic_vector(bitwidth-1 downto 0);
	--signal reset_count_plus_one	: dual_rail_logic_vector(shadeBitwidth downto 0);

	--signal inputHEQMUX, inputSFMUX: dual_rail_logic_vector(2*bitwidth-1 downto 0);
	--signal globalOutput: dual_rail_logic_vector(4*bitwidth-1 downto 0);
	--signal inputHEQ, inputSF, outputSF, outputHEQ: dual_rail_logic_vector(bitwidth-1 downto 0);
	--signal sleep_SF, sleep_HEQ, sleepOut_HEQ, sleepOut_SF: std_logic;
	--signal ki_SF, ki_HEQ, ko_HEQ, ko_SF: std_logic;
	--signal sleep_global_00, sleep_global_01: std_logic;

	signal control_unit_input: dual_rail_logic_vector(bitwidth-1 downto 0);
	signal image_loaded, image_stored, control_unit_ko, control_unit_sleep_in, control_unit_ki, ko_image_store_load, sleep_in_image_store_load: std_logic;
	
begin


	ko <= ko_image_store_load;

	generate_sleep_in_image_store_load : inv_a
	port map(
		a => ko_image_store_load,
		z => sleep_in_image_store_load);

	image_store_load_instance : image_store_load
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)

		port map(
				mem_data => mem_data,
				read_address => read_address,
				write_en => write_en,
				standard_read_en => standard_read_en,
				parallelism_en => parallelism_en,
				reset => rst,
				ki => control_unit_ko,
				ko => ko_image_store_load,
				sleep_in => sleep_in_image_store_load,
				sleep_out => control_unit_sleep_in,
				image_loaded => image_loaded,
				image_stored => image_stored,
				z => control_unit_input
		);

	  control_unit_instance: MTNCL_Control_Unit
	 	generic map(
	 					bitwidth => bitwidth, 
	 					numberOfShades => numberOfShades,  
	 					shadeBitwidth =>shadeBitwidth , 
	 					numberOfPixels => numberOfPixels, 
	 					opCodeBitwidth => opCodeBitwidth
	 					)

	  	port map(
				    opCode => opCode,
				    input => control_unit_input,
				    ki => control_unit_ki,
				    sleep => control_unit_sleep_in,
				    rst => rst,
				    ko => control_unit_ko,
				    sleepOut => sleepOut,
				    output => output
	    );


end arch;
