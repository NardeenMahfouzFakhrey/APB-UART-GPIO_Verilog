`include "C:/altera/13.0sp1/GPIO_V.v "
`include "C:/altera/13.0sp1/UART_V.v "
`include "C:/altera/13.0sp1/APB_V.v "


module test_UARTAPB();
   parameter Tt     = 2; //clock timout
   
    reg rxd;
    wire txd;
    reg PCLK,PRESETn,transfer,READ_WRITE;
    reg[31:0]  apb_write_paddr,apb_write_data,apb_read_paddr;
    wire[31:0] apb_read_data_out,GPIO_INPUT,GPIO_OUTPUT;
   

    integer i;
    
     reg [31:0] expected; 
     
     
     integer errors = 0;
     
     
    initial begin
        PCLK = 0;
        forever PCLK = #(Tt/2) ~PCLK;
    end
    
  reg [31:0]TX;
    
    
  task automatic write (
  );
  begin
    expected = $random;
    PRESETn = 1;
    transfer=1;
    READ_WRITE=0;  
    apb_write_paddr= 32'hFFFFFFFF;
    apb_write_data = expected;
    #1059;
    for(i=0;i<32;i=i+1)begin
    if ((i+1)%8 ==0 )begin 
      #636;
    end
  
    TX[i] = txd; 
    #212;
    end   
    $display("Expected = %b",expected);
    $display("%b",TX);
    /////////////////
    $display("Checking UART_APB_WRITE if Transmitted data: %b equals Expected value: %b", TX, expected);
    if (TX == expected) begin 
    $display("ZERO ERRORS , The transmitted data equals the expected value");
    end
    if (TX !== expected) begin 
    errors = 1;
    $display("ERROR , The transmitted data not equal the expected value");
    end
 
  end
  endtask

   task automatic read (
    
  );
  begin
    PRESETn = 1;
    transfer= 1;
    READ_WRITE = 1;
     apb_read_paddr= 32'hFFFFFFFF;
     expected = $random;
    for (i=0 ; i< 32; i=i+1) begin
    
      if(i%8==0 && i!=0)
        begin 
          rxd =0; #260;
          rxd =0; #260;
        end
        #260;
      rxd = expected[i];    
      end
      #1300;
     //$monitor("%b",apb_read_data_out );
    $display("Checking UART_APB_READ if Reciecved data: %b equals Expected value: %b", apb_read_data_out, expected);
    if (apb_read_data_out == expected) begin 
    $display("ZERO ERRORS , The recieved data equals the expected value");
    end
    if (apb_read_data_out !== expected) begin 
    errors = 1;
    $display("ERROR , The recieved data not equal the expected value");
    end
  end
  endtask

APB_Protocol1 APB_protocol_dut(PCLK,PRESETn,transfer,READ_WRITE,rxd,apb_write_paddr,apb_write_data,apb_read_paddr,apb_read_data_out,txd,
    GPIO_INPUT,GPIO_OUTPUT);
    
  initial
begin
test_UARTAPB.welcome_text;
#20;
test_UARTAPB.read;
#20;
test_UARTAPB.finish_text;
/*
test_UARTAPB.welcome_text;
#20;
test_UARTAPB.write;
*/
 end

 
 
  
  task welcome_text();
   begin
    $display ("------------------------------------------------------------");
    $display (" APB UART Testbench Initialized                             ");
    $display ("------------------------------------------------------------");
   end
  endtask 


  task finish_text();
  begin
    if (errors>0)
    begin
        $display ("------------------------------------------------------------");
        $display (" APB UART Testbench failed with (%0d) error ", errors);
        $display ("------------------------------------------------------------");
    end
    else
    begin
        $display ("------------------------------------------------------------");
        $display (" APB UART Testbench finished successfully ");
        $display ("------------------------------------------------------------");
    end
  end
  endtask


task check (
    input reg[10*8:0]      name,
    input [31:0] actual,expected
  );
  begin
    $display("Checking %s for %b==%b", name, actual, expected);
    if (actual == expected) begin 
    //errors = 1;
    $display("ZERO ERRORS Expected: %b, received: %b @%0t", name, expected, actual, $time);
    end
    if (actual !== expected) begin 
    //errors = 1;
    $display("ERROR  : Incorrect %s value. Expected: %b, received: %b @%0t", name, expected, actual, $time);
    end
  end
  endtask


  
endmodule







