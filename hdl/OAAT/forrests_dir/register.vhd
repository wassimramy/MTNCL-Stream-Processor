library IEEE;
use IEEE.std_logic_1164.all;
-- Boolean DFF
entity DFFRX1MTR_No_QN is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic);
end DFFRX1MTR_No_QN;

architecture arch of DFFRX1MTR_No_QN is
begin
	P1 : process(clk, rst)
	begin
		if (rst = '1') then
			Q <= '0' after 1 ns;
		elsif (clk'event and clk = '1') then
			Q <= D after 2 ns;
		end if;
	end process;
end arch;

library IEEE;
use IEEE.std_logic_1164.all;
----------------------------------------------------------- 
-- Reg with reset to 1
----------------------------------------------------------- 
entity regD is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic);
end regD;

architecture arch of regD is
begin
	P1 : process(clk, rst)
	begin
		if (rst = '1') then
			Q <= '1' after 1 ns;
		elsif (clk'event and clk = '1') then
			Q <= D after 2 ns;
		end if;
	end process;
end arch;

----------------------------------------------------------- 
-- Reg with Sleep Input
----------------------------------------------------------- 
library IEEE;
use IEEE.std_logic_1164.all;

entity reg_sleep is
	port(
		D   : in  std_logic;
		clk : in  std_logic;
		rst : in  std_logic;
		sleep : in std_logic;
		Q   : out std_logic);
end reg_sleep;

architecture arch of reg_sleep is
	
begin
	process(clk, rst, sleep) begin
		if(rst = '1') then
			Q <= '0';
		elsif(sleep = '1') then
			Q <= '0';
		elsif(clk'event and clk = '1') then
			Q <= D;
		end if;
	end process;
end arch;


library IEEE;
use IEEE.std_logic_1164.all;
-- Boolean Generic Register
entity reg_gen is
	generic(width : integer := 16);
	port(
		D   : in  std_logic_vector(width - 1 downto 0);
		clk : in  std_logic;
		rst : in  std_logic;
		Q   : out std_logic_vector(width - 1 downto 0));
end reg_gen;

architecture arch of reg_gen is
	component DFFRX1MTR_No_QN is
		port(
			D   : in  std_logic;
			clk : in  std_logic;
			rst : in  std_logic;
			Q   : out std_logic);
	end component;

begin
	Gen1 : for i in 0 to width - 1 generate
		RegA : DFFRX1MTR_No_QN
			port map(D(i), clk, rst, Q(i));
	end generate;
end arch;

library IEEE;
use IEEE.std_logic_1164.all;
-- Boolean Generic Register with Sleep Input
entity reg_gen_sleep is
	generic(width : integer := 16);
	port(
		D   : in  std_logic_vector(width - 1 downto 0);
		clk : in  std_logic;
		rst : in  std_logic;
		sleep : in std_logic;
		Q   : out std_logic_vector(width - 1 downto 0));
end reg_gen_sleep;

architecture arch of reg_gen_sleep is
	component reg_sleep is
		port(
			D   : in  std_logic;
			clk : in  std_logic;
			rst : in  std_logic;
			sleep : in std_logic;
			Q   : out std_logic);
	end component;

begin
	Gen1 : for i in 0 to width - 1 generate
		RegA : reg_sleep
			port map(D(i), clk, rst, sleep, Q(i));
	end generate;
end arch;
