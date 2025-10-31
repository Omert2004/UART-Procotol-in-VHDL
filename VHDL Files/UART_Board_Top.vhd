library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
			
entity UART_Board_Top is
	port(physical_clk 	  : in std_logic;
		 physical_rx_data : in std_logic;
		 rs232_mode		  : in std_logic;
		 physical_tx_data : out std_logic);
end entity;

architecture Behaviour of UART_Board_Top is

--RX_Block Signals
signal rx_busy_flag		: std_logic;
signal rx_received_data	:std_logic_vector(7 downto 0);
signal received_data_valid: std_logic;

--TX_Block Signals
signal tx_busy_flag		: std_logic;

--RX_Controller Signals
signal received_message_valid : std_logic; 
signal operand_1  	  : std_logic_vector(7 downto 0);
signal operand_2  	  : std_logic_vector(7 downto 0);
signal opcode	      : std_logic_vector(7 downto 0);
signal controller_valid : std_logic;
signal twospluschecksum : std_logic_vector(7 downto 0);

--ALU_Block Signals
signal F			 : std_logic_vector(7 downto 0);
signal ALU_Complete  : std_logic;

signal sig_pll_clk	 : std_logic;
signal sig_pll_locked: std_logic;
signal logic_zero 	 : std_logic := '0';

	component my_pll is
			port (
				refclk   : in  std_logic := '0'; --  refclk.clk
				rst      : in  std_logic := '0'; --   reset.reset
				outclk_0 : out std_logic;        -- outclk0.clk
				locked   : out std_logic         --  locked.export
			);
		end component my_pll;

	component RX_Block
	generic(Clk_Freq 		  : Integer := 50000000;
			Baudrate 		  : Integer := 115200;
			Stop_Bit_Config	  : Integer:= 0;  --0 1bit, 1 2bit, 2 1.5bit
			Parity_Bit_Config : Integer:= 0); --0 even 1 odd 2 no parity
			
		port(clk_in  	      :in std_logic;
			 rst	          :in std_logic;
			 serial_in   	  :in std_logic;
			 rx_busy_flag	  :out std_logic;
			 rx_received_data :out std_logic_vector(7 downto 0);
			 received_data_valid:out std_logic);
	end component;

	component RX_CONTROLLER
		port(clk_in 		  : in std_logic;
			 rst	    	  : in std_logic;
			 msg_in			  : in std_logic_vector(7 downto 0);
			 received_message_valid : in std_logic;
			 operand_1  	  : out std_logic_vector(7 downto 0);
			 operand_2  	  : out std_logic_vector(7 downto 0);
			 opcode	    	  : out std_logic_vector(7 downto 0);
			 controller_valid : out std_logic;
			 twospluschecksum : out std_logic_vector(7 downto 0));
	end component;

	component ALU_Block 
			port(clk_in: in STD_LOGIC;
			rst			: in STD_LOGIC;
			A, B 		: in std_logic_vector(7 downto 0);
			Op 			: in std_logic_vector(7 downto 0);
			control_valid	: in STD_LOGIC;
			F 			: out std_logic_vector(7 downto 0);
			ALU_Complete: out STD_LOGIC);
	end component; 

	component TX_Block
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
	end component;

begin 
	
	--Circuit connections 
	
U_PLL: component my_pll
			port map (
				refclk   					=> physical_clk,   --  refclk.clk
				rst      					=> logic_zero,      --   reset.reset
				outclk_0 					=> sig_pll_clk, -- outclk0.clk
				locked   					=> sig_pll_locked    --  locked.export
				);
	

U_RX: RX_Block generic map(Clk_Freq 		 => 50000000, --50 MHz
							Baudrate 		 => 115200,
							Stop_Bit_Config	 => 0,  -- 1 stop bit
							Parity_Bit_Config=> 1)	-- even parity
				
			port map(clk_in 				 => sig_pll_clk,
					 rst 					 => sig_pll_locked,
					 serial_in 				 => physical_rx_data,
					 rx_busy_flag 			 => rx_busy_flag,
					 rx_received_data 		 => rx_received_data,
					 received_data_valid 	 => received_data_valid);
					 
U_CONTROLLER : RX_CONTROLLER port map(
					clk_in 				     => sig_pll_clk,
		 			rst	  				     => sig_pll_locked,
		 			msg_in 				     => rx_received_data,
		 			received_message_valid   => received_data_valid,
		 			operand_1 			     => operand_1,
		 			operand_2 			     => operand_2,
		 			opcode 				     => opcode,
		 			controller_valid 		 => controller_valid,
					twospluschecksum		 => twospluschecksum);
					
U_ALU: ALU_Block port map(clk_in 			 => sig_pll_clk,
						  rst				 => sig_pll_locked,
						  A		 			 => operand_1,
						  B		 			 => operand_2,
						  Op	 			 => opcode,
						  control_valid 	 => controller_valid,
						  F 				 => F,
						  ALU_Complete 		 => ALU_Complete);

	
U_TX: TX_Block generic map(Clk_Freq 		 => 50000000, --50 MHz
							Baudrate 		 => 115200,
							Stop_Bit_Config	 => 0,  -- 1 stop bit
							Parity_Bit_Config=> 1)	-- even parity
			
			port map(clk_in 				 => sig_pll_clk,
					 rst 					 => sig_pll_locked,
					 start_tx_command 		 => ALU_Complete,
					 data_frame_in 			 => F,
					 serial_out 			 => physical_tx_data,
					 tx_busy_flag 			 => tx_busy_flag);
					 
end Behaviour;
		 