
interface RF_if #(parameter NBIT = 64,
                  parameter NREG = 16,
                  parameter NADDR = 4 
                  //parameter M = 4,
                  //parameter N = 4,
                  //parameter F = 4
                  );

    /* INTERFACE SIGNALS */
    logic               CLK; 
    logic               RESET;
    logic               ENABLE;
    //logic               RD1;
    //logic               RD2;
    logic               WR;
    logic [NADDR-1:0]  ADD_WR;
    //logic [NADDR-1:0]  ADD_RD1;
    //logic [NADDR-1:0]  ADD_RD2;
    logic [NBIT-1:0]   DATAIN;
    //logic              SUBCALL; 
    //logic              SUBRETURN; 
    //logic [NBIT-1:0]   BUSIN;
    //logic [NBIT-1:0]   BUSOUT;
    logic [NBIT-1:0]   OUT1;
    //logic [NBIT-1:0]   OUT2;
  
    /* Interface port at RF side (DUT) */
    modport RF_port (
        input   CLK,
        input   RESET,
        input   ENABLE,
        //input   RD1,
        //input   RD2, 
        input   WR,
        input   ADD_WR,
        //input   ADD_RD1, 
        //input   ADD_RD2, 
        input   DATAIN, 
        //input   SUBCALL, 
        //input   SUBRETURN, 
        //input   BUSIN, 

        //output  BUSOUT,
        output  OUT1
        //output  OUT2
    ); 
endinterface


module RF_wrap #(parameter NBIT = 64,
                  parameter NREG = 16,
                  parameter NADDR = 4)
                  //parameter M = 4,
                  //parameter N = 4,
                  //parameter F = 4)

                (RF_if.RF_port p); 
  
     register_file #(NBIT,NREG,NADDR) 
      RF_u (
            .CLK      (p.CLK),
            .RESET    (p.RESET),
            .ENABLE   (p.ENABLE),
            //.RD1    (p.RD1),
            //.RD2    (p.RD2),
            .WR    (p.WR),
            .ADD_WR    (p.ADD_WR),
            //.ADD_RD1    (p.ADD_RD1),
            //.ADD_RD2    (p.ADD_RD2),
            .DATAIN    (p.DATAIN),
            //.SUBCALL    (p.SUBCALL),
            //.SUBRETURN    (p.SUBRETURN),
            //.BUSIN    (p.BUSIN),
            //.BUSOUT    (p.BUSOUT),
            .OUT1    (p.OUT1)
            //.OUT2    (p.OUT2)
            );
endmodule
