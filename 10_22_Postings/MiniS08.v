// MiniS08 starter file
module MiniS08(clk50,rxd,resetin,pbin,clksel,clkdisp,txd,addr,data,stateout,IRout,debugOut);
input clk50, rxd, resetin, pbin;
input [2:0] clksel;
output debugOut;
output txd;
output [20:0] addr;  // three 7-segment displays
output [13:0] data;  // two 7-segment displays
output [13:0] IRout;
output [6:0] stateout;
wire IMM, IX, INH, REL, DIR, EXT, STK;
wire ldIR, ldA, oeA, ldHX, oeH, oeX, oeHXad, incSP, decSP, oeSPad, ldMARH, ldMARL, clrMARH, oeMARad, oeMAR;
wire ldPC, oeIncPCad, oePCH, oePCL, write, read, IOaddr, RAMaddr, ROMaddr, FPUaddr;
wire modA, stoA, modHX; 
wire br, jmp, jsr, rts, ldapula, add, sub, And, ora, eor, lsra, asra, lsla;
wire psha, pshh, pshx;
wire lda, ldz, ldx, pula, pulx, pulh, aix;
wire BCT, bra, bcc, bcs, bpl, bmi, bne, beq, sta, stx; 
wire N, Z, Co;
wire [7:0] fpuout, sciout, RAMout, ROMout; 
wire [9:0] abus; 
wire [7:0] dbus; 
wire [7:0] ALU;
wire [9:0] PCLU, HXLU;
wire reset;
wire st0, st1, st2, st3, st4;
reg [2:0] CPUstate;
reg [27:0] clkdiv;
reg resetout, gotoreset, pbout, pbreg, S08clk, C;
output clkdisp;
reg [7:0] A, IR;
reg [9:0] HX, MAR, PC, SP;
wire [3:0] IRH;

sevenseg A2({2'd0,abus[9:8]},addr[20:14]);
sevenseg A1(abus[7:4],addr[13:7]);
sevenseg A0(abus[3:0],addr[6:0]);
sevenseg D1(dbus[7:4],data[13:7]);
sevenseg D0(dbus[3:0],data[6:0]);

sevenseg IR1(IR[7:4], IRout[13:7]);    
sevenseg IR0(IR[3:0], IRout[6:0]);
sevenseg ST({1'b0,CPUstate}-1,stateout);

sci S08sci(clk50, dbus, sciout, IOaddr, abus[2:0], read, write, rxd, txd);
FPU S08fpu(clk50, dbus, fpuout, FPUaddr, abus[2:0], read, write);
S08ram ram(abus[7:0],clk50,dbus,write&RAMaddr,RAMout);
S08rom rom(abus,clk50,ROMout);

assign clkdisp = clksel==0 ? pbreg : clksel==1 ? clkdiv[27] : clksel==2 ? clkdiv[24] : clksel==3 ? clkdiv[21]
           : clksel==4 ? clkdiv[17] : clksel==5 ? clkdiv[15] : clksel==6 ? clkdiv[13] : clkdiv[2];
			  
always @(posedge clk50)
   begin
   clkdiv <= clkdiv+1;
   gotoreset <= resetout;
   resetout <= ~resetin;
   pbreg <= pbout;
   pbout <= ~pbin;
   S08clk <= clkdisp;
   end
  
always @(posedge S08clk)
   begin
		A 			<= ldA ? ALU 
						: A;
		HX 		<= ldHX ? HXLU 
						: HX;
		SP 		<= reset ? 'hFF 
						: incSP ? SP+1 
						: decSP ? SP-1 
						: SP;
		PC 		<= reset ? 'h100 
						: ldPC ? PCLU 
						: oeIncPCad ? PC+1 
						: PC;
		IR 		<= ldIR ? dbus 
						: IR;
		C 			<= ldA&(add|sub|lsla|lsra|asra) ? Co 
						: C;
		MAR 		<= (clrMARH&ldMARL) ? dbus 
						: clrMARH ? MAR[7:0] 
						: ldMARH ? {dbus[1:0],MAR[7:0]} 
						: ldMARL ? {MAR[9:8],dbus} 
						: MAR; 

		CPUstate <= gotoreset ? 0 
						: reset ? 1 
						: st0 ? 2
						: st1 ? ((INH|IMM|IX|psha|pshh|pshx|REL) ? 1 : 3)
						: st2 ? ((((EXT|jsr)&~jmp)|rts) ? 4 : 1)
						: st3 ? (jsr ? 5 : 1) 
						: st4 ? 1 
						: CPUstate;
   end

assign debugOut = 0;
assign IRH 		 = IR[7:4];
assign IMM 		 = (IRH=='hA);
assign IX  		 = (IRH=='hF);
assign INH 		 = (IRH=='h4);
assign REL		 = (IRH=='h2);
assign DIR 		 = (IRH=='hB);
assign EXT 		 = (IRH=='hC);
assign STK 		 = (IRH=='h8);

assign reset 	 = CPUstate==0;
assign st0 		 = CPUstate==1;
assign st1 		 = CPUstate==2;
assign st2 		 = CPUstate==3;
assign st3 		 = CPUstate==4;
assign st4 		 = CPUstate==5;

assign N 		 = A[7];
assign Z 		 = ~|A;

assign {Co,ALU} = (ldapula) ? dbus 
						: add ? ({1'b0,A}+{1'b0,dbus}) 
						: sub ? ({1'b0,A}-{1'b0,dbus}) 
						: And ? (A&dbus) 
						: ora ? (A|dbus) 
						: eor ? (A^dbus) 
						: lsra ? {A[0],1'b0,A[7:1]} 
						: asra ? {A[0],A[7],A[7:1]} 
						: lsla ? {A[7:0],1'b0} 
						: A;
assign HXLU 	= (ldx|pulx) ? {HX[9:8],dbus} 
						: pulh ? {dbus[1:0],HX[7:0]} 
						: aix ? HX+{dbus[7],dbus[7],dbus} 
						: HX;
assign PCLU	   = br ? (PC+{dbus[7],dbus[7],dbus}+1) 
						: jsr ? MAR 
						: {MAR[9:8],dbus};

assign abus 	= oeMARad ? MAR 
						: oeHXad ? HX 
						: oeSPad ?  SP 
						: oeIncPCad ? PC 
						: 0;
assign dbus 	= oeMAR&oePCH ? PC[9:8] 
						: oeMAR ? MAR 
						: oeA ? A 
						: oeX ? HX[7:0] 
						: oeH ? {6'b0,HX[9:8]} 
						: oePCL ? PC[7:0] 
						: oePCH ? {6'b0,PC[9:8]}
						: IOaddr&read ? sciout 
						: FPUaddr&read ? fpuout 
						: RAMaddr&read ? RAMout 
						: ROMaddr&read ? ROMout 
						: 0;
		 
assign ldIR 		= st0;
assign ldA 			= modA&INH&st1  | modA&STK&st2  | modA&IMM&st1  | modA&DIR&st2  | modA&EXT&st3 | modA&IX&st1;
assign oeA 			= stoA&STK&st1  | stoA&DIR&st2  |
						  stoA&EXT&st3  | stoA&IX&st1;
assign ldHX 		= modHX&STK&st2 | modHX&IMM&st1 | modHX&DIR&st2 | modHX&EXT&st3 | modHX&IX&st1;	
assign oeH 			= pshh&st1; 
assign oeX 			= pshx&st1|
						  stx&DIR&st2  | stx&EXT&st3  | stx&IX&st1;	
assign oeHXad 		= modA&IX&st1   |
						  stoA&IX&st1   |
						  modHX&IX&st1  |
						  stx&IX&st1;
assign incSP 		= modA&STK&st1  |
						  modHX&STK&st1 |
						  rts&st1       | rts&st2;
assign decSP 		= stoA&STK&st1  |
						  pshh&st1| pshx&st1|
						  jsr&st3		 | jsr&st4;
assign oeSPad 		= modA&STK&st2  |
						  stoA&STK&st1  | 
						  modHX&STK&st2 | pshh&st1| pshx&st1 |
						  rts&st2       | rts&st3       |
						  jsr&st3		 | jsr&st4;	
assign ldMARH 		= modA&EXT&st1  |
						  stoA&EXT&st1  |
						  modHX&EXT&st1 |
						  stx&EXT&st1  |
						  jmp&st1		 |
						  jsr&st1		 |
						  rts&st2;	
assign ldMARL 		= modA&DIR&st1  | modA&EXT&st2  |
						  stoA&DIR&st1  | stoA&EXT&st2  |
						  modHX&DIR&st1 | modHX&EXT&st2 |
						  stx&DIR&st1  | stx&EXT&st2  |
						  jsr&st2;	
assign clrMARH 	= modA&DIR&st1  |
						  stoA&DIR&st1  |
						  modHX&DIR&st1 |
						  stx&DIR&st1;		
assign oeMARad 	= modA&DIR&st2  | modA&EXT&st3  |
						  stoA&DIR&st2  | stoA&EXT&st3  |
						  modHX&DIR&st2 | modHX&EXT&st3 |
						  stx&DIR&st2  | stx&EXT&st3;
assign oeMAR 		= jsr&st4;
assign ldPC 		= br&BCT&st1    |
						  jmp&st2		 |
						  jsr&st4		 |
						  rts&st3;		
assign oeIncPCad 	= st0 	 		 | modA&IMM&st1  | modA&DIR&st1  | modA&EXT&st1  | modA&EXT&st2 |
						  stoA&DIR&st1  | stoA&EXT&st1  | stoA&EXT&st2  |
						  modHX&IMM&st1 | modHX&DIR&st1 | modHX&EXT&st1 | modHX&EXT&st2 |
						  stx&DIR&st1  | stx&EXT&st1  | stx&EXT&st2  |
						  br&st1    	 |
						  jmp&st1   	 | jmp&st2       |
						  jsr&st1		 | jsr&st2;	
assign oePCH 		= jsr&st4;
assign oePCL 		= jsr&st3;
assign write 		= stoA&STK&st1  | stoA&DIR&st2  | stoA&EXT&st3  | stoA&IX&st1   |
						  pshh&st1| pshx&st1| 
						  stx&DIR&st2  | stx&EXT&st3  | stx&IX&st1   |
						  jsr&st3       | jsr&st4;
assign read 		= st0 			 | 
						  modA&STK&st2  | modA&IMM&st1  | modA&DIR&st1  | modA&DIR&st2  | modA&EXT&st1  | modA&EXT&st2  | modA&EXT&st3  | modA&IX&st1  |
						  stoA&DIR&st1  | stoA&EXT&st1  | stoA&EXT&st2  | 
						  modHX&STK&st2 | modHX&IMM&st1 | modHX&DIR&st1 | modHX&DIR&st2 | modHX&EXT&st1 | modHX&EXT&st2 | modHX&EXT&st3 | modHX&IX&st1 |
						  stx&DIR&st1  | stx&EXT&st1  | stx&EXT&st2  |
						  br&BCT&st1    |
						  jmp&st1       | jmp&st2		  |
						  jsr&st1       | jsr&st2       |
						  rts&st2       | rts&st3;

assign FPUaddr 	= (abus<'h4);
assign IOaddr 		= ~FPUaddr&(abus<'h8);
assign RAMaddr 	= ~FPUaddr&~IOaddr&(abus<'h100);
assign ROMaddr 	= ~FPUaddr&~IOaddr&~RAMaddr;

assign modA 		= lda | pula | add | sub | And | ora | eor | lsra | asra | lsla;
assign stoA 		= sta | psha;
assign modHX 		= ldx | pulh | pulx | aix;
assign br 			= REL;

assign jmp 			= (IR=='hCC);
assign jsr 			= (IR=='hCD);
assign rts 			= (IR=='h81);
assign ldapula 	= lda | pula;
assign add 			= (IR=='hAB)|(IR=='hBB)|(IR=='hCB)|(IR=='hFB);
assign sub 			= (IR=='hA0)|(IR=='hB0)|(IR=='hC0)|(IR=='hF0);
assign And 			= (IR=='hA4)|(IR=='hB4)|(IR=='hC4)|(IR=='hF4);
assign ora 			= (IR=='hAA)|(IR=='hBA)|(IR=='hCA)|(IR=='hFA);
assign eor 			= (IR=='hA8)|(IR=='hB8)|(IR=='hC8)|(IR=='hF8);
assign lsra 		= (IR=='h44);
assign asra 		= (IR=='h47);
assign lsla 		= (IR=='h48);

assign psha 		= (IR=='h87);
assign pshh 		= (IR=='h8B);
assign pshx 		= (IR=='h89);

assign lda 			= (IR=='hA6)|(IR=='hB6)|(IR=='hC6)|(IR=='hF6);
assign ldx 			= (IR=='hAE)|(IR=='hBE)|(IR=='hCE)|(IR=='hFE);
assign pula 		= (IR=='h86);
assign pulx 		= (IR=='h88);
assign pulh 		= (IR=='h8A);
assign aix 			= (IR=='hAF);	

assign BCT 			= bra | bcc&~C | bcs&C | bpl&~N | bmi&N | bne&~Z | beq&Z;
assign bra 			= (IR=='h20);
assign bcc 			= (IR=='h24);
assign bcs 			= (IR=='h25);
assign bpl 			= (IR=='h2A);
assign bmi 			= (IR=='h2B);
assign bne 			= (IR=='h26);
assign beq 			= (IR=='h27);
assign sta 			= (IR=='hB7)|(IR=='hC7)|(IR=='hF7);
assign stx 			= (IR=='hBF)|(IR=='hCF)|(IR=='hFF);

//DO THIS
//assign IOout = sc;
endmodule

module sevenseg(hex, segs);
input [3:0] hex;
output [6:0] segs;
assign segs = hex==0  ? 'b0000001   // active-low segments
            : hex==1  ? 'b1001111
            : hex==2  ? 'b0010010
            : hex==3  ? 'b0000110
            : hex==4  ? 'b1001100
            : hex==5  ? 'b0100100
            : hex==6  ? 'b0100000
            : hex==7  ? 'b0001111
            : hex==8  ? 'b0000000
            : hex==9  ? 'b0001100
            : hex==10 ? 'b0001000
            : hex==11 ? 'b1100000
            : hex==12 ? 'b0110001
            : hex==13 ? 'b1000010
            : hex==14 ? 'b0110000
            :           'b0111000;
endmodule
