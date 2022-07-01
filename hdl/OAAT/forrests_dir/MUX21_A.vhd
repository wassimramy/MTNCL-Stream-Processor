library ieee; 
use ieee.std_logic_1164.all; 

entity MUX21_A is 
	port(A: in std_logic; 
		B: in std_logic;
		S: in std_logic;
		 Z: out std_logic); 
end MUX21_A; 

architecture arch of MUX21_A is
begin

	BUFFER_A: process(S,A,B)
	begin
		if S = '0' then
			Z <= A after 160 ps;
		elsif S = '1' then
			Z <= B after 160 ps;
		end if ;
	end process;

end arch; 

