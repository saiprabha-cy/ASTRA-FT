`timescale 1ns/1ps

module tb_ecc_memory_32;

    reg clk;
    reg reset;

    reg write_enable;
    reg [3:0] write_address;
    reg [31:0] write_data;

    reg read_enable;
    reg [3:0] read_address;

    wire [31:0] read_data;
    wire read_data_valid;

    wire read_error_detected;
    wire read_error_corrected;
    wire read_uncorrectable_error;

    reg [3:0] scrub_address;
    wire [38:0] scrub_codeword;

    reg scrub_write_enable;
    reg [38:0] scrub_write_codeword;

    reg inject_enable;
    reg [3:0] inject_address;
    reg [38:0] inject_mask;

    integer passed;
    integer failed;
    integer tests;

    ecc_memory_32 dut (
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

    always #5 clk = ~clk;

    task write_word;
        input [3:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            write_enable = 1;
            write_address = address;
            write_data = value;

            @(posedge clk);
            #1;
            write_enable = 0;
        end
    endtask

    task read_word;
        input [3:0] address;
        begin
            @(negedge clk);
            read_enable = 1;
            read_address = address;

            @(posedge clk);
            #1;
            read_enable = 0;
        end
    endtask

    task inject_fault;
        input [3:0] address;
        input [38:0] mask;
        begin
            @(negedge clk);
            inject_enable = 1;
            inject_address = address;
            inject_mask = mask;

            @(posedge clk);
            #1;
            inject_enable = 0;
            inject_mask = 0;
        end
    endtask

    task check_result;
        input condition;
        input [255:0] message;
        begin
            tests = tests + 1;

            if (condition) begin
                passed = passed + 1;
                $display("PASS | %0s", message);
            end
            else begin
                failed = failed + 1;
                $display("FAIL | %0s", message);
            end
        end
    endtask

    initial begin

        clk = 0;
        reset = 1;

        write_enable = 0;
        write_address = 0;
        write_data = 0;

        read_enable = 0;
        read_address = 0;

        scrub_address = 0;
        scrub_write_enable = 0;
        scrub_write_codeword = 0;

        inject_enable = 0;
        inject_address = 0;
        inject_mask = 0;

        passed = 0;
        failed = 0;
        tests = 0;

        $dumpfile("sim/waveforms/ecc_memory_32.vcd");
        $dumpvars(0, tb_ecc_memory_32);

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 0;

        // Test 1: Normal write/read
        write_word(3, 32'h12345678);
        read_word(3);

        check_result(
            read_data_valid &&
            read_data == 32'h12345678 &&
            !read_error_detected &&
            !read_error_corrected &&
            !read_uncorrectable_error,
            "Normal protected memory write/read"
        );

        // Test 2: Independent memory address
        write_word(7, 32'hDEADBEEF);
        read_word(7);

        check_result(
            read_data_valid &&
            read_data == 32'hDEADBEEF,
            "Second memory address independent"
        );

        // Test 3: Single-bit error correction
        inject_fault(3, 39'h000000000100);
        read_word(3);

        check_result(
            read_data_valid &&
            read_data == 32'h12345678 &&
            read_error_detected &&
            read_error_corrected &&
            !read_uncorrectable_error,
            "Single-bit corruption corrected on read"
        );

        // Test 4: Double-bit error rejection
        inject_fault(7, 39'h000000000003);
        read_word(7);

        check_result(
            !read_data_valid &&
            read_error_detected &&
            !read_error_corrected &&
            read_uncorrectable_error,
            "Double-bit error detected and data rejected"
        );

        // Test 5: Rewrite damaged memory address
        write_word(7, 32'hCAFEBABE);
        read_word(7);

        check_result(
            read_data_valid &&
            read_data == 32'hCAFEBABE &&
            !read_error_detected,
            "Rewrite restores clean memory data"
        );

        // Test 6: Another single-bit error
        write_word(3, 32'h12345678);
        inject_fault(3, 39'h0000100000);
        read_word(3);

        check_result(
            read_data_valid &&
            read_data == 32'h12345678 &&
            read_error_corrected,
            "Single-bit error at another position corrected"
        );
        $display("");
        $display("===============================================");
        $display(" ASTRA-FT DAY 5 MEMORY SUMMARY");
        $display("===============================================");
        $display("Tests : %0d", tests);
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);

        if (failed == 0)
            $display("MEMORY STATUS: PASS");
        else
            $display("MEMORY STATUS: FAIL");

        $display("===============================================");

        $finish;

    end

endmodule