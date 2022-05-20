
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

entity MTNCL_SF_Core_w_reg_sram is
generic(
					bitwidth: in integer := 4; 
					addresswidth: in integer := 12; 
					clock_delay: in integer := 12; 
					mem_delay: in integer := 12; 
					numberOfShades: in integer := 256; 
					shadeBitwidth: in integer := 12; 
					numberOfPixels: in integer := 4096);

	port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 	: in std_logic;
		sleep 		: in  std_logic;
		rst  		: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector(bitwidth-1 downto 0)
	);
end;

architecture arch of MTNCL_SF_Core_w_reg_sram is

  component MTNCL_SF_Node_W_Registers is
    generic(bitwidth: in integer := 4);
    port(
		input    	: in  dual_rail_logic_vector(bitwidth-1 downto 0);
		ki	 			: in std_logic;
		sleep 		: in  std_logic;
		rst  			: in std_logic;
		sleepOut 	: out std_logic;
		ko 	     	: out std_logic;
		output   	: out dual_rail_logic_vector((bitwidth-1) downto 0)
      );
  end component;

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
			accReset_loaded : out dual_rail_logic;
			image_stored : out std_logic;
			accReset_stored : out dual_rail_logic;
			z : out dual_rail_logic_vector(bitwidth-1 downto 0)
			);
	end component;

	component inv_a is
		port(a : in  std_logic;
			 z : out std_logic);
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

	signal input_1		: dual_rail_logic_vector((9*(bitwidth))-1 downto 0);
	signal data_0, data_1	: dual_rail_logic;
	signal sleep_out_sram, ko_sf	: std_logic;
	signal reset_count	: dual_rail_logic_vector(shadeBitwidth downto 0);
	signal memory_output : dual_rail_logic_vector(bitwidth-1 downto 0);

	signal write_en_inputs: dual_rail_logic_vector(1 downto 0);
	signal write_en, write_en_sel: dual_rail_logic_vector(0 downto 0);
	signal accReset_loaded, accReset_stored: dual_rail_logic;
	signal image_loaded, image_stored: std_logic;

begin

	data_0.rail0 <= '1';
	data_0.rail1 <= '0';
	data_1.rail0 <= '0';
	data_1.rail1 <= '1';

	setting_reset_count : for i in 0 to shadeBitwidth generate
		reset_count(i) <= data_1 ;
	end generate;

	--Generate the right write_en value
	write_en_sel(0).RAIL1 <= image_stored;
	write_en_generation : inv_a
		port map(a => image_stored,
			z => write_en_sel(0).RAIL0);

	write_en_inputs <= data_0 & data_1 ;
	generate_sram_address : mux_nto1_gen
	generic map(bitwidth => 1,
			numInputs => 2)
		port map(
			a => write_en_inputs,
			sel => write_en_sel(0 downto 0),
			sleep => '0',
			z => write_en);

	image_store_load_instance : image_store_load
		generic map(
					addresswidth => addresswidth,
					bitwidth => bitwidth,
					clock_delay => clock_delay,
					mem_delay => mem_delay)

		port map(
				mem_data => input,
				read_address => reset_count(shadeBitwidth-1 downto 0),
				write_en => write_en(0),
				standard_read_en => data_1,
				parallelism_en => data_0,
				reset => rst,
				ki => ko_sf,
				ko => ko,
				sleep_in => sleep,
				sleep_out => sleep_out_sram,
				image_loaded => image_loaded,
				accReset_loaded => accReset_loaded,
				image_stored => image_stored,
				accReset_stored => accReset_stored,
				z => memory_output
		);

  SF_Core_instance : MTNCL_SF_Node_W_Registers
	 generic map(bitwidth => bitwidth)
	  port map(
	    input => memory_output,
	    ki => ki,
	    sleep => sleep_out_sram,
	    rst => rst,
	    ko => ko_sf,
	    output => output,
	    sleepOut => sleepOut
	  );



end arch;
