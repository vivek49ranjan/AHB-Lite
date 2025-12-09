module external_mem(
    input clk,
    input we,
    input [9:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata
);

    reg [7:0] mem [0:1023]; 

    always @(*) begin
        rdata = mem[addr];
    end
    
    always @(posedge clk) begin
        if (we) mem[addr] <= wdata;
    end
endmodule


module slave_ahb(
    input HCLK,
    input HRESETn,
    input HSEL,
    input [31:0] HADDR,
    input HWRITE,
    input [2:0] HSIZE,
    input [2:0] HBURST,
    input [1:0] HTRANS,
    input [31:0] HWDATA,
    input HREADY,
    output reg HREADYOUT,
    output reg HRESP,
    output reg [31:0] HRDATA
);

    localparam IDLE_STATE     = 4'b0000;
    localparam SETUP_STATE    = 4'b0001; 
    localparam READ_S1_STATE  = 4'b0010; 
    localparam READ_S2_STATE  = 4'b0011; 
    localparam READ_S3_STATE  = 4'b0100; 
    localparam READ_S4_STATE  = 4'b0101; 
    localparam TRANSFER_STATE = 4'b0110; 
    localparam WRITE_S1_STATE = 4'b0111; 
    localparam WRITE_S2_STATE = 4'b1000; 
    localparam WRITE_S3_STATE = 4'b1001; 
    localparam WRITE_S4_STATE = 4'b1010; 

    reg [3:0] state;

    reg [31:0] addr_reg;
    reg [2:0]  size_reg;
    reg        write_reg;
    reg        valid_packet;
    reg        error_hit;
    
    reg [31:0] internal_read; 
    reg [1:0]  byte_offset; 

    reg [9:0] mem_addr;
    reg mem_we;
    reg [7:0] mem_wdata;
    wire [7:0] mem_rdata;

    wire [9:0] base_addr = {addr_reg[9:2],2'b00};

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state <= IDLE_STATE;
            addr_reg <= 0;
            size_reg <= 0;
            write_reg <= 0;
            valid_packet <= 0;
            mem_addr <= 0;
            mem_we <= 0;
            mem_wdata <= 0;
            internal_read <= 0;
            byte_offset <= 0;
        end else begin
            mem_we <= 0;

            case (state)
                IDLE_STATE: begin
                    if (HSEL && HTRANS[1] && HREADY) begin
                        state <= SETUP_STATE;
                        addr_reg <= HADDR;
                        size_reg <= HSIZE;
                        write_reg <= HWRITE;
                        valid_packet <= 1;
                        byte_offset <= HADDR[1:0];
                    end
                end

                SETUP_STATE: begin
                    if (!error_hit) begin
                        mem_addr <= base_addr + byte_offset;
                        if (write_reg) begin
                            mem_we <= 1;
                            mem_wdata <= HWDATA[7:0];
                            state <= WRITE_S1_STATE;
                        end else begin
                            state <= READ_S1_STATE;
                        end
                    end else begin
                        state <= TRANSFER_STATE;
                    end
                end

                READ_S1_STATE: begin
                    internal_read[7:0] <= mem_rdata;
                    if (size_reg == 3'b000)
                        state <= TRANSFER_STATE;
                    else begin
                        mem_addr <= base_addr + byte_offset + 1;
                        state <= READ_S2_STATE;
                    end
                end

                READ_S2_STATE: begin
                    internal_read[15:8] <= mem_rdata;
                    if (size_reg == 3'b001)
                        state <= TRANSFER_STATE;
                    else begin
                        mem_addr <= base_addr + byte_offset + 2;
                        state <= READ_S3_STATE;
                    end
                end

                READ_S3_STATE: begin
                    internal_read[23:16] <= mem_rdata;
                    mem_addr <= base_addr + byte_offset + 3;
                    state <= READ_S4_STATE;
                end

                READ_S4_STATE: begin
                    internal_read[31:24] <= mem_rdata;
                    state <= TRANSFER_STATE;
                end

                WRITE_S1_STATE: begin
                    mem_we <= 1;
                    mem_wdata <= HWDATA[7:0];
                    if (size_reg == 3'b000)
                        state <= TRANSFER_STATE;
                    else begin
                        mem_addr <= base_addr + byte_offset + 1;
                        state <= WRITE_S2_STATE;
                    end
                end

                WRITE_S2_STATE: begin
                    mem_we <= 1;
                    mem_wdata <= HWDATA[15:8];
                    if (size_reg == 3'b001)
                        state <= TRANSFER_STATE;
                    else begin
                        mem_addr <= base_addr + byte_offset + 2;
                        state <= WRITE_S3_STATE;
                    end
                end

                WRITE_S3_STATE: begin
                    mem_we <= 1;
                    mem_wdata <= HWDATA[23:16];
                    mem_addr <= base_addr + byte_offset + 3;
                    state <= WRITE_S4_STATE;
                end

                WRITE_S4_STATE: begin
                    mem_we <= 1;
                    mem_wdata <= HWDATA[31:24];
                    state <= TRANSFER_STATE;
                end

                TRANSFER_STATE: begin
                    if (HSEL && HTRANS[1] && HREADY) begin
                        state <= SETUP_STATE;
                        addr_reg <= HADDR;
                        size_reg <= HSIZE;
                        write_reg <= HWRITE;
                        valid_packet <= 1;
                        byte_offset <= HADDR[1:0];
                    end else begin
                        state <= IDLE_STATE;
                        valid_packet <= 0;
                    end
                end

                default: state <= IDLE_STATE;
            endcase
        end
    end

    always @(*) begin
        error_hit = 0;

        if (size_reg != 3'b000 && size_reg != 3'b001 && size_reg != 3'b010)
            error_hit = 1;

        else if (size_reg == 3'b001 && addr_reg[0] != 0)
            error_hit = 1;

        else if (size_reg == 3'b010 && addr_reg[1:0] != 0)
            error_hit = 1;
    end

    external_mem mem_inst (
        .clk(HCLK),
        .we(mem_we),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .rdata(mem_rdata)
    );

    always @(*) begin
        HRESP = 0;
        HRDATA = 0;

        case (state)
            SETUP_STATE,
            READ_S1_STATE, READ_S2_STATE, READ_S3_STATE, READ_S4_STATE,
            WRITE_S1_STATE, WRITE_S2_STATE, WRITE_S3_STATE, WRITE_S4_STATE: begin
                HREADYOUT = 0;
                if (state == SETUP_STATE && error_hit) begin
                    HREADYOUT = 1;
                    HRESP = 1;
                end
            end

            TRANSFER_STATE: begin
                HREADYOUT = 1;

                if (valid_packet && error_hit)
                    HRESP = 1;

                else if (!write_reg) begin
                    if (size_reg == 3'b010)
                        HRDATA = internal_read;
                    else if (size_reg == 3'b001)
                        HRDATA = {16'h0, internal_read[15:0]};
                    else
                        HRDATA = {24'h0, internal_read[7:0]};
                end
            end

            default: begin
                HREADYOUT = 0;
                HRESP = 0;
            end
        endcase
    end

endmodule