// In this program we will see a UVM blocking put port communicates with blocking put imp through a export
// Ports are always initiators (exceptions apply)
// exports are passthru ports 
// Imp are termination ports
// Note using blocking ports we can use task, if it is a non blocking we will have to use function



import uvm_pkg::*;
`include "uvm_macros.svh"
program tb;

// Simple transaction which has 3 fields data,addr,wr_en
class transaction extends uvm_object; 
  rand bit[3:0] data;
  rand bit[5:0] addr;
  rand bit wr_en;
  
  `uvm_object_utils_begin(transaction);
  `uvm_field_int(data,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_ALL_ON)
  `uvm_field_int(wr_en,UVM_ALL_ON)
  `uvm_object_utils_end;
  
  
  function new (string name  = "transaction");
    super.new(name);
  endfunction  
    
endclass


// comp_a is the initator in this program which randomizes the transaction and calls the put method. 
class comp_a extends uvm_component;
  `uvm_component_utils (comp_a)
  
  uvm_blocking_put_port #(transaction) trans_out;
  
  function new (string name = "comp_a", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     trans_out = new("trans_out",this);
  endfunction
  
  task run_phase (uvm_phase phase);
    transaction tx;
    
    tx = transaction::type_id::create("tx", this);
    
    void'(tx.randomize());
    `uvm_info(get_type_name(),$sformatf(" tranaction randomized"),UVM_LOW)
    tx.print();
    `uvm_info(get_type_name(),$sformatf(" tranaction sending to comp_b"),UVM_LOW)
    trans_out.put(tx);

  endtask  
  
endclass


// comp_b has a imp port where we need to implement the put method.
class comp_b extends uvm_component;
  `uvm_component_utils (comp_b)
  
  uvm_blocking_put_imp #(transaction,comp_b) trans_in;
  
  function new (string name = "comp_b", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     trans_in = new("trans_in",this);
  endfunction
  
  task put (transaction tx);
    
    #100;
    `uvm_info(get_type_name(),$sformatf(" Recived trans On comp_b "),UVM_LOW)
    `uvm_info(get_type_name(),$sformatf(" trans, \n %s",tx.sprint()),UVM_LOW)

  endtask  
  
endclass

// Parent comp_b is the component that connects with comp_a and parent_comp_b acts as a channel to comp_b

class parent_comp_b extends uvm_component;
  `uvm_component_utils (parent_comp_b)
  
  comp_b test_comp_b;
  
  uvm_blocking_put_export #(transaction) trans_passthru;
  
  function new (string name = "parent_comp_b", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     trans_passthru = new("trans_passthru",this);
     test_comp_b = comp_b::type_id::create("test_comp_b",this);
  endfunction
  
  function void connect_phase (uvm_phase phase);
    trans_passthru.connect(test_comp_b.trans_in);
  endfunction


  
endclass

// env is connecting both the comp_a and parent_comp_b 
class my_env extends uvm_env;
  `uvm_component_utils(my_env)
  
  comp_a test_a;
  parent_comp_b test_b;
  
  function new (string name = "my_env", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     test_a = comp_a::type_id::create("test_a",this);
     test_b = parent_comp_b::type_id::create("test_b",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    test_a.trans_out.connect(test_b.trans_passthru);
  endfunction
  
endclass

class base_test extends uvm_test;

  `uvm_component_utils(base_test)
  
 
  my_env env;

  
  function new(string name = "base_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

 
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = my_env::type_id::create("env", this);
  endfunction : build_phase
  
  
   function void end_of_elaboration();
   
    print();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #500;
    phase.drop_objection(this);
  endtask
  
endclass : base_test



  initial begin
    run_test("base_test");  
  end  
  
endprogram
