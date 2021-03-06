
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

entity SYNC_SF_Core_2048 is
generic(bitwidth: in integer := 8);
	port(
		pixel_in    			: in  std_logic_vector((bitwidth)-1 downto 0);
		clk  				: in std_logic;
		reset  				: in std_logic;
		parallelism_en  	: in std_logic;
		id  				: in std_logic;
		pixel_out   			: out std_logic_vector(2*bitwidth-1 downto 0)
	);
end;

architecture arch of SYNC_SF_Core_2048 is

component SYNC_Weighted_Box_Filter_W_reg is
    generic(bitwidth: in integer := 8);
    port(
    		clk : in std_logic;
			input    	: in  std_logic_vector(bitwidth-1 downto 0);
			reset  		: in std_logic;
			output   	: out std_logic_vector((bitwidth-1) downto 0)
      );
  end component;

component SYNC_SF_Data_Loader_2048 is
    generic(bitwidth: in integer := 8);
    port(
    	clk : in std_logic;
			input    	: in  std_logic_vector(bitwidth-1 downto 0);
			reset  		: in std_logic;
			parallelism_en : in std_logic;
			id: in std_logic;
			clk_out : out std_logic;
			output   	: out std_logic_vector((2*bitwidth-1) downto 0)
      );
 end component;

signal clk_sf_data_loader : std_logic;
signal pixels : std_logic_vector (2*bitwidth-1 downto 0);

begin

sf_data_loader_instance : SYNC_SF_Data_Loader_2048
 generic map(bitwidth => bitwidth)
  port map(
  					clk => clk,
				    input => pixel_in,
				    reset => reset,
				    parallelism_en => parallelism_en,
				    id => id,
				    clk_out => clk_sf_data_loader,
				    output => pixels
    );

box_filter_instance_a: SYNC_Weighted_Box_Filter_W_reg
 generic map(bitwidth => bitwidth)
  port map(
  					clk => clk_sf_data_loader,
				    input => pixels(bitwidth-1 downto 0),
				    reset => reset,
				    output => pixel_out (bitwidth-1 downto 0)
    );   

box_filter_instance_b: SYNC_Weighted_Box_Filter_W_reg
 generic map(bitwidth => bitwidth)
  port map(
  					clk => clk_sf_data_loader,
				    input => pixels(2*bitwidth-1 downto bitwidth),
				    reset => reset,
				    output => pixel_out (2*bitwidth-1 downto bitwidth)
    );  
end arch;
