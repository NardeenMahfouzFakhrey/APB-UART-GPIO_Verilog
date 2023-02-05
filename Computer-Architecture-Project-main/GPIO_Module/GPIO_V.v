module GPIO_Port #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32
) (
    
    input PCLK,
    input PRESETn,
    input [DATA_WIDTH - 1 : 0] PADDR,
    input PSEL1,
    input PENABLE,
    input PWRITE,
    input [DATA_WIDTH - 1 : 0] PWDATA,
    output PREADY,
    output reg [DATA_WIDTH - 1 : 0] PRDATA,
    input [DATA_WIDTH - 1 : 0] GPIO_INPUT,
    output reg [DATA_WIDTH - 1 : 0] GPIO_OUTPUT,
    output reg [DATA_WIDTH - 1 : 0] GPIO_DIR

);

// Cases
localparam DIRECTION = 0,
           INPUT     = 1,
           OUTPUT    = 2 ;

// To sync the GPIO input with the PRDATA since the GPIO input is not synchronized with the PCLK
localparam  GPIO_INPUT_SYNC = 2;


reg [DATA_WIDTH - 1 : 0]  output_reg,
                          input_reg;


// Input Sync Registers
reg [DATA_WIDTH - 1 : 0] input_sync_regs [0 : GPIO_INPUT_SYNC - 1];

assign PREADY = 1'b1; // GPIO is always ready
assign PSLVERR = 0'b0; // No Error


// Write Operations
always @(posedge PCLK, negedge PRESETn) begin
    if(!PRESETn)begin
        GPIO_DIR <= 0;
    end
    else if(PWRITE && PSEL1 && PENABLE && PADDR == DIRECTION)begin
        GPIO_DIR <= PWDATA;
    end

end

always @(posedge PCLK, negedge PRESETn) begin
    if(!PRESETn)begin
        output_reg <= 0;
    end
    else if(PWRITE && PSEL1 && PENABLE && PADDR == INPUT)begin
        output_reg <= PWDATA;
    end

end

always @(posedge PCLK, negedge PRESETn) begin
    if(!PRESETn)begin
        output_reg <= 0;
    end
    else if(PWRITE && PSEL1 && PENABLE && PADDR == OUTPUT)begin
        output_reg <= PWDATA;
    end

end

// Read Operations
always @(posedge PCLK) begin

    if(!PWRITE && PSEL1 && PENABLE)begin
        
        case (PADDR) 
            DIRECTION: PRDATA <= GPIO_DIR;
            INPUT:     PRDATA <= input_reg;
            OUTPUT:    PRDATA <= output_reg;
            default:   PRDATA <= 0;
        endcase

    end
end 

integer i;
always @(posedge PCLK) begin

    for(i = 0; i < DATA_WIDTH; i = i + 1)begin
        
        if(!GPIO_DIR[i])begin
            input_reg[i] <= GPIO_INPUT[i];            
        end
        else begin
            input_reg[i] <= 1'bz;

        end

    end

end


always @(posedge PCLK) begin

    for(i = 0; i < DATA_WIDTH; i = i + 1)begin

        if(GPIO_DIR[i])begin
            GPIO_OUTPUT[i] <= output_reg[i];
        end
        else begin
            GPIO_OUTPUT[i] <= 1'bx;
        end 
    end

end


endmodule

