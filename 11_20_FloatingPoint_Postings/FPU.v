// starter file for the FPU.  It handles all the reading of and writing to its registers
module FPU(clk, datain, dataout, FPUsel, addr, read, write);
input clk, FPUsel, read, write;
input [7:0] datain; // command or value being sent to the FPU
                    // commands are 1 Set Y as next value
                    //              2 Set X as next value
                    //              3 Perform division
                    //              4 Perform multiplication
input [1:0] addr;   // status read 00, result read 01, command write 10, value write 11
output [7:0] dataout;  // result being read from the FPU
reg [2:0] inloc;    // index in the YX set for next incoming value
reg [1:0] outloc;   // index in the Res reg for next result out (on read)
reg [31:0] Y,X,Res;
reg prevreadval, prevwritecmd, prevwriteval;
wire readval, readstatus, writecmd, writeval;
wire readvalnegedge, writecmdposedge, writevalnegedge;  //write cmd is pos edge -- others neg edge
assign readstatus = read & FPUsel & (addr==0);
assign readval = read & FPUsel & (addr==1);
assign writecmd = write & FPUsel & (addr==2);
assign writeval = write & FPUsel & (addr==3);

always @(posedge clk)
   begin
      prevreadval <= readval;
      prevwritecmd <= writecmd;
      prevwriteval <= writeval;
      inloc <= writevalnegedge ? inloc+1 : writecmdposedge&datain==1 ? 0 : writecmdposedge&datain==2 ? 4 : inloc;
      outloc <= DivDone | MulDone ? 0 : readvalnegedge ? outloc+1 : outloc;
      Y[31:24] <= writeval&inloc==0 ? datain : Y[31:24];
      Y[23:16] <= writeval&inloc==0 ? 0 : writeval&inloc==1 ? datain : Y[23:16];
      Y[15:8] <= writeval&inloc==0 ? 0 : writeval&inloc==2 ? datain : Y[15:8];
      Y[7:0] <= writeval&inloc==0 ? 0 : writeval&inloc==3 ? datain : Y[7:0];
      X[31:24] <= writeval&inloc==4 ? datain : X[31:24];
      X[23:16] <= writeval&inloc==4 ? 0 : writeval&inloc==5 ? datain : X[23:16];
      X[15:8] <= writeval&inloc==4 ? 0 : writeval&inloc==6 ? datain : X[15:8];
      X[7:0] <= writeval&inloc==4 ? 0 : writeval&inloc==7 ? datain : X[7:0];
      Res <= DivDone ? {S, E[7:0], Q[22:0]} : MulDone ? {mS, mE[7:0], P[22:0]} : Res;
   end
    
assign dataout = readval&outloc==0 ? Res[31:24]
               : readval&outloc==1 ? Res[23:16]
               : readval&outloc==2 ? Res[15:8]
               : readval&outloc==3 ? Res[7:0]
               : readstatus ? {~Wait|~mWait,7'd0}  // msb is a FPU busy bit
               : 0;
// we want to react to each cmd immediately, but only once so need a pos edge
assign writecmdposedge = writecmd & ~prevwritecmd; // pos edge
// we need to advance the result index at end of a reading a value so need neg edge
assign readvalnegedge = ~readval & prevreadval;    // neg edge
// we need to advance the XY index at end of a write value so need neg edge
assign writevalnegedge = ~writeval & prevwriteval; // neg edge

// FP Divide section
// student needs to declare Done, Rneed, Wait, Step, Start, Neg
//                          A, B, AmB, E, Q, S, DivDone, DivState
// some are wires others regs, some scalars others vectors
reg [24:0] A, B, AmB;
reg [23:0] Q;
reg [9:0] E;
reg S, DivState;
wire, Done, Rneed, Wait, Step, Start, Neg, DivDone;

assign Wait = 
assign Step = 
assign Start = writecmdposedge&datain==3;
always @(posedge clk)
   begin
      DivState <= 
      S <= 
      A <= 
      B <= 
      E <= 
      Q <= 
      DivDone <= 
    end
assign Done = Q[23];
assign AmB = 
assign Neg = 
assign Rneed =


// FP Multiply section
// Even though several Vectors are 1-bit different in size than the Divide, it would
//    be possible to share them.  However, I think the benefit of keeping them separate
//    far outweighs any savings.  Therefore, below I have placed an m in front of any
//    variable named the same in my multiply and divide write-ups.
// student needs to declare mDone, mRneed, mWait, mStep, mShift, mStart, Sneed,
//                          mA, mB, mE, P, mS, MulDone, MulState, Round, SBit
// some are wires others regs, some scalors others vectors

assign mWait = 
assign mStep = 
assign mShift = 
assign mStart = writecmdposedge&datain==4;
always @(posedge clk)
   begin
      MulState <=
      mS <= 
      mA <= 
      mB <= 
      mE <= 
      P <=
      MulDone <=
      Round <= 
      SBit <= 
   end
assign mDone = 
assign mRneed =
assign Sneed = 
endmodule
