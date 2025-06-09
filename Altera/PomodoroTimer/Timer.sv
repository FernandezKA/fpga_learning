module Timer #(parameter CLK_VALUE = 50_000_000,
	parameter COUNT_DIGIT = 4,
	parameter SEG_NUM = 8
 )(
	input logic i_clk,
	input logic i_rst_n,
	input logic i_key_n,
	output wire [COUNT_DIGIT - 1 : 0] o_digit,
	output wire [SEG_NUM - 1 : 0] o_seg
);

	reg [3 : 0] digit_0 = 0;

always_ff @(posedge i_clk) begin
	if (!i_rst_n) begin
		o_digit <= 4'h0;
		o_seg <= 8'h0;
	end else begin 
		o_digit <= 4'hf;
		o_seg <= 8'h0;
	end
end

endmodule