`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////

// Design: mult_switch.v
// Author: Eric Qin

// Description: Multiplier switch with local stationary buffer

/////////////////////////////////////////////////////////////////////////

module mult_switch(
	clk, 
	rst,
	i_valid, // input valid signal
	i_data, // input data
	i_stationary, // input control bit whether 
	o_valid, // output valid signal
	o_data // output data
);

	input clk;
	input rst;
	input i_valid;
	input [7:0] i_data;
	input i_stationary;

	output reg o_valid;
	output [23:0] o_data;

	reg [7:0] r_buffer; // buffer to hold stationary value
	reg r_buffer_valid; // valid buffer entry
	
	wire [7:0] w_A;
	wire [7:0] w_B;
	
	// logic to store correct value into the stationary buffer
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_buffer <= 'd0; // clear buffer during reset
			r_buffer_valid <= 1'b0; // invalidate buffer
		end else begin
			if (i_stationary == 1'b1 && i_valid == 1'b1) begin
				r_buffer <= i_data; // latch the stationary value into the switch buffer
				r_buffer_valid <= 1'b1; // validate buffer
			end
		end
	end
		
	assign w_A = (r_buffer_valid == 1'b1 && i_valid == 1'b1) ? i_data : 'd0; // streaming
	assign w_B = (r_buffer_valid == 1'b1 && i_valid == 1'b1) ? r_buffer : 'd0; // stationary
	
	// logic to generate correct output valid signal
	always @ (posedge clk) begin
		if (r_buffer_valid == 1'b1 && i_valid == 1'b1) begin
			o_valid <= 1'b1;
		end else begin
			o_valid <= 1'b0;
		end
	end

	// instantiate multiplier 
	// assign o_data = {{8{w_A[7]}}, w_A} * {{8{w_B[7]}}, w_B};
  assign o_data = w_A * w_B;

endmodule