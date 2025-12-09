module mux_ahb (
    input wire HSEL_S0,
    input wire HSEL_S1,
    input wire HSEL_S2,
    input wire HSEL_S3,
    input wire HSEL_S4,
    input wire HSEL_S5,
    input wire HSEL_S6,
    input wire HSEL_S7,
    input wire HSEL_DEF,

    input wire [31:0] SLAVE0_HRDATA,
    input wire [31:0] SLAVE1_HRDATA,
    input wire [31:0] SLAVE2_HRDATA,
    input wire [31:0] SLAVE3_HRDATA,
    input wire [31:0] SLAVE4_HRDATA,
    input wire [31:0] SLAVE5_HRDATA,
    input wire [31:0] SLAVE6_HRDATA,
    input wire [31:0] SLAVE7_HRDATA,
    
    input wire [31:0] DEF_HRDATA,
    
    input wire SLAVE0_HRESP,
    input wire SLAVE1_HRESP,
    input wire SLAVE2_HRESP,
    input wire SLAVE3_HRESP,
    input wire SLAVE4_HRESP,
    input wire SLAVE5_HRESP,
    input wire SLAVE6_HRESP,
    input wire SLAVE7_HRESP,
    input wire DEF_HRESP,
    
    input wire SLAVE0_READY,
    input wire SLAVE1_READY,
    input wire SLAVE2_READY,
    input wire SLAVE3_READY,
    input wire SLAVE4_READY,
    input wire SLAVE5_READY,
    input wire SLAVE6_READY,
    input wire SLAVE7_READY,
    input wire DEF_READY,

    output reg [31:0] HRDATA,
    output reg        HRESP,
    output wire       HREADY
);

    always @(*) begin
        HRDATA = 32'hFFFFFFFF;
        HRESP  = 1'b0;

        if (HSEL_S0) begin
            HRDATA = SLAVE0_HRDATA;
            HRESP  = SLAVE0_HRESP;
        end else if (HSEL_S1) begin
            HRDATA = SLAVE1_HRDATA;
            HRESP  = SLAVE1_HRESP;
        end else if (HSEL_S2) begin
            HRDATA = SLAVE2_HRDATA;
            HRESP  = SLAVE2_HRESP;
        end else if (HSEL_S3) begin
            HRDATA = SLAVE3_HRDATA;
            HRESP  = SLAVE3_HRESP;
        end else if (HSEL_S4) begin
            HRDATA = SLAVE4_HRDATA;
            HRESP  = SLAVE4_HRESP;
        end else if (HSEL_S5) begin
            HRDATA = SLAVE5_HRDATA;
            HRESP  = SLAVE5_HRESP;
        end else if (HSEL_S6) begin
            HRDATA = SLAVE6_HRDATA;
            HRESP  = SLAVE6_HRESP;
        end else if (HSEL_S7) begin
            HRDATA = SLAVE7_HRDATA;
            HRESP  = SLAVE7_HRESP;
        end else if (HSEL_DEF) begin
            HRDATA = DEF_HRDATA;
            HRESP  = DEF_HRESP;
        end
    end

    assign HREADY = 
        (HSEL_S0  & SLAVE0_READY) |
        (HSEL_S1  & SLAVE1_READY) |
        (HSEL_S2  & SLAVE2_READY) |
        (HSEL_S3  & SLAVE3_READY) |
        (HSEL_S4  & SLAVE4_READY) |
        (HSEL_S5  & SLAVE5_READY) |
        (HSEL_S6  & SLAVE6_READY) |
        (HSEL_S7  & SLAVE7_READY) |
        (HSEL_DEF & DEF_READY);

endmodule
