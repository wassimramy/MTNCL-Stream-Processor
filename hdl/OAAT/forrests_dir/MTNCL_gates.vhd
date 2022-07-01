-- delays based on physical-level simulations of static gates designed with 1.8v, 0.18um technology


----------------------------------------------------------- 
-- bufferm_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity bufferm_a is 
	port(a: in std_logic; 
		 s: in std_logic; 
		 z: out std_logic); 
end bufferm_a; 

architecture arch of bufferm_a is
begin
	bufferm_a: process(a, s)
	begin
		if s = '1' then
			z <= '0' after 2 ns;
		elsif a = '1' then
			z <= '1' after 2 ns;
		else
			z <= '0' after 1 ns;
		end if ;
	end process;
end arch; 


----------------------------------------------------------- 
-- th12m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th12m_a is 
	port(a: in std_logic; 
		 b: in std_logic;
		 s: in std_logic; 
		 z: out std_logic); 
end th12m_a; 

architecture archth12m_a of th12m_a is
begin
	th12m_a: process(a, b, s)
	begin
		if s = '1' then
			z <= '0' after 5 ns;
		elsif a = '1'
			   or b = '1' then
			z <= '1' after 1 ns;
		else
			z <= '0' after 1 ns;
		end if ;
	end process;
end archth12m_a; 


----------------------------------------------------------- 
-- th12dm_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th12dm_a is 
	port(a: in std_logic; 
		 b: in std_logic;
		 rst: in std_logic;
		 s: in std_logic;
		 z: out std_logic); 
end th12dm_a; 

architecture archth12dm_a of th12dm_a is
begin
	th12dm_a: process(a, b, rst, s)
	begin
		if rst = '1' then
			z <= '1' after 2 ns;
		elsif (rst = '0' and s = '1') then
			z <= '0' after 5 ns;
		elsif (rst = '0' and (a = '1' or b = '1')) then
			z <= '1' after 1 ns;
		else
			z <= '0' after 1 ns;
		end if ;
	end process;
end archth12dm_a; 
	
	
----------------------------------------------------------- 
-- th12nm_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 
	
entity th12nm_a is 
	port(a: in std_logic; 
		 b: in std_logic;
		 rst: in std_logic;
		 s: in std_logic; 
		 z: out std_logic); 
end th12nm_a; 
	
architecture archth12nm_a of th12nm_a is
begin
	th12nm_a: process(a, b, rst, s)
	begin
		if rst = '1' then 
			z <= '0' after 2 ns;
		elsif (rst = '0' and s = '1') then
			z <= '0' after 5 ns;
		elsif (rst = '0' and (a = '1' or b = '1')) then
			z <= '1' after 1 ns;
		else
			z <= '0' after 1 ns;
		end if ;
	end process;
end archth12nm_a;


----------------------------------------------------------- 
-- th13m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th13m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 s: in std_logic;
		 z: out std_logic); 
end th13m_a; 

architecture archth13m_a of th13m_a is 
begin 
	th13m_a: process(a, b, c, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns;
		elsif a = '1'
			   or b = '1'
			   or c = '1' then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 1 ns; 
		end if ;
	end process; 
end archth13m_a; 


----------------------------------------------------------- 
-- th14m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th14m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic); 
end th14m_a; 

architecture archth14m_a of th14m_a is 
begin 
	th14m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif a = '1'
			   or b = '1'
			   or c = '1'
			   or d = '1' then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 1 ns; 
		end if ;
	end process; 
end archth14m_a; 


----------------------------------------------------------- 
-- th22m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th22m_a is 
	port(a: in std_logic; 
		 b: in std_logic;
		 s: in std_logic;
		 z: out std_logic ); 
end th22m_a; 

architecture archth22m_a of th22m_a is 
begin 
	th22m_a: process(a, b, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns;
		elsif (a = '1' and b = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 1 ns;
		end if ;
	end process; 
end archth22m_a;		


----------------------------------------------------------- 
-- th23m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th23m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic ); 
end th23m_a; 

architecture archth23m_a of th23m_a is 
begin 
	th23m_a: process(a, b, c, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
			    or (b = '1' and c = '1')
				or (c = '1' and a = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth23m_a; 


----------------------------------------------------------- 
-- th23w2m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th23w2m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic ); 
end th23w2m_a; 

architecture arch of th23w2m_a is 
begin 
	th23w2m_a: process(a, b, c, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif a = '1'
			   or (b = '1' and c = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns;
		end if ;
	end process; 
end arch; 


----------------------------------------------------------- 
-- th24m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th24m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th24m_a; 

architecture archth24m_a of th24m_a is 
begin 
	th24m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
				or (a = '1' and c = '1')
				or (a = '1' and d = '1') 
				or (b = '1' and c = '1')
				or (b = '1' and d = '1')
				or (c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth24m_a; 


----------------------------------------------------------- 
-- th24w2m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th24w2m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic;
		 s: in std_logic; 
		 z: out std_logic ); 
end th24w2m_a; 

architecture archth24w2m_a of th24w2m_a is 
begin 
	th24w2m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif a = '1'
			   or (b = '1' and c = '1')
			   or (b = '1' and d = '1')
			   or (c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth24w2m_a;


----------------------------------------------------------- 
-- th24w22m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th24w22m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th24w22m_a; 

architecture archth24w22m_a of th24w22m_a is 
begin 
	th24w22m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif a = '1' 
			   or b = '1'
			   or (c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth24w22m_a; 


----------------------------------------------------------- 
-- th24compm_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th24compm_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th24compm_a; 

architecture archth24compm_a of th24compm_a is 
begin 
	th24compm_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' or b = '1') and (c = '1' or d = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns;	
		end if ;
	end process; 
end archth24compm_a; 


----------------------------------------------------------- 
-- th33m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th33m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic ); 
end th33m_a; 

architecture archth33m_a of th33m_a is 
begin 
	th33m_a: process(a, b, c, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns;
		elsif (a = '1' and b = '1' and c = '1') then 
			z <= '1' after 2 ns; 
 		else 
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth33m_a; 


----------------------------------------------------------- 
-- th33w2m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th33w2m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic;
		 s: in std_logic;
		 z: out std_logic ); 
end th33w2m_a; 

architecture archth33w2m_a of th33w2m_a is 
begin 
	th33w2m_a: process(a, b, c, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns;
		elsif (a = '1' and b = '1')
				or (a = '1' and c = '1') then 
			z <= '1' after 2 ns; 
 		else 
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth33w2m_a; 


----------------------------------------------------------- 
-- th34m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th34m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th34m_a; 

architecture archth34m_a of th34m_a is 
begin 
	th34w3m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1' and c = '1') 
				or (a = '1' and c = '1' and d = '1') 
				or (a = '1' and b = '1' and d = '1')
				or (b = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 1 ns;	
		end if ;
	end process; 
end archth34m_a; 


----------------------------------------------------------- 
--th34w2m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th34w2m_a is 
	port(a: in std_logic;
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic;
		 s: in std_logic;
		 z: out std_logic ); 
end th34w2m_a; 

architecture archth34w2m_a of th34w2m_a is 
begin 
	th34w2m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1') 
				or (a = '1' and c = '1') 
				or (a = '1' and d = '1') 
				or (b = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 1 ns;	
		end if ;
	end process; 
end archth34w2m_a; 


----------------------------------------------------------- 
--th34w22m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th34w22m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th34w22m_a; 

architecture archth34w22m_a of th34w22m_a is 
begin 
	th34w22m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
				or (a = '1' and c = '1')
				or (a = '1' and d = '1') 
				or (b = '1' and c = '1')
				or (b = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth34w22m_a; 


----------------------------------------------------------- 
-- th34w3m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th34w3m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th34w3m_a; 

architecture archth34w3m_a of th34w3m_a is 
begin 
	th34w3m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif a = '1'
			   or (b = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth34w3m_a; 


----------------------------------------------------------- 
-- th34w32m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th34w32m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th34w32m_a; 

architecture archth34w32m_a of th34w32m_a is 
begin 
	th34w32m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif a = '1'
			   or (b = '1' and (c = '1' or d = '1')) then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth34w32m_a; 


----------------------------------------------------------- 
-- th44m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th44m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th44m_a; 

architecture archth44m_a of th44m_a is 
begin 
	th44m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns;
		elsif (a = '1' and b = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth44m_a; 


----------------------------------------------------------- 
-- th44w2m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th44w2m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th44w2m_a; 

architecture archth44w2m_a of th44w2m_a is 
begin 
	th44w2m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1' and c = '1')
				or (a = '1' and b = '1' and d = '1')
				or (a = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns; 
		end if ; 
	end process; 
end archth44w2m_a; 


----------------------------------------------------------- 
-- th44w22m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th44w22m_a is 
	port(a: in std_logic; 
		 b: in std_logic;
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th44w22m_a; 

architecture archth44w22m_a of th44w22m_a is 
begin 
	th44w22m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 	
		elsif (a = '1' and b = '1') 
				or (a = '1' and c = '1' and d = '1')
				or (b = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth44w22m_a; 


----------------------------------------------------------- 
-- th44w3m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th44w3m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th44w3m_a; 

architecture archth44w3m_a of th44w3m_a is 
begin 
	th44w3m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and (b = '1' or c = '1' or d = '1')) then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth44w3m_a ; 


----------------------------------------------------------- 
-- th44w322m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th44w322m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th44w322m_a ; 

architecture archth44w322m_a of th44w322m_a is 
begin 
	th44w322m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and ( b = '1' or c = '1' or d = '1'))
				or ( b = '1' and c = '1' ) then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archth44w322m_a; 


----------------------------------------------------------- 
-- th54w22m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th54w22m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th54w22m_a; 

architecture archth54w22m_a of th54w22m_a is 
begin 
	th54w22m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1' and (c = '1' or d = '1')) then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth54w22m_a; 


----------------------------------------------------------- 
-- th54w32m_a
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th54w32m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic;
		 s: in std_logic; 
		 z: out std_logic ); 
end th54w32m_a; 

architecture archth54w32m_a of th54w32m_a is 
begin 
	th54w32m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
				or (a = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ;
	end process; 
end archth54w32m_a; 


----------------------------------------------------------- 
-- th54w322m
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity th54w322m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end th54w322m_a; 

architecture archth54w322m_a of th54w322m_a is 
begin 
	th54w322m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
				or (a = '1' and c = '1')
				or (b = '1' and c = '1' and d = '1') then 
			z <= '1' after 2 ns;
		else
			z <= '0' after 2 ns; 
		end if ; 
	end process; 
end archth54w322m_a; 


----------------------------------------------------------- 
-- thand0m_a 
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity thand0m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic; 
		 s: in std_logic;
		 z: out std_logic ); 
end thand0m_a; 

architecture archthand0m_a of thand0m_a is 
begin 
	thand0m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
				or (b = '1' and c = '1')
				or (a = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else 
			z <= '0' after 2 ns;	
		end if ;
	end process; 
end archthand0m_a; 

----------------------------------------------------------- 
-- thxor0m_a	
----------------------------------------------------------- 
library ieee; 
use ieee.std_logic_1164.all; 

entity thxor0m_a is 
	port(a: in std_logic; 
		 b: in std_logic; 
		 c: in std_logic; 
		 d: in std_logic;
		 s: in std_logic; 
		 z: out std_logic ); 
end thxor0m_a; 

architecture archthxor0m_a of thxor0m_a is 
begin 
	thxor0m_a: process(a, b, c, d, s) 
	begin 
		if s = '1' then 
			z <= '0' after 2 ns; 
		elsif (a = '1' and b = '1')
				or (c = '1' and d = '1') then 
			z <= '1' after 2 ns; 
		else
			z <= '0' after 2 ns;
		end if ; 
	end process; 
end archthxor0m_a; 

