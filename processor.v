/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
	 
	 
);
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;
	 

    /* YOUR CODE STARTS HERE */
	 
	 /*I am gonna to implement control using ROM*/
	 //The control bit will be :
	 // BR JR ALUinB ALUop(4bits) DMwe Rwe Rdst Rwd		[Rdst is actually not used]
	 reg [11:0] control [31:0];		//[bit-width] control [number of reg]
	 
	 initial
	 begin
		// BR JR ALUinB ALUop(5bits) DMwe Rwe Rdst Rwd 
		//control bits for R type: add, sub, and, or, sll, sra
		control[5'b00000] = 12'b000xxxxx0110;
		//control bits for addi
		control[5'b00101] = 12'b001000000100;
		//control bits for sw
		control[5'b00111] = 12'b0010000010xx;
		//control bits for lw
		control[5'b01000] = 12'b001000000101;
		//control bits for j
		control[5'b00001] = 12'b010xxxxx00xx;
		//control bits for bne
		control[5'b00010] = 12'b1000000100xx;
		//control bits for jal
		control[5'b00011] = 12'b010xxxxx01x0;
		//control bits for jr
		control[5'b00100] = 12'b010xxxxx00xx;
		//control bits for blt
		control[5'b00110] = 12'b1000000100xx;
		//controls bits for bex
		control[5'b10110] = 12'b0100000100xx;
		//controls bits for setx
		control[5'b10101] = 12'b0010000001x0;
	 end
	 
	 
	wire [4:0] opcode;
	
	
	wire [31:0] jump_or_branch;
	
	
	wire [31:0] jump;
	wire [31:0] branch;
	wire j;
	wire jal;
	wire [31:0] alu_or_pc_plus1;
	wire [31:0] alu_or_pc1_or_setx;
	wire jr;
	wire [31:0] pc_plus_one_plus_N;
	wire bne;
	wire [31:0] bne_where;
	wire blt;
	wire [31:0] blt_where;
	wire bex;
	wire setx;
	wire ALUinB;
	
	/*initialise my alu*/
	wire [31:0] data_operandA, data_operandB;
	wire [4:0] ctrl_ALUopcode, ctrl_shiftamt;
	wire [31:0] data_result;
	wire isNotEqual, isLessThan, overflow;
	
	wire [11:0] ctrl;
	wire Op;
	wire overf;
	wire [4:0] overflow_writeReg;
	wire [31:0] s_immediate;
	wire [31:0] alu_output;
	wire [31:0] pc_next;
	wire [31:0] T;
	wire [31:0] pc_plus_1;
	wire [31:0] bex_where;
	wire [31:0] pc;
	
	//if br or jr is set, it is jump or branch, else it is pc_plus_1
	assign pc_next = (ctrl[11] || ctrl[10]) ? jump_or_branch : pc_plus_1;
	//if ctrl[11] == br is set, then it is branch, else it is branch
	assign jump_or_branch = ctrl[11] ? branch : jump;
	
	//jump
	
	//1.j
	
	assign j = ~opcode[4] && ~opcode[3] && ~opcode[2] && ~opcode[1] && opcode[0];
	
	//2.jal
	
	assign jal = ~opcode[4] && ~opcode[3] && ~opcode[2] && opcode[1] && opcode[0];
	
	//$r31 = PC + 1
	assign ctrl_writeReg = jal ? 5'd31 : overflow_writeReg;
	
	assign alu_or_pc_plus1 = jal ? pc_plus_1 : alu_output;
	assign alu_or_pc1_or_setx = setx ? T : alu_or_pc_plus1;
	//write what to reg: ctrl[0]==1 -> dmem , else alu or pc + 1
	assign data_writeReg = ctrl[0] ? q_dmem : alu_or_pc1_or_setx;
	
	
	//3.jr
	assign jr = ~opcode[4] && ~opcode[3] && opcode[2] && ~opcode[1] && ~opcode[0];
	
	assign bex =  opcode[4] && ~opcode[3] && opcode[2] && opcode[1] && ~opcode[0];
	
	assign bex_where[31:0] = (bex && isNotEqual) ? T : pc_plus_1;
	
	//for j and jal and bex, PC = T
	//for jr, PC = $rd = data_readRegA
	assign jump = bex ? bex_where:((j || jal ) ? T : data_readRegA);
	
	
	
	//branch
	
	
	assign pc_plus_one_plus_N = pc_plus_1 + s_immediate;	//pc + 1 + N
	
	
	//1. bne	$rd - $rs
	
	assign bne = ~opcode[4] && ~opcode[3] && ~opcode[2] && opcode[1] && ~opcode[0];
	
	assign bne_where = isNotEqual ? pc_plus_one_plus_N : pc_plus_1;
	
	//2.blt
	
	assign blt = ~opcode[4] && ~opcode[3] && opcode[2] && opcode[1] && ~opcode[0];
	
	assign blt_where = isLessThan ? pc_plus_one_plus_N : pc_plus_1;
	
	//3. bex
	
	
	
	
	
	assign branch = bne ? bne_where : blt_where;
	//4. setx
	
	assign setx =  opcode[4] && ~opcode[3] && opcode[2] && ~opcode[1] && opcode[0];
	
	 
	 
	 
	 
	/*initialise my alu*/
	
	alu alu1(data_operandA, 
				data_operandB, 
				ctrl_ALUopcode,
				ctrl_shiftamt, 
				data_result, 
				isNotEqual, 
				isLessThan, 
				overflow);
	
	/*cycles*/
	
	
	
	/*fetch the instruction which is q_imem*/
	
	
	
	//first: get the opcode
	
	assign opcode[4:0] = q_imem[31:27];
	//second: get the ctrl signal according to the control opcode
	
	assign ctrl[11:0] = control[opcode];
	
	//Op is 0 if opcode is 00000, else 1
	
	or or_(Op, opcode[0], opcode[1], opcode[2], opcode[3], opcode[4]);
	
	
	
	
	/*RegFile*/
    
	//Rwe signal
	assign ctrl_writeEnable = ctrl[2];
	//$reg write  [$rd]
	//when overflow occurs, $rd should be $30
	
	//when overflow is unknown or overflow is 0, writeReb will be $rd, otherwise
	//assign ctrl_writeReg[4:0] = (overf == 1'bX || overf == 1'b0) ? q_imem[26:22] : 5'b11110;
	
	
	assign overflow_writeReg[4:0] = (overf || setx)  ? 5'b11110 : q_imem[26:22];
	
	//assign ctrl_writeReg[4:0] = q_imem[26:22];
	
	//accomadate for sw $rd, (N)$rs   [opcode: 00111]
	//wire w1, w2, w3;
	//not not1(w1, opcode[4]);
	//not not2(w2, opcode[3]);
	//and and1(w3, w1,w2,opcode[2], opcode[1], opcode[0]);
	assign sw = ~opcode[4] && ~opcode[3] && opcode[2] && opcode[1] && opcode[0];
	//$reg read A (when sw, it is $rs, else it is still $rs)
	
	
	//when bne, jr, blt, ctrl read reg A is $rd
	wire [4:0] ctrl_regA;
	assign ctrl_regA[4:0] = (bne || jr || blt) ? q_imem[26:22] : q_imem[21:17];
	assign ctrl_readRegA = (bex || setx) ? 5'd30 : ctrl_regA;
	//$reg read B	(when sw, it is $rd, otherwise, it is it is $rt)
	
	wire [4:0] ctrl_readRegInB;
	assign ctrl_readRegInB [4:0] = sw ? q_imem[26:22]:q_imem[16:12];
	//when bne or blt, ctrl read reg read B is $rs
	wire [4:0] ctrl_regB;
	assign ctrl_regB[4:0] = (bne || blt) ? q_imem[21:17] : ctrl_readRegInB [4:0];
	assign ctrl_readRegB = (bex || setx) ? 5'd0 : ctrl_regB;
	
	
	
	
	
	
	/*ALU signal*/
	
	
	//give signal to ctrl_ALUopCode
	//if opcode is 00000: aluop comes from instruction
	//else: aluop comes from ctrl signal
	assign ctrl_ALUopcode[4:0] = Op ? ctrl[8:4] : q_imem[6:2];
	assign data_operandA = data_readRegA;	//assign data_operand A
	//assign data operand B
	//we need the sign extension immediate
	//get the signed_immediate
	 
	assign s_immediate[16:0] = q_imem[16:0];
	//sign extended immediate
	assign s_immediate[31:17] = q_imem[16] ? 15'b111111111111111:15'b000000000000000;
	//add a mux between the immediate and the data_readRegB
	
	assign ALUinB = ctrl[9];
	//For data_operandB, we need a mux to select between immediate and data_readRegB
	assign data_operandB = ALUinB ? s_immediate : data_readRegB;
	assign ctrl_shiftamt = q_imem[11:7];
	
	//if there is an overflow, we need to change ctrl_writeReg to $30 and change data_writeReg to 1,2,3 accordingly
	//this means we need to overwrite ctrl_writeReg and data_writeReg
	
	
	//overflow1 = 1 when add overflow
	wire w5, _w5, overflow1;
	or or1 (w5, Op, q_imem[6], q_imem[5], q_imem[4], q_imem[3], q_imem[2]);
	not not3(_w5, w5);
	and and2(overflow1, _w5, overflow);
	
	
	
	//overflow2 = 1 when addi overflows
	wire	w6, w7, w8, overflow2;
	not not4(w6, opcode[4]);
	not not5(w7, opcode[3]);
	not not6(w8, opcode[1]);
	and and3(overflow2, w6, w7, w8, opcode[0], opcode[2], overflow);
	
	//overflow3 = 1 when sub overflows
	wire w9, w10, w11, w12, w13, overflow3;
	not not7(w9, q_imem[6]);
	not not8(w10, q_imem[5]);
	not not9(w11, q_imem[4]);
	not not10(w12, q_imem[3]);
	not not11(w13, Op);
	and and4(overflow3, w13, w9, w10, w11, w12,  q_imem[2], overflow);
	
	//ctrl_writereg is $30 if overflow occurs, else it is $rd
	//using wire overf to cobtrol the mux in the regfile above
	or or_gate(overf, overflow1, overflow2, overflow3);
	
	
	
	//alu output
	//when overflow occurs: alu output should be 1/2/3, else output data result
	
	
	//data_result_flag is 1 when overflow1 = 0, overflow2 = 0 and overflow3 = 0
	wire data_result_flag, w14;
	or or_gate1(w14, overflow1, overflow2, overflow3);
	not not_gate1(data_result_flag, w14);
	
	//using two control bits mux select between dataresult, 1, 2 and 3
	wire [2:0] not_overs;
	not not12 (not_overs[2], overflow3);
	not not13 (not_overs[1], overflow2);
	not not14 (not_overs[0], overflow1);
	
	wire w15, w16, in1;
	and and5 (w15, not_overs[0], overflow2, not_overs[2]);
	and and6 (w16, not_overs[0], not_overs[1], overflow3);
	or or6(in1, w15, w16);
	
	
	wire w17, w18, in2; 
	and and7 (w17, overflow1, not_overs[1], not_overs[2]);
	and and8 (w18, not_overs[0], not_overs[1], overflow3);
	or or7(in2, w17, w18);
	
	wire [31:0] up [1:0];
	assign up[0] = data_result;
	assign up[1] = 32'd1;
	
	wire [31:0] down [1:0];
	assign down[0] = 32'd2;
	assign down[1] = 32'd3;
	
	wire [31:0] first_level [1:0];
	assign first_level[0] = in1 ? down[0] : up[0];
	assign first_level[1] = in1 ? down[1] : up[1];
	
	assign  alu_output = in2 ? first_level[1] : first_level[0];
	
	
	//assign alu_output = data_result_flag ? data_result : 32'hzzzzzzzz;
	//assign alu_output = overflow1 ? 32'd1 : 32'hzzzzzzzz;
	//assign alu_output = overflow2 ? 32'd2 : 32'hzzzzzzzz;
	//assign alu_output = overflow3 ? 32'd3 : 32'hzzzzzzzz;
	
	
	/*data memo*/
	
	
	// Dmem
    //output [11:0] address_dmem;
    //output [31:0] data;
    //output wren;
    //input [31:0] q_dmem;
	
	assign address_dmem[11:0] = alu_output[11:0];
	assign data = data_readRegB;
	assign wren = ctrl[3];	//assign with DMwe contral signal
	
	
	
	assign T[26:0] = q_imem[26:0];
	
	//add the instruction address (PC)
	reg_32 pc_fet(pc, pc_next, 1'b1, clock, reset);
	assign address_imem = pc[11:0];
	
	assign pc_plus_1 = pc + 1'b1;
	
	
	
	
	
	
	
endmodule