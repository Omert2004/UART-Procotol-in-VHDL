--------------------------------------------------------------------------------------------------
--      Project Name            : UART Transmission Using VHDL                                  --
--      System/Block Name 		: RX_Block                                                      --
--      Design Engineer      	: Oğuz Mert Coşkun                                              --
--      Date                    : 10.09.2025                                                    --
--      Short Description 	   	: Handles UART Reception                                        --
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

entity RX_Block is
generic(Clk_Freq 		  : Integer := 50000000;
		Baudrate 		  : Integer := 115200;
		Stop_Bit_Config	  : Integer:= 0;  --0 1bit, 1 2bit, 2 1.5bit
		Parity_Bit_Config : Integer:= 0); --0 even 1 odd 2 no parity
		
port(clk_in  	    	:in std_logic;
     rst	     		:in std_logic;
	 serial_in   		:in std_logic;
	 rx_busy_flag		:out std_logic;
	 rx_received_data	:out std_logic_vector(7 downto 0);		--After reception is completed, the received data frame is sent out
	 received_data_valid:out std_logic);						--After reception is completed, the received data is valid
	 
end RX_Block;

architecture Behaviour of RX_Block is

signal clk_baud_tick	 :std_logic:= '0'; 
signal rx_clk_counter	 :Integer;         						--Used for clk_baud_period by counting clk_in
constant clk_baud_period :Integer := Clk_Freq / Baudrate;		--The period for bit reception

signal rx_stop_clk_counter : Integer;							--At second phase of STOP_STATE, used for clk_baud_period by counting clk_in

Type StateType is (IDLE_STATE, START_STATE, DATA_STATE, PARITY_STATE, STOP_STATE);
signal state_rx_partition : StateType := IDLE_STATE;

signal data_bit_indx	 	 : Integer;							--Index for data frame parsing in bits
signal temp_received_data	 : std_logic_vector(7 downto 0);	--Parse the received data frame bits to assign rx_received_data

signal xor_parity 		 	 : std_logic;						--During data frame reception, calculate whether the parity is odd or even
signal parity_valid 	 	 : std_logic;						--If parity bit matches with data parity, say valid

signal stop_bit_period   	 : Integer := 0;					--The clk_baud_periods for 1, 1.5 and 2 stop bits 
signal stop_state_period_type: std_logic := '0';				--At STOP_STATE, first count clk_baud_period, after that count (stop_bit_period-clk_baud_period/2)
 
signal stop_bit_err	 		 : std_logic := '0';				--Whether stop_bit is received during whole stop_bit_period




begin
 
	PROC_RX_RECEPTION: process(clk_in, rst)
	begin 
	if rst = '0' then													--Reset values of all the signals
			rx_clk_counter 		<= 0;
			rx_stop_clk_counter <= 0;
			state_rx_partition  <= IDLE_STATE;
			data_bit_indx 		<= 0;
			xor_parity 			<= '0';
			parity_valid		<= '0';
			rx_busy_flag 		<= '0';
			temp_received_data	<= (others => '0');
			rx_received_data	<= (others => '0');
			stop_bit_err		<= '0';
			stop_state_period_type<= '0';
			received_data_valid	<= '0';
			
	elsif rising_edge(clk_in) then
		case state_rx_partition is
			when IDLE_STATE => 
		
				data_bit_indx 	  <= 0;									--Initalize the signals
				xor_parity 	  	  <= '0';								
				parity_valid	  <= '0';
				rx_busy_flag 	  <= '0';
				temp_received_data	<= (others => '0');
				stop_state_period_type			<= '0';
				received_data_valid<= '0';
	
				
				if   (Stop_Bit_Config = 0) then							--Initalize Stop Bit Baud Period
					stop_bit_period <=  clk_baud_period;
				elsif(Stop_Bit_Config = 1) then
					stop_bit_period <= clk_baud_period + clk_baud_period/2;
				elsif(Stop_Bit_Config = 2) then
					stop_bit_period <= clk_baud_period + clk_baud_period;
				end if;
		
				if( serial_in = '0') then	--Falling Edge method  Wait for start bit
					state_rx_partition <= START_STATE;
					rx_busy_flag <= '1';
				end if;
				

			when START_STATE =>	
				if(rx_clk_counter = clk_baud_period/2) then
					rx_clk_counter 		<= 0;
					clk_baud_tick  		<= '1';
					
					state_rx_partition  <= DATA_STATE;
				else 
					rx_clk_counter <= rx_clk_counter + 1;
					if(serial_in = '0') then 							--Check whether the potential 0 bit is start bit
						--still 0
					else
						-- in half period it rose to 1
						state_rx_partition <= IDLE_STATE;
						rx_busy_flag   <= '0';
						rx_clk_counter <= 0;
					end if;
				end if;
			
			when DATA_STATE => 
				if(rx_clk_counter = clk_baud_period) then
					rx_clk_counter <=0;
					clk_baud_tick <= '1';
					
					if(data_bit_indx < 8) then
						temp_received_data(data_bit_indx)	<= serial_in;	-- Parse from LSB to MSB
						xor_parity   <= xor_parity xor serial_in;  			--Calculate the xor_parity to get parity bit beforehand
						data_bit_indx <= data_bit_indx + 1;
						
						if(data_bit_indx = 7) then							--After assigning temp_received_data's 7th bit, go to next state 
							if(Parity_Bit_Config = 2) then 					--If no parity skip to STOP STATE
								state_rx_partition <= STOP_STATE;
							else 
								state_rx_partition <= PARITY_STATE;
							end if;
						end if;						
					end if;
				else 
					rx_clk_counter <= rx_clk_counter + 1;
				end if;

				if(clk_baud_tick = '1') then
					clk_baud_tick <= '0';
				end if;
				
			
			when PARITY_STATE => 
			
				if(rx_clk_counter = clk_baud_period) then
					rx_clk_counter <= 0;
					clk_baud_tick  <= '1';							
	
					state_rx_partition  <= STOP_STATE;		-- One baud period later go to STOP_STATE
															--Check parity bit with Parity_Bit_Config
					if(Parity_Bit_Config = 0) then			--IF parity is even
						if(serial_in <= xor_parity) then	--Received Parity Bit
							parity_valid <= '1';
						else 
							parity_valid <= '0';		
						end if;
					elsif(Parity_Bit_Config = 1) then		--If parity is odd
						if(serial_in = not xor_parity) then
							parity_valid <= '1';
						else 
							parity_valid <= '0';		
						end if;
					end if;
				else 
					rx_clk_counter <= rx_clk_counter + 1;
				end if;
				
				if(clk_baud_tick = '1') then
					clk_baud_tick  <= '0';				
				end if;
				
			when STOP_STATE =>
				if stop_state_period_type = '0' then					--First process 1 baud period to get first sample
					if(rx_clk_counter = clk_baud_period) then
						rx_clk_counter 		<= 0;
						clk_baud_tick  		<= '1';
						
						if(serial_in = '1') then 						--Check sample (stop bit) whether is 1, if true check remaining stop_bit_period
							--still 1
							stop_state_period_type	<= '1';				
						else
							rx_busy_flag <= '0';
							stop_bit_err <= '1';
							state_rx_partition <= IDLE_STATE;
							rx_received_data	<= (others => '0');
							
						end if;
					else 
						rx_clk_counter <= rx_clk_counter + 1;
					end if;
				elsif stop_state_period_type = '1' then 				--After receiving 1 (stop bit) , check whether it stay 1 remaninig stop_bit_period 
					if(rx_stop_clk_counter = (stop_bit_period - clk_baud_period/2)-1) then
						rx_stop_clk_counter <= 0;
						
						rx_received_data <= temp_received_data;			--Print the received data after completing data Reception
						received_data_valid <='1';
						
						state_rx_partition <= IDLE_STATE;
						rx_busy_flag <= '0';
					else 
						rx_stop_clk_counter <= rx_stop_clk_counter + 1;
						if(serial_in = '1') then 						--check whether the potential 0 bit is start bit
							--still 1
						else
							--Dropped to 0 at remanining stop period
							state_rx_partition <= IDLE_STATE;
							stop_bit_err <= '1';
							rx_busy_flag <= '0';
							rx_received_data	<= (others => '0');
						end if;
					end if;
				end if;
 		end case;			
	end if;
	end process;
end Behaviour;
					

	