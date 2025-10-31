--------------------------------------------------------------------------------------------------
--      Project Name            : UART Transmission Using VHDL                                  --
--      System/Block Name 		: TX_Block                                                      --
--      Design Engineer      	: Oğuz Mert Coşkun                                              --
--      Date                    : 08.09.2025                                                    --
--      Short Description 	   	: Handles UART Transmission                                     --
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

entity TX_Block is
generic(Clk_Freq 		  : Integer := 50000000;
		Baudrate 		  : Integer := 115200;
		Stop_Bit_Config	  : Integer:= 0;  --0 1bit, 1 2bit, 2 1.5bit
		Parity_Bit_Config : Integer:= 0); --0 even 1 odd 2 no parity
		
port(clk_in  	    	:in std_logic;
     rst	     		:in std_logic;
	 start_tx_command 	:in std_logic;
	 data_frame_in  	:in std_logic_vector(7 downto 0);
	 serial_out   		:out std_logic;
	 tx_busy_flag		:out std_logic);
	 
end TX_Block;

architecture Behaviour of TX_Block is

signal clk_baud_tick	 :std_logic:= '0'; 
signal tx_clk_counter	 :Integer;         
constant clk_baud_period :Integer := Clk_Freq / Baudrate;

Type StateType is (IDLE_STATE, START_STATE, DATA_STATE, PARITY_STATE, STOP_STATE);
signal state_tx_partition : StateType := IDLE_STATE;

signal data_bit_indx	: Integer;

signal tx_valid  		:std_logic;

signal temp_parity 		: std_logic := '0';

signal stop_bit_period : Integer := 0;

begin 

	PROC_TX_TRANSMISSON: process(clk_in,rst)
	begin
		if rst = '0' then
			tx_clk_counter 		<= 0;
			state_tx_partition  <= IDLE_STATE;
			data_bit_indx 		<= 0;
			temp_parity 		<= '0';
			serial_out			<= '1';
			tx_busy_flag 		<= '0';
			tx_valid	 		<= '0';
		elsif(rising_edge(clk_in)) then
			case state_tx_partition is
				when IDLE_STATE  => 					--Initialize Data Frame Size, Data Frame index, temp_parity, Stop Bit Baud Period beforehand
					serial_out		  <= '1';  			--Keep sending High for IDLE_STATE
					
					data_bit_indx 	  <= 0;				--Initalize data frame index
					
					temp_parity 	  <= '0';			-- Initialize temp parities
					tx_valid		  <= '0';
					
					if (Stop_Bit_Config = 0) then		--Initalize Stop Bit Baud Period
						stop_bit_period <=  clk_baud_period;
					elsif(Stop_Bit_Config = 1) then
						stop_bit_period <= clk_baud_period + clk_baud_period/2;
					elsif(Stop_Bit_Config = 2) then
						stop_bit_period <= clk_baud_period + clk_baud_period;
					else
						report "Stop Bit Config is not taken properly";	
					end if;
					
					if(start_tx_command = '1') then 	--If Start Command is received, go to Start State
						state_tx_partition 	 <= START_STATE;
						tx_busy_flag <= '1' ;
					end if;
					
				when  START_STATE =>  					--Send Start Bit	
					serial_out 	 	   <= '0'; 
					
					if(tx_clk_counter = clk_baud_period) then
						tx_clk_counter <= 0;
						clk_baud_tick  <= '1';
						state_tx_partition 	<= DATA_STATE;
						
						serial_out 	  <= data_frame_in(data_bit_indx);					-- Parse LSB for data
						temp_parity   <= temp_parity xor data_frame_in(data_bit_indx);  --Calculate the temp_parity to get parity bit beforehand
						data_bit_indx <= data_bit_indx + 1;
					else 
						tx_clk_counter <= tx_clk_counter + 1;
					end if;
					
					
				when DATA_STATE =>						--Send Data Frame
					
					if(tx_clk_counter = clk_baud_period) then
						tx_clk_counter <=0;
						clk_baud_tick <= '1';
						
						if(data_bit_indx < 8) then
							serial_out 	  <= data_frame_in(data_bit_indx);					-- Parse from LSB + 1 to MSB
							temp_parity   <= temp_parity xor data_frame_in(data_bit_indx);  --Calculate the temp_parity to get parity bit beforehand
							data_bit_indx <= data_bit_indx + 1; 				
						else	
							if(Parity_Bit_Config = 2) then 						--If no parity skip to STOP STATE
								state_tx_partition <= STOP_STATE;
							else 
								state_tx_partition <= PARITY_STATE;
																				-- Partity Bit Generation using Parity_Bit_Config and temp_parity
								if(Parity_Bit_Config = 0) then 					--IF parity is even
									if(temp_parity = '1') then
										serial_out <= '1';
									else 
										serial_out <= '0';
									end if;
								else 											-- If parity is odd
									if(temp_parity = '1') then
										serial_out <= '0';
									else 
										serial_out <= '1';
									end if;
								end if;
							end if;
						end if;
						
					else 
						tx_clk_counter <= tx_clk_counter + 1;
					end if;
					
					if(clk_baud_tick = '1') then
						clk_baud_tick <= '0';
					end if;
						
					
				when PARITY_STATE => 							--Send parity bit 			
					if(tx_clk_counter = clk_baud_period) then
						tx_clk_counter <= 0;
						clk_baud_tick  <= '1';
						serial_out <= '1';
						state_tx_partition  <= STOP_STATE;
					else 
						tx_clk_counter <= tx_clk_counter + 1;
					end if;
					
					if(clk_baud_tick = '1') then
						clk_baud_tick  <= '0';				
					end if;
					
				when STOP_STATE =>   		    				--Send stop bit according to stop_bit_period
					if(tx_clk_counter = stop_bit_period) then
						tx_clk_counter <= 0;
						clk_baud_tick <= '1';
						tx_valid	  <= '1';
						state_tx_partition <= IDLE_STATE;
						tx_busy_flag <='0';
						
						if(clk_baud_tick = '1') then
						clk_baud_tick <= '0';
						end if;
					
					else 
						tx_clk_counter <= tx_clk_counter + 1;
					end if;
			end case;	
		end if;	
	end process;
	
end Behaviour;
