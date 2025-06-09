module DigitalCounter #(parameter OLED_WIDTH = 8, 
	parameter DIGIT_COUNT = 3) (
	input logic i_clk,
	input logic i_rst_n,
	input logic i_key_n,
	output wire [DIGIT_COUNT - 1 : 0] o_digit,
	output wire [OLED_WIDTH - 1 : 0] o_led
	);
	
	reg [3:0] counter;
	reg [OLED_WIDTH : 0] decoded_counter;
	logic key_last;
	logic key_clean;
	
	
	always @(posedge i_clk) begin 
		if(!i_rst_n) begin
			counter <= 0;
			key_last <= 0;
			key_clean <= 0;
		end else begin 
			if (key_last && ~key_clean) begin 
				counter <= counter + 1;
			end
		end
	end
	
	always @(posedge i_clk) begin 
		case (counter)
			4'h0: decoded_counter = 8'd64;
			4'h1: decoded_counter = 8'd121;
			4'h2: decoded_counter = 8'd36;
			4'h3: decoded_counter = 8'd48;
			4'h4: decoded_counter = 8'd25;
			4'h5: decoded_counter = 8'd18;
			4'h6: decoded_counter = 8'd82;
			4'h7: decoded_counter = 8'd90;
			default: decoded_counter = 8'd22;
		endcase 
		
		o_digit <= 3'h2;
	end
	
	endmodule