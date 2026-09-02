`timescale 1ns / 1ps

`define opcode      IR[31:27]
`define dst_reg     IR[26:22]
`define src_reg1    IR[21:17]
`define mode        IR[16] //mode=1->immediate mode
`define src_reg2    IR[15:11]
`define imm_data    IR[15:0] //immediate mode data 



//arthemetic operatins
`define movsgpr     5'b00000 //move the content of SGPR to dst_reg
`define mov         5'b00001 //move operaation
`define add         5'b00010
`define sub         5'b00011
`define mul         5'b00100
//logical operations
`define rand        5'b00101//as OR is keyword we define ror
`define ror         5'b00110
`define rxor        5'b00111
`define rxnor       5'b01000
`define rnand       5'b01001
`define rnor        5'b01010
`define rnot        5'b01011
//Input-Output connection
`define storereg    5'b01100//store content of reg to data memory
`define storedin    5'b01101//store content of din to Data memory
`define senddout    5'b01110//send data from DM to dout
`define sendreg     5'b01111//send data from data memory to reg
//jump and branching
`define jump        5'b10000//jump to adress
`define jcarry      5'b10001//jump if carry flag is high
`define jnocarry    5'b10010//jump if carry flag is not high
`define jsign       5'b10011
`define jnosign     5'b10100
`define jzero       5'b10101
`define jnozero     5'b10110
`define joverflow   5'b10111
`define jnooverflow 5'b11000

`define halt        5'b11001


module top(
input clk,reset,
input [15:0] din,//to recive input from external world
output reg [15:0] dout//to output data to the extenal world 
);

reg [31:0] IR ; //instruction Reg
reg [15:0] GPR [31:0]; //32 General pupose reg of each 16 bit 

reg [15:0] SGPR; //special GPR to store multipicaton
reg [31:0] mul_res; //store multiplication result (16 bit*16 bit=32bit)

//Condition Flags
reg sign=1'd0,overflow=1'd0,zero=1'd0,carry=1'd0;
reg [16:0] temp_sum;//to store the reult of sum temperaorily 

//memory
reg [31:0] inst_mem [31:0];//16-program memory (each instruction is 32 bit)
reg [15:0] data_mem [15:0];//16-data memeory (each operand is 16 bit0

//there is no direct acess to din and reg we contact using data memory

initial begin
$readmemb("D:/Verilog/Udemy/Processor/inst_mem.mem",inst_mem);
end

//program counter
reg [2:0]count;//ensure all instruction is completed we wait 4 clk cycle
integer PC;

reg jump_flag=1'b0;
reg stop_flag=1'b0;

parameter idle=0,fetch_inst=1,decode_execute_inst=2,delay_next_inst=3,next_inst=4,sense_halt=5;
reg [2:0] state=idle,nstate=idle;

always@(posedge clk)
    begin
        if(reset)
            state<=idle;
        else
            state<=nstate;
    end

always@(*)
    begin
        case(state)
            idle:
                begin
                    IR=0;
                    PC=0;
                    nstate=fetch_inst;
                end
            fetch_inst:
                begin
                    IR=inst_mem[PC];
                    nstate=decode_execute_inst;
                end
            decode_execute_inst:
                begin
                    decode_inst();
                    decode_condflag();
                    nstate=delay_next_inst;
                end
            delay_next_inst:
                begin
                    if(count<4)
                        nstate=delay_next_inst;
                    else
                        nstate=next_inst;
                end
            next_inst:
                begin
                    if(jump_flag)
                        PC=`imm_data;
                    else
                        PC=PC+1;
                    nstate=sense_halt;
                end
            sense_halt:
                begin
                    if(stop_flag==1'b0)
                        nstate=fetch_inst;
                    else if(reset)
                        nstate=idle;
                    else
                        nstate=sense_halt;
                end
        endcase
    end
                    
always@(posedge clk)
    begin
        case(state)
            idle:count<=0;
            fetch_inst:count<=0;
            decode_execute_inst:count<=0;
            delay_next_inst:count<=count+1'b1;
            next_inst:count<=0;
            sense_halt:count<=0;
            
        default:count<=0;
        endcase
    end




task decode_inst();
    begin
        jump_flag=1'b0;
        stop_flag=1'b0;
        case(`opcode)
            
            `movsgpr:
                begin
                    GPR[`dst_reg]=SGPR; //move the content of SGPR to the GPR of adress dst_reg(both are 16 bit)
                end
            `mov:
                begin
                    if(`mode)
                        GPR[`dst_reg]=`imm_data;//if mode is 1 the move the data present in IR directly to src reg
                    else
                        GPR[`dst_reg]=GPR[`src_reg1]; //move the content of reg present in the adress of src_reg to dst_reg adressed reg
                end
            `add:
                begin
                    if(`mode)
                        GPR[`dst_reg]=GPR[`src_reg1]+`imm_data;//if mode is 1 the move the data present in IR directly to src reg
                    else
                        GPR[`dst_reg]=GPR[`src_reg1]+GPR[`src_reg2]; //move the content of reg present in the adress of src_reg to dst_reg adressed reg
                end
            `sub:
                begin
                    if(`mode)
                        GPR[`dst_reg]=GPR[`src_reg1]-`imm_data;//if mode is 1 the move the data present in IR directly to src reg
                    else
                        GPR[`dst_reg]=GPR[`src_reg1]-GPR[`src_reg2]; //move the content of reg present in the adress of src_reg to dst_reg adressed reg
                end
            `mul:
                begin
                    if(`mode)
                        mul_res=GPR[`src_reg1]*`imm_data;//if mode is 1 the move the data present in IR directly to src reg
                    else
                        mul_res=GPR[`src_reg1]*GPR[`src_reg2]; //move the content of reg present in the adress of src_reg to dst_reg adressed reg
                    GPR[`dst_reg]=mul_res[15:0];
                    SGPR=mul_res[31:0];
                end
            `rand:
                begin
                    if(`mode)
                        GPR[`dst_reg]=GPR[`src_reg1] & `imm_data;
                    else
                        GPR[`dst_reg]=GPR[`src_reg1] & GPR[`src_reg2];
                end
            `ror:
                begin
                    if(`mode)
                        GPR[`dst_reg]=GPR[`src_reg1] | `imm_data;
                    else
                        GPR[`dst_reg]=GPR[`src_reg1] | GPR[`src_reg2];
                end
            `rxor:
                begin
                    if(`mode)
                        GPR[`dst_reg]=GPR[`src_reg1] ^ `imm_data;
                    else
                        GPR[`dst_reg]=GPR[`src_reg1] ^ GPR[`src_reg2];
                end
            `rxnor:
                begin
                    if(`mode)
                        GPR[`dst_reg]=GPR[`src_reg1] ~^ `imm_data;
                    else
                        GPR[`dst_reg]=GPR[`src_reg1] ~^ GPR[`src_reg2];
                end
            `rnand:
                begin
                    if(`mode)
                        GPR[`dst_reg]=~(GPR[`src_reg1] & `imm_data);
                    else
                        GPR[`dst_reg]=~(GPR[`src_reg1] & GPR[`src_reg2]);
                end
            `rnor:
                begin
                    if(`mode)
                        GPR[`dst_reg]=~(GPR[`src_reg1] | `imm_data);
                    else
                        GPR[`dst_reg]=~(GPR[`src_reg1] | GPR[`src_reg2]);
                end
            `rnot:
                begin
                    if(`mode)
                        GPR[`dst_reg]=~(`imm_data);
                    else
                        GPR[`dst_reg]=~(GPR[`src_reg1]);
                end
            `storereg:
                begin
                   data_mem[`imm_data]=GPR[`src_reg1]; 
                end
            `storedin:
                begin
                    data_mem[`imm_data]=din;//16 bit adress can only be prsent in imm_data in IR    
                end
            `senddout:
                begin
                    dout=data_mem[`imm_data];                    
                end
            `sendreg:
                begin
                    GPR[`dst_reg]=data_mem[`imm_data];
                end
            `jump:
                begin
                   jump_flag=1'b1; 
                end
            `jcarry:
                begin
                    if(carry)
                        jump_flag=1'b1;
                    else
                        jump_flag=1'b0;
                end
             `jnocarry:
                begin
                    if(carry)
                        jump_flag=1'b0;
                    else
                        jump_flag=1'b1;
                end
             `jsign:
                begin
                    if(sign)
                        jump_flag=1'b1;
                    else
                        jump_flag=1'b0;
                end
             `jnosign:
                begin
                    if(sign)
                        jump_flag=1'b0;
                    else
                        jump_flag=1'b1;
                end 
             `jzero:
                begin
                    if(zero)
                        jump_flag=1'b1;
                    else
                        jump_flag=1'b0;
                end 
             `jnozero:
                begin
                    if(zero==1'b0)
                        jump_flag=1'b1;
                    else
                        jump_flag=1'b0;
                end
             `joverflow:
                begin
                    if(overflow)
                        jump_flag=1'b1;
                    else
                        jump_flag=1'b0;
                end 
             `jnooverflow:
                begin
                    if(overflow)
                        jump_flag=1'b0;
                    else
                        jump_flag=1'b1;
                end  
             `halt:
                begin
                  stop_flag=1'b1;  
                end               
        endcase
    end
    endtask
    
task decode_condflag();
    begin
    //sign flag
        if(`opcode==`mul)
            sign=SGPR[15];//sign of mul is present in MSB bit of SGPR
        else
            sign=GPR[`dst_reg][15];//16th bit of the dst reg
    //carry flag
        if(`opcode==`add)
            begin
                if(`mode)
                    begin
                        temp_sum=GPR[`src_reg1]+`imm_data;
                        carry=temp_sum[16];
                    end
                else
                    begin
                        temp_sum=GPR[`src_reg1]+GPR[`src_reg2];
                        carry=temp_sum[16];
                    end
            end
          else
              carry=1'b0;
    //zeroflag;
        if(`opcode==`mul)
            zero=~((|SGPR)|(|GPR[`dst_reg]));
        else
            zero=~(|GPR[`dst_reg]);
      //overflow flag;
        if(`opcode==`add)
            begin
                if(`mode)
                    overflow=((GPR[`dst_reg][15]&~GPR[`src_reg1][15]&~IR[15])||(~GPR[`dst_reg][15]&GPR[`src_reg1][15]&IR[15]));
                else
                    overflow=((GPR[`dst_reg][15]&~GPR[`src_reg1][15]&~GPR[`src_reg2])||(~GPR[`dst_reg][15]&GPR[`src_reg1][15]&GPR[`src_reg2]));
            end
        else if(`opcode==`sub)
            begin
                if(`mode)
                    overflow=((~GPR[`dst_reg][15]&GPR[`src_reg1][15]&~IR[15])||(GPR[`dst_reg][15]&~GPR[`src_reg1][15]&IR[15]));
                else
                    overflow=((~GPR[`dst_reg][15]&GPR[`src_reg1][15]&~GPR[`src_reg2])||(GPR[`dst_reg][15]&~GPR[`src_reg1][15]&GPR[`src_reg2]));
            end
       else
            overflow=1'd0;                      
    end
    endtask
    
    
endmodule
