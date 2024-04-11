//##########################################################
// Generated Fowarding Adder Network (FAN topology)
// Author: Eric Qin
// Contact: ecqin@gatech.edu
//##########################################################


module fan_network # (
	parameter DATA_TYPE =  24 ,
	parameter NUM_PES =  16 ,
	parameter LOG2_PES =  4 ) (
	clk,
	rst,
	i_valid,
	i_data_bus,
	i_add_en_bus,
	i_cmd_bus,
	i_sel_bus,
	o_valid,
	o_data_bus
);
	input clk;
	input rst;
	input i_valid; // valid input data bus
	input [NUM_PES*DATA_TYPE-1 : 0] i_data_bus; // input data bus
	input [(NUM_PES-1)-1 : 0] i_add_en_bus; // adder enable bus
	input [3*(NUM_PES-1)-1 : 0] i_cmd_bus; // command bits for each adder
	input [7 : 0] i_sel_bus; // select bits for FAN topolgy
	output reg [NUM_PES-1 : 0] o_valid; // output valid signal
	output reg [NUM_PES*DATA_TYPE-1 : 0] o_data_bus; // output data bus

	// tree wires (includes binary and forwarding wires)
	wire [ 335  : 0] w_fan_lvl_0;
	wire [ 143  : 0] w_fan_lvl_1;
	wire [ 47  : 0] w_fan_lvl_2;
	wire [ 23  : 0] w_fan_lvl_3;


	// flop forwarding levels across levels to maintain pipeline timing
	reg [47 : 0] r_fan_ff_lvl_0_to_3;
	reg [143 : 0] r_fan_ff_lvl_0_to_2;
	reg [47 : 0] r_fan_ff_lvl_1_to_3;


	// output virtual neuron (completed partial sums) wires for each level and valid bits
	wire [383 : 0] w_vn_lvl_0;
	wire [15 : 0] w_vn_lvl_0_valid;
	wire [191 : 0] w_vn_lvl_1;
	wire [7 : 0] w_vn_lvl_1_valid;
	wire [95 : 0] w_vn_lvl_2;
	wire [3 : 0] w_vn_lvl_2_valid;
	wire [47 : 0] w_vn_lvl_3;
	wire [1 : 0] w_vn_lvl_3_valid;


	// output ff within each level of adder tree to maintain pipeline behavior
	reg [1535 : 0] r_lvl_output_ff;
	reg [63 : 0] r_lvl_output_ff_valid;


	// valid FFs for each level of the adder tree
	reg [5 : 0] r_valid;
	// flop final adder output cmd and values
	reg [DATA_TYPE-1:0] r_final_sum;
	reg r_final_add;
	reg r_final_add2;
	// FAN topology flip flops between forwarding levels to maintain pipeline timing
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_fan_ff_lvl_0_to_3 = 'd0;
			r_fan_ff_lvl_0_to_2 = 'd0;
			r_fan_ff_lvl_1_to_3 = 'd0;
		end else begin
			r_fan_ff_lvl_0_to_3[23:0] = r_fan_ff_lvl_0_to_2[71:48];
			r_fan_ff_lvl_0_to_3[47:24] = r_fan_ff_lvl_0_to_2[95:72];
			r_fan_ff_lvl_0_to_2[23:0] = w_fan_lvl_0[71:48];
			r_fan_ff_lvl_0_to_2[47:24] = w_fan_lvl_0[95:72];
			r_fan_ff_lvl_0_to_2[71:48] = w_fan_lvl_0[167:144];
			r_fan_ff_lvl_0_to_2[95:72] = w_fan_lvl_0[191:168];
			r_fan_ff_lvl_0_to_2[119:96] = w_fan_lvl_0[263:240];
			r_fan_ff_lvl_0_to_2[143:120] = w_fan_lvl_0[287:264];
			r_fan_ff_lvl_1_to_3[23:0] = w_fan_lvl_1[71:48];
			r_fan_ff_lvl_1_to_3[47:24] = w_fan_lvl_1[95:72];
		end
	end


	// Output Buffers and Muxes across all levels to pipeline finished VNs (complete Psums)
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_lvl_output_ff[383:0] <= 'd0;
			r_lvl_output_ff_valid[15:0] <= 'd0;
		end else begin
			if (w_vn_lvl_0_valid[1:0] == 2'b11) begin // both VN complete
				r_lvl_output_ff[47:0] <= w_vn_lvl_0[47:0];
				r_lvl_output_ff_valid[1:0] <= 2'b11;
			end else if (w_vn_lvl_0_valid[1:0] == 2'b10) begin // right VN complete
				r_lvl_output_ff[47:24] <= w_vn_lvl_0[47:24];
				r_lvl_output_ff[23:0] <= 'd0;
				r_lvl_output_ff_valid[1:0] <= 2'b10;
			end else if (w_vn_lvl_0_valid[1:0] == 2'b01) begin // left VN complete
				r_lvl_output_ff[47:0] <= 'd0;
				r_lvl_output_ff[23:0] <= w_vn_lvl_0[23:0];
				r_lvl_output_ff_valid[1:0] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[47:0] <= 'd0; 
				r_lvl_output_ff_valid[1:0] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[3:2] == 2'b11) begin // both VN complete
				r_lvl_output_ff[95:48] <= w_vn_lvl_0[95:48];
				r_lvl_output_ff_valid[3:2] <= 2'b11;
			end else if (w_vn_lvl_0_valid[3:2] == 2'b10) begin // right VN complete
				r_lvl_output_ff[95:72] <= w_vn_lvl_0[95:72];
				r_lvl_output_ff[71:48] <= 'd0;
				r_lvl_output_ff_valid[3:2] <= 2'b10;
			end else if (w_vn_lvl_0_valid[3:2] == 2'b01) begin // left VN complete
				r_lvl_output_ff[95:48] <= 'd0;
				r_lvl_output_ff[71:48] <= w_vn_lvl_0[71:48];
				r_lvl_output_ff_valid[3:2] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[95:48] <= 'd0; 
				r_lvl_output_ff_valid[3:2] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[5:4] == 2'b11) begin // both VN complete
				r_lvl_output_ff[143:96] <= w_vn_lvl_0[143:96];
				r_lvl_output_ff_valid[5:4] <= 2'b11;
			end else if (w_vn_lvl_0_valid[5:4] == 2'b10) begin // right VN complete
				r_lvl_output_ff[143:120] <= w_vn_lvl_0[143:120];
				r_lvl_output_ff[119:96] <= 'd0;
				r_lvl_output_ff_valid[5:4] <= 2'b10;
			end else if (w_vn_lvl_0_valid[5:4] == 2'b01) begin // left VN complete
				r_lvl_output_ff[143:96] <= 'd0;
				r_lvl_output_ff[119:96] <= w_vn_lvl_0[119:96];
				r_lvl_output_ff_valid[5:4] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[143:96] <= 'd0; 
				r_lvl_output_ff_valid[5:4] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[7:6] == 2'b11) begin // both VN complete
				r_lvl_output_ff[191:144] <= w_vn_lvl_0[191:144];
				r_lvl_output_ff_valid[7:6] <= 2'b11;
			end else if (w_vn_lvl_0_valid[7:6] == 2'b10) begin // right VN complete
				r_lvl_output_ff[191:168] <= w_vn_lvl_0[191:168];
				r_lvl_output_ff[167:144] <= 'd0;
				r_lvl_output_ff_valid[7:6] <= 2'b10;
			end else if (w_vn_lvl_0_valid[7:6] == 2'b01) begin // left VN complete
				r_lvl_output_ff[191:144] <= 'd0;
				r_lvl_output_ff[167:144] <= w_vn_lvl_0[167:144];
				r_lvl_output_ff_valid[7:6] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[191:144] <= 'd0; 
				r_lvl_output_ff_valid[7:6] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[9:8] == 2'b11) begin // both VN complete
				r_lvl_output_ff[239:192] <= w_vn_lvl_0[239:192];
				r_lvl_output_ff_valid[9:8] <= 2'b11;
			end else if (w_vn_lvl_0_valid[9:8] == 2'b10) begin // right VN complete
				r_lvl_output_ff[239:216] <= w_vn_lvl_0[239:216];
				r_lvl_output_ff[215:192] <= 'd0;
				r_lvl_output_ff_valid[9:8] <= 2'b10;
			end else if (w_vn_lvl_0_valid[9:8] == 2'b01) begin // left VN complete
				r_lvl_output_ff[239:192] <= 'd0;
				r_lvl_output_ff[215:192] <= w_vn_lvl_0[215:192];
				r_lvl_output_ff_valid[9:8] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[239:192] <= 'd0; 
				r_lvl_output_ff_valid[9:8] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[11:10] == 2'b11) begin // both VN complete
				r_lvl_output_ff[287:240] <= w_vn_lvl_0[287:240];
				r_lvl_output_ff_valid[11:10] <= 2'b11;
			end else if (w_vn_lvl_0_valid[11:10] == 2'b10) begin // right VN complete
				r_lvl_output_ff[287:264] <= w_vn_lvl_0[287:264];
				r_lvl_output_ff[263:240] <= 'd0;
				r_lvl_output_ff_valid[11:10] <= 2'b10;
			end else if (w_vn_lvl_0_valid[11:10] == 2'b01) begin // left VN complete
				r_lvl_output_ff[287:240] <= 'd0;
				r_lvl_output_ff[263:240] <= w_vn_lvl_0[263:240];
				r_lvl_output_ff_valid[11:10] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[287:240] <= 'd0; 
				r_lvl_output_ff_valid[11:10] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[13:12] == 2'b11) begin // both VN complete
				r_lvl_output_ff[335:288] <= w_vn_lvl_0[335:288];
				r_lvl_output_ff_valid[13:12] <= 2'b11;
			end else if (w_vn_lvl_0_valid[13:12] == 2'b10) begin // right VN complete
				r_lvl_output_ff[335:312] <= w_vn_lvl_0[335:312];
				r_lvl_output_ff[311:288] <= 'd0;
				r_lvl_output_ff_valid[13:12] <= 2'b10;
			end else if (w_vn_lvl_0_valid[13:12] == 2'b01) begin // left VN complete
				r_lvl_output_ff[335:288] <= 'd0;
				r_lvl_output_ff[311:288] <= w_vn_lvl_0[311:288];
				r_lvl_output_ff_valid[13:12] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[335:288] <= 'd0; 
				r_lvl_output_ff_valid[13:12] <= 2'b00;
			end


			if (w_vn_lvl_0_valid[15:14] == 2'b11) begin // both VN complete
				r_lvl_output_ff[383:336] <= w_vn_lvl_0[383:336];
				r_lvl_output_ff_valid[15:14] <= 2'b11;
			end else if (w_vn_lvl_0_valid[15:14] == 2'b10) begin // right VN complete
				r_lvl_output_ff[383:360] <= w_vn_lvl_0[383:360];
				r_lvl_output_ff[359:336] <= 'd0;
				r_lvl_output_ff_valid[15:14] <= 2'b10;
			end else if (w_vn_lvl_0_valid[15:14] == 2'b01) begin // left VN complete
				r_lvl_output_ff[383:336] <= 'd0;
				r_lvl_output_ff[359:336] <= w_vn_lvl_0[359:336];
				r_lvl_output_ff_valid[15:14] <= 2'b01;
			end else begin // no VN complete
				r_lvl_output_ff[383:336] <= 'd0; 
				r_lvl_output_ff_valid[15:14] <= 2'b00;
			end


		end
	end


	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_lvl_output_ff[767:384] <= 'd0;
			r_lvl_output_ff_valid[31:16] <= 'd0;
		end else begin
			r_lvl_output_ff[407:384] <= r_lvl_output_ff[23:0];
			r_lvl_output_ff_valid[16] <= r_lvl_output_ff_valid[0];


			if (w_vn_lvl_1_valid[0] == 1'b1) begin
				r_lvl_output_ff[431:408] <= w_vn_lvl_1[23:0];
				r_lvl_output_ff_valid[17] <= 1'b1;
			end else begin
				r_lvl_output_ff[431:408] <= r_lvl_output_ff[47:24];
				r_lvl_output_ff_valid[17] <= r_lvl_output_ff_valid[1];
			end


			if (w_vn_lvl_1_valid[1] == 1'b1) begin
				r_lvl_output_ff[455:432] <= w_vn_lvl_1[47:24];
				r_lvl_output_ff_valid[18] <= 1'b1;
			end else begin
				r_lvl_output_ff[455:432] <= r_lvl_output_ff[71:48];
				r_lvl_output_ff_valid[18] <= r_lvl_output_ff_valid[2];
			end


			r_lvl_output_ff[479:456] <= r_lvl_output_ff[95:72];
			r_lvl_output_ff_valid[19] <= r_lvl_output_ff_valid[3];


			r_lvl_output_ff[503:480] <= r_lvl_output_ff[119:96];
			r_lvl_output_ff_valid[20] <= r_lvl_output_ff_valid[4];


			if (w_vn_lvl_1_valid[2] == 1'b1) begin
				r_lvl_output_ff[527:504] <= w_vn_lvl_1[71:48];
				r_lvl_output_ff_valid[21] <= 1'b1;
			end else begin
				r_lvl_output_ff[527:504] <= r_lvl_output_ff[143:120];
				r_lvl_output_ff_valid[21] <= r_lvl_output_ff_valid[5];
			end


			if (w_vn_lvl_1_valid[3] == 1'b1) begin
				r_lvl_output_ff[551:528] <= w_vn_lvl_1[95:72];
				r_lvl_output_ff_valid[22] <= 1'b1;
			end else begin
				r_lvl_output_ff[551:528] <= r_lvl_output_ff[167:144];
				r_lvl_output_ff_valid[22] <= r_lvl_output_ff_valid[6];
			end


			r_lvl_output_ff[575:552] <= r_lvl_output_ff[191:168];
			r_lvl_output_ff_valid[23] <= r_lvl_output_ff_valid[7];


			r_lvl_output_ff[599:576] <= r_lvl_output_ff[215:192];
			r_lvl_output_ff_valid[24] <= r_lvl_output_ff_valid[8];


			if (w_vn_lvl_1_valid[4] == 1'b1) begin
				r_lvl_output_ff[623:600] <= w_vn_lvl_1[119:96];
				r_lvl_output_ff_valid[25] <= 1'b1;
			end else begin
				r_lvl_output_ff[623:600] <= r_lvl_output_ff[239:216];
				r_lvl_output_ff_valid[25] <= r_lvl_output_ff_valid[9];
			end


			if (w_vn_lvl_1_valid[5] == 1'b1) begin
				r_lvl_output_ff[647:624] <= w_vn_lvl_1[143:120];
				r_lvl_output_ff_valid[26] <= 1'b1;
			end else begin
				r_lvl_output_ff[647:624] <= r_lvl_output_ff[263:240];
				r_lvl_output_ff_valid[26] <= r_lvl_output_ff_valid[10];
			end


			r_lvl_output_ff[671:648] <= r_lvl_output_ff[287:264];
			r_lvl_output_ff_valid[27] <= r_lvl_output_ff_valid[11];


			r_lvl_output_ff[695:672] <= r_lvl_output_ff[311:288];
			r_lvl_output_ff_valid[28] <= r_lvl_output_ff_valid[12];


			if (w_vn_lvl_1_valid[6] == 1'b1) begin
				r_lvl_output_ff[719:696] <= w_vn_lvl_1[167:144];
				r_lvl_output_ff_valid[29] <= 1'b1;
			end else begin
				r_lvl_output_ff[719:696] <= r_lvl_output_ff[335:312];
				r_lvl_output_ff_valid[29] <= r_lvl_output_ff_valid[13];
			end


			if (w_vn_lvl_1_valid[7] == 1'b1) begin
				r_lvl_output_ff[743:720] <= w_vn_lvl_1[191:168];
				r_lvl_output_ff_valid[30] <= 1'b1;
			end else begin
				r_lvl_output_ff[743:720] <= r_lvl_output_ff[359:336];
				r_lvl_output_ff_valid[30] <= r_lvl_output_ff_valid[14];
			end


			r_lvl_output_ff[767:744] <= r_lvl_output_ff[383:360];
			r_lvl_output_ff_valid[31] <= r_lvl_output_ff_valid[15];


		end
	end


	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_lvl_output_ff[1151:768] <= 'd0;
			r_lvl_output_ff_valid[47:32] <= 'd0;
		end else begin
			r_lvl_output_ff[791:768] <= r_lvl_output_ff[407:384];
			r_lvl_output_ff_valid[32] <= r_lvl_output_ff_valid[16];


			r_lvl_output_ff[815:792] <= r_lvl_output_ff[431:408];
			r_lvl_output_ff_valid[33] <= r_lvl_output_ff_valid[17];


			r_lvl_output_ff[839:816] <= r_lvl_output_ff[455:432];
			r_lvl_output_ff_valid[34] <= r_lvl_output_ff_valid[18];


			if (w_vn_lvl_2_valid[0] == 1'b1) begin
				r_lvl_output_ff[863:840] <= w_vn_lvl_2[23:0];
				r_lvl_output_ff_valid[35] <= 1'b1;
			end else begin
				r_lvl_output_ff[863:840] <= r_lvl_output_ff[479:456];
				r_lvl_output_ff_valid[35] <= r_lvl_output_ff_valid[19];
			end


			if (w_vn_lvl_2_valid[1] == 1'b1) begin
				r_lvl_output_ff[887:864] <= w_vn_lvl_2[47:24];
				r_lvl_output_ff_valid[36] <= 1'b1;
			end else begin
				r_lvl_output_ff[887:864] <= r_lvl_output_ff[503:480];
				r_lvl_output_ff_valid[36] <= r_lvl_output_ff_valid[20];
			end


			r_lvl_output_ff[911:888] <= r_lvl_output_ff[527:504];
			r_lvl_output_ff_valid[37] <= r_lvl_output_ff_valid[21];


			r_lvl_output_ff[935:912] <= r_lvl_output_ff[551:528];
			r_lvl_output_ff_valid[38] <= r_lvl_output_ff_valid[22];


			r_lvl_output_ff[959:936] <= r_lvl_output_ff[575:552];
			r_lvl_output_ff_valid[39] <= r_lvl_output_ff_valid[23];


			r_lvl_output_ff[983:960] <= r_lvl_output_ff[599:576];
			r_lvl_output_ff_valid[40] <= r_lvl_output_ff_valid[24];


			r_lvl_output_ff[1007:984] <= r_lvl_output_ff[623:600];
			r_lvl_output_ff_valid[41] <= r_lvl_output_ff_valid[25];


			r_lvl_output_ff[1031:1008] <= r_lvl_output_ff[647:624];
			r_lvl_output_ff_valid[42] <= r_lvl_output_ff_valid[26];


			if (w_vn_lvl_2_valid[2] == 1'b1) begin
				r_lvl_output_ff[1055:1032] <= w_vn_lvl_2[71:48];
				r_lvl_output_ff_valid[43] <= 1'b1;
			end else begin
				r_lvl_output_ff[1055:1032] <= r_lvl_output_ff[671:648];
				r_lvl_output_ff_valid[43] <= r_lvl_output_ff_valid[27];
			end


			if (w_vn_lvl_2_valid[3] == 1'b1) begin
				r_lvl_output_ff[1079:1056] <= w_vn_lvl_2[95:72];
				r_lvl_output_ff_valid[44] <= 1'b1;
			end else begin
				r_lvl_output_ff[1079:1056] <= r_lvl_output_ff[695:672];
				r_lvl_output_ff_valid[44] <= r_lvl_output_ff_valid[28];
			end


			r_lvl_output_ff[1103:1080] <= r_lvl_output_ff[719:696];
			r_lvl_output_ff_valid[45] <= r_lvl_output_ff_valid[29];


			r_lvl_output_ff[1127:1104] <= r_lvl_output_ff[743:720];
			r_lvl_output_ff_valid[46] <= r_lvl_output_ff_valid[30];


			r_lvl_output_ff[1151:1128] <= r_lvl_output_ff[767:744];
			r_lvl_output_ff_valid[47] <= r_lvl_output_ff_valid[31];


		end
	end


	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_lvl_output_ff[1535:1152] <= 'd0;
			r_lvl_output_ff_valid[63:48] <= 'd0;
		end else begin
			r_lvl_output_ff[1175:1152] <= r_lvl_output_ff[791:768];
			r_lvl_output_ff_valid[48] <= r_lvl_output_ff_valid[32];


			r_lvl_output_ff[1199:1176] <= r_lvl_output_ff[815:792];
			r_lvl_output_ff_valid[49] <= r_lvl_output_ff_valid[33];


			r_lvl_output_ff[1223:1200] <= r_lvl_output_ff[839:816];
			r_lvl_output_ff_valid[50] <= r_lvl_output_ff_valid[34];


			r_lvl_output_ff[1247:1224] <= r_lvl_output_ff[863:840];
			r_lvl_output_ff_valid[51] <= r_lvl_output_ff_valid[35];


			r_lvl_output_ff[1271:1248] <= r_lvl_output_ff[887:864];
			r_lvl_output_ff_valid[52] <= r_lvl_output_ff_valid[36];


			r_lvl_output_ff[1295:1272] <= r_lvl_output_ff[911:888];
			r_lvl_output_ff_valid[53] <= r_lvl_output_ff_valid[37];


			r_lvl_output_ff[1319:1296] <= r_lvl_output_ff[935:912];
			r_lvl_output_ff_valid[54] <= r_lvl_output_ff_valid[38];


			if (w_vn_lvl_3_valid[0] == 1'b1) begin
				r_lvl_output_ff[1343:1320] <= w_vn_lvl_3[23:0];
				r_lvl_output_ff_valid[55] <= 1'b1;
			end else begin
				r_lvl_output_ff[1343:1320] <= r_lvl_output_ff[959:936];
				r_lvl_output_ff_valid[55] <= r_lvl_output_ff_valid[39];
			end


			if (w_vn_lvl_3_valid[1] == 1'b1) begin
				r_lvl_output_ff[1367:1344] <= w_vn_lvl_3[47:24];
				r_lvl_output_ff_valid[56] <= 1'b1;
			end else begin
				r_lvl_output_ff[1367:1344] <= r_lvl_output_ff[983:960];
				r_lvl_output_ff_valid[56] <= r_lvl_output_ff_valid[40];
			end


			r_lvl_output_ff[1391:1368] <= r_lvl_output_ff[1007:984];
			r_lvl_output_ff_valid[57] <= r_lvl_output_ff_valid[41];


			r_lvl_output_ff[1415:1392] <= r_lvl_output_ff[1031:1008];
			r_lvl_output_ff_valid[58] <= r_lvl_output_ff_valid[42];


			r_lvl_output_ff[1439:1416] <= r_lvl_output_ff[1055:1032];
			r_lvl_output_ff_valid[59] <= r_lvl_output_ff_valid[43];


			r_lvl_output_ff[1463:1440] <= r_lvl_output_ff[1079:1056];
			r_lvl_output_ff_valid[60] <= r_lvl_output_ff_valid[44];


			r_lvl_output_ff[1487:1464] <= r_lvl_output_ff[1103:1080];
			r_lvl_output_ff_valid[61] <= r_lvl_output_ff_valid[45];


			r_lvl_output_ff[1511:1488] <= r_lvl_output_ff[1127:1104];
			r_lvl_output_ff_valid[62] <= r_lvl_output_ff_valid[46];


			r_lvl_output_ff[1535:1512] <= r_lvl_output_ff[1151:1128];
			r_lvl_output_ff_valid[63] <= r_lvl_output_ff_valid[47];


		end
	end


	// Flop input valid for different level of the adder tree
	always @ (*) begin
		if (i_valid == 1'b1) begin
			r_valid[0] <= 1'b1;
		end else begin
			r_valid[0] <= 1'b0;
		end
	end

	genvar i;
	generate
		for (i=0; i < 5; i=i+1) begin
			always @ (posedge clk) begin
				if (rst == 1'b1) begin
					r_valid[i+1] <= 1'b0;
				end else begin
					r_valid[i+1] <= r_valid[i];
				end
			end
		end
	endgenerate

	// Instantiating Adder Switches

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_0 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[47 : 0]),
		.i_add_en(i_add_en_bus[0]),
		.i_cmd(i_cmd_bus[2:0]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[47 : 0]),
		.o_vn_valid(w_vn_lvl_0_valid[1 : 0]),
		.o_adder(w_fan_lvl_0[23 : 0])
	);

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_1 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[1]),
		.i_data_bus({ w_fan_lvl_0[47:24], w_fan_lvl_0[23:0]}),
		.i_add_en(i_add_en_bus[8]),
		.i_cmd(i_cmd_bus[26:24]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_1[47 : 0]),
		.o_vn_valid(w_vn_lvl_1_valid[1 : 0]),
		.o_adder(w_fan_lvl_1[23 : 0])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_2 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[95 : 48]),
		.i_add_en(i_add_en_bus[1]),
		.i_cmd(i_cmd_bus[5:3]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[95 : 48]),
		.o_vn_valid(w_vn_lvl_0_valid[3 : 2]),
		.o_adder(w_fan_lvl_0[71 : 24])
	);

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 4 ),
		.SEL_IN( 2 )) my_adder_3 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[2]),
		.i_data_bus({ w_fan_lvl_1[47:24], r_fan_ff_lvl_0_to_2[47:24], r_fan_ff_lvl_0_to_2[23:0], w_fan_lvl_1[23:0]}),
		.i_add_en(i_add_en_bus[12]),
		.i_cmd(i_cmd_bus[38:36]),
		.i_sel(i_sel_bus[1:0]),
		.o_vn(w_vn_lvl_2[47 : 0]),
		.o_vn_valid(w_vn_lvl_2_valid[1 : 0]),
		.o_adder(w_fan_lvl_2[23 : 0])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_4 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[143 : 96]),
		.i_add_en(i_add_en_bus[2]),
		.i_cmd(i_cmd_bus[8:6]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[143 : 96]),
		.o_vn_valid(w_vn_lvl_0_valid[5 : 4]),
		.o_adder(w_fan_lvl_0[119 : 72])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_5 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[1]),
		.i_data_bus({ w_fan_lvl_0[143:120], w_fan_lvl_0[119:96]}),
		.i_add_en(i_add_en_bus[9]),
		.i_cmd(i_cmd_bus[29:27]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_1[95 : 48]),
		.o_vn_valid(w_vn_lvl_1_valid[3 : 2]),
		.o_adder(w_fan_lvl_1[71 : 24])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_6 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[191 : 144]),
		.i_add_en(i_add_en_bus[3]),
		.i_cmd(i_cmd_bus[11:9]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[191 : 144]),
		.o_vn_valid(w_vn_lvl_0_valid[7 : 6]),
		.o_adder(w_fan_lvl_0[167 : 120])
	);

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 6 ),
		.SEL_IN( 4 )) my_adder_7 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[3]),
		.i_data_bus({ w_fan_lvl_2[47:24], r_fan_ff_lvl_1_to_3[47:24], r_fan_ff_lvl_0_to_3[47:24], r_fan_ff_lvl_0_to_3[23:0], r_fan_ff_lvl_1_to_3[23:0], w_fan_lvl_2[23:0]}),
		.i_add_en(i_add_en_bus[14]),
		.i_cmd(i_cmd_bus[44:42]),
		.i_sel(i_sel_bus[7:4]),
		.o_vn(w_vn_lvl_3[47 : 0]),
		.o_vn_valid(w_vn_lvl_3_valid[1 : 0]),
		.o_adder(w_fan_lvl_3[23 : 0])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_8 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[239 : 192]),
		.i_add_en(i_add_en_bus[4]),
		.i_cmd(i_cmd_bus[14:12]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[239 : 192]),
		.o_vn_valid(w_vn_lvl_0_valid[9 : 8]),
		.o_adder(w_fan_lvl_0[215 : 168])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_9 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[1]),
		.i_data_bus({ w_fan_lvl_0[239:216], w_fan_lvl_0[215:192]}),
		.i_add_en(i_add_en_bus[10]),
		.i_cmd(i_cmd_bus[32:30]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_1[143 : 96]),
		.o_vn_valid(w_vn_lvl_1_valid[5 : 4]),
		.o_adder(w_fan_lvl_1[119 : 72])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_10 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[287 : 240]),
		.i_add_en(i_add_en_bus[5]),
		.i_cmd(i_cmd_bus[17:15]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[287 : 240]),
		.o_vn_valid(w_vn_lvl_0_valid[11 : 10]),
		.o_adder(w_fan_lvl_0[263 : 216])
	);

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 4 ),
		.SEL_IN( 2 )) my_adder_11 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[2]),
		.i_data_bus({ w_fan_lvl_1[143:120], r_fan_ff_lvl_0_to_2[143:120], r_fan_ff_lvl_0_to_2[119:96], w_fan_lvl_1[119:96]}),
		.i_add_en(i_add_en_bus[13]),
		.i_cmd(i_cmd_bus[41:39]),
		.i_sel(i_sel_bus[3:2]),
		.o_vn(w_vn_lvl_2[95 : 48]),
		.o_vn_valid(w_vn_lvl_2_valid[3 : 2]),
		.o_adder(w_fan_lvl_2[47 : 24])
	);

	adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_12 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[335 : 288]),
		.i_add_en(i_add_en_bus[6]),
		.i_cmd(i_cmd_bus[20:18]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[335 : 288]),
		.o_vn_valid(w_vn_lvl_0_valid[13 : 12]),
		.o_adder(w_fan_lvl_0[311 : 264])
	);

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_13 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[1]),
		.i_data_bus({ w_fan_lvl_0[335:312], w_fan_lvl_0[311:288]}),
		.i_add_en(i_add_en_bus[11]),
		.i_cmd(i_cmd_bus[35:33]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_1[191 : 144]),
		.o_vn_valid(w_vn_lvl_1_valid[7 : 6]),
		.o_adder(w_fan_lvl_1[143 : 120])
	);

	edge_adder_switch #(
		.DATA_TYPE( 24 ),
		.NUM_IN( 2 ),
		.SEL_IN( 2 )) my_adder_14 (
		.clk(clk),
		.rst(rst),
		.i_valid(r_valid[0]),
		.i_data_bus(i_data_bus[383 : 336]),
		.i_add_en(i_add_en_bus[7]),
		.i_cmd(i_cmd_bus[23:21]),
		.i_sel(2'b00),
		.o_vn(w_vn_lvl_0[383 : 336]),
		.o_vn_valid(w_vn_lvl_0_valid[15 : 14]),
		.o_adder(w_fan_lvl_0[335 : 312])
	);


	// Flop last level adder cmd for timing matching
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			r_final_add <= 'd0;
			r_final_add2 <= 'd0;
			r_final_sum <= 'd0;
		end else begin
			r_final_add <= i_add_en_bus[14];
			r_final_add2 <= r_final_add;
			r_final_sum <= w_fan_lvl_3;
			end
	end


	// Assigning output bus (with correct timing and final adder mux)
	always @ (*) begin
		if (rst == 1'b1) begin
			o_data_bus <= 'd0;
		end else begin
			o_data_bus[167:0] <= r_lvl_output_ff[1319:1152];
			if (r_final_add2 == 1'b1) begin
				o_data_bus[191:168] <= r_final_sum;
			end else begin
				o_data_bus[191:168] <= r_lvl_output_ff[1343:1320];
			end
			o_data_bus[383:192] <= r_lvl_output_ff[1535:1344];
		end
	end


	// Assigning output valid (with correct timing and final adder mux)
	always @ (*) begin
		if (rst == 1'b1 || r_valid[5] == 1'b0) begin
			o_valid <= 'd0;
		end else begin
			o_valid[6:0] <= r_lvl_output_ff_valid[55:48];
			if (r_final_add2 == 1'b1) begin
				o_valid[7] <= 1'b1 ;
			end else begin
				o_valid[7] <= r_lvl_output_ff_valid[55];
			end
			o_valid[15:8] <= r_lvl_output_ff_valid[63:56];
		end
	end


endmodule
