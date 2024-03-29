module datapath(input logic clk, reset,
                input logic memtoreg, pcsrc,
                input logic [1:0] alusrc,
                input logic ne,
                input logic regdst,
                input logic regwrite, jump, half,b,
                input logic [2:0] alucontrol,
                output logic zero,
                output logic [31:0] pc,
                input logic [31:0] instr,
                output logic [31:0] aluout, writedata,
                input logic [31:0] readdata);


    logic [4:0] writereg;
    logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
    logic [31:0] signimm, signimmsh;
    logic [31:0] srca, srcb;
    logic [31:0] result_T; 
    logic [31:0] half_result_extended;
    logic [31:0] hw_dataMemeoryOutput; // datamemory after the half word design
    logic [31:0] result; // datamemory after the one byte design
    logic [31:0] one_byte_result_sign_extended;

    // next PC logic
    flopr #(32) pcreg(clk, reset, pcnext, pc);

    adder pcadd1(pc, 32'b100, pcplus4); //normal +4

    sl2 immsh(signimm, signimmsh); //jumb

    adder pcadd2(pcplus4, signimmsh, pcbranch); //branch or jumb

    //half
    signext se2(result_T[15:0], half_result_extended); //extend sign
    //mux after the halfword
    mux2 #(32) halfmux(result_T,half_result_extended,half,hw_dataMemeoryOutput);

    // one byte
    signex #(24,8) se3(result_T[7:0], one_byte_result_sign_extended);
    //mux after the one byte word
    mux2 #(32) ob_mux(hw_dataMemeoryOutput,
                       one_byte_result_sign_extended,
                       b,
                       result);


    mux2 #(32) pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
    mux2 #(32) pcmux(pcnextbr, {pcplus4[31:28],
                    instr[25:0], 2'b00}, jump, pcnext);


    regfile rf(clk, regwrite, instr[25:21], instr[20:16],
                writereg, result, srca, writedata);

    mux2 #(5) wrmux(instr[20:16], instr[15:11],
                    regdst, writereg);
    mux2 #(32) resmux(aluout, readdata, memtoreg, result_T);

    signext se(instr[15:0], signimm); //extend sign

    logic [31:0] extimm;
    logic [31:0] zeroimm;
    extnext ex(instr[15:0], zeroimm);
    // ALU logic
    mux2 #(32) srcbmux(writedata, extimm, alusrc[0], srcb);
    mux2 #(32) extimux(signimm ,  zeroimm, alusrc[1], extimm);
    alu alu(srca, srcb, alucontrol, aluout, zero);
endmodule