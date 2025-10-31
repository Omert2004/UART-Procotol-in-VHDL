--------------------------------------------------------------------------------------------------
--      Project Name            : UART Transmission Using VHDL                                  --
--      System/Block Name 		: RX_Controller                                                 --
--      Design Engineer      	: Oğuz Mert Coşkun                                              --
--      Date                    : 10.09.2025                                                    --
--      Short Description 	   	: Checks the received incoming data,							-- 
--								   then forward the data to ALU COMPONENT                       --
--------------------------------------------------------------------------------------------------
--                                                                                              --
--    	Revision          		: $Revision: $                                                  --                                        
--   	Date              		: $Date: $                                                      --                                  
--   	Last Changed By   		: $Author:$                                                     --        
--                                                                                              --
--                                                                                              --
--    	Revisions   Designer            Date                   Description                      --
--      ….                       …                                             …                --
--------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity RX_Controller is
	
	port(clk_in 				: in std_logic;
		 rst	    			: in std_logic;
		 msg_in					: in std_logic_vector(7 downto 0);
		 received_message_valid : in std_logic;
		 operand_1  			: out std_logic_vector(7 downto 0);
		 operand_2  			: out std_logic_vector(7 downto 0);
		 opcode	    			: out std_logic_vector(7 downto 0);
		 controller_valid 		: out std_logic;
		 twospluschecksum		: out std_logic_vector(7 downto 0));
end entity;

architecture Behaviour of RX_Controller is

signal controller_busy : std_logic;						--Flag for controller availability
signal checksum :  std_logic_vector(7 downto 0);
signal twos_complement: std_logic_vector(7 downto 0);  
signal sig_operand1	: 	std_logic_vector(7 downto 0);
signal sig_operand2	: 	std_logic_vector(7 downto 0);
signal sig_opcode	: 	std_logic_vector(7 downto 0);
signal opcode_error :	std_logic;
signal sig_twospluschecksum : std_logic_vector(7 downto 0);
signal cheksum_flag	: 	std_logic;


Type STATE_TYPES is (IDLE_STATE, HEX_1_STATE, HEX_2_STATE, OPERAND_1_STATE, OPERAND_2_STATE, OPCODE_STATE, CHECKSUM_STATE);
signal state_controller :STATE_TYPES := IDLE_STATE;


begin 
PROC_CONTROLLER: process(clk_in, rst) 
	begin
		if (rst = '0') then
			controller_busy  <= '0';
			state_controller <= IDLE_STATE;
			operand_1 		 <= (others => '0');
			operand_2 		 <= (others => '0');
			opcode 			 <= (others => '0');
			checksum 		 <= (others => '0');
			controller_valid 	 <= '0';
			twos_complement  <= (others =>'0');
			sig_twospluschecksum	 <= (others => '0');
			twospluschecksum <= (others => '0');
			cheksum_flag	 <= '0';
			opcode_error 	<= '0';
			
		elsif(rising_edge(clk_in)) then
			case state_controller is
				when IDLE_STATE =>
				
					controller_busy <= '0';
					operand_1 		<= (others => '0');
					operand_2 		<= (others => '0');
					opcode 			<= (others => '0');
					checksum 		<= (others => '0');
					controller_valid 	<= '0';
					twos_complement <= (others =>'0');
					sig_twospluschecksum	 <= (others => '0');
					twospluschecksum	 <= (others => '0');
					cheksum_flag	 <= '0';
					opcode_error 	<= '0';
					
					if(received_message_valid = '1' and controller_busy = '0') then
						if(msg_in = x"41") then
							state_controller <= HEX_1_STATE;	-- Start the process after getting x"41", go to HEX_STATE to expect receiving 
							controller_busy  	<= '1';
						end if;
					end if;
					
				when HEX_1_STATE =>
					if(received_message_valid = '1') then
						if msg_in = x"53" then					-- Go to HEX_2_STATE to receive operand_1
							state_controller <= HEX_2_STATE;
						else 
							-- Expected x"53" is not received 
							state_controller <= IDLE_STATE;
							controller_busy  <= '0';
						end if;
					end if;
						
				when HEX_2_STATE =>								--Go to OPERAND_1_STATE to receive operand_2 after receiving operand_1 
					if(received_message_valid = '1') then
						sig_operand1 <= msg_in;
						state_controller <= OPERAND_1_STATE;
					end if;
					
				when OPERAND_1_STATE => 						--Go to OPERAND_2_STATE to receive opcode after receiving operand_2 
					if(received_message_valid = '1') then
						sig_operand2 <= msg_in;
						state_controller <= OPERAND_2_STATE;
					end if;
					
				when OPERAND_2_STATE => 					
					if(received_message_valid = '1') then 	 --Go to OPCODE_STATE  to receive checksum after receiving opcode
							if(msg_in < x"0A") then
								sig_opcode <= msg_in;
								state_controller <= OPCODE_STATE;
							else 
								opcode_error <= '1';
								state_controller <= IDLE_STATE;
								controller_busy <= '0';
							end if;
					end if;
						
				when OPCODE_STATE => 
					if(received_message_valid = '1') then 	--Go to CHECKSUM_STATE  to receive checksum after receiving opcode
							checksum <= msg_in;
							state_controller <= CHECKSUM_STATE;
							twos_complement <= std_logic_vector((signed'(x"41") + signed'(x"53") + signed(sig_operand1) + signed(sig_operand2) + signed(sig_opcode)));
					end if;
				
				when CHECKSUM_STATE =>		
					
					if cheksum_flag = '0' then
						sig_twospluschecksum <= std_logic_vector(signed(twos_complement) + signed(checksum));
						cheksum_flag <= '1';
				
					elsif(cheksum_flag = '1') then
						if( sig_twospluschecksum = x"00" )  then	-- If Checksum valid, send output to ALU component
							controller_valid <= '1';
							operand_1 <= sig_operand1;
							operand_2 <= sig_operand2;
							opcode 	  <= sig_opcode;
							twospluschecksum <= sig_twospluschecksum;
						else 
							controller_valid <= '0';
						end if;
							state_controller <= IDLE_STATE;
							controller_busy <= '0';
					end if;
			end case;
		end if;
	end process;
						
					
end Behaviour;