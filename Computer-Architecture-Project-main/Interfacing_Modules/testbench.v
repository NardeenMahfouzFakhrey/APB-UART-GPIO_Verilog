module testbench #(
  parameter DATA_WIDTH = 32,
  parameter ADDRESS_WIDTH = 32
)(
    input PCLK,
    output [DATA_WIDTH - 1 : 0] PADDR,
    output PSEL1,
    output PENABLE,
    output PWRITE,
    output [DATA_WIDTH - 1 : 0] PWDATA,
    output PREADY,
    input  [DATA_WIDTH - 1 : 0] PRDATA,

    input [DATA_WIDTH - 1 : 0] GPIO_OUTPUT ,
    output reg [DATA_WIDTH - 1 : 0]  GPIO_INPUT 
);

  wire PSEL2; 
  reg PRESETn;
  reg transfer;
  reg READ_WRITE;
  reg  [DATA_WIDTH - 1 : 0] apb_write_paddr;
  reg  [DATA_WIDTH - 1 : 0] apb_write_data;
  reg  [DATA_WIDTH - 1 : 0] apb_read_paddr;
  wire [DATA_WIDTH - 1 : 0] apb_read_data_out;
  
    
  localparam DIRECTION = 0,
             INPUT     = 1, 
             OUTPUT    = 2;
    
    integer errors = 0;
    integer got_reset = 0;

    APB_master apb_master(
       PCLK,PRESETn,transfer,READ_WRITE,PREADY,apb_write_paddr,apb_write_data,
       apb_read_paddr,PRDATA, PWRITE, PENABLE, PSEL1, PSEL2,PADDR,PWDATA,apb_read_data_out ); 

  initial begin
    
    welcome_text();

    test_reset_register_values();
    
    //simple_test();
    
    //error_test();
    
    test_io_basic();
    
    repeat (100) @(posedge PCLK);
    finish_text();
    $finish();
    
  end

 task welcome_text();
   begin
    $display ("------------------------------------------------------------");
    $display (" APB GPIO Testbench Initialized                             ");
    $display ("------------------------------------------------------------");
   end
  endtask 

task write (
    input [ADDRESS_WIDTH  -1:0] address,
    input [DATA_WIDTH  -1:0] data
);
    begin
    
     PRESETn = 1;
     transfer = 1;
     READ_WRITE = 0;
     apb_write_paddr = address;
     apb_write_data = data;
     @(posedge PCLK);
     @(posedge PCLK);
     @(posedge PCLK);
     @(posedge PCLK);
    end
endtask

  
task read (
    input  [ADDRESS_WIDTH -1:0] address,
    output [DATA_WIDTH -1:0] data
);
    begin
      
     PRESETn = 1;
     transfer = 1;
     READ_WRITE = 1;
     apb_read_paddr = address;
     
     @(posedge PCLK);
     @(posedge PCLK);
     @(posedge PCLK);
     @(posedge PCLK);
     
     transfer = 0;
     READ_WRITE = 1'bx;
     apb_read_paddr = {ADDRESS_WIDTH{1'bx}};
     data = apb_read_data_out;
    end
endtask



task check (
    input reg[15*8:0]      name,
    input [DATA_WIDTH-1:0] actual,
                           expected
  );
  begin
    $display("Checking %s for %b==%b ", name, actual, expected);
    if (actual !== expected) error_msg(name, actual, expected);
  end
  endtask


  task error_msg(
    input reg[10*8:0]       name,
    input [DATA_WIDTH-1:0]  actual,
                            expected
  );
  begin
    errors = errors + 1;
    $display("ERROR  : Incorrect %s value. Expected: %b, received: %b @%0t", name, expected, actual, $time);
  end
  endtask


task test_reset_register_values;
  
    reg [DATA_WIDTH-1:0] readdata;
  begin
    $display ("Checking reset values ...");

    read(DIRECTION, readdata);
    
    read(DIRECTION, readdata);
    check("DIRECTION", readdata, {DATA_WIDTH{1'b0}});

    read(OUTPUT, readdata);
    check("gpio_output", readdata, {DATA_WIDTH{1'b0}});

  end

endtask


/*
   * Basic IO tests
   */
  task test_io_basic;
     
      reg [DATA_WIDTH-1:0] readdata;
      reg [DATA_WIDTH-1:0] dir;
      reg [DATA_WIDTH-1:0] input_data;
      reg [DATA_WIDTH-1:0] expected_output;
      reg [DATA_WIDTH-1:0] expected_input;
      reg [DATA_WIDTH-1:0] output_data;
      integer i;
      integer test;
    begin
      $display ("Basic IO test ...\n");

          for (test = 0; test < 30; test = test + 1) begin

                $display("Test %d", test);

                dir = $random;
                output_data = $random;
                input_data = $random;
                
                write(DIRECTION, dir);
                read(DIRECTION , readdata);
                
                check("Direction", readdata, dir);
              
              
                write(OUTPUT   , output_data);
                
                for(i = 0; i < DATA_WIDTH; i = i + 1)begin
                  expected_output[i] = dir[i] ? output_data[i] : 1'bx ;
                end 

                @(posedge PCLK);
                @(posedge PCLK);

                check("gpio_output", GPIO_OUTPUT , expected_output);

                GPIO_INPUT = input_data;
                for(i = 0; i < DATA_WIDTH; i = i + 1)begin
                  expected_input[i] = dir[i] ? 1'bz : input_data[i];
                end 


                read(INPUT , readdata);
                check("gpio_input", readdata , expected_input);

                 expected_output = 'hxx;
                 expected_input = 'hxx;

                $display("\n");

          end
    end 
  endtask

  task finish_text();
  begin
    if (errors>0)
    begin
        $display ("------------------------------------------------------------");
        $display (" APB GPIO Testbench failed with (%0d) errors @%0t", errors, $time);
        $display ("------------------------------------------------------------");
    end
    else
    begin
        $display ("------------------------------------------------------------");
        $display (" APB GPIO Testbench finished successfully @%0t", $time);
        $display ("------------------------------------------------------------");
    end
  end
  endtask


task simple_test;
  reg [DATA_WIDTH-1:0] readdata;
  reg [DATA_WIDTH-1:0] dir;
  reg [DATA_WIDTH-1:0] input_data;
  reg [DATA_WIDTH-1:0] expected_output;
  reg [DATA_WIDTH-1:0] expected_input;
  reg [DATA_WIDTH-1:0] output_data;
  integer i;
  begin
    $display("simple test begin\n");

                dir = $random;
                output_data = $random;
                input_data = $random;
                
                for(i = 0; i < DATA_WIDTH; i = i + 1)begin
                  expected_output[i] = dir[i] ? output_data[i] : 1'bx ;
                end 
                for(i = 0; i < DATA_WIDTH; i = i + 1)begin
                  expected_input[i] = dir[i] ? 1'bz : input_data[i];
                end 
                
                write(DIRECTION, dir);
                read(DIRECTION , readdata);
                check("Direction", readdata, dir);
                
              
                write(OUTPUT   , output_data);
                check("gpio_output", GPIO_OUTPUT , expected_output);

                GPIO_INPUT = input_data;
                read(INPUT , readdata);
                check("gpio_input", readdata , expected_input);

                expected_output = 'hxx;
                expected_input = 'hxx;

                $display("\n");

  end
endtask 

task error_test;
  reg [DATA_WIDTH-1:0] readdata;
  reg [DATA_WIDTH-1:0] dir;
  reg [DATA_WIDTH-1:0] input_data;
  reg [DATA_WIDTH-1:0] expected_output;
  reg [DATA_WIDTH-1:0] expected_input;
  reg [DATA_WIDTH-1:0] output_data;
  begin
    $display("Just an example of an error:\n");

                dir = $random;
                output_data = $random;
                input_data = $random;
                
                expected_output = 'hzz;
                expected_input = 'hzz;
                
                write(DIRECTION, dir);
                read(DIRECTION , readdata);
                check("Direction", readdata, dir);
              
                write(OUTPUT   , output_data);
                check("gpio_output", GPIO_OUTPUT , expected_output);

                GPIO_INPUT = input_data;
                read(INPUT , readdata);
                check("gpio_input", readdata , expected_input);

                expected_output = 'hxx;
                expected_input = 'hxx;

                $display("\n");

  end
endtask 
   

endmodule




