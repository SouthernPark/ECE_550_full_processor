# ECE_550_full_processor  
j T:  
add the conrtol bits for jump in ROM;  
according to the JP control bit, we can determine whether the next pc is pc+1 or T by using a mux.  
bne $rd, $rs, N  
Firstly, we have to set $rd as the data_readRegA and $rs as data_readRegB, because we want to do $rd - $rs using the ALU.  
And the input of the alu is actuall data_readReg  