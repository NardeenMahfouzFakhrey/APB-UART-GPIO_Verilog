`include "C:/altera/13.0sp1/GPIO_V.v "
`include "C:/altera/13.0sp1/UART_V.v "

module APB_master(
input PCLK,PRESETn,transfer,READ_WRITE,PREADY,
input reg [31:0]apb_write_paddr,reg [31:0]apb_write_data,reg [31:0]apb_read_paddr,reg [31:0]prdata, 
output reg PWRITE,reg PENABLE, 
output PSEL1,PSEL2,
output reg [31:0] paddr,reg [31:0] pwdata,reg [31:0] apb_read_data_out
);

reg [1:0]current_state,next_state;
localparam IDLE= 2'b01, SETUP=2'b10, ACCESS=2'b11;


assign {PSEL1,PSEL2} = ((current_state != IDLE) ? (paddr[31] ? {1'b0,1'b1} : {1'b1,1'b0}) : 2'd0);

always @(posedge PCLK)
begin
  if(!PRESETn)
    current_state <=IDLE;
else
  current_state <=next_state;
end



always@(current_state,transfer,PREADY)
begin
  
  
    PWRITE = ~READ_WRITE;
    
   
    case(current_state)
      
      IDLE: begin
        
        PENABLE=0;
        
        
        if(transfer)
          next_state = SETUP;
      else 
          next_state = IDLE;
      end
    ///////////////////
      SETUP: begin
        PENABLE=0;
        
        if(READ_WRITE)begin
          paddr=apb_read_paddr;
        end
        else
          begin
          paddr = apb_write_paddr;
          pwdata = apb_write_data;
        end 
        
        next_state = ACCESS;
      end
      
      //////////////////
      ACCESS: begin
        if(PSEL1 || PSEL2)
        begin PENABLE=1; end
        if(transfer)
          begin
            if(PREADY)begin
              if(READ_WRITE)begin
              apb_read_data_out = prdata; 
            end
            next_state=SETUP;
          end
        else
        next_state=ACCESS;  
        end
      else
      next_state=IDLE;      
      end
         
         default: 
      next_state = IDLE;
    
    endcase
end
endmodule


module APB_Protocol_Interface_Test();
    parameter Tt     = 2; // clock timout
    reg rxd;
    wire txd;
    reg PCLK,PRESETn,transfer,READ_WRITE;
    reg[31:0]  apb_write_paddr,apb_write_data,apb_read_paddr;
    wire[31:0] apb_read_data_out;
    integer i;
    initial begin
        PCLK = 0;
        forever PCLK = #(Tt/2) ~PCLK;
    end
    
    initial begin
      
      
      PRESETn = 1;
      transfer=1;
      READ_WRITE=0;
       apb_write_paddr= 32'hFFFFFFFF;
       apb_write_data = 32'h5a;

    end
    
    APB_Protocol APB_protocol_dut(PCLK,PRESETn,transfer,READ_WRITE,rxd,apb_write_paddr,apb_write_data,apb_read_paddr,apb_read_data_out,txd);
    
  endmodule
module APB_Protocol1(
     input PCLK,PRESETn,transfer,READ_WRITE, rxd,
     input [31:0] apb_write_paddr,
		 input [31:0]apb_write_data,
		 input [31:0] apb_read_paddr,     
		 output [31:0] apb_read_data_out,
		 output txd,
		 output reg [31 : 0] GPIO_INPUT,
     input [31 : 0]GPIO_OUTPUT
		 );

       wire [31:0]PWDATA,PRDATA;
       wire [31:0]PADDR;

       wire PREADY,PREADY1,PREADY2,PENABLE,PSEL1,PSEL2,PWRITE;
      

       APB_master master(
       PCLK,PRESETn,transfer,READ_WRITE,PREADY,apb_write_paddr,apb_write_data,
       apb_read_paddr,PRDATA, PWRITE,PENABLE, PSEL1,PSEL2,PADDR,PWDATA,apb_read_data_out ); 

      
       UART_TOP_MODULE slave2(PADDR,PWDATA,PSEL2,PENABLE,PWRITE,PRESETn,PCLK,PREADY,PRDATA,txd,rxd);
      
endmodule



module APB_Protocol_Interface_Test1();
    parameter Tt     = 2; // clock timout
    reg rxd;
    wire txd;
    reg PCLK,PRESETn,transfer,READ_WRITE;
    reg[31:0]  apb_write_paddr,apb_write_data,apb_read_paddr;
    wire[31:0] apb_read_data_out,GPIO_INPUT,GPIO_OUTPUT;
    integer i;
    reg [31:0]data = 32'hF555;
    initial begin
        PCLK = 0;
        forever PCLK = #(Tt/2) ~PCLK;
    end
          assign GPIO_INPUT =data;
    initial begin      
      PRESETn = 1;
      transfer=1;
      READ_WRITE=1;
      apb_read_paddr= 32'h0;
      #250
      apb_read_paddr= 32'h01;

     apb_write_paddr= 32'h00000000;
      apb_write_data = 32'hFFFFFFFF;
      #250
      apb_write_paddr= 32'h00000002;
      apb_write_data = 32'hFFFFFFFF;
    end
    
    APB_Protocol1 APB_protocol_dut(PCLK,PRESETn,transfer,READ_WRITE,rxd,apb_write_paddr,apb_write_data,apb_read_paddr,apb_read_data_out,txd,
    GPIO_INPUT,GPIO_OUTPUT);
    
  endmodule


