
`include "uvm_macros.svh"

package my_pkg; 

  localparam int NBIT = 64;
  localparam int NREG = 16;
  localparam int NADDR = 4;
  localparam int num_cycles = 50;

  import uvm_pkg::*;
  import RAL_pkg::*;

    class sqnc_item extends uvm_sequence_item;

      `uvm_object_utils(sqnc_item)

      bit RESET; 
      rand bit WR;
      rand logic [NADDR-1:0] ADD_WR;
      rand logic [NBIT-1:0] DATAIN;
      logic [NBIT-1:0] OUT1;
      
      function new (string name = "");
        super.new(name);
      endfunction
      
      function string convert2string;
        return $sformatf("RESET = %b | WR = %b | ADD_WR = %h | DATAIN = %h |  OUT1 = %h |", 
        RESET, WR, ADD_WR, DATAIN, OUT1 );
      endfunction

    //copies an existing object
    function void do_copy(uvm_object rhs);
      sqnc_item tx;
      $cast(tx, rhs);
      RESET  = tx.RESET;
      WR = tx.WR;
      ADD_WR = tx.ADD_WR;
      DATAIN = tx.DATAIN;  
      OUT1 = tx.OUT1; 
    endfunction

  endclass: sqnc_item


  class reset_seq extends uvm_sequence #(sqnc_item); 
    `uvm_object_utils(reset_seq)

    sqnc_item rst_item; 

    function new (string name = ""); 
      super.new (name); 
    endfunction

    task body; 
      if (starting_phase != null)
        starting_phase.raise_objection(this); 
        repeat(3) begin 
          rst_item = sqnc_item::type_id::create("rst_item");
          start_item(rst_item);
          rst_item.RESET = 1; 
          rst_item.WR = 0; 
          rst_item.ADD_WR = 0; 
          rst_item.DATAIN = 0; 
          finish_item(rst_item);
          `uvm_info (get_type_name(), $sformatf("SEQUENCE ITEM GENERATED! | %S", rst_item.convert2string()), UVM_HIGH)
        end
          if (starting_phase != null)
        starting_phase.drop_objection(this);

    endtask

  endclass


  //implement default register sequences. 
  class rand_rw_seq extends uvm_sequence #(sqnc_item); 

    `uvm_object_utils(rand_rw_seq)

    function new (string name = ""); 
      super.new (name); 
    endfunction

    task body; 
      if (starting_phase != null)
      starting_phase.raise_objection(this); 
      repeat(num_cycles)
      // create the object, start it, randomize it, finish it. 
        begin
          req = sqnc_item::type_id::create("req");
          start_item(req);
          if( !req.randomize() )
            `uvm_error("", "Randomize failed")
          finish_item(req);
          `uvm_info (get_type_name(), $sformatf("SEQUENCE ITEM GENERATED!| %S", req.convert2string()), UVM_HIGH)
        end
      if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask 
  endclass

    //implement default register sequences. 
  class regmodel_rw extends uvm_reg_sequence(); 
    
    `uvm_object_utils(regmodel_rw)
    function new (string name = ""); 
      super.new (name); 
    endfunction

    task body; 
      //instance regmdoel, data variable and status var. 
      top_reg_block regmodel; 
      uvm_status_e status; 
      uvm_reg_data_t data;
     

      $cast (regmodel, model);
        for (int i = 0; i<16; i++)
        //
          begin 
            //write op on a specific register (status, value, parent)
            //regmodel.reg_file.reg_[i].write(status, .value('hcafecafecafecafe), .parent(this)); 
            //assert wethere write was successful. 
            //assert(status == UVM_IS_OK)
            //`uvm_info("MY_SEQ", $sformatf("Reading register: %s", regmodel.reg_file.reg_[i].get_full_name()), UVM_LOW);
            regmodel.reg_file.reg_[i].read(status, data, .parent(this));
            assert(status == UVM_IS_OK);  
            `uvm_info (get_type_name(), $sformatf("\n REGISTER %0d VALUE READ: %0h, MIRRORED VALUE: %0h\n", i, regmodel.reg_file.reg_[i].get(), regmodel.reg_file.reg_[i].get_mirrored_value()), UVM_MEDIUM)
          end
      //regmodel.reg_file.reg_[0].read(status, .value(data), .parent(this));
    endtask 
  endclass

  
  class driver extends uvm_driver #(sqnc_item); 
   `uvm_component_utils(driver)

    virtual RF_if dut_vi; 

    function new (string name, uvm_component parent); 
        super.new (name, parent); 
    endfunction

    function void build_phase (uvm_phase phase); 
      // Get interface reference from config database
      if( !uvm_config_db #(virtual RF_if)::get(this, "", "RF_if", dut_vi) )
        `uvm_error("", "uvm_config_db::get failed")
    endfunction

    task run_phase (uvm_phase phase); 
    //get sqnc_item, drive it to IF at posedge, close it
      forever
          begin
            seq_item_port.get_next_item(req);
            @(posedge dut_vi.CLK);
            `uvm_info ("DRIVER", $sformatf("DRIVING THE GENERATED PACKET: %h\n", dut_vi.DATAIN), UVM_HIGH)
            dut_vi.RESET = req.RESET;
            dut_vi.WR = req.WR;  
            dut_vi.ADD_WR = req.ADD_WR; 
            dut_vi.DATAIN = req.DATAIN;  
            seq_item_port.item_done();
          end
    endtask
  endclass


  class sequencer extends uvm_sequencer #(sqnc_item); 
    `uvm_component_utils(sequencer)
    function new (string name = "", uvm_component parent); 
      super.new(name, parent); 
    endfunction 
  endclass: sequencer


class monitor extends uvm_monitor; 
  
  `uvm_component_utils(monitor)
  virtual RF_if dut_vi;

  // I add the regmodel to check the value of the register at each operation;   
  top_reg_block regmodel; 

  function new (string name, uvm_component parent); 
    super.new(name,parent);
  endfunction
  
  // instance analysis port
  uvm_analysis_port #(sqnc_item) mon_analysis_port; 

  function void build_phase (uvm_phase phase); 
      `uvm_info (get_type_name(), "START BUILDING PHASE", UVM_HIGH)
    //get if
    if( !uvm_config_db #(virtual RF_if)::get(this, "", "RF_if", dut_vi) )
    `uvm_error("", "uvm_config_db::get failed")
    //if( !uvm_config_db #(top_reg_block)::get(this, "", "top_reg_block", regmodel) )
    //`uvm_error("", "uvm_config_db::get failed")
    //call analysys_port constructor
    mon_analysis_port = new ("mon_analaysis_port", this); 
  endfunction

  task run_phase (uvm_phase phase);
    //create an transaction object, assign the if value to it, write it on the port.
    sqnc_item data; 
    data = sqnc_item::type_id::create("data"); 
    //read at each positive edge of the clock
    forever begin 
      @(negedge dut_vi.CLK);
      `uvm_info(get_type_name(), $sformatf("MONITOR STARTS SAMPLING"), UVM_HIGH)
      data.RESET = dut_vi.RESET; 
      data.WR = dut_vi.WR; 
      data.ADD_WR = dut_vi.ADD_WR;  
      data.DATAIN = dut_vi.DATAIN; 
      //data.SUBCALL = dut_vi.SUBCALL; 
      //data.SUBRETURN = dut_vi.SUBRETURN; 
      //data.BUSIN = dut_vi.BUSIN; 
      data.OUT1 = dut_vi.OUT1; 
      //data.OUT2 = dut_vi.OUT2; 
      //data.BUSOUT = dut_vi.BUSOUT; 
      `uvm_info(get_type_name(), $sformatf("TRANSACTION RECEIVED: %s\n", data.convert2string()), UVM_MEDIUM)
    //pass the data to subscribers thorugh analysis port  
    mon_analysis_port.write(data);
    `uvm_info (get_type_name(), $sformatf("\n REGISTER %0d DESIRED VALUE: %0h, MIRRORED VALUE: %0h\n", data.ADD_WR , regmodel.reg_file.reg_[data.ADD_WR].get(), regmodel.reg_file.reg_[data.ADD_WR].get_mirrored_value()), UVM_MEDIUM)
    end     
  endtask
endclass



  class agent extends uvm_agent; 
    
    `uvm_component_utils(agent)

    driver drv; 
    sequencer sqncr; 
    monitor mntr; 

    function new (string name, uvm_component parent); 
      super.new(name, parent); 
    endfunction

    virtual function void build_phase (uvm_phase phase); 
      drv = driver::type_id::create("drv", this);
      sqncr = sequencer::type_id::create ("sqncr", this);
      mntr = monitor::type_id::create("mntr", this); 
    endfunction
    
    virtual function void connect_phase (uvm_phase phase);
      `uvm_info (get_type_name(), "START CONNECT PHASE", UVM_HIGH)
      //connect driver to sequencer
      drv.seq_item_port.connect(sqncr.seq_item_export);
    endfunction
  endclass


//   class scoreboard extends uvm_scoreboard; 

//   `uvm_component_utils(scoreboard)

//   int addr; 
//   bit [63:0] result; 
//   sqnc_item trans; 


//   top_reg_block regmodel; 

//   function new (string name = "scoreboard", uvm_component parent = null);
//     super.new(name, parent); 
//   endfunction

//   //get data from analysis_port, compute expected results, compare real results with expected. 
//   uvm_analysis_imp #(sqnc_item, scoreboard) ap_imp; 

//   virtual function void build_phase (uvm_phase phase); 
//       `uvm_info (get_type_name(), "START BUILDING PHASE", UVM_HIGH)
//     super.build_phase(phase);
//     ap_imp = new("ap_imp", this); 
//   endfunction

//   //check wether expected output matches the actual one.
//   virtual function void write (sqnc_item item); 
//     trans = sqnc_item::type_id::create("trans");
//     trans.do_copy(item); 
//     //if it's a write operation check write was successful
//     if (!trans.WR) begin 
//       addr = trans.ADD_WR;
//       result = regmodel.reg_file.reg_[addr].get_mirrored_value();
//       `uvm_info (get_type_name(), $sformatf("Mirrored Read: %0d, Actual: %0d, addr = %0h", result, trans.OUT1, addr), UVM_HIGH)
//       if (result != trans.OUT1)
//          `uvm_error(get_type_name(), $sformatf("Mirrored Read: %0d, Actual: %0d", result, trans.OUT1))
//     end
//   endfunction 

// endclass: scoreboard



  class adapter extends uvm_reg_adapter; 

    `uvm_object_utils(adapter)

    function new (string name = "");
      super.new (name);
      supports_byte_enable = 0; 
      provides_responses = 0; 
    endfunction

    //this function converts a reg operation object to a sequence item.  
    virtual function uvm_sequence_item reg2bus( const ref uvm_reg_bus_op rw); 
      sqnc_item bus_item = sqnc_item::type_id::create("bus_item"); 
      //if the reg_bus_op is a write set the sqnc_item's WR to 1, else it's a read op.
      bus_item.WR = (rw.kind == UVM_WRITE) ? 1 : 0;
      //copy addr and datain. 
      bus_item.ADD_WR = rw.addr;
      bus_item.DATAIN = rw.data;
      `uvm_info (get_type_name(), $sformatf("REG2BUS: ORDERING A %s OPERATION\n", rw.kind.name()), UVM_MEDIUM)
      return bus_item;
    endfunction

    //take a sqnc_item and convert it into a reg_bus_op. 
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw); 
    sqnc_item bus_item_in = sqnc_item::type_id::create("item");
      //cast the uvm_sequence_item into my own definition of it. 
      if (!$cast(bus_item_in, bus_item)) begin
        `uvm_fatal("BUS2REG", "Casting failed.")
        return;
        end 
      //`uvm_info (get_type_name(), $sformatf("BUS_ITEM_IN (casted) = %s | BUS_ITEM = %s", bus_item_in.convert2string(), bus_item.convert2string()), UVM_MEDIUM)
      //if bus.WR = 1 it's a write, else a read; 
      rw.kind = bus_item_in.WR ? UVM_WRITE : UVM_READ; 
      //if (bus_item_in.WR == 1) rw.kind = UVM_WRITE; 
      //else rw.kind = UVM_READ;
      `uvm_info (get_type_name(), $sformatf("BUS2REG: MAKING A %s OPERATION\n", rw.kind.name()), UVM_MEDIUM)
      rw.addr = bus_item_in.ADD_WR; 
      rw.data = bus_item_in.DATAIN; 
    endfunction
  endclass


  class env extends uvm_env; 

    `uvm_component_utils(env)

    agent ag0; 
    uvm_reg_predictor #(sqnc_item) p0; 
    adapter ad0; 
    //scoreboard sb0; 


    function new (string name = "", uvm_component parent); 
      super.new (name, parent); 
    endfunction


    virtual function void build_phase (uvm_phase phase); 
      `uvm_info (get_type_name(), "START BUILDING PHASE", UVM_HIGH)

      ag0 = agent::type_id::create("ag0", this);
      p0 = uvm_reg_predictor #(sqnc_item)::type_id::create ("p0", this);
      ad0 = adapter::type_id::create("ad0", this); 
      //sb0 = scoreboard::type_id::create("sb0", this);
    endfunction

    virtual function void connect_phase (uvm_phase phase);
      `uvm_info (get_type_name(), "START CONNECT PHASE", UVM_HIGH)
    // connect predictors adapter to my adapter
    p0.adapter   = ad0;
    //connect monitor to subscribers
    ag0.mntr.mon_analysis_port.connect(p0.bus_in);
    //ag0.mntr.mon_analysis_port.connect(sb0.ap_imp);
    endfunction
  endclass


  class top_env extends uvm_env;

    `uvm_component_utils(top_env)

    function new (string name = "", uvm_component parent); 
      super.new (name, parent); 
    endfunction

    env e0; 
    top_reg_block regmodel; 

    virtual function void build_phase (uvm_phase phase); 
      e0 = env::type_id::create("e0", this);
      regmodel = top_reg_block::type_id::create("regmodel", this);
      regmodel.build(); 
      uvm_config_db #(top_reg_block)::set (null, "top", "regmodel", regmodel);
    endfunction

    virtual function void connect_phase (uvm_phase phase); 
      //connect predictor map to regmodel map
      e0.p0.map = regmodel.top_rf_map;  
      //set regmodel's sequencer to agent's sequencer (also specify the adapter)
      regmodel.top_rf_map.set_sequencer(e0.ag0.sqncr, e0.ad0); 
      // turn off auto prediction
      regmodel.top_rf_map.set_auto_predict(1);
      //connect scoreboard regmodel to this regmodel 
      //e0.sb0.regmodel = regmodel; 
      e0.ag0.mntr.regmodel = regmodel; 
    endfunction
  endclass

  class test extends uvm_test; 
    `uvm_component_utils(test)
    top_env e0; 
    reset_seq rst;
    rand_rw_seq seq;
    regmodel_rw rw_model; 
   
    function new (string name, uvm_component parent); 
      super.new(name,parent); 
    endfunction

    virtual function void build_phase (uvm_phase phase); 
      `uvm_info (get_type_name(), "START BUILDING PHASE", UVM_MEDIUM)
      e0 = top_env::type_id::create("e0",this);
      seq = rand_rw_seq::type_id::create("seq");
      rst = reset_seq::type_id::create("rst");
      rw_model = regmodel_rw::type_id::create("rw_model");
    endfunction

    virtual function void connect_phase (uvm_phase phase); 
      rw_model.model = e0.regmodel;
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this); 
        //reset phase
        rst.starting_phase = phase; 
        rst.start(e0.e0.ag0.sqncr); 
        //randomize and start randop inputs sequence
        if( !seq.randomize() ) 
          `uvm_error("", "Randomize failed")
        //setting the starting phase, allows sequence to execute it's body.
        seq.starting_phase = phase;
        seq.start(e0.e0.ag0.sqncr);    
        //rw_model.starting_phase = phase; 
        rw_model.start(e0.e0.ag0.sqncr);
      phase.drop_objection(this); 
    endtask
      
  endclass

endpackage: my_pkg



module top; 
  import my_pkg::*;
  import uvm_pkg::*;
  //import RAL_pkg::*;
  
  
  
  //instance interface and wrap
  RF_if dut_if (); 
  RF_wrap dut_wrap(dut_if); 

  //clock
  initial
  begin
    dut_if.ENABLE = 1; 
    dut_if.CLK = 0;
    forever #5 dut_if.CLK = ~dut_if.CLK;
  end
  
  initial
  begin
    //set if db
    uvm_config_db #(virtual RF_if)::set(null, "*", "RF_if", dut_if);
    uvm_top.finish_on_completion = 1;
    //verbosity level
    uvm_top.set_report_verbosity_level(UVM_MEDIUM);
    //run the test
    `uvm_info ("TOP", $sformatf("TEST STARTIG..."), UVM_MEDIUM)
    run_test("test");
    `uvm_info ("TOP", $sformatf("TEST FINISHED"), UVM_MEDIUM)
  end

endmodule: top
