module decoder_ahb(
    input wire [31:0] HADDR,      
    input wire HREADY,            

    output reg HSEL_SLAVE1,       
    output reg HSEL_SLAVE2,       
    output reg HSEL_SLAVE3,       
    output reg HSEL_SLAVE4,       
    output reg HSEL_SLAVE5,       
    output reg HSEL_SLAVE6,       
    output reg HSEL_SLAVE7,       
    output reg HSEL_SLAVE8,       
    output reg HSEL_DEFAULT       
);

    parameter SLAVE1_addr = 32'h0000_0000;
    parameter SLAVE2_addr = 32'h1000_0000;
    parameter SLAVE3_addr = 32'h2000_0000;
    parameter SLAVE4_addr = 32'h3000_0000;
    parameter SLAVE5_addr = 32'h4000_0000;
    parameter SLAVE6_addr = 32'h5000_0000;
    parameter SLAVE7_addr = 32'h6000_0000;
    parameter SLAVE8_addr = 32'h7000_0000;
    
    parameter ADDR_MASK   = 32'hFF00_0000;

    always @(*) begin
        HSEL_SLAVE1   = 1'b0;
        HSEL_SLAVE2   = 1'b0;
        HSEL_SLAVE3   = 1'b0;
        HSEL_SLAVE4   = 1'b0;
        HSEL_SLAVE5   = 1'b0;
        HSEL_SLAVE6   = 1'b0;
        HSEL_SLAVE7   = 1'b0;
        HSEL_SLAVE8   = 1'b0;
        HSEL_DEFAULT  = 1'b0;

        case (HADDR & ADDR_MASK)

            (SLAVE1_addr & ADDR_MASK): HSEL_SLAVE1 = 1'b1;

            (SLAVE2_addr & ADDR_MASK): HSEL_SLAVE2 = 1'b1;

            (SLAVE3_addr & ADDR_MASK): HSEL_SLAVE3 = 1'b1;

            (SLAVE4_addr & ADDR_MASK): HSEL_SLAVE4 = 1'b1;

            (SLAVE5_addr & ADDR_MASK): HSEL_SLAVE5 = 1'b1;

            (SLAVE6_addr & ADDR_MASK): HSEL_SLAVE6 = 1'b1;

            (SLAVE7_addr & ADDR_MASK): HSEL_SLAVE7 = 1'b1;

            (SLAVE8_addr & ADDR_MASK): HSEL_SLAVE8 = 1'b1;

            default: HSEL_DEFAULT = 1'b1;
        endcase
    end

endmodule
