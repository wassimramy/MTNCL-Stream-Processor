----------------------------------------------------------- 
-- BUFFER_A
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity BUFFER_A is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end BUFFER_A; 

architecture arch of BUFFER_A is
begin
	BUFFER_A: process(A)
	begin
		if A = '1' then
			Z <= '1' after 160 ps;
		elsif A = '0' then
			Z <= '0' after 160 ps;
		end if ;
	end process;
end arch; 

----------------------------------------------------------- 
-- BUFFER_B
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity BUFFER_B is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end BUFFER_B; 

architecture arch of BUFFER_B is
begin
	BUFFER_B: process(A)
	begin
		if A = '1' then
			Z <= '1' after 2*160 ps;
		elsif A = '0' then
			Z <= '0' after 2*160 ps;
		end if ;
	end process;
end arch; 

----------------------------------------------------------- 
-- BUFFER_C
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity BUFFER_C is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end BUFFER_C; 

architecture arch of BUFFER_C is
begin
	BUFFER_C: process(A)
	begin
		if A = '1' then
			Z <= '1' after 4*160 ps;
		elsif A = '0' then
			Z <= '0' after 4*160 ps;
		end if ;
	end process;
end arch; 

----------------------------------------------------------- 
-- BUFFER_D
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity BUFFER_D is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end BUFFER_D; 

architecture arch of BUFFER_D is
begin
	BUFFER_D: process(A)
	begin
		if A = '1' then
			Z <= '1' after 8*160 ps;
		elsif A = '0' then
			Z <= '0' after 8*160 ps;
		end if ;
	end process;
end arch; 

----------------------------------------------------------- 
-- BUFFER_E
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity BUFFER_E is 
	port(A: in std_logic; 
		 Z: out std_logic); 
end BUFFER_E; 

architecture arch of BUFFER_E is
begin
	BUFFER_E: process(A)
	begin
		if A = '1' then
			Z <= '1' after 16*160 ps;
		elsif A = '0' then
			Z <= '0' after 16*160 ps;
		end if ;
	end process;
end arch; 

----------------------------------------------------------- 
-- and2_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity and2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end and2_a; 

architecture arch of and2_a is
begin
	and2_a: process(a,b)
	begin
		if a = '1' and b = '1' then
			z <= '1' after 1 ns;
		elsif a = '0' or b = '0' then
			z <= '0' after 1 ns;
		end if ;
	end process;
end arch; 


----------------------------------------------------------- 
-- or2_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity or2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end or2_a; 

architecture arch of or2_a is
begin
	or2_a: process(a,b)
	begin
		if a = '1' or b = '1' then
			z <= '1' after 1 ns;
		elsif a = '0' and b = '0' then
			z <= '0' after 1 ns;
		end if ;
	end process;
end arch; 

----------------------------------------------------------- 
-- xor2_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity xor2_a is 
	port(a,b: in std_logic; 
		 z: out std_logic); 
end xor2_a; 

architecture arch of xor2_a is
begin
	xor2_a: process(a,b)
	begin
		if (a = '0' and b = '1') or (a = '1' and b = '0') then
			z <= '1' after 1 ns;
		elsif (a = '1' and b = '1') or (a = '0' and b = '0') then
			z <= '0' after 1 ns;
		end if ;
	end process;
end arch; 



----------------------------------------------------------- 
-- or3_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity or3_a is 
	port(a,b,c: in std_logic; 
		 z: out std_logic); 
end or3_a; 

architecture arch of or3_a is
begin
	or3_a: process(a,b,c)
	begin
		if a = '1' or b = '1' or c = '1' then
			z <= '1' after 1 ns;
		elsif a = '0' and b = '0' and c = '0' then
			z <= '0' after 1 ns;
		end if ;
	end process;
end arch;


