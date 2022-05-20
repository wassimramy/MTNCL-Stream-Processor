Library IEEE;
use IEEE.std_logic_1164.all;

package ncl_signals is

type quad_rail_logic is
   record
        RAIL3 : std_logic;
        RAIL2 : std_logic;
        RAIL1 : std_logic;
        RAIL0 : std_logic;
   end record;

type quad_rail_logic_vector is array (NATURAL range <>) of quad_rail_logic;

type dual_rail_logic is
   record
        RAIL1 : std_logic;
        RAIL0 : std_logic;
   end record;

type dual_rail_logic_vector is array (NATURAL range <>) of dual_rail_logic;

end ncl_signals;
