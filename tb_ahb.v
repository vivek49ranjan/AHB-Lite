`timescale 1ns/1ps

module tb_ahb;

    reg HCLK;
    reg HRESETn;
    reg start;
    reg [31:0] start_addr;
    reg [2:0] burst_mode;
    reg [2:0] transfer_size;
    reg write_en;
    reg [31:0] write_data;
    wire [31:0] read_data;

    integer read_dump_file; 

    top_module_ahb dut (
        .HCLK (HCLK),
        .HRESETn (HRESETn),
        .start (start),
        .start_addr (start_addr),
        .burst_mode (burst_mode),
        .transfer_size(transfer_size),
        .write_en (write_en),
        .write_data (write_data),
        .read_data (read_data)
    );

    initial begin
        HCLK = 1'b0;
        forever #5 HCLK = ~HCLK;
    end

    initial begin
        HRESETn = 1'b0;
        start = 1'b0;
        start_addr = 32'h0;
        burst_mode = 3'b000;
        transfer_size = 3'b000;
        write_en = 1'b0;
        write_data = 32'h0;

        @(posedge HCLK);
        @(posedge HCLK);
        @(posedge HCLK);
        HRESETn = 1'b1;
    end

    integer error_count = 0;
    reg monitor_on;
    reg expected_error;
    reg error_seen;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            error_seen <= 1'b0;
        end else begin
            if (monitor_on && dut.HRESP) begin
                error_seen <= 1'b1;
                if (!expected_error) begin
                    $error("Unexpected HRESP error at time %0t", $time);
                    error_count = error_count + 1;
                end
            end
        end
    end

    task wait_for_idle;
    begin
        @(posedge HCLK);
        while (dut.u_master.active) begin
            @(posedge HCLK);
        end
        @(posedge HCLK); 
    end
    endtask

    task ahb_write;
        input [31:0] addr;
        input [2:0] burst;
        input [2:0] size;
        input [31:0] data;
    begin
        @(posedge HCLK);
        start_addr <= addr;
        burst_mode <= burst;
        transfer_size <= size;
        write_en <= 1'b1;
        write_data <= data;
        start <= 1'b1;

        @(posedge HCLK);
        start <= 1'b0;

        wait_for_idle();
    end
    endtask

    task ahb_read;
        input [31:0] addr;
        input [2:0] burst;
        input [2:0] size;
    begin
        @(posedge HCLK);
        start_addr <= addr;
        burst_mode <= burst;
        transfer_size <= size;
        write_en <= 1'b0;
        start <= 1'b1;

        @(posedge HCLK);
        start <= 1'b0;

        wait_for_idle();
    end
    endtask

    task do_single_test;
        input [31:0] addr;
        input [2:0] burst;
        input [2:0] size;
        input [31:0] data;
        input is_write_first;
        input exp_err;
    begin
        $display("=== Test: addr=0x%08h, size=%b, burst=%b, exp_err=%0b @ %0t ===",
                 addr, size, burst, exp_err, $time);

        monitor_on = 1'b1;
        expected_error = exp_err;
        error_seen = 1'b0;

        if (is_write_first) begin
            ahb_write(addr, burst, size, data);
            if (!exp_err) begin
                ahb_read(addr, burst, size);
                $fwrite(read_dump_file, "W-R| TIME=%0t | ADDR=0x%08h | BURST=%b | SIZE=%b | DATA=0x%08h\n", 
                        $time, addr, burst, size, read_data);
                if (read_data !== data) begin
                    $error("Data mismatch: got 0x%08h, expected 0x%08h", read_data, data);
                    error_count = error_count + 1;
                end
            end
        end else begin
            ahb_read(addr, burst, size);
            $fwrite(read_dump_file, "READ| TIME=%0t | ADDR=0x%08h | BURST=%b | SIZE=%b | DATA=0x%08h\n", 
                    $time, addr, burst, size, read_data);
        end

        if (exp_err && !error_seen) begin
            $error("Expected HRESP error not seen for size=%b, burst=%b", size, burst);
            error_count = error_count + 1;
        end

        monitor_on = 1'b0;
        @(posedge HCLK);
    end
    endtask

    integer sz_idx, b;
    reg [2:0] sz;
    reg [31:0] base_addr;
    reg [31:0] pattern;

    initial begin
        @(posedge HRESETn);
        @(posedge HCLK);

        read_dump_file = $fopen("read_dump.txt", "w");
        if (read_dump_file == 0) begin
            $display("ERROR: Could not open read_dump.txt");
            $finish;
        end
        $display("Opened read_dump.txt for logging read_data.");

        for (sz_idx = 0; sz_idx < 3; sz_idx = sz_idx + 1) begin
            case (sz_idx)
                0: sz = 3'b000;
                1: sz = 3'b001;
                2: sz = 3'b010;
            endcase

            for (b = 0; b < 8; b = b + 1) begin
                base_addr = {22'h0, b[5:0], 2'b00};
                pattern = {16'hA5A5, b[2:0], sz[2:0]};
                do_single_test(base_addr, b[2:0], sz, pattern, 1'b1, 1'b0);
            end
        end

        for (sz_idx = 0; sz_idx < 8; sz_idx = sz_idx + 1) begin
            if (sz_idx != 3'b000 && sz_idx != 3'b001 && sz_idx != 3'b010) begin
                sz = sz_idx[2:0];
                base_addr = 32'h0000_0040 + {27'h0, sz, 2'b00};
                pattern = {16'hDEAD, 5'h0, sz};
                do_single_test(base_addr, 3'b000, sz, pattern, 1'b1, 1'b1);
            end
        end

        sz = 3'b010;
        do_single_test(32'h0000_0001, 3'b000, sz, 32'hCAFEBABE, 1'b1, 1'b1);
        do_single_test(32'h0000_0002, 3'b001, sz, 32'hCAFEBABE, 1'b1, 1'b1);
        do_single_test(32'h0000_0003, 3'b010, sz, 32'hCAFEBABE, 1'b1, 1'b1);

        sz = 3'b001;
        do_single_test(32'h0000_0001, 3'b000, sz, 32'h1234ABCD, 1'b1, 1'b1);

        $fclose(read_dump_file);

        if (error_count == 0) begin
            $display("\n====================================================");
            $display("          ALL AHB-Lite TESTS PASSED");
            $display("====================================================\n");
        end else begin
            $display("\n====================================================");
            $display("          AHB-Lite TESTS FAILED: %0d errors", error_count);
            $display("====================================================\n");
        end

        $finish;
    end

endmodule