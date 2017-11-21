// debugged version 10-22-17
module sci(clk, datain, dataout, IOsel, addr, read, write, rxd, txd);
input clk, IOsel, read, write, rxd;
input [7:0] datain;  // data being sent to the SCI
input [2:0] addr; // status read 100, data read 101, data write 110
output txd;
output [7:0] dataout;  // data being read from the SCI

reg [12:0] baudgen;
reg [2:0] rcvstate, rcvbitcnt;
reg [8:0] shiftout;
reg [7:0] shiftin, trandata;
reg [3:0] txdstate;
reg rdrf, tdrf, newtrandata;
wire readdataedge, writedataedge, rcvstate7edge, txdstate1edge, txdstate9edge;
reg prevreaddata, prevwritedata, prevrcvstate7, prevtxdstate1, prevtxdstate9;

// the clk will be 50 MHz -- the count sequence produces the top 3 bit of baudgen
// from 000 to 110 for 672 cycles each and 111 for 504.  Thus, the msb is a 48%
// duty cycle 9600 baud clock, bit 10 is an oversampled clock with 3 out of 4 pulses
// being 50% duty cycle and the 4th 43%
assign readdataedge = read & IOsel & (addr==5) & ~prevreaddata;
assign writedataedge = write & IOsel & (addr==6) & ~prevwritedata;
assign rcvstate7edge = (rcvstate==7)&~prevrcvstate7;
assign txdstate1edge = (txdstate==1)&~prevtxdstate1;
assign txdstate9edge = (txdstate==9)&~prevtxdstate9;
assign dataout = read&IOsel&(addr==5) ? shiftin
               : read&IOsel&(addr==4) ? {~tdrf,6'd0,rdrf} : 0;
assign txd = shiftout[0];

always @(posedge clk)
   begin
   baudgen <= baudgen==7913 ? 0 : baudgen[5:0]==41 ? baudgen+23 : baudgen+1;
   prevreaddata <= read & IOsel & (addr==5);
   prevwritedata <= write & IOsel & (addr==6);
   prevrcvstate7 <= (rcvstate==7);
	prevtxdstate1 <= (txdstate==1);
   prevtxdstate9 <= (txdstate==9);
   rdrf <= rcvstate7edge ? 1 : readdataedge ? 0 : rdrf;
	tdrf <= writedataedge ? 1 : txdstate9edge ? 0 : tdrf;
   newtrandata <= writedataedge ? 1 : txdstate1edge ? 0 : newtrandata;
   trandata <= writedataedge ? datain : trandata;
   end
   
always @(posedge baudgen[10])   // 4x 9600 baud clock
   begin
   rcvstate <= (rcvstate==0)&rxd ? 0 : (rcvstate==7)&~rxd ? 7
             : (rcvstate==6)&(rcvbitcnt!=0) ? 3 : rcvstate+1;
   rcvbitcnt <= (rcvstate==0) ? 0 : (rcvstate==5) ? rcvbitcnt+1 : rcvbitcnt;
   shiftin <= (rcvstate==5) ? {rxd,shiftin[7:1]} : shiftin;
   end
   
always @(posedge baudgen[12])   // 1x 9600 baud clock
   begin
	
   shiftout <= newtrandata&(txdstate==0) ? {trandata,1'b0} : {1'b1,shiftout[8:1]};
	txdstate <= txdstate==0 ? (newtrandata ? 1 : 0)
	          : txdstate==9 ? 0 : txdstate+1;
   end
endmodule