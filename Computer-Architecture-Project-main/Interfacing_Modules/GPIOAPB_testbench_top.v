module GPIOAPB_testbench_top; // run for at least 12300 psec
 parameter DATA_WIDTH = 32;
 parameter ADDRESS_WIDTH = 32;



  /////////////////////////////////////////////////////////
  //
  // Variables
  //
  //APB signals
  reg                           PSEL1;
  reg                           PSEL2;
  reg                           PENABLE;
  reg  [ADDRESS_WIDTH - 1:0]    PADDR;
  reg  [DATA_WIDTH  -1:0]       PWDATA;
  wire [DATA_WIDTH  -1:0]       PRDATA;
  reg                           PWRITE;
  wire                          PREADY;
  reg [31:0]                    apb_read_data_out;
  

  //GPIOs
  reg [DATA_WIDTH -1:0] GPIO_OUTPUT, GPIO_INPUT, GPIO_DIR;


  /////////////////////////////////////////////////////////
  //
  // Clock & Reset
  //
  reg PCLK, PRESETn;
  initial begin : gen_PCLK
      PCLK <= 1'b0;
      forever #10 PCLK = ~PCLK;
  end : gen_PCLK

  initial begin : gen_PRESET
    PRESETn = 1'b1;
    //ensure falling edge of PRESETn
    #10;
    PRESETn = 1'b0;
    #32;
    PRESETn = 1'b1;
  end : gen_PRESET
   
  /////////////////////////////////////////////////////////
  // 
  // Instantiate the TB and GPIO
  //
  testbench#(.DATA_WIDTH(DATA_WIDTH))
  tb(.*);
  
  GPIO_Port#(.DATA_WIDTH(DATA_WIDTH))
  gpio(.*);
  
endmodule

