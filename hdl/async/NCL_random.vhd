-- to be used in testbenches
-- not to be synthesized

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.MATH_REAL.all;

package random is

impure function rand_time(seed : integer; min_val, max_val : time; unit : time := ns) return time;
impure function rand_slv(seed, len : integer) return std_logic_vector;

end random;

package body random is

impure function rand_time(seed : integer; min_val, max_val : time; unit : time := ns) return time is
  variable r, r_scaled, min_real, max_real : real;
  variable seed1, seed2 : integer := 5;
begin
  seed1 := seed;
  seed2 := seed;
  uniform(seed1, seed2, r);
  min_real := real(min_val / unit);
  max_real := real(max_val / unit);
  r_scaled := r * (max_real - min_real) + min_real;
  return real(r_scaled) * unit;
end rand_time;


impure function rand_slv(seed, len : integer) return std_logic_vector is
  variable r : real;
  variable slv : std_logic_vector(len - 1 downto 0);
  variable seed1, seed2 : integer := 5;
begin
  seed1 := seed;
  seed2 := seed;
  for i in slv'range loop
    uniform(seed1, seed2, r);
	if r > 0.5 then
		slv(i) := '1';
	else
		slv(i) := '0';
	end if;
  end loop;
  return slv;
end function;
						

end random;
