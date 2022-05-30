module i3c_time_control (
   RSTn,
   CLK_SLOW,
   clk_SCL_n,
   timec_ena,//no load
   event_start,
   was_nacked,//no load
   sc1_stop,
   sc2_stop,
   time_info_sel,
   time_info_byte,
   ibi_timec,
   time_overflow,
   slow_gate,
   scan_no_rst
   );
   
   
input RSTn;
input CLK_SLOW;
input clk_SCL_n;
input [2:0] timec_ena;
input event_start;
input was_nacked;
input sc1_stop;
input sc2_stop;
input [2:0] time_info_sel;
input scan_no_rst;


output [7:0] time_info_byte;
output time_overflow;
output ibi_timec;   
output slow_gate;


reg [2:0] sc1_delay;
reg [2:0] sc2_delay;
wire sc1_stop_pulse;
wire sc2_stop_pulse;
reg event_start_dly;
reg [2:0] event_start_dly1;
wire timer1_en_set;
wire timer1_en_clr;
reg timer1_en;
wire timer2_en_set;
wire timer2_en_clr;
reg timer2_en;
wire time_overflow;
reg [15:0] timer1;
reg [7:0] timer2;
reg [15:0] TC_1;
reg [7:0] TC_2;
wire [7:0] time_info_byte;
wire ibi_timec;

always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) sc1_delay <= 3'h0;
   else sc1_delay <= #1 {sc1_delay[1:0], sc1_stop};
end

assign sc1_stop_pulse = sc1_delay[1] & ~sc1_delay[2];

always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) sc2_delay <= 3'h0;
   else sc2_delay <= #1 {sc2_delay[1:0], sc2_stop};
end

assign sc2_stop_pulse = sc2_delay[1] & ~sc2_delay[2];

always @(posedge clk_SCL_n or negedge RSTn) begin
   if (~RSTn) event_start_dly <= 1'b0;
   else event_start_dly <= #1 event_start;
end

always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) event_start_dly1 <= 3'b0;
   else event_start_dly1 <= #1 {event_start_dly1[1:0], (event_start_dly | event_start)};
end

assign timer1_en_set = (event_start_dly1[2:1] == 2'b01);
assign timer1_en_clr = (sc1_stop_pulse & timer1_en) | (timer1 >= 16'hfffe);
always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) timer1_en <= 1'b0;
   else if (timer1_en_clr) timer1_en <= #1 1'b0;
   else if (timer1_en_set) timer1_en <= #1 1'b1;
end
   
always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) timer1 <= 16'h0;
   else if (~(timer1_en | timer1_en_set)) timer1 <= #1 16'h0;
   else if (&timer1) timer1 <= #1 timer1;
   else timer1 <= #1 timer1 + 1'b1;
end

assign timer2_en_set = sc1_stop_pulse;
assign timer2_en_clr = (sc2_stop_pulse & timer2_en) | (timer2 >= 8'hfe);
always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) timer2_en <= 1'b0;
   else if (timer2_en_clr) timer2_en <= #1 1'b0;
   else if (timer2_en_set) timer2_en <= #1 1'b1;
end
   
always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) timer2 <= 8'h0;
   else if (~(timer2_en | timer2_en_set)) timer2 <= #1 8'h0;
   else if (&timer2) timer2 <= #1 timer2;
   else timer2 <= #1 timer2 + 1'b1;
end

assign time_overflow = (&timer1) | (&timer2);

always @(posedge CLK_SLOW or negedge RSTn) begin
   if (~RSTn) begin
      TC_1 <= 16'h0;
	  TC_2 <= 8'h0;
   end
   else if (sc1_stop_pulse) TC_1 <= #1 timer1;
   else if (sc2_stop_pulse) TC_2 <= #1 timer2;
end
assign time_info_byte = (time_info_sel == 3'h5) ? TC_1[7:0] :
                       (time_info_sel == 3'h6) ? TC_1[15:8] :     
					   (time_info_sel == 3'h7) ? TC_2[7:0] : 8'h0;
					   
assign ibi_timec = (time_info_sel >= 3'h4) & (time_info_sel <= 3'h6);

assign slow_gate = 1'b1;
endmodule					   

   