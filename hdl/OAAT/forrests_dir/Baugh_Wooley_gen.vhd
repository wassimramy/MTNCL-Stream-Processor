library ieee;
use ieee.std_logic_1164.all;
use work.ncl_signals.all;

entity baugh_wooley_gen is 
	generic(width: integer);
	port(a: in dual_rail_logic_vector(width-1 downto 0);
		 b: in dual_rail_logic_vector(width-1 downto 0);
		 sleep: in std_logic;
		 z: out dual_rail_logic_vector(width*2-1 downto 0));
end baugh_wooley_gen;

architecture arch1 of baugh_wooley_gen is
	component full_adder is
		port(a: in dual_rail_logic;
			b: in dual_rail_logic;
			cin: in dual_rail_logic;
			sleep: in std_logic;
			sum: out dual_rail_logic;
			cout: out dual_rail_logic);
	end component;
	component adder_w_and is
		port(a: in dual_rail_logic;
			b: in dual_rail_logic;
			cin: in dual_rail_logic;
			sum_in: in dual_rail_logic;
			sleep: in std_logic;
			sum_out: out dual_rail_logic;
			cout: out dual_rail_logic);
	end component;
	component adder_w_nand is
		port(a: in dual_rail_logic;
			b: in dual_rail_logic;
			cin: in dual_rail_logic;
			sum_in: in dual_rail_logic;
			sleep: in std_logic;
			sum_out: out dual_rail_logic;
			cout: out dual_rail_logic);
	end component;

type array_sum_out is array (width-1 downto 0) of dual_rail_logic_vector(width-1 downto 0);
signal sumout, carryout: array_sum_out;
signal fulladd_sumout, fulladd_carryout: dual_rail_logic_vector(width-1 downto 0);

begin
	col: for i in 0 to width-1 generate
		non_left_cols: if i < width-1 generate
			rows: for j in 0 to width generate
				row1: if j = 0 generate
					add_and1: adder_w_and
						port map(
							a(i),
							b(j),
							('0','1'),
							('0','1'),
							sleep,
							sumout(i)(j),
							carryout(i)(j));
				end generate;
				rowx: if j > 0 generate
					row_not_nand: if j < width-1 generate
						add_andx: adder_w_and
							port map(
								a(i),
								b(j),
								carryout(i)(j-1),
								sumout(i+1)(j-1),
								sleep,
								sumout(i)(j),
								carryout(i)(j));
					end generate;
					row_nand: if j = width-1 generate
						add_nand: adder_w_nand
							port map(
								a(i),
								b(j),
								carryout(i)(j-1),
								sumout(i+1)(j-1),
								sleep,
								sumout(i)(j),
								carryout(i)(j));
					end generate;
					row_fulladd: if j = width generate
						fulladd1: if i = 0 generate
							fulladd1: full_adder
								port map(
									carryout(i)(j-1),
									sumout(i+1)(j-1),
									('1','0'),
									sleep,
									fulladd_sumout(i),
									fulladd_carryout(i));
						end generate;
						fulladdx: if i > 0 generate
							fulladdx: full_adder
								port map(
									carryout(i)(j-1),
									sumout(i+1)(j-1),
									fulladd_carryout(i-1),
									sleep,
									fulladd_sumout(i),
									fulladd_carryout(i));
						end generate;
					end generate;
				end generate;
			end generate;
		end generate;
		col_right: if i = width-1 generate
			rows: for k in 0 to width generate
				rows_nand: if k < width-1 generate
					rows_nand1: if k = 0 generate
						right_col_add1: adder_w_nand
							port map(
								a(i),
								b(k),
								('0','1'),
								('0','1'),
								sleep,
								sumout(i)(k),
								carryout(i)(k));
					end generate;
					rows_nandx: if k > 0 generate
						right_col_addx: adder_w_nand
							port map(
								a(i),
								b(k),
								carryout(i)(k-1),
								('0','1'),
								sleep,
								sumout(i)(k),
								carryout(i)(k));
					end generate;
				end generate;
				row_and: if k = width-1 generate
					add_and2: adder_w_and
						port map(
							a(i),
							b(k),
							carryout(i)(k-1),
							('0','1'),
							sleep,
							sumout(i)(k),
							carryout(i)(k));
				end generate;
				row_fulladd: if k = width generate
					fulladd2: full_adder
						port map(
							carryout(i)(k-1),
							('1','0'),
							fulladd_carryout(i-1),
							sleep,
							fulladd_sumout(i),
							fulladd_carryout(i));
				end generate;
			end generate;
		end generate;
	end generate;
					
					
z <= fulladd_sumout & sumout(0);
end arch1;