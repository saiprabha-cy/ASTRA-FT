`timescale 1ns/1ps

module tb_memory_scrubber;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset = 1;
    reg write_enable = 0;
    reg [1:0] write_address = 0;
    reg [31:0] write_data = 0;
    reg read_enable = 0;
    reg [1:0] read_address = 0;

    wire [31:0] read_data;
    wire read_data_valid;
    wire read_error_detected;
    wire read_error_corrected;
    wire read_uncorrectable_error;

    wire [1:0] scrub_address;
    wire [38:0] scrub_codeword;
    wire scrub_write_enable;
    wire [38:0] scrub_write_codeword;

    reg inject_enable = 0;
    reg [1:0] inject_address = 0;
    reg [38:0] inject_mask = 0;

    reg scrub_start = 0;
    wire scrub_busy;
    wire scrub_done;
    wire [2:0] words_scanned;
    wire [31:0] corrected_count;
    wire [31:0] uncorrectable_count;

    integer cycles;

    ecc_memory_32 #(
        .DEPTH(4),
        .ADDR_WIDTH(2)
    ) memory (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .read_enable(read_enable),
        .read_address(read_address),
        .read_data(read_data),
        .read_data_valid(read_data_valid),
        .read_error_detected(read_error_detected),
        .read_error_corrected(read_error_corrected),
        .read_uncorrectable_error(read_uncorrectable_error),
        .scrub_address(scrub_address),
        .scrub_codeword(scrub_codeword),
        .scrub_write_enable(scrub_write_enable),
        .scrub_write_codeword(scrub_write_codeword),
        .inject_enable(inject_enable),
        .inject_address(inject_address),
        .inject_mask(inject_mask)
    );

    ecc_scrubber_32 #(
        .DEPTH(4),
        .ADDR_WIDTH(2)
    ) scrubber (
        .clk(clk),
        .reset(reset),
        .start(scrub_start),
        .busy(scrub_busy),
        .done(scrub_done),
        .scrub_address(scrub_address),
        .scrub_codeword(scrub_codeword),
        .scrub_write_enable(scrub_write_enable),
        .scrub_write_codeword(scrub_write_codeword),
        .words_scanned(words_scanned),
        .corrected_count(corrected_count),
        .uncorrectable_count(uncorrectable_count)
    );

    task automatic write_word(input [1:0] addr, input [31:0] value);
        begin
            @(negedge clk);
            write_enable = 1;
            write_address = addr;
            write_data = value;
            @(negedge clk);
            write_enable = 0;
        end
    endtask

    task automatic read_word(input [1:0] addr);
        begin
            @(negedge clk);
            read_enable = 1;
            read_address = addr;
            @(posedge clk);
            #1;
            read_enable = 0;
        end
    endtask

    task automatic inject_fault(input [1:0] addr, input [38:0] mask);
        begin
            @(negedge clk);
            inject_enable = 1;
            inject_address = addr;
            inject_mask = mask;
            @(negedge clk);
            inject_enable = 0;
            inject_mask = 0;
        end
    endtask

    initial begin
        $display("======================================");
        $display(" ASTRA-FT MEMORY + SCRUBBER TEST");
        $display("======================================");

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Test 1: user write and clean read
        write_word(2'd1, 32'h12345678);
        read_word(2'd1);

        if (read_data !== 32'h12345678 ||
            read_data_valid !== 1'b1 ||
            read_error_detected !== 1'b0 ||
            read_uncorrectable_error !== 1'b0)
            $fatal(1, "FAIL: clean memory write/read");

        $display("PASS: clean memory write/read");

        // Initialize every memory location before the scrubber scans.
        // The memory RTL does not reset its storage array.
        write_word(2'd0, 32'hA5A5A5A5);
        write_word(2'd2, 32'h5A5A5A5A);
        write_word(2'd3, 32'hCAFEBABE);

        // Test 2: single-bit fault correction on read
        inject_fault(2'd1, (39'b1 << 5));
        read_word(2'd1);

        if (read_data !== 32'h12345678 ||
            read_error_detected !== 1'b1 ||
            read_error_corrected !== 1'b1 ||
            read_uncorrectable_error !== 1'b0)
            $fatal(1, "FAIL: single-bit read correction");

        $display("PASS: single-bit read correction");

        // Remove the earlier bit-5 fault.
        // A corrected read does not automatically rewrite memory.
        inject_fault(2'd1, (39'b1 << 5));

        // Test 3: scrubber repairs a single correctable error.
        inject_fault(2'd1, (39'b1 << 7));

        @(negedge clk);
        scrub_start = 1;
        @(negedge clk);
        scrub_start = 0;

        cycles = 0;
        while (scrub_done !== 1'b1 && cycles < 20) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        if (scrub_done !== 1'b1)
            $fatal(1, "FAIL: scrubber did not finish");

        if (words_scanned !== 3'd4)
            $fatal(1, "FAIL: expected four scanned words");

        if (corrected_count !== 32'd1)
            $fatal(1, "FAIL: expected one corrected word, got %0d",
                   corrected_count);

        if (uncorrectable_count !== 32'd0)
            $fatal(1, "FAIL: unexpected uncorrectable count");

        $display("PASS: scrubber scan and corrected-word accounting");

        // Read repaired word; it must now be clean.
        read_word(2'd1);

        if (read_data !== 32'h12345678 ||
            read_error_detected !== 1'b0 ||
            read_error_corrected !== 1'b0 ||
            read_uncorrectable_error !== 1'b0)
            $fatal(1, "FAIL: scrubber writeback did not repair memory");

        $display("PASS: scrubber physically rewrote corrected codeword");

        // Test 4: double-bit fault is reported uncorrectable
        inject_fault(2'd1, (39'b1 << 2) | (39'b1 << 9));
        read_word(2'd1);

        if (read_error_detected !== 1'b1 ||
            read_error_corrected !== 1'b0 ||
            read_uncorrectable_error !== 1'b1 ||
            read_data_valid !== 1'b0)
            $fatal(1, "FAIL: double-bit error handling");

        $display("PASS: double-bit error detection");

        $display("======================================");
        $display(" MEMORY + SCRUBBER TEST: PASS");
        $display("======================================");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL: testbench timeout");
    end

endmodule
