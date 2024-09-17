`include "uvm_macros.svh"

package RAL_pkg; 

import uvm_pkg::*;

localparam int NBIT = 64;
localparam int NREG = 16;
localparam int NADDR = 4;
localparam int M = 4;
localparam int N = 4;
localparam int F = 4;

//register component
class my_reg extends uvm_reg; 

  `uvm_object_utils(my_reg)
 
  function new (string name = ""); 
    super.new(name, NBIT, UVM_NO_COVERAGE); 
  endfunction

  //instantiate a single field that is 64 bits long. 
  rand uvm_reg_field f; 

  virtual function void build (); 
    f = uvm_reg_field::type_id::create("f");
    //parent - size - LSB - Access - Volatile - Reset_value - has_reset - gets_randomized - is_accessible
    f.configure(this, NBIT, 0, "RW", 1, 'h0, 1, 1, 1);  
  endfunction
endclass

//instances all registers needed, and maps them into a map object
class my_reg_block extends uvm_reg_block;

`uvm_object_utils(my_reg_block)
  //here I'm creating all the registers I need: each reg has a single field of 64 bits. 
  my_reg reg_ [(2*N*F)+M]; 
  uvm_reg_map rf_map; 

  function new (string name = ""); 
    super.new(name, UVM_NO_COVERAGE); 
  endfunction

  virtual function void build (); 
                       //***little_endian means LSB stored and transmitted first
                      //(name, base_address, Bytewidth, endianness) 
    rf_map = create_map ("rf_map", 0, 8, UVM_LITTLE_ENDIAN);  
    //'create', 'configure', build each register; then add each register in the map's address space
      for (int i=0; i<(2*N*F+M); i++) begin
        reg_[i] = my_reg::type_id::create($sformatf("reg_[%0d]", i),,get_full_name());
        reg_[i].configure(this, null, ""); 
        reg_[i].build(); 
                    //(reg, offset, access)
        rf_map.add_reg(reg_[i], i, "RW");
      end
      default_map = rf_map;
      lock_model(); 
  endfunction
endclass

//instance the regblock into this top module
class top_reg_block extends uvm_reg_block;

 `uvm_object_utils (top_reg_block)
  //instantiate reg file and map
  my_reg_block reg_file; 
  uvm_reg_map top_rf_map; 

  function new (string name = ""); 
    super.new(name, UVM_NO_COVERAGE); 
  endfunction

  virtual function void build (); 
    reg_file = my_reg_block::type_id::create("reg_file");
    reg_file.configure(this); 
    reg_file.build(); 
    top_rf_map = create_map ("top_rf_map", 0, 8, UVM_LITTLE_ENDIAN);
    default_map = top_rf_map; 
    top_rf_map.add_submap(reg_file.rf_map, 0); 
    lock_model(); 
  endfunction
endclass

endpackage