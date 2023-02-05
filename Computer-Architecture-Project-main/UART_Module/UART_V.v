module BaudRateGenerator  #(
    parameter CLOCK_RATE = 1000000, 
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    output reg rxClk, 
    output reg txClk
);

parameter MAX_RATE_RX = CLOCK_RATE / (2 * BAUD_RATE * 16);
parameter MAX_RATE_TX = CLOCK_RATE / (2 * BAUD_RATE);
parameter RX_CNT_WIDTH = $clog2(MAX_RATE_RX);
parameter TX_CNT_WIDTH = $clog2(MAX_RATE_TX);

reg [RX_CNT_WIDTH - 1:0] rxCounter = 0;
reg [TX_CNT_WIDTH - 1:0] txCounter = 0;

initial begin
    rxClk = 1'b0;
    txClk = 1'b0;
end

always @(posedge clk) begin
    // rx clock
    if (rxCounter == MAX_RATE_RX[RX_CNT_WIDTH-1:0] ) begin
        rxCounter <= 0;
        rxClk <= ~rxClk;
    end else begin
        rxCounter <= rxCounter + 1'b1;
    end
    
    // tx clock
    if (txCounter == MAX_RATE_TX[TX_CNT_WIDTH-1:0]) begin
        txCounter <= 0;
        txClk <= ~txClk;
    end else begin
        txCounter <= txCounter + 1'b1;
    end
end

endmodule

module BaudRateGenerator_Test ();
  parameter Tt     = 2; // clock timout
  reg clk;
  wire rxClk,txClk;
  
  initial begin
        clk = 0;
        forever clk = #(Tt/2) ~clk;
  end
  BaudRateGenerator BRG(clk,rxClk,txClk);
endmodule

module Uart8Receiver (
    input  wire       clk,  
    input  wire       en,
    input  wire       in,   
    output reg  [7:0] out,  
    output reg        done, 
    output reg        busy 
);
    // states of state machine
    parameter [1:0] IDLE      = 2'b01;
    parameter [1:0] DATA_BITS = 2'b10;
    parameter [1:0] STOP_BIT  = 2'b11;

    reg [1:0] state        = IDLE;
    reg [2:0] bitIdx       = 3'b0; 
    reg [3:0] clockCount   = 4'b0; 
    reg [7:0] receivedData = 8'b0;

    initial begin
        out  <= 8'b0;
        done <= 1'b0;
        busy <= 1'b0;
    end

    always @(posedge clk) begin

        if (!en) begin
            state = IDLE;
        end

        case (state)
            
            IDLE: begin
                done <= 1'b0;
                if (&clockCount && en) begin
                    state <= DATA_BITS;
                    out <= 8'b0;
                    bitIdx <= 3'b0;
                    clockCount <= 4'b0;
                    receivedData <= 8'b0;
                    busy <= 1'b1;
                end 
                clockCount <= clockCount + 4'b1;
            end
            
            DATA_BITS: begin
                if (&clockCount) begin 
                    clockCount = 4'b0;
                    receivedData[bitIdx] <= in;
                    if (&bitIdx) begin
                        bitIdx <= 3'b0;
                        state <= STOP_BIT;
                    end else begin
                        bitIdx <= bitIdx + 3'b1;
                    end
                end else begin
                    clockCount <= clockCount + 4'b1;
                end
            end
        
            STOP_BIT: begin
                if (&clockCount) begin
                    state <= IDLE;
                    done <= 1'b1;
                    busy <= 1'b0;
                    out <= receivedData;
                    clockCount <= 4'b0;
                end else begin
                    clockCount <= clockCount + 1;
                end
            end
            default: state <= IDLE;
        endcase
    end
endmodule

module Uart8Receiver_Test();
  parameter  Tt     = 8; // clock timout
  reg        clk;
  reg        en;
  reg        in;
  wire [7:0] out;
  wire       done;
  wire       busy;
  
  
  initial begin
        clk = 0;
        forever clk = #(Tt/2) ~clk;
  end
  integer i;

  
  initial begin 
  en = 1;
  for (i=0 ; i<67000 ; i=i+1) begin
        in = 0; #130;
        in = 1; #130;
        in = 0; #130;
        in = 1; #130;
        in = 1; #130;
        in = 0; #130;
        in = 1; #130;
        in = 0; #130;
        in = 0; #130;
        in = 0; #130;
  end
end
  
  Uart8Receiver UARTRx(clk,en,in,out,done,busy);
endmodule


module Uart8Transmitter (
    input  wire       clk,   
    input  wire       en,
    input  wire       start, 
    input  wire [7:0] in,    
    output reg        out,  
    output reg        done,  
    output reg        busy  
);


   // states of state machine
    parameter [1:0] IDLE      = 2'b00;
    parameter [1:0] START_BIT  = 2'b01;
    parameter [1:0] DATA_BITS = 2'b10;
    parameter [1:0] STOP_BIT  = 2'b11;
    
    reg [1:0] state  = IDLE;
    reg [7:0] data   = 8'b0; 
    reg [2:0] bitIdx = 3'b0; 
    wire [2:0] idx;

    assign idx = bitIdx;

    always @(posedge clk) begin
        case (state)
            default     : begin
                state   <= IDLE;
            end
            IDLE       : begin
                out     <= 1'b1; 
                done    <= 1'b0;
                busy    <= 1'b0;
                bitIdx  <= 3'b0;
                data    <= 8'b0;
                if (start & en) begin
                    data    <= in; 
                    state   <= START_BIT;
                end
            end
            START_BIT  : begin
                out     <= 1'b0; 
                busy    <= 1'b1;
                state   <= DATA_BITS;
            end
            DATA_BITS  : begin 
                out     <= data[idx];
                if (&bitIdx) begin
                    bitIdx  <= 3'b0;
                    state   <= STOP_BIT;
                end else begin
                    bitIdx  <= bitIdx + 1'b1;
                end
            end
            STOP_BIT   : begin 
                done    <= 1'b1;
                out    <= 1'b0;
                state   <= IDLE;
            end
        endcase
    end

endmodule

module UARTTransmiter_Test ();
   parameter Tt     = 20; // clock timout

    reg       clk;
    reg       en;
    reg       start;
    reg [7:0] in;
    wire       out;
    wire       done;
    wire      busy;

    Uart8Transmitter utx (
        .clk    ( clk    ),
        .en     ( en     ),
        .start  ( start  ),
        .in     ( in     ),
        .out    ( out    ),
        .done   ( done   ),
        .busy   ( busy   )
    );
    
  initial begin
        clk = 0;
        en=1;
        start=1;
        in=8'b10101001;
        forever clk = #(Tt/2) ~clk;
  end
endmodule

module APB_UART_Interfacee (
    input PCLK,
    input PRESET,
    input [31 : 0] PADDR,
    input PSEL,
    input PENABLE,
    input PWR,
    input [31 : 0] PWDATA,
    input [7:0] dataRx,
    input doneRx,
    input busyRx,
    input doneTx,
    input busyTx,
    output reg enTx,
    output reg startTx,
    output reg [7:0] dataTx,
    output reg enRx,
    output reg PREADY,
    output reg [31 : 0] PRDATA
);

parameter IDLE = 2'b00;
parameter WRITEDATA= 2'b01;
parameter SENDDATA= 2'b10;


parameter IDLET = 2'b00;
parameter SENDT = 2'b01;
parameter BUSYT = 2'b10;
parameter DONET = 2'b01;

parameter IDLER = 2'b00;
parameter RECEIVERx = 2'b01;
parameter BUSYR = 2'b10;
parameter DONER = 2'b01;

reg [7:0] buffTx [0:7]; //2 buff
reg [3:0] indexApbTx = 4'b0;
reg [3:0] indexUartTx =4'b0;
reg [2:0] indexApbRx = 3'b0;
reg [2:0] indexUartRx =3'b0;
reg [7:0] first;
reg [7:0] second;
reg [7:0] third;
reg [7:0] fourth;


initial begin 
  indexApbTx = 4'b0;
  indexUartTx =4'b0;
  indexApbRx = 3'b0;
  indexUartRx =3'b0;
end


reg [1:0] stateAPB  = IDLE;
reg [1:0] stateT  = IDLET;
reg [1:0] stateR  = IDLER;


always @(posedge PCLK , negedge PRESET) begin

    if(!PRESET) begin
      stateAPB   <= IDLE;
    end

    case (stateAPB)
       default : begin
                  stateAPB  <= IDLE;
       end
   
       IDLE : begin
             if(PWR && PSEL && PENABLE)
                stateAPB <= SENDDATA;

             if(!PWR && PSEL && PENABLE)
                stateAPB <= WRITEDATA;
       end

       WRITEDATA : begin
       
              if(PENABLE)
                  begin
                if( (indexUartRx) == 4 ) 
                  begin                
                      
                      PREADY=1;
                      PRDATA = {fourth,third,second,first};

                  end
                else begin
                      PREADY=1'b0;
                     end  
              end
       end
          
       SENDDATA: begin 

              if(PENABLE)
                  begin
                 if( indexApbTx != 4'b 1000)
                  begin
                    PREADY =1;
                    buffTx[indexApbTx]<=PWDATA[7:0];
                    indexApbTx=indexApbTx+1;
                    buffTx[indexApbTx]<=PWDATA[15:8];
                    indexApbTx=indexApbTx+1;
                    buffTx[indexApbTx]<=PWDATA[23:16];
                    indexApbTx=indexApbTx+1;   
                    buffTx[indexApbTx]<=PWDATA[31:24];
                    indexApbTx=indexApbTx+1;
                                  
                  end

                 else 
                    begin
                      PREADY <=1'b0;
                    end 
              end      
       end
    endcase
end


 always @(posedge PCLK) begin
        
    case (stateT)
            default : begin
                  stateT <= IDLET;
            end

            IDLET : begin
                      if( indexApbTx != 0)
                        begin
                        stateT <=SENDT;
                      end
            end            
                 
            SENDT:  begin
                        if(!busyTx) begin
                          startTx <=1'b1;
                          enTx <=1'b1;  
                          if ( indexUartTx == 0)begin
                          dataTx =buffTx[indexUartTx]; 
                          indexUartTx =indexUartTx+1;
                        end
                          stateT <= BUSYT;
                        end
            end

            BUSYT :  begin
                      if(doneTx) begin
                        stateT<=DONER;
                        dataTx =buffTx[indexUartTx];
                        indexUartTx =indexUartTx+1;
                      end
            end
            
            DONET: begin
                   if( indexUartTx != indexApbTx)
                     begin
                      stateT<=SENDT;
                   end    
             
                  else begin
                      indexUartTx<=0;
                      indexApbTx<=0;
                 end
           end

      endcase
  end  
always @(posedge PCLK) begin
        
    case (stateR)
        default : begin
              stateR <= IDLER;
        end

        IDLER : begin
                  if( indexApbRx == 0)
                    begin
                   stateR<=RECEIVERx;
                 end
        end
                 
        RECEIVERx:  begin
                      if(!busyRx)
                        begin
                        enRx <=1'b1; 
                        stateR <= BUSYR;
                      end
        end

        BUSYR:  begin
                  if(doneRx)
                    begin
                    stateR <=DONER;
                    if (indexUartRx == 0)begin
                    first = dataRx;
                    indexUartRx = indexUartRx+1;
                    #17;
                    end 
                    else if (indexUartRx == 1)begin
                    second = dataRx;
                    indexUartRx = indexUartRx+1;
                    #17;
                    end
                    else if (indexUartRx == 2)begin
                    third = dataRx;
                    indexUartRx = indexUartRx+1;
                    #17;
                    end
                    else begin
                    fourth = dataRx;
                    indexUartRx = indexUartRx+1;
                    end
                  end
                  
        end

        DONER: begin
                if( indexUartRx != indexApbRx )
                  begin
                  stateR=RECEIVERx;
                end
                else begin
                  indexUartRx <= 4'b0;
                  indexApbRx <= 4'b0;
                end
        end  
   endcase 
end
endmodule

  module UART_TOP_MODULE (
    input [31 : 0] padd,
    input [31 : 0] pdata,
    input psel,
    input pen,
    input pwr,
    input rst,
    input clk,    
    output pready,
    output [31 : 0] prdata,
    output txd,
    input rxd
    );
    
     // rx interface
     wire rxEn;
     wire [7:0] out;
     wire rxDone;
     wire rxBusy;

     // tx interface
     wire txEn;
     wire txStart;
     wire [7:0] in;
     wire txDone;
     wire txBusy;
    
     parameter CLOCK_RATE = 1000000; // board internal clock
     parameter BAUD_RATE = 9600;
    
     wire rxClk;
     wire txClk;

    
    APB_UART_Interfacee APB_UART(clk,
    rst,padd,psel,pen,pwr,pdata,out,rxDone,rxBusy,txDone,
    txBusy,txEn,txStart,in,rxEn,pready,prdata);
    
BaudRateGenerator #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE)
) generatorInst (
    .clk(clk),
    .rxClk(rxClk),
    .txClk(txClk)
);

Uart8Receiver rxInst (
    .clk(rxClk),
    .en(rxEn),
    .in(rxd),
    .out(out),
    .done(rxDone),
    .busy(rxBusy)
);

Uart8Transmitter txInst (
    .clk(txClk),
    .en(txEn),
    .start(txStart),
    .in(in),
    .out(txd),
    .done(txDone),
    .busy(txBusy)
);
endmodule
  
module TOP_MODULE_Test();
    parameter Tt     = 2; // clock timout
    
    reg clk;
    reg PRESET;
    reg [31 : 0] PADDR;
    reg PSEL;
    reg PENABLE;
    reg PWR;
    reg [31 : 0] PWDATA;
    reg Rx;
    wire Tx;
    wire PREADY;
    wire [31 : 0] PRDATA;
    
    initial begin
        clk = 0;
        forever clk = #(Tt/2) ~clk;
    end
    integer i;
    
    initial begin
      PRESET = 1;
      PSEL = 1;
      PENABLE = 1;
      PWR = 1;
      PWDATA = 32'hab876359;
      /*for (i=0 ; i<67000 ; i=i+1) begin
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;

        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 0; #260;

        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 1; #260;
        Rx = 1; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;
        Rx = 0; #260;


  end*/
    end
    
  UART_TOP_MODULE test(PADDR , PWDATA ,PSEL,PENABLE,PWR,PRESET,clk,PREADY,PRDATA,Tx,Rx);
  initial begin 
      $monitor("%b",PWDATA );
    end
    
  endmodule
