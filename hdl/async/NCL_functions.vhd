-- to be used in testbenches
-- not to be synthesized

Library IEEE;
use IEEE.std_logic_1164.all;
use work.NCL_signals.all;

package NCL_functions is

function is_null(s: DUAL_RAIL_LOGIC_VECTOR) return BOOLEAN;
function is_data(s: DUAL_RAIL_LOGIC_VECTOR) return BOOLEAN;
function is_null(s: DUAL_RAIL_LOGIC) return BOOLEAN;
function is_data(s: DUAL_RAIL_LOGIC) return BOOLEAN;

function is_null(s: QUAD_RAIL_LOGIC_VECTOR) return BOOLEAN;
function is_data(s: QUAD_RAIL_LOGIC_VECTOR) return BOOLEAN;
function is_null(s: QUAD_RAIL_LOGIC) return BOOLEAN;
function is_data(s: QUAD_RAIL_LOGIC) return BOOLEAN;

function to_null(s: DUAL_RAIL_LOGIC) return dual_rail_logic;
function to_null(s: QUAD_RAIL_LOGIC) return quad_rail_logic;
--function to_null(s: three_RAIL_LOGIC) return three_RAIL_LOGIC;
function to_null(s: DUAL_RAIL_LOGIC_VECTOR) return dual_rail_logic_vector;
function to_null(s: QUAD_RAIL_LOGIC_VECTOR) return quad_rail_logic_vector;

function to_DR(s:std_logic) return DUAL_RAIL_LOGIC;
function to_DR(s:std_logic_vector) return DUAL_RAIL_LOGIC_VECTOR;

function to_SL(d:DUAL_RAIL_LOGIC) return std_logic;
function to_SL(d:DUAL_RAIL_LOGIC_VECTOR) return std_logic_vector;

function to_SL(q:QUAD_RAIL_LOGIC) return	std_logic_vector;
function to_SL(q:QUAD_RAIL_LOGIC_VECTOR) return std_logic_vector;

function to_DR(q:QUAD_RAIL_LOGIC) return DUAL_RAIL_LOGIC_VECTOR;
function to_DR(q:QUAD_RAIL_LOGIC_VECTOR) return DUAL_RAIL_LOGIC_VECTOR;

--function to_DR(q:three_RAIL_LOGIC) return DUAL_RAIL_LOGIC_VECTOR;

function to_QR(s: std_logic_vector) return QUAD_RAIL_LOGIC;
function to_QR(d:DUAL_RAIL_LOGIC_VECTOR) return QUAD_RAIL_LOGIC;

function to_QR(s:std_logic_vector) return QUAD_RAIL_LOGIC_VECTOR;
function to_QR(d:DUAL_RAIL_LOGIC_VECTOR) return QUAD_RAIL_LOGIC_VECTOR;

--function to_TR(s: std_logic_vector) return three_RAIL_LOGIC ;
--function to_SL(q: three_RAIL_LOGIC) return	std_logic_vector;

end NCL_functions;

package body NCL_functions is

function is_null(s: DUAL_RAIL_LOGIC_VECTOR) return BOOLEAN is
variable st: DUAL_RAIL_LOGIC_VECTOR(s'length-1 downto 0) := s;
begin
	for i in 0 to s'length - 1 loop
	if st(i).rail0 = '0' and st(i).rail1 = '0' then
		null;
	else
		return FALSE;
	end if;
	end loop;
	return TRUE;
end is_null;

function is_data(s: DUAL_RAIL_LOGIC_VECTOR) return BOOLEAN is
variable st: DUAL_RAIL_LOGIC_VECTOR(s'length-1 downto 0) := s;
begin
	for i in 0 to s'length - 1 loop
		if st(i).rail0 = '1' or st(i).rail1 = '1' then
			null;
		else
			return FALSE;
		end if;
	end loop;
	return TRUE;
end is_data;

function is_null(s: DUAL_RAIL_LOGIC) return BOOLEAN is
begin
	if s.rail0 = '0' and s.rail1 = '0' then
		return TRUE;
	else
		return FALSE;
	end if;
end is_null;

function is_data(s: DUAL_RAIL_LOGIC) return BOOLEAN is
begin
	if s.rail0 = '1' or s.rail1 = '1' then
		return TRUE;
	else
		return FALSE;
	end if;
end is_data;

function is_null(s: QUAD_RAIL_LOGIC_VECTOR) return BOOLEAN is
variable st: QUAD_RAIL_LOGIC_VECTOR(s'length-1 downto 0) := s;
begin
	for i in 0 to s'length - 1 loop
		if st(i).rail0 = '0' and st(i).rail1 = '0' and st(i).rail2 = '0' and st(i).rail3 = '0' then
			null;
		else
			return FALSE;
		end if;
		end loop;
	return TRUE;
end is_null;

function is_data(s: QUAD_RAIL_LOGIC_VECTOR) return BOOLEAN is
variable st: QUAD_RAIL_LOGIC_VECTOR(s'length-1 downto 0) := s;
begin
	for i in 0 to s'length - 1 loop
		if st(i).rail0 = '1' or st(i).rail1 = '1' or st(i).rail2 = '1' or st(i).rail3 = '1' then
			null;
		else
			return FALSE;
		end if;
	end loop;
	return TRUE;
end is_data;

function is_null(s: QUAD_RAIL_LOGIC) return BOOLEAN is
begin
	if s.rail0 = '0' and s.rail1 = '0' and s.rail2 = '0' and s.rail3 = '0' then
		return TRUE;
	else
		return FALSE;
	end if;
end is_null;

function is_data(s: QUAD_RAIL_LOGIC) return BOOLEAN is
begin
	if s.rail0 = '1' or s.rail1 = '1' or s.rail2 = '1' or s.rail3 = '1' then
		return TRUE;
	else
		return FALSE;
	end if;
end is_data;

function to_null(s: DUAL_RAIL_LOGIC) return DUAL_RAIL_LOGIC is
variable d: DUAL_RAIL_LOGIC;
begin
	d.rail1 := '0';
	d.rail0 := '0';
	return d;
end to_null;

function to_null(s: DUAL_RAIL_LOGIC_VECTOR) return DUAL_RAIL_LOGIC_VECTOR is
variable d: DUAL_RAIL_LOGIC_VECTOR(s'length-1 downto 0);
begin
	for i in d'range loop
		d(i).rail1 := '0';
		d(i).rail0 := '0';
	end loop;
	return d;
end to_null;

function to_null(s: QUAD_RAIL_LOGIC_VECTOR) return QUAD_RAIL_LOGIC_VECTOR is
variable q: QUAD_RAIL_LOGIC_VECTOR(s'length-1 downto 0);
begin
	for i in q'range loop
		q(i).rail3 := '0';
		q(i).rail2 := '0';
		q(i).rail1 := '0';
		q(i).rail0 := '0';
	end loop;
	return q;
end to_null;

function to_null(s: QUAD_RAIL_LOGIC) return QUAD_RAIL_LOGIC is
variable q: QUAD_RAIL_LOGIC;
begin
	q.rail3 := '0';
	q.rail2 := '0';
	q.rail1 := '0';
	q.rail0 := '0';
	return q;
end to_null;

--function to_null(s: three_RAIL_LOGIC) return three_RAIL_LOGIC is
--variable q: three_RAIL_LOGIC;
--begin
--	q.rail2 := '0';
--	q.rail1 := '0';
--	q.rail0 := '0';
--	return q;
--end to_null;

function to_DR(s: std_logic) return DUAL_RAIL_LOGIC is
variable d:DUAL_RAIL_LOGIC;
begin 
	if s='0' then
		d.rail0:='1';
		d.rail1:='0';
		return d;
	else 
		d.rail0:='0';
		d.rail1:='1';
		return d;	
	end if;
end to_DR;	

function to_DR(s: std_logic_vector) return DUAL_RAIL_LOGIC_VECTOR is
variable st: STD_LOGIC_VECTOR(s'length-1 downto 0) := s;
variable d:DUAL_RAIL_LOGIC_VECTOR(s'length-1 downto 0);
begin
	for i in 0 to s'length - 1 loop
		if st(i)='0' then
			d(i).rail0:='1';
			d(i).rail1:='0';
		else 
			d(i).rail0:='0';
			d(i).rail1:='1';
		end if; 
	end loop;	
	return d;
end to_DR;	

function to_SL(d: DUAL_RAIL_LOGIC) return std_logic is
variable s:std_logic;
begin
	s:=d.rail1;
	return s;
end to_SL; 	
	
function to_SL(d: DUAL_RAIL_LOGIC_VECTOR) return std_logic_vector is
variable dt: DUAL_RAIL_LOGIC_VECTOR(d'length-1 downto 0) := d;
variable s:std_logic_vector(d'length-1 downto 0);
begin
	for i in 0 to d'length - 1 loop
		s(i):=dt(i).rail1;
	end loop;
	return s;
end to_SL;			

function to_SL(q: QUAD_RAIL_LOGIC) return	std_logic_vector is
variable s:std_logic_vector(1 downto 0);
begin
	if q.rail0='1' and q.rail1='0' and q.rail2='0' and q.rail3='0' then
		s(1):='0';
		s(0):='0';
	elsif q.rail0='0' and q.rail1='1' and q.rail2='0' and q.rail3='0' then
		s(1):='0';
		s(0):='1';
	elsif q.rail0='0' and q.rail1='0' and q.rail2='1' and q.rail3='0' then
		s(1):='1';
		s(0):='0';
	elsif q.rail0='0' and q.rail1='0' and q.rail2='0' and q.rail3='1' then	
		s(1):='1';
		s(0):='1';
	else	
		s(1):='U';
		s(0):='U';
	end if;
	return s;
end to_SL;

function to_SL(q: QUAD_RAIL_LOGIC_VECTOR) return std_logic_vector is
variable qt: QUAD_RAIL_LOGIC_VECTOR(q'length-1 downto 0) := q;
variable s:std_logic_vector(2*q'length-1 downto 0);
begin
	for i in 0 to q'length-1 loop
		if qt(i).rail0='1' then
			s(2*i):='0';
			s(2*i+1):='0';	
		elsif qt(i).rail1='1' then
			s(2*i):='1';
			s(2*i+1):='0';
		elsif qt(i).rail2='1' then
			s(2*i):='0';
			s(2*i+1):='1';
		else
			s(2*i):='1';
			s(2*i+1):='1';
		end if;
	end loop;
	return s;
end to_SL; 

function to_DR(q:QUAD_RAIL_LOGIC) return DUAL_RAIL_LOGIC_VECTOR is
variable d:DUAL_RAIL_LOGIC_VECTOR(1 downto 0);
begin
	if q.rail0='1' then
		d(1).rail0:='1';
		d(1).rail1:='0';
		d(0).rail0:='1';
		d(0).rail1:='0';
	elsif q.rail1='1' then
		d(1).rail0:='1';
		d(1).rail1:='0';
		d(0).rail0:='0';
		d(0).rail1:='1';
	elsif q.rail2='1' then
		d(1).rail0:='0';
		d(1).rail1:='1';
		d(0).rail0:='1';
		d(0).rail1:='0'; 
	elsif q.rail3='1' then
		d(1).rail0:='0';
		d(1).rail1:='1';
		d(0).rail0:='0';
		d(0).rail1:='1'; 
	else
		d(1).rail0:='0';
		d(1).rail1:='0';
		d(0).rail0:='0';
		d(0).rail1:='0';	
	end if;
	return d;
end to_DR; 

--function to_DR(q:three_RAIL_LOGIC) return DUAL_RAIL_LOGIC_VECTOR is
--variable d:DUAL_RAIL_LOGIC_VECTOR(1 downto 0);
--begin
--	if q.rail0='1' then
--		d(1).rail0:='1';
--		d(1).rail1:='0';
--		d(0).rail0:='1';
--		d(0).rail1:='0';
--	elsif q.rail1='1' then
--		d(1).rail0:='1';
--		d(1).rail1:='0';
--		d(0).rail0:='0';
--		d(0).rail1:='1';
--	elsif q.rail2='1' then
--		d(1).rail0:='0';
--		d(1).rail1:='1';
--		d(0).rail0:='1';
--		d(0).rail1:='0'; 
--	else
--		d(1).rail0:='0';
--		d(1).rail1:='0';
--		d(0).rail0:='0';
--		d(0).rail1:='0';
--	end if;
--	return d;
--end to_DR; 			

function to_DR(q: QUAD_RAIL_LOGIC_VECTOR) return DUAL_RAIL_LOGIC_VECTOR is
variable qt: QUAD_RAIL_LOGIC_VECTOR(q'length-1 downto 0) := q;
variable d:DUAL_RAIL_LOGIC_VECTOR(2*q'length-1 downto 0);
begin
	for i in 0 to q'length-1 loop
		if qt(i).rail0='1' then
			d(2*i+1).rail0:='1';
			d(2*i+1).rail1:='0';
			d(2*i).rail0:='1';
			d(2*i).rail1:='0';
		elsif qt(i).rail1='1' then
			d(2*i+1).rail0:='1';
			d(2*i+1).rail1:='0';
			d(2*i).rail0:='0';
			d(2*i).rail1:='1';	
		elsif qt(i).rail2='1' then
			d(2*i+1).rail0:='0';
			d(2*i+1).rail1:='1';
			d(2*i).rail0:='1';
			d(2*i).rail1:='0';	
		elsif qt(i).rail3='1' then
			d(2*i+1).rail0:='0';
			d(2*i+1).rail1:='1';
			d(2*i).rail0:='0';
			d(2*i).rail1:='1'; 
		else
			d(2*i+1).rail0:='0';
			d(2*i+1).rail1:='0';
			d(2*i).rail0:='0';
			d(2*i).rail1:='0';
		end if;
	end loop;	
	return d;
end to_DR;

function to_QR(s: std_logic_vector) return QUAD_RAIL_LOGIC is
variable st: STD_LOGIC_VECTOR(1 downto 0) := s;
variable q : QUAD_RAIL_LOGIC;
begin 
	if (st(1)='0' and st(0)='0') then 
		q.rail0:='1';
		q.rail1:='0';
		q.rail2:='0';
		q.rail3:='0';
	elsif (st(1)='0' and st(0)='1') then 
		q.rail0:='0';
		q.rail1:='1';
		q.rail2:='0';
		q.rail3:='0';
	elsif (st(1)='1' and st(0)='0') then 
		q.rail0:='0';
		q.rail1:='0';
		q.rail2:='1';
		q.rail3:='0';
	elsif (st(1)='1' and st(0)='1') then
		q.rail0:='0';
		q.rail1:='0';
		q.rail2:='0';
		q.rail3:='1';
	end if;
	return q; 
end to_QR;		
				
function to_QR(s: std_logic_vector) return QUAD_RAIL_LOGIC_VECTOR is
variable st: std_logic_vector(s'length-1 downto 0) := s;
variable q : QUAD_RAIL_LOGIC_VECTOR((s'length/2)-1 downto 0);
begin
	for i in 0 to q'length-1 loop
		if (st(2*i+1)='0' and st(2*i)='0') then 
			q(i).rail0:='1';
			q(i).rail1:='0';
			q(i).rail2:='0';
			q(i).rail3:='0';
		elsif (st(2*i+1)='0' and st(2*i)='1') then 
			q(i).rail0:='0';
			q(i).rail1:='1';
			q(i).rail2:='0';
			q(i).rail3:='0';
		elsif (st(2*i+1)='1' and st(2*i)='0') then 
			q(i).rail0:='0';
			q(i).rail1:='0';
			q(i).rail2:='1';
			q(i).rail3:='0';
		elsif (st(2*i+1)='1' and st(2*i)='1') then
			q(i).rail0:='0';
			q(i).rail1:='0';
			q(i).rail2:='0';
			q(i).rail3:='1';
		end if;
	end loop;
	return q;
end to_QR; 

function to_QR(d: DUAL_RAIL_LOGIC_VECTOR) return QUAD_RAIL_LOGIC is
variable dt: DUAL_RAIL_LOGIC_VECTOR(1 downto 0) := d;
variable q : QUAD_RAIL_LOGIC;
begin
	if (dt(1).rail0='1' and dt(0).rail0='1') then 
		q.rail0:='1';
		q.rail1:='0';
		q.rail2:='0';
		q.rail3:='0';
	elsif (dt(1).rail0='1' and dt(0).rail1='1') then 
		q.rail0:='0';
		q.rail1:='1';
		q.rail2:='0';
		q.rail3:='0';
	elsif (dt(1).rail1='1' and dt(0).rail0='1') then 
		q.rail0:='0';
		q.rail1:='0';
		q.rail2:='1';
		q.rail3:='0';
	elsif (dt(1).rail1='1' and dt(0).rail1='1') then 
		q.rail0:='0';
		q.rail1:='0';
		q.rail2:='0';
		q.rail3:='1';
	else
		q.rail0:='0';
		q.rail1:='0';
		q.rail2:='0';
		q.rail3:='0';
	end if;
	return q;
end to_QR;			

function to_QR(d: DUAL_RAIL_LOGIC_VECTOR) return QUAD_RAIL_LOGIC_VECTOR is
variable dt: DUAL_RAIL_LOGIC_VECTOR(d'length-1 downto 0) := d;
variable q:QUAD_RAIL_LOGIC_VECTOR((d'length/2)-1 downto 0);
begin
	for i in 0 to q'length-1 loop
		if (dt(2*i+1).rail1='0' and dt(2*i).rail1='0') then 
			q(i).rail0:='1';
			q(i).rail1:='0';
			q(i).rail2:='0';
			q(i).rail3:='0';
		elsif (dt(2*i+1).rail1='0' and dt(2*i).rail1='1') then 
			q(i).rail0:='0';
			q(i).rail1:='1';
			q(i).rail2:='0';
			q(i).rail3:='0';
		elsif (dt(2*i+1).rail1='1' and dt(2*i).rail1='0') then 
			q(i).rail0:='0';
			q(i).rail1:='0';
			q(i).rail2:='1';
			q(i).rail3:='0';
		elsif (dt(2*i+1).rail1='1' and dt(2*i).rail1='1') then 
			q(i).rail0:='0';
			q(i).rail1:='0';
			q(i).rail2:='0';
			q(i).rail3:='1';
		else
			q(i).rail0:='0';
			q(i).rail1:='0';
			q(i).rail2:='0';
			q(i).rail3:='0';
		end if;
	end loop;
	return q;
end to_QR; 

--function to_TR(s: std_logic_vector) return three_RAIL_LOGIC is
--variable st: STD_LOGIC_VECTOR(1 downto 0) := s;
--variable q : three_RAIL_LOGIC;
--begin 
--	if (st(1)='0' and st(0)='0') then 
--		q.rail0:='1';
--		q.rail1:='0';
--		q.rail2:='0';
--	elsif (st(1)='0' and st(0)='1') then 
--		q.rail0:='0';
--		q.rail1:='1';
--		q.rail2:='0';	
--	elsif (st(1)='1' and st(0)='0') then 
--		q.rail0:='0';
--		q.rail1:='0';
--		q.rail2:='1';	
--	end if;
--	return q; 
--end to_TR;
 
--function to_SL(q: three_RAIL_LOGIC) return	std_logic_vector is
--variable s:std_logic_vector(1 downto 0);
--begin
--	if q.rail0='1' and q.rail1='0' and q.rail2='0' then
--		s(1):='0';
--		s(0):='0';
--	elsif q.rail0='0' and q.rail1='1' and q.rail2='0' then
--		s(1):='0';
--		s(0):='1';
--	elsif q.rail0='0' and q.rail1='0' and q.rail2='1' then
--		s(1):='1';
--		s(0):='0';
--	else
--		s(1):='U';
--		s(0):='U';
--	end if;
--	return s;
--end to_SL;							

end NCL_functions;