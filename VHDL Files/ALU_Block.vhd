library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
			

entity ALU_Block is
	
	port(clk_in: in STD_LOGIC;
		A, B 		: in std_logic_vector(7 downto 0);
		rst			: in STD_LOGIC;
		Op 			: in std_logic_vector(7 downto 0);
		control_valid: in STD_LOGIC;
		F 			: out std_logic_vector(7 downto 0);
		ALU_Complete: out STD_LOGIC);
end;

architecture Behaviour of ALU_Block is

type OPERATION_STATES is ( FZero,AplusB, AminusB, Adividedby2, Bdividedby2,  
							BminusA,Amultiply2, Bmultiply2, OnlyA, OnlyB);
signal state_operation : OPERATION_STATES;

signal sig_A : signed(7 downto 0);
signal sig_B : signed(7 downto 0);

type ALU_STATES is (IDLE_STATE,PROCESS_STATE);
signal state_alu : ALU_STATES:= IDLE_STATE;
begin
	PROC_ALU: process(clk_in,rst)
	begin
	if(rst = '0') then
		state_alu 	 <= IDLE_STATE;
		sig_A 		 <= (others => '0');
		sig_B 		 <= (others => '0');
		F 			 <= (others => '0');
		ALU_Complete <='0';
	elsif(rising_edge(clk_in)) then
		case state_alu is
			when IDLE_STATE => 
				F 			 <= (others => '0');
				ALU_Complete <='0';
				
				if(control_valid = '1') then
					state_alu <= PROCESS_STATE;
					sig_A <= signed(A);
					sig_B <= signed(B);
					
					case Op is
						when x"00" => state_operation <= FZero;
						when x"01" => state_operation <= AplusB;
						when x"02" => state_operation <= AminusB;
						when x"03" => state_operation <= Adividedby2;
						when x"04" => state_operation <= Bdividedby2;
						when x"05" => state_operation <= BminusA;
						when x"06" => state_operation <= Amultiply2;
						when x"07" => state_operation <= Bmultiply2;
						when x"08" => state_operation <= OnlyA;
						when x"09" => state_operation <= OnlyB;
						when others => -- do nothing
					end case;
				end if;
				
			when PROCESS_STATE => 
				case state_operation is
					when Fzero =>
						F <= (others => '0');
						
					when AplusB => 
						F <= std_logic_vector(sig_A + sig_B);
						
					when AminusB =>
						F <= std_logic_vector(sig_A - sig_B);
					
					when Adividedby2 =>
						F <= '0' & A(6 downto 0) ;
					
					when Bdividedby2 =>
						F <= '0' & B(6 downto 0) ;
						
					when BminusA =>
						F <= std_logic_vector(sig_B- sig_A);
						
					when Amultiply2 =>
						F <= A(6 downto 0) & '0';	
					
					when Bmultiply2 =>
						F <= B(6 downto 0) & '0';	
					
					when OnlyA => 
						F <= std_logic_vector(sig_A);
						
					when OnlyB => 
						F <= std_logic_vector(sig_B);	
					
				end case;
				state_alu 	 <= IDLE_STATE;
				ALU_Complete <= '1';
			end case;
	end if;
end process;

end Behaviour;