use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.ncl_signals.all;
use work.functions.all;
use work.tree_funcs.all;

entity tb_GRNN_gru_8_16 is
generic(bitwidth : integer := 16;
	maxLayerSize : integer := 128);
end tb_GRNN_gru_8_16;

architecture arch_tb_GRNN_gru_8_16 of tb_GRNN_gru_8_16 is


--COMPONENT UNDER TEST

component GRNN_w_IO is
	generic(maxBitwidth : integer := 16;
		maxLayerSize : integer := 128);
	port(	
		--Configuration Ports
		numberLayers	: in std_logic_vector(1 downto 0);
		inputWidth	: in std_logic_vector(7 downto 0);
		layerBitwidth 	: in std_logic_vector(3 downto 0);
		layerSize 	: in std_logic_vector(3 downto 0);
		layerType 	: in std_logic_vector(3 downto 0);
		fcNumberLayers	: in std_logic;
		fcLayerBitwidth	: in std_logic;
		--prevLayerSize 	: in std_logic_vector(3 downto 0);

		trunc_zt 	: in std_logic_vector(11 downto 0);
		trunc_htm1_zt 	: in std_logic_vector(11 downto 0);
		trunc_zeta 	: in std_logic_vector(11 downto 0);
		trunc_rt 	: in std_logic_vector(11 downto 0);
		trunc_htm1_rt 	: in std_logic_vector(11 downto 0);
		trunc_sht 	: in std_logic_vector(11 downto 0);
		trunc_ztm1_sht 	: in std_logic_vector(11 downto 0);
		trunc_bitchange : in std_logic_vector(8 downto 0);
		trunc_fc 	: in std_logic_vector(2 downto 0);

		configDataRequest : out std_logic;
		configDataReady : in std_logic;

		--Primary Layer Inputs
		Xt 		: in std_logic_vector(maxBitwidth-1 downto 0);
		reset 		: in std_logic;
		inDataReady 	: in std_logic;
		outDataReceived	: in std_logic;

		--Flash Ports
		DO 		: in std_logic;
		cs 		: out std_logic;
		clk		: out std_logic;
		DIO 		: out std_logic;


		--Primary Layer Outputs
		outDataIsReady 	: out std_logic;
		dataRequest	: out std_logic;
		z 		: out std_logic_vector(maxBitwidth-1 downto 0)
	);
end component;



--COMPONENT TEST SIGNALS
signal Xt, z : std_logic_vector(bitwidth-1 downto 0);
signal reset_count : dual_rail_logic_vector(6 downto 0);
signal reset, data_in_ready, ki_not, DO, cs, clk, DIO, ko, data_out_ready, configDataRequest, configDataReady  : std_logic;

--DATA GENERATION AND SELF TEST SIGNALS
signal data_a, null_a, data_0 : dual_rail_logic_vector(bitwidth-1 downto 0);
signal a_sr, z_sr, z_correct : std_logic_vector(bitwidth-1 downto 0);
signal reset_count_sr, correct_count : std_logic_vector(6 downto 0);

type inputData is array(0 to 255) of std_logic_vector(15 downto 0);
type memoryData is array(0 to 45193) of std_logic_vector(15 downto 0);
signal memData : memoryData;
signal file_inputData : inputData;

signal count : std_logic_vector(19 downto 0);

signal file_data_input_L1_dr, file_data_forget_L1_dr, file_data_cell_L1_dr, file_data_output_L1_dr, file_data_input_L2_dr, file_data_forget_L2_dr, file_data_cell_L2_dr, file_data_output_L2_dr, file_data_fc_dr, flashToMemData : dual_rail_logic_vector(15 downto 0);
file zwh0, zwh1, zwh2, zwh3, zwx0, zwx1, zwx2, zwx3, rwh0, rwh1, rwh2, rwh3, rwx0, rwx1, rwx2, rwx3, swh0, swh1, swh2, swh3, swx0, swx1, swx2, swx3, wfc, bfc, zb0, zb1, zb2, zb3, rb0, rb1, rb2, rb3, sb0, sb1, sb2, sb3, zetaNu, inDataFile : text;
signal input_L1_count, cell_L1_count, forget_L1_count, output_L1_count, input_L2_count, cell_L2_count, forget_L2_count, output_L2_count, fc_count, input_data_count, instruction_count : integer := 0;

signal SCAN_out : std_logic_vector(15 downto 0);
signal SCAN_select : std_logic_vector(4 downto 0);

begin

--UNIT UNDER TEST INSTANTIATION
uut : GRNN_w_IO
	generic map(maxBitwidth => bitwidth,
		maxLayerSize => maxLayerSize)
	port map(	
		--Configuration Ports
		numberLayers	=> "01",
		inputWidth	=> "11111111",
		layerBitwidth 	=> "0010",
		layerSize 	=> "1111",
		layerType 	=> "0000",
		fcNumberLayers	=> '1',
		fcLayerBitwidth	=> '1',
		--prevLayerSize 	: in std_logic_vector(3 downto 0);

		trunc_zt 	=> "111111111101",
		trunc_htm1_zt 	=> "111111111110",
		trunc_zeta 	=> "111111111101",
		trunc_rt 	=> "111111111101",
		trunc_htm1_rt 	=> "111111111110",
		trunc_sht 	=> "111111111101",
		trunc_ztm1_sht 	=> "111111111111",
		trunc_bitchange => "111111101",
		trunc_fc 	=> "111",

		configDataRequest => configDataRequest,
		configDataReady => configDataReady,

		--Primary Layer Inputs
		Xt 		=> Xt,
		reset 		=> reset,
		inDataReady 	=> data_in_ready,
		outDataReceived	=> ki_not,

		--Flash Ports
		DO 		=> DO,
		cs 		=> cs,
		clk		=> clk,
		DIO 		=> DIO,


		--Primary Layer Outputs
		outDataIsReady 	=> data_out_ready,
		dataRequest	=> ko,
		z 		=> z
	);




process
variable v_ILINE : line;
variable v_inval : std_logic_vector(15 downto 0);
begin
	file_open(zwh0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_z0.txt", read_mode);
	file_open(zwh1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_z1.txt", read_mode);
	file_open(zwh2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_z1.txt", read_mode);
	file_open(zwh3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_z1.txt", read_mode);
	file_open(zwx0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_z0.txt", read_mode);
	file_open(zwx1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_z1.txt", read_mode);
	file_open(zwx2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_z1.txt", read_mode);
	file_open(zwx3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_z1.txt", read_mode);

	file_open(zb0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_z0.txt", read_mode);
	file_open(zb1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_z1.txt", read_mode);
	file_open(zb2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_z1.txt", read_mode);
	file_open(zb3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_z1.txt", read_mode);

	file_open(rwh0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_r0.txt", read_mode);
	file_open(rwh1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_r1.txt", read_mode);
	file_open(rwh2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_r1.txt", read_mode);
	file_open(rwh3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_r1.txt", read_mode);
	file_open(rwx0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_r0.txt", read_mode);
	file_open(rwx1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_r1.txt", read_mode);
	file_open(rwx2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_r1.txt", read_mode);
	file_open(rwx3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_r1.txt", read_mode);

	file_open(rb0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_r0.txt", read_mode);
	file_open(rb1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_r1.txt", read_mode);
	file_open(rb2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_r1.txt", read_mode);
	file_open(rb3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_r1.txt", read_mode);

	file_open(swh0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_h0.txt", read_mode);
	file_open(swh1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_h1.txt", read_mode);
	file_open(swh2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_h1.txt", read_mode);
	file_open(swh3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_U_h1.txt", read_mode);
	file_open(swx0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_h0.txt", read_mode);
	file_open(swx1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_h1.txt", read_mode);
	file_open(swx2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_h1.txt", read_mode);
	file_open(swx3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_W_h1.txt", read_mode);

	file_open(sb0, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_h0.txt", read_mode);
	file_open(sb1, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_h1.txt", read_mode);
	file_open(sb2, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_h1.txt", read_mode);
	file_open(sb3, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_b_h1.txt", read_mode);

	file_open(zetaNu, "/home/sxn013/TSMC/GRNN/data/newTransfer/txtfile_circulant/binary_weights/binary_zetaNu.txt", read_mode);

	file_open(wfc, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_fc_w.txt", read_mode);
	file_open(bfc, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_fc_bias.txt", read_mode);

	file_open(inDataFile, "/home/sxn013/TSMC/GRNN/data/truncFixData/binary_weights/binary_inputs.txt", read_mode);
---X VALUE READ--------------------
	for i in 0 to 255 loop
		readline(inDataFile, v_ILINE);
		read(v_ILINE, v_inval);
		file_inputData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
---X VALUE READ--------------------

------ZT WEIGHT READ---------------

	for i in 0 to 2047 loop
		readline(zwh0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
	for i in 2048 to 2175 loop
		readline(zwx0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;

	for i in 2176 to 2191 loop
		for j in 0 to 127 loop
			readline(zwh1, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-2176)*256)+j+2176) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(zwx1, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-2176)*256)+j+2176) <= v_inval;
		end loop;
	end loop;

	for i in 6272 to 6287 loop
		for j in 0 to 127 loop
			readline(zwh2, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-6272)*256)+j+6272) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(zwx2, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-6272)*256)+j+6272) <= v_inval;
		end loop;
	end loop;

	for i in 10368 to 10383 loop
		for j in 0 to 127 loop
			readline(zwh3, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-10368)*256)+j+10368) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(zwx3, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-10368)*256)+j+10368) <= v_inval;
		end loop;
	end loop;
------END ZT WEIGHT READ---------------

------RT WEIGHT READ---------------


	for i in 14464 to 16511 loop
		readline(rwh0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
	for i in 16512 to 16639 loop
		readline(rwx0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;

	for i in 16640 to 16655 loop
		for j in 0 to 127 loop
			readline(rwh1, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-16640)*256)+j+16640) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(rwx1, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-16640)*256)+j+16640) <= v_inval;
		end loop;
	end loop;

	for i in 20736 to 20751 loop
		for j in 0 to 127 loop
			readline(rwh2, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-20736)*256)+j+20736) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(rwx2, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-20736)*256)+j+20736) <= v_inval;
		end loop;
	end loop;

	for i in 24832 to 24847 loop
		for j in 0 to 127 loop
			readline(rwh3, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-24832)*256)+j+24832) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(rwx3, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-24832)*256)+j+24832) <= v_inval;
		end loop;
	end loop;

------END RT WEIGHT READ---------------

------SHT WEIGHT READ---------------

	for i in 28928 to 30975 loop
		readline(swh0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
	for i in 30976 to 31103 loop
		readline(swx0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;

	for i in 31104 to 31119 loop
		for j in 0 to 127 loop
			readline(swh1, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-31104)*256)+j+31104) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(swx1, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-31104)*256)+j+31104) <= v_inval;
		end loop;
	end loop;

	for i in 35200 to 35215 loop
		for j in 0 to 127 loop
			readline(swh2, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-35200)*256)+j+35200) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(swx2, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-35200)*256)+j+35200) <= v_inval;
		end loop;
	end loop;

	for i in 39296 to 39311 loop
		for j in 0 to 127 loop
			readline(swh3, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-39296)*256)+j+39296) <= v_inval;
		end loop;
		for j in 128 to 255 loop
			readline(swx3, v_ILINE);
			read(v_ILINE, v_inval);
			memData(((i-39296)*256)+j+39296) <= v_inval;
		end loop;
	end loop;

------END SHT WEIGHT READ---------------

------ZT BIAS READ---------------

	for i in 43392 to 43519 loop
		readline(zb0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
	for i in 43520 to 43647 loop
		readline(zb1, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 43648 to 43775 loop
		readline(zb2, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 43776 to 43903 loop
		readline(zb3, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;

------END ZT BIAS READ---------------

------RT BIAS READ---------------

	for i in 43904 to 44031 loop
		readline(rb0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
	for i in 44032 to 44159 loop
		readline(rb1, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 44160 to 44287 loop
		readline(rb2, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 44288 to 44415 loop
		readline(rb3, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;

------END RT BIAS READ---------------

------SHT BIAS READ---------------

	for i in 44416 to 44543 loop
		readline(sb0, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval(7 downto 0) & "00000000";
	end loop;
	for i in 44544 to 44671 loop
		readline(sb1, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 44672 to 44799 loop
		readline(sb2, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 44800 to 44927 loop
		readline(sb3, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;

------END SHT BIAS READ---------------

------ZETA NU READ---------------

	for i in 44928 to 44935 loop
		readline(zetaNu, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;

------END ZETA NU READ---------------

------FC READ---------------

	for i in 44936 to 45191 loop
		readline(wfc, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;
	for i in 45192 to 45193 loop
		readline(bfc, v_ILINE);
		read(v_ILINE, v_inval);
		memData(i) <= v_inval;
	end loop;

------END FC READ---------------

	
wait;
end process;

reset_proc : process
begin
	reset <= '1';
	wait for 10 ns;
	reset <= '0';
	wait;
end process;


ki_proc: process
begin
	wait for 1 ns;
	if reset = '1' then
		ki_not <= '0';
	end if;
	if data_out_ready = '1' then
		wait for 50 ns;
		ki_not <= '1';
	elsif data_out_ready = '0' then 
		wait for 5 ns;
		ki_not<= '0';
	else
		wait for 1 ns;
	end if;
end process;


flash_mem_proc : process(reset, clk)
begin
	if reset = '1' then
		count <= "00000000000000000000"; 
		instruction_count <= 0;
	elsif rising_edge(clk) then
		if instruction_count < 33 then
			instruction_count <= instruction_count + 1;
		end if;
	elsif falling_edge(clk) then
		if instruction_count > 32 and count < 723103 then
			count <= count + '1';
		end if;
	end if;

end process;

data_sr_proc: process
begin
	wait for 1 ns;
	if reset = '1' then
		Xt <= file_inputData(input_data_count); 
		data_in_ready <= '0';
	end if;
	wait until ko = '1';
	Xt <= file_inputData(input_data_count mod 256);
	wait for 1 ns;
	data_in_ready <= '1';
	wait until ko = '0';
	input_data_count <= input_data_count + 1;
	data_in_ready <= '0';


end process;

config_sr_proc: process
begin
	wait for 1 ns;
	if reset = '1' then
		configDataReady <= '0';
	end if;
	wait until configDataRequest = '1';
	wait for 10 ns;
	configDataReady <= '1';
	wait until configDataRequest = '0';
	configDataReady <= '0';
	wait;


end process;

--SCAN_select_proc : process
--begin
--	wait for 1 ns;
--	if reset = '1' then
--		SCAN_select <= "00000"; 
--	else
--		wait for 30 ns;
--		SCAN_select <= SCAN_select + '1';
--	end if;
--
--end process;

DO <= memData(to_integer(unsigned(count(19 downto 4))))(to_integer(unsigned(count(3 downto 0))));


end arch_tb_GRNN_gru_8_16;
