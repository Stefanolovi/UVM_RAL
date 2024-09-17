module register_file #(parameter NBIT = 64,
                  parameter NREG = 16,
                  parameter NADDR = 4)
  (
        input   logic CLK,
        input   logic RESET,
        input   logic ENABLE, 
        input   logic WR,
        input   logic [NADDR-1:0] ADD_WR,
        //input   logic [NADDR-1:0] ADD_RD1, 
        //input   logic [NADDR-1:0] ADD_RD2, 
        input   logic [NBIT-1:0] DATAIN, 
        //input   logic SUBCALL, 
        //input   logic SUBRETURN, 
        //input   logic [NBIT-1:0] BUSIN, 

        //output  logic [NBIT-1:0] BUSOUT,
        output  logic [NBIT-1:0] OUT1
        //output  logic [NBIT-1:0] OUT2
    ); 
  
      // Register array
  logic [NBIT-1:0] reg_array [0:NREG-1];

    // Write operation
  always_ff @(posedge CLK or posedge RESET) begin
    if (RESET) begin
            // Initialize all registers to 0 on reset
            integer i;
      for (i = 0; i < NREG; i = i + 1) begin
                reg_array[i] <= '0;
            end
    end else if (WR) 
            // Write data to the specified register
      reg_array[ADD_WR] <= DATAIN;
      else OUT1 <= reg_array[ADD_WR];

  end

    // Read operation
  // always_ff @(posedge CLK) begin
  //       // Read data from the specified register
  //   OUT1 <= reg_array[ADD_RD1];
  //   OUT2 <= reg_array[ADD_RD2];
  //   end
endmodule