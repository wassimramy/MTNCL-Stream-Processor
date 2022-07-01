-- Generic AND tree

library ieee;
use ieee.std_logic_1164.all;
use work.tree_funcs.all;

entity andtreem is
	generic(width: in integer := 4);
	port(a: in std_logic_vector(width-1 downto 0);
		 sleep: in std_logic;
		 ko: out std_logic);
end andtreem;

architecture arch of andtreem is

type completion is array(log_u(width, 4) downto 0, width-1 downto 0) of std_logic;
signal comp_array: completion;

	component th22m_a
		port(a: in std_logic;
			 b: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

	component th33m_a
		port(a: in std_logic;
			 b: in std_logic;
			 c: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

	component th44m_a
		port(a: in std_logic;
			 b: in std_logic;
			 c: in std_logic;
			 d: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

begin
	RENAME: for i in 0 to width-1 generate
		comp_array(0, i) <= a(i);
	end generate;

	STRUCTURE: for k in 0 to log_u(width, 4)-1 generate
	begin
		NOT_LAST: if level_number(width, k, 4) > 4 generate
		begin
			PRINCIPLE: for j in 0 to (level_number(width, k, 4) / 4)-1 generate
				G4: th44m_a
					port map(comp_array(k, j*4), comp_array(k, j*4+1), comp_array(k, j*4+2), comp_array(k, j*4+3),sleep, 
					comp_array(k+1, j));
			end generate;

			LEFT_OVER_GATE: if log_u((level_number(width, k, 4) / 4) + (level_number(width, k, 4) rem 4), 4) + k + 1 
				/= log_u(width, 4) generate
			begin
				NEED22: if (level_number(width, k, 4) rem 4) = 2 generate
					G2: th22m_a
						port map(comp_array(k, level_number(width, k, 4)-2), comp_array(k, level_number(width, k, 4)-1), sleep,
						comp_array(k+1, (level_number(width, k, 4) / 4)));
				end generate;

				NEED33: if (level_number(width, k, 4) rem 4) = 3 generate
					G3: th33m_a
						port map(comp_array(k, level_number(width, k, 4)-3), comp_array(k, level_number(width, k, 4)-2), 
						comp_array(k, level_number(width, k, 4)-1), sleep, comp_array(k+1, (level_number(width, k, 4) / 4)));
				end generate;
			end generate;

			LEFT_OVER_SIGNALS: if (log_u((level_number(width, k, 4) / 4) + (level_number(width, k, 4) rem 4), 4) + k + 1
				= log_u(width, 4)) and ((level_number(width, k, 4) rem 4) /= 0) generate
			begin
				RENAME_SIGNALS: for h in 0 to (level_number(width, k, 4) rem 4)-1 generate
					comp_array(k+1, (level_number(width, k, 4) / 4)+h) <= comp_array(k, level_number(width, k, 4)-1-h);
				end generate;
			end generate;
		end generate;

		LAST22: if level_number(width, k, 4) = 2 generate
			G2F: th22m_a
				port map(comp_array(k, 0), comp_array(k, 1), sleep, ko);
		end generate;

		LAST33: if level_number(width, k, 4) = 3 generate
			G3F: th33m_a
				port map(comp_array(k, 0), comp_array(k, 1), comp_array(k, 2),sleep, ko);
		end generate;

		LAST44: if level_number(width, k, 4) = 4 generate
			G4F: th44m_a
				port map(comp_array(k, 0), comp_array(k, 1), comp_array(k, 2), comp_array(k, 3), sleep, ko);
		end generate;
	end generate;

end arch;


-- Generic OR tree

library ieee;
use ieee.std_logic_1164.all;
use work.tree_funcs.all;

entity ortreem is
	generic(width: in integer := 4);
	port(a: in std_logic_vector(width-1 downto 0);
		 sleep: in std_logic;
		 ko: out std_logic);
end ortreem;

architecture arch of ortreem is

type completion is array(log_u(width, 4) downto 0, width-1 downto 0) of std_logic;
signal comp_array: completion;

	component th12m_a
		port(a: in std_logic;
			 b: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

	component th13m_a
		port(a: in std_logic;
			 b: in std_logic;
			 c: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

	component th14m_a
		port(a: in std_logic;
			 b: in std_logic;
			 c: in std_logic;
			 d: in std_logic;
			 s: in std_logic;
			 z: out std_logic);
	end component;

begin
	RENAME: for i in 0 to width-1 generate
		comp_array(0, i) <= a(i);
	end generate;

	STRUCTURE: for k in 0 to log_u(width, 4)-1 generate
	begin
		NOT_LAST: if level_number(width, k, 4) > 4 generate
		begin
			PRINCIPLE: for j in 0 to (level_number(width, k, 4) / 4)-1 generate
				G4: th14m_a
					port map(comp_array(k, j*4), comp_array(k, j*4+1), comp_array(k, j*4+2), comp_array(k, j*4+3), sleep,
					comp_array(k+1, j));
			end generate;

			LEFT_OVER_GATE: if log_u((level_number(width, k, 4) / 4) + (level_number(width, k, 4) rem 4), 4) + k + 1 
				/= log_u(width, 4) generate
			begin
				NEED22: if (level_number(width, k, 4) rem 4) = 2 generate
					G2: th12m_a
						port map(comp_array(k, level_number(width, k, 4)-2), comp_array(k, level_number(width, k, 4)-1), 
						sleep, comp_array(k+1, (level_number(width, k, 4) / 4)));
				end generate;

				NEED33: if (level_number(width, k, 4) rem 4) = 3 generate
					G3: th13m_a
						port map(comp_array(k, level_number(width, k, 4)-3), comp_array(k, level_number(width, k, 4)-2), 
						comp_array(k, level_number(width, k, 4)-1), sleep, comp_array(k+1, (level_number(width, k, 4) / 4)));
				end generate;
			end generate;

			LEFT_OVER_SIGNALS: if (log_u((level_number(width, k, 4) / 4) + (level_number(width, k, 4) rem 4), 4) + k + 1
					= log_u(width, 4)) and ((level_number(width, k, 4) rem 4) /= 0) generate
			begin
				RENAME_SIGNALS: for h in 0 to (level_number(width, k, 4) rem 4)-1 generate
					comp_array(k+1, (level_number(width, k, 4) / 4)+h) <= comp_array(k, level_number(width, k, 4)-1-h);
				end generate;
			end generate;
		end generate;

		LAST22: if level_number(width, k, 4) = 2 generate
			G2F: th12m_a
				port map(comp_array(k, 0), comp_array(k, 1), sleep, ko);
		end generate;

		LAST33: if level_number(width, k, 4) = 3 generate
			G3F: th13m_a
				port map(comp_array(k, 0), comp_array(k, 1), comp_array(k, 2),sleep, ko);
		end generate;

		LAST44: if level_number(width, k, 4) = 4 generate
			G4F: th14m_a
				port map(comp_array(k, 0), comp_array(k, 1), comp_array(k, 2), comp_array(k, 3),sleep, ko);
		end generate;
	end generate;

end arch;
