`timescale 1ns/1ps

module tb_ecc_scrubber_32;

    reg clk;
    reg reset;

    // User memory interface
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

    // Scrubber
    reg scrub_start;

    wire scrub_busy;
    wire scrub_done;

    wire [3:0] scrub_address;
    wire [38:0] scrub_codeword;

    wire scrub_write_enable;
    wire [38:0] scrub_write_codeword;

    wire [4:0] words_scanned;
    wire [31:0] corrected_count;
    wire [31:0] uncorrectable_count;

    // Fault injection
    reg inject_enable;
    reg [3:0] inject_address;
    reg [38:0] inject_mask;

    // Test accounting
    integer passed;
    integer failed;
    integer tests;
    integer i;

    reg [31:0] expected_data [0:15];

    // -----------------------------------------
    // Protected memory
    // -----------------------------------------
    ecc_memory_32 memory_dut (
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

    // -----------------------------------------
    // Scrubber controller
    // -----------------------------------------
    ecc_scrubber_32 scrubber_dut (
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

    // -----------------------------------------
    // Clock
    // -----------------------------------------
    always #5 clk = ~clk;

    // -----------------------------------------
    // Write task
    // -----------------------------------------
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

    // -----------------------------------------
    // Read task
    // -----------------------------------------
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

    // -----------------------------------------
    // Fault injection task
    // -----------------------------------------
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

    // -----------------------------------------
    // Check task
    // -----------------------------------------
    task check_result;
        input condition;
        input [511:0] message;

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

    // -----------------------------------------
    // Main
    // -----------------------------------------
    initial begin

        clk = 0;
        reset = 1;

        write_enable = 0;
        write_address = 0;
        write_data = 0;

        read_enable = 0;
        read_address = 0;

        scrub_start = 0;

        inject_enable = 0;
        inject_address = 0;
        inject_mask = 0;

        passed = 0;
        failed = 0;
        tests = 0;

        $dumpfile("sim/waveforms/ecc_scrubber_32.vcd");
        $dumpvars(0, tb_ecc_scrubber_32);

        // -------------------------------------
        // Reset
        // -------------------------------------
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 0;

        // -------------------------------------
        // Initialize all 16 memory locations
        // -------------------------------------
        for (i = 0; i < 16; i = i + 1) begin

            expected_data[i] =
                32'h10000000 + (i * 32'h00010101);

            write_word(4'(i), expected_data[i]);

        end

        // -------------------------------------
        // Inject one correctable fault
        // -------------------------------------
        inject_fault(
            4'd2,
            39'h000000000100
        );

        // -------------------------------------
        // Inject one double-bit fault
        // -------------------------------------
        inject_fault(
            4'd5,
            39'h000000000003
        );

        // -------------------------------------
        // Start scrub pass
        // -------------------------------------
        @(negedge clk);

        scrub_start = 1;

        @(posedge clk);

        #1;

        @(negedge clk);

        scrub_start = 0;

        // Wait for scrub completion
        wait(scrub_done);

        #1;

        // -------------------------------------
        // Verify scan count
        // -------------------------------------
        check_result(
            words_scanned == 16,
            "Scrubber scanned all 16 memory locations"
        );

        // -------------------------------------
        // Verify correction counter
        // -------------------------------------
        check_result(
            corrected_count == 1,
            "Exactly one correctable error repaired"
        );

        // -------------------------------------
        // Verify uncorrectable counter
        // -------------------------------------
        check_result(
            uncorrectable_count == 1,
            "Exactly one uncorrectable error recorded"
        );

        // -------------------------------------
        // Verify corrected address 2
        // -------------------------------------
        read_word(4'd2);

        check_result(
            read_data_valid &&
            read_data == expected_data[2] &&
            !read_error_detected,
            "Scrubber repaired address 2 and wrote back"
        );

        // -------------------------------------
        // Verify address 5 remains invalid
        //
        // Scrubber cannot correct a double-bit error.
        // -------------------------------------
        read_word(4'd5);

        check_result(
            !read_data_valid &&
            read_error_detected &&
            read_uncorrectable_error,
            "Double-bit error remains flagged and data rejected"
        );

        // -------------------------------------
        // Verify an unaffected address
        // -------------------------------------
        read_word(4'd9);

        check_result(
            read_data_valid &&
            read_data == expected_data[9] &&
            !read_error_detected,
            "Unaffected memory location remains correct"
        );

        // -------------------------------------
        // Summary
        // -------------------------------------
        $display("");
        $display("===============================================");
        $display(" ASTRA-FT DAY 6 SCRUBBER SUMMARY");
        $display("===============================================");

        $display("Tests              : %0d", tests);
        $display("Passed             : %0d", passed);
        $display("Failed             : %0d", failed);

        $display("Words scanned      : %0d", words_scanned);
        $display("Corrected errors   : %0d", corrected_count);
        $display("Uncorrectable      : %0d", uncorrectable_count);

        if (failed == 0)
            $display("SCRUBBER STATUS: PASS");
        else
            $display("SCRUBBER STATUS: FAIL");

        $display("===============================================");

        $finish;

    end

endmodule
