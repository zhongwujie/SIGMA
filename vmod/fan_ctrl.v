//##########################################################
// Generated Fowarding Adder Network Controller (FAN topology routing)
// Author: Eric Qin
// Contact: ecqin@gatech.edu
//##########################################################


module fan_ctrl # (
	parameter DATA_TYPE =  24 ,
	parameter NUM_PES =  16 ,
	parameter LOG2_PES =  4 ) (
	clk,
	rst,
	i_vn,
	i_stationary,
	i_data_valid,
	o_reduction_add,
	o_reduction_cmd,
	o_reduction_sel,
	o_reduction_valid
);
	input clk;
	input rst;
	input [NUM_PES*LOG2_PES-1: 0] i_vn; // different partial sum bit seperator
	input i_stationary; // if input data is for stationary or streaming
	input i_data_valid; // if input data is valid or not
	output reg [(NUM_PES-1)-1:0] o_reduction_add; // determine to add or not
	output reg [3*(NUM_PES-1)-1:0] o_reduction_cmd; // reduction command (for VN commands)
	output reg [7 : 0] o_reduction_sel; // select bits for FAN topology
	output reg o_reduction_valid; // if reduction output from FAN is valid or not

	// reduction cmd and sel control bits (not flopped for timing yet)
	reg [(NUM_PES-1)-1:0] r_reduction_add;
	reg [3*(NUM_PES-1)-1:0] r_reduction_cmd;
	reg [7 : 0] r_reduction_sel;


	// diagonal flops for timing fix across different levels in tree (add_en signal)
	reg [7 : 0] r_add_lvl_0;
	reg [7 : 0] r_add_lvl_1;
	reg [5 : 0] r_add_lvl_2;
	reg [3 : 0] r_add_lvl_3;


	// diagonal flops for timing fix across different levels in tree (cmd signal)
	reg [23 : 0] r_cmd_lvl_0;
	reg [23 : 0] r_cmd_lvl_1;
	reg [17 : 0] r_cmd_lvl_2;
	reg [11 : 0] r_cmd_lvl_3;


	// diagonal flops for timing fix across different levels in tree (sel signal)
	reg [11 : 0] r_sel_lvl_2;
	reg [15 : 0] r_sel_lvl_3;


	// timing alignment for i_vn delay and for output valid
	reg [2*NUM_PES*LOG2_PES-1:0] r_vn;
	reg [NUM_PES*LOG2_PES-1:0] w_vn;
	reg [4 : 0 ] r_valid;


	genvar i, x;;
	// add flip flops to delay i_vn
	generate
		for (i=0; i < 2; i=i+1) begin : vn_ff
			if (i == 0) begin: pass
				always @ (posedge clk) begin
					if (rst == 1'b1) begin
						r_vn[(i+1)*NUM_PES*LOG2_PES-1:i*NUM_PES*LOG2_PES] <= 'd0;
					end else begin
						r_vn[(i+1)*NUM_PES*LOG2_PES-1:i*NUM_PES*LOG2_PES] <= i_vn;
					end
				end
			end else begin: flop
				always @ (posedge clk) begin
					if (rst == 1'b1) begin
						r_vn[(i+1)*NUM_PES*LOG2_PES-1:i*NUM_PES*LOG2_PES] <= 'd0;
					end else begin
						r_vn[(i+1)*NUM_PES*LOG2_PES-1:i*NUM_PES*LOG2_PES] <= r_vn[i*NUM_PES*LOG2_PES-1:(i-1)*NUM_PES*LOG2_PES];
					end
				end
			end
		end
	endgenerate

	// assign last flop to w_vn
	always @(*) begin
		w_vn = r_vn[2*NUM_PES*LOG2_PES-1:1*NUM_PES*LOG2_PES];
	end


	// generating control bits for lvl: 0
	// Note: lvl 0 and 1 do not require sel bits
	generate
		for (x=0; x < 8; x=x+1) begin: adders_lvl_0
			if (x == 0) begin: l_edge_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[0+x] = 'd0;
						r_reduction_cmd[3*0+3*x+:3] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[0+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[0+x] = 1'b0;
							end


							if (w_vn[(2*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+2)*LOG2_PES+:LOG2_PES] && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b101; // both vn done
							end else if (w_vn[(2*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+2)*LOG2_PES+:LOG2_PES] && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b000; // nothing
							end
						end else begin
							r_reduction_add[0+x] = 1'b0;
							r_reduction_cmd[3*0+3*x+:3] = 3'b000; // nothing
						end

					end
				end
			end else if (x == 7) begin: r_edge_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[0+x] = 'd0;
						r_reduction_cmd[3*0+3*x+:3] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[0+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[0+x] = 1'b0;
							end


							if (w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+-1)*LOG2_PES+:LOG2_PES] && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b101; // both vn done
							end else if (w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+-1)*LOG2_PES+:LOG2_PES] && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b100; // right vn done
							end else begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b000; // nothing
							end

						end else begin
							r_reduction_add[0+x] = 1'b0;
							r_reduction_cmd[3*0+3*x+:3] = 3'b000; // nothing
						end

					end
				end
			end else begin: normal
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[0+x] = 'd0;
						r_reduction_cmd[3*0+3*x+:3] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[0+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[0+x] = 1'b0;
							end


							if ((w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(2*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+2)*LOG2_PES+:LOG2_PES]) && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(2*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+2)*LOG2_PES+:LOG2_PES]) && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b100; // right vn done
							end else if ((w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(2*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(2*x+2)*LOG2_PES+:LOG2_PES]) && w_vn[(2*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(2*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*0+3*x+:3] = 3'b001; // bypass
							end

						end else begin
							r_reduction_add[0+x] = 1'b0;
					r_reduction_cmd[3*0+3*x+:3] = 3'b000; // nothing
						end

					end
				end
			end
		end
	endgenerate

	// generating control bits for lvl: 1
	// Note: lvl 0 and 1 do not require sel bits
	generate
		for (x=0; x < 4; x=x+1) begin: adders_lvl_1
			if (x == 0) begin: l_edge_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[8+x] = 'd0;
						r_reduction_cmd[3*8+3*x+:3] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[8+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[8+x] = 1'b0;
							end


							if ((w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+1)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+2)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(4*x+2)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b100; // right vn done
							end else if ((w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+1)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b000; // nothing
							end
						end else begin
							r_reduction_add[8+x] = 1'b0;
							r_reduction_cmd[3*8+3*x+:3] = 3'b000; // nothing
						end

					end
				end
			end else if (x == 3) begin: r_edge_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[8+x] = 'd0;
						r_reduction_cmd[3*8+3*x+:3] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[8+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[8+x] = 1'b0;
							end


							if ((w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+1)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+2)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+-1)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+1)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+-1)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b011; // left vn done
							end else if ((w_vn[(4*x+2)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b100; // right vn done
							end else begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b000; // nothing
							end

						end else begin
							r_reduction_add[8+x] = 1'b0;
							r_reduction_cmd[3*8+3*x+:3] = 3'b000; // nothing
						end

					end
				end
			end else begin: normal
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[8+x] = 'd0;
						r_reduction_cmd[3*8+3*x+:3] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[8+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[8+x] = 1'b0;
							end


							if ((w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+1)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+2)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(4*x+2)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+3)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b100; // right vn done
							end else if ((w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] == w_vn[(4*x+1)*LOG2_PES+:LOG2_PES]) && (w_vn[(4*x+0)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+-1)*LOG2_PES+:LOG2_PES]) && w_vn[(4*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(4*x+2)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*8+3*x+:3] = 3'b000; // nothing
							end

						end else begin
							r_reduction_add[8+x] = 1'b0;
					r_reduction_cmd[3*8+3*x+:3] = 3'b000; // nothing
						end

					end
				end
			end
		end
	endgenerate

	// generating control bits for lvl: 2
	// Note: lvl 0 and 1 do not require sel bits
	generate
		for (x=0; x < 2; x=x+1) begin: adders_lvl_2
			if (x == 0) begin: l_edge_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[12+x] = 'd0;
						r_reduction_cmd[3*12+3*x+:3] = 'd0;
						r_reduction_sel[(x*2)+0+:2] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+4)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[12+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[12+x] = 1'b0;
							end


							if ((w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+2)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+8)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+2)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+4)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+3)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+8)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+6)*LOG2_PES+:LOG2_PES])  && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+3)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b100; // right vn done
							end else if ((w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+2)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+2)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+4)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b000; // nothing
							end
						end else begin
							r_reduction_add[12+x] = 1'b0;
							r_reduction_cmd[3*12+3*x+:3] = 3'b000; // nothing
						end

						// generate left select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*2)+0+:1] = 'd0;
							end else begin
								r_reduction_sel[(x*2)+0+:1] = 'd1;
							end
						end else begin
							r_reduction_sel[(x*2)+0+:2] = 'd0;
						end


						// generate right select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+4)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*2)+1+:1] = 'd1;
							end else begin
								r_reduction_sel[(x*2)+1+:1] = 'd0;
							end
						end else begin
							r_reduction_sel[(x*2)+0+:2] = 'd0;
						end

					end
				end
			end else if (x == 1) begin: r_edge_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[12+x] = 'd0;
						r_reduction_cmd[3*12+3*x+:3] = 'd0;
						r_reduction_sel[(x*2)+0+:2] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+4)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[12+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[12+x] = 1'b0;
							end


							if ((w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+2)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+2)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+4)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+3)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+2)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+2)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b011; // left vn done
							end else if ((w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+3)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b100; // right vn done
							end else begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b000; // nothing
							end

						end else begin
							r_reduction_add[12+x] = 1'b0;
							r_reduction_cmd[3*12+3*x+:3] = 3'b000; // nothing
						end

						// generate left select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*2)+0+:1] = 'd0;
							end else begin
								r_reduction_sel[(x*2)+0+:1] = 'd1;
							end
						end else begin
							r_reduction_sel[(x*2)+0+:2] = 'd0;
						end


						// generate right select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+4)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*2)+1+:1] = 'd1;
							end else begin
								r_reduction_sel[(x*2)+1+:1] = 'd0;
							end
						end else begin
							r_reduction_sel[(x*2)+0+:2] = 'd0;
						end

					end
				end
			end else begin: normal
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[12+x] = 'd0;
						r_reduction_cmd[3*12+3*x+:3] = 'd0;
						r_reduction_sel[(x*2)+0+:2] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+4)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[12+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[12+x] = 1'b0;
							end


							if ((w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+2)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+8)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+6)*LOG2_PES+:LOG2_PES])  && (w_vn[(8*x+2)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+4)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+3)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+8)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+6)*LOG2_PES+:LOG2_PES])  && (w_vn[(8*x+5)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+3)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b100; // right vn done
							end else if ((w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+2)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+1)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+-1)*LOG2_PES+:LOG2_PES]) && (w_vn[(8*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(8*x+2)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*12+3*x+:3] = 3'b000; // nothing
							end

						end else begin
							r_reduction_add[12+x] = 1'b0;
					r_reduction_cmd[3*12+3*x+:3] = 3'b000; // nothing
						end

						// generate left select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+1)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*2)+0+:1] = 'd0;
							end else begin
								r_reduction_sel[(x*2)+0+:1] = 'd1;
							end
						end else begin
							r_reduction_sel[(x*2)+0+:2] = 'd0;
						end


						// generate right select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(8*x+4)*LOG2_PES+:LOG2_PES] == w_vn[(8*x+6)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*2)+1+:1] = 'd1;
							end else begin
								r_reduction_sel[(x*2)+1+:1] = 'd0;
							end
						end else begin
							r_reduction_sel[(x*2)+0+:2] = 'd0;
						end

					end
				end
			end
		end
	endgenerate

	// generating control bits for lvl: 3
	generate
		for (x=0; x < 1; x=x+1) begin: adders_lvl_3
			if (x == 0) begin: middle_case
				always @ (*) begin
					if (rst == 1'b1) begin
						r_reduction_add[14+x] = 'd0;
						r_reduction_cmd[3*14+3*x+:3] = 'd0;
						r_reduction_sel[(x*4)+4+:4] = 'd0;
					end else begin
						// generate cmd logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(16*x+7)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+8)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_add[14+x] = 1'b1; // add enable
							end else begin
								r_reduction_add[14+x] = 1'b0;
							end


							if ((w_vn[(16*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+4)*LOG2_PES+:LOG2_PES]) && (w_vn[(16*x+11)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+12)*LOG2_PES+:LOG2_PES]) && (w_vn[(16*x+4)*LOG2_PES+:LOG2_PES] != w_vn[(16*x+8)*LOG2_PES+:LOG2_PES]) && (w_vn[(16*x+11)*LOG2_PES+:LOG2_PES] != w_vn[(16*x+7)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*14+3*x+:3] = 3'b101; // both vn done
							end else if ((w_vn[(16*x+11)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+12)*LOG2_PES+:LOG2_PES]) && (w_vn[(16*x+11)*LOG2_PES+:LOG2_PES] != w_vn[(16*x+7)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*14+3*x+:3] = 3'b100; // right vn done
							end else if ((w_vn[(16*x+3)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+4)*LOG2_PES+:LOG2_PES]) && (w_vn[(16*x+8)*LOG2_PES+:LOG2_PES] != w_vn[(16*x+4)*LOG2_PES+:LOG2_PES])) begin
								r_reduction_cmd[3*14+3*x+:3] = 3'b011; // left vn done
							end else begin
								r_reduction_cmd[3*14+3*x+:3] = 3'b000; // nothing
							end

						end else begin
							r_reduction_add[14+x] = 1'b0;
							r_reduction_cmd[3*14+3*x+:3] = 3'b000; // nothing
						end

						// generate left select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(16*x+7)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+3)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*4)+4+:2] = 'd0;
							end else if (w_vn[(16*x+7)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+5)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*4)+4+:2] = 'd1;
							end else begin
								r_reduction_sel[(x*4)+4+:2] = 'd2;
							end
						end else begin
							r_reduction_sel[(x*4)+4+:4] = 'd0;
						end


						// generate right select logic
						if (r_valid[1] == 1'b1) begin
							if (w_vn[(16*x+8)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+12)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*4)+6+:2] = 'd2;
							end else if (w_vn[(16*x+8)*LOG2_PES+:LOG2_PES] == w_vn[(16*x+10)*LOG2_PES+:LOG2_PES]) begin
								r_reduction_sel[(x*4)+6+:2] = 'd1;
							end else begin
								r_reduction_sel[(x*4)+6+:2] = 'd0;
							end
						end else begin
							r_reduction_sel[(x*4)+4+:4] = 'd0;
						end

					end
				end
			end
		end
	endgenerate



	// generate diagonal flops for cmd and sel timing alignment
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_add_lvl_0 <= 'd0;
			r_add_lvl_1 <= 'd0;
			r_add_lvl_2 <= 'd0;
			r_add_lvl_3 <= 'd0;


			r_cmd_lvl_0 <= 'd0;
			r_cmd_lvl_1 <= 'd0;
			r_cmd_lvl_2 <= 'd0;
			r_cmd_lvl_3 <= 'd0;


			r_sel_lvl_2 <= 'd0;
			r_sel_lvl_3 <= 'd0;
		end else begin
			r_add_lvl_0[7:0] <= r_reduction_add[7:0];
			r_add_lvl_1[3:0] <= r_reduction_add[11:8];
			r_add_lvl_1[7:4] <= r_add_lvl_1[3:0];
			r_add_lvl_2[1:0] <= r_reduction_add[13:12];
			r_add_lvl_2[3:2] <= r_add_lvl_2[1:0];
			r_add_lvl_2[5:4] <= r_add_lvl_2[3:2];
			r_add_lvl_3[0:0] <= r_reduction_add[14:14];
			r_add_lvl_3[1:1] <= r_add_lvl_3[0:0];
			r_add_lvl_3[2:2] <= r_add_lvl_3[1:1];
			r_add_lvl_3[3:3] <= r_add_lvl_3[2:2];


			r_cmd_lvl_0[23:0] <= r_reduction_cmd[23:0];
			r_cmd_lvl_1[11:0] <= r_reduction_cmd[35:24];
			r_cmd_lvl_1[23:12] <= r_cmd_lvl_1[11:0];
			r_cmd_lvl_2[5:0] <= r_reduction_cmd[41:36];
			r_cmd_lvl_2[11:6] <= r_cmd_lvl_2[5:0];
			r_cmd_lvl_2[17:12] <= r_cmd_lvl_2[11:6];
			r_cmd_lvl_3[2:0] <= r_reduction_cmd[44:42];
			r_cmd_lvl_3[5:3] <= r_cmd_lvl_3[2:0];
			r_cmd_lvl_3[8:6] <= r_cmd_lvl_3[5:3];
			r_cmd_lvl_3[11:9] <= r_cmd_lvl_3[8:6];


			r_sel_lvl_2[3:0] <= r_reduction_sel[3:0];
			r_sel_lvl_2[7:4] <= r_sel_lvl_2[3:0];
			r_sel_lvl_2[11:8] <= r_sel_lvl_2[7:4];
			r_sel_lvl_3[3:0] <= r_reduction_sel[7:4];
			r_sel_lvl_3[7:4] <= r_sel_lvl_3[3:0];
			r_sel_lvl_3[11:8] <= r_sel_lvl_3[7:4];
			r_sel_lvl_3[15:12] <= r_sel_lvl_3[11:8];
		end
	end


	// Adjust output valid timing and logic
	always @ (posedge clk) begin
		if (i_stationary == 1'b0 && i_data_valid == 1'b1) begin
			r_valid[0] <= 1'b1;
		end else begin
			r_valid[0] <= 1'b0;
		end
	end

	generate
		for (i=0; i < 4; i=i+1) begin
			always @ (posedge clk) begin
				if (rst == 1'b1) begin
					r_valid[i+1] <= 1'b0;
				end else begin
					r_valid[i+1] <= r_valid[i];
				end
			end
		end
	endgenerate

	always @ (*) begin
		if (rst == 1'b1) begin
			o_reduction_valid <= 1'b0;
		end else begin
			o_reduction_valid <= r_valid[3];
		end
	end

	// assigning diagonally flopped cmd and sel
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			o_reduction_add <= 'd0;
			o_reduction_cmd <= 'd0;
			o_reduction_sel <= 'd0;
		end else begin
			o_reduction_add <= {r_add_lvl_3[3:3],r_add_lvl_2[5:4],r_add_lvl_1[7:4],r_add_lvl_0[7:0]};
			o_reduction_cmd <= {r_cmd_lvl_3[11:9],r_cmd_lvl_2[17:12],r_cmd_lvl_1[23:12],r_cmd_lvl_0[23:0]};
			o_reduction_sel <= {r_sel_lvl_3[15:12],r_sel_lvl_2[11:8]};
		end
	end

endmodule
