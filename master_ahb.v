module master_ahb(
    input HCLK,
    input HRESETn,
    input HREADY,
    input HRESP,
    input [31:0] HRDATA,

    output reg [31:0] HADDR,
    output reg [31:0] HWDATA,
    output reg HWRITE,
    output reg [1:0] HTRANS,
    output reg [2:0] HBURST,
    output reg [2:0] HSIZE,

    input start,
    input [31:0] start_addr,
    input [2:0] burst_mode,
    input [2:0] transfer_size,
    input write_en,
    input [31:0] write_data,
    output reg [31:0] read_data
);

    localparam IDLE=2'b00, BUSY=2'b01, NONSEQ=2'b10, SEQ=2'b11;

    reg [2:0] current_beat;
    reg [2:0] beats_total;
    reg active;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            active <= 0;
            current_beat <= 0;
            HADDR <= 0;
            HTRANS <= IDLE;
            HWRITE <= 0;
            HSIZE <= 0;
            HBURST <= 0;
            beats_total <= 0;
            read_data <= 0;
        end
        else if (HREADY) begin
            
            if (!HWRITE && HTRANS != IDLE && HRESP == 1'b0) begin
                read_data <= HRDATA;
            end
            
            if (!active && start) begin
                active <= 1;
                HADDR <= start_addr;
                HWRITE <= write_en;
                HBURST <= burst_mode;
                HSIZE <= transfer_size;
                HTRANS <= NONSEQ;
                current_beat <= 0;
                
                case (burst_mode)
                    3'b000: beats_total <= 0;
                    3'b001: beats_total <= 0;
                    3'b010: beats_total <= 3;
                    3'b011: beats_total <= 3;
                    3'b100: beats_total <= 7;
                    3'b101: beats_total <= 7;
                    3'b110: beats_total <= 15;
                    3'b111: beats_total <= 15;
                endcase
            end
            else if (active) begin
                if (current_beat < beats_total) begin
                    HTRANS <= SEQ;
                    HADDR <= next_address(HADDR, HBURST, HSIZE);
                    current_beat <= current_beat + 1;
                end
                else begin
                    HTRANS <= IDLE;
                    active <= 0;
                end
            end
            else begin
                HTRANS <= IDLE;
            end
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HWDATA <= 0;
        end
        else if (HREADY && active) begin
            if (HWRITE) begin
                HWDATA <= write_data;
            end
        end
    end

    function [31:0] next_address;
        input [31:0] curr_addr;
        input [2:0] burst;
        input [2:0] size;
        
        reg [31:0] incr;
        reg [31:0] boundary_mask;
        begin
            case (size)
                3'b000: incr = 1;
                3'b001: incr = 2;
                3'b010: incr = 4;
                default: incr = 4;
            endcase

            case (burst)
                3'b010: boundary_mask = (incr * 4) - 1; 
                3'b100: boundary_mask = (incr * 8) - 1; 
                3'b110: boundary_mask = (incr * 16) - 1; 
                default: boundary_mask = 0; 
            endcase

            if (boundary_mask != 0) begin
                if ((curr_addr & boundary_mask) == (boundary_mask - incr + 1)) begin
                    
                    next_address = (curr_addr + incr) & ~boundary_mask; 
                    
                end else begin
                    next_address = curr_addr + incr;
                end
            end else begin
                next_address = curr_addr + incr;
            end
        end
    endfunction

endmodule