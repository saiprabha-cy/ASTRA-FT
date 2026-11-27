`timescale 1ns/1ps

module tb_day5_ecc_memory_full;

    localparam integer DEPTH = 16;
    localparam integer ADDR_WIDTH = 4;

    localparam logic [ADDR_WIDTH-1:0] TEST_ADDR = 4'd3;

    localparam logic [31:0] TEST_DATA =
        32'hA5C3_7E19;

    localparam logic [31:0] ARBITRATION_WRITE_DATA =
        32'h1357_9BDF;

    localparam logic [31:0] ARBITRATION_SCRUB_DATA =
        32'h2468_ACE0;

    localparam logic [31:0] ARBITRATION_SCRUB_DATA_2 =
        32'hDEAD_BEEF;

    logic clk;
    logic reset;

    // User write interface
    logic write_enable;
    logic [ADDR_WIDTH-1:0] write_address;
    logic [31:0] write_data;

    // User read interface
    logic read_enable;
    logic [ADDR_WIDTH-1:0] read_address;

    logic [31:0] read_data;
    logic read_data_valid;

    logic read_error_detected;
    logic read_error_corrected;
    logic read_uncorrectable_error;

    // Scrubber interface
    logic [ADDR_WIDTH-1:0] scrub_address;
    logic [38:0] scrub_codeword;

    logic scrub_write_enable;
    logic [38:0] scrub_write_codeword;

    // Fault injection
    logic inject_enable;
    logic [ADDR_WIDTH-1:0] inject_address;
    logic [38:0] inject_mask;

    // Reference encoder
    logic [31:0] ref_data;
    logic [38:0] ref_codeword;

    // Read task outputs
    logic [31:0] got_data;
    logic got_valid;
    logic got_detected;
    logic got_corrected;
    logic got_uncorrectable;

    integer checks;
    integer failures;

    integer clean_cases;
    integer single_cases;
    integer double_cases;
    integer arbitration_cases;

    integer i;
    integer j;

    logic [38:0] fault_mask;

    // ------------------------------------------------
    // Clock
    // ------------------------------------------------

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------
    // Independent reference encoder instance
    // ------------------------------------------------

    secded_encoder_32 reference_encoder (
        .data_in(ref_data),
        .encoded_data(ref_codeword)
    );

    // ------------------------------------------------
    // Device under test
    // ------------------------------------------------

    ecc_memory_32 #(
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
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

    // ------------------------------------------------
    // Deterministic memory payload patterns
    // ------------------------------------------------

    function automatic logic [31:0] data_pattern(
        input integer index
    );
        begin
            case (index)
                0: data_pattern = 32'h0000_0000;
                1: data_pattern = 32'hFFFF_FFFF;
                2: data_pattern = 32'hAAAA_AAAA;
                3: data_pattern = 32'h5555_5555;
                4: data_pattern = 32'hDEAD_BEEF;
                5: data_pattern = 32'h0123_4567;
                6: data_pattern = 32'h89AB_CDEF;
                7: data_pattern = 32'h8000_0001;
                8: data_pattern = 32'h7FFF_FFFE;
                9: data_pattern = 32'h1357_9BDF;
                10: data_pattern = 32'h2468_ACE0;
                11: data_pattern = 32'hA5A5_5A5A;
                12: data_pattern = 32'h0F0F_F0F0;
                13: data_pattern = 32'h3333_CCCC;
                14: data_pattern = 32'hF00D_BAAD;
                15: data_pattern = 32'hC001_D00D;
                default: data_pattern =
                    32'h9E37_79B9 * (index + 1);
            endcase
        end
    endfunction

    // ------------------------------------------------
    // Common assertion/check task
    // ------------------------------------------------

    task automatic check_result(
        input logic condition,
        input string description
    );
        begin
            checks = checks + 1;

            if (condition !== 1'b1) begin
                failures = failures + 1;
                $display(
                    "FAIL | %s | time=%0t",
                    description,
                    $time
                );
            end
        end
    endtask

    // ------------------------------------------------
    // Write one memory word
    // ------------------------------------------------

    task automatic write_word(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [31:0] data
    );
        begin
            @(negedge clk);

            write_enable = 1'b1;
            write_address = address;
            write_data = data;

            @(posedge clk);
            #1;

            write_enable = 1'b0;
        end
    endtask

    // ------------------------------------------------
    // Read one memory word
    // ------------------------------------------------

    task automatic read_word(
        input logic [ADDR_WIDTH-1:0] address
    );
        begin
            @(negedge clk);

            read_enable = 1'b1;
            read_address = address;

            @(posedge clk);
            #1;

            got_data = read_data;
            got_valid = read_data_valid;
            got_detected = read_error_detected;
            got_corrected = read_error_corrected;
            got_uncorrectable = read_uncorrectable_error;

            read_enable = 1'b0;
        end
    endtask

    // ------------------------------------------------
    // Inject an XOR fault into a memory codeword
    // ------------------------------------------------

    task automatic inject_fault(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [38:0] mask
    );
        begin
            @(negedge clk);

            inject_enable = 1'b1;
            inject_address = address;
            inject_mask = mask;

            @(posedge clk);
            #1;

            inject_enable = 1'b0;
            inject_mask = '0;
        end
    endtask

    // ------------------------------------------------
    // Initialize all control signals
    // ------------------------------------------------

    task automatic initialize_controls;
        begin
            write_enable = 1'b0;
            write_address = '0;
            write_data = '0;

            read_enable = 1'b0;
            read_address = '0;

            scrub_address = '0;
            scrub_write_enable = 1'b0;
            scrub_write_codeword = '0;

            inject_enable = 1'b0;
            inject_address = '0;
            inject_mask = '0;

            ref_data = '0;
        end
    endtask

    // ------------------------------------------------
    // Test 1: clean writes and reads across all addresses
    // ------------------------------------------------

    task automatic test_all_memory_locations;
        logic [31:0] expected;
        integer address_index;

        begin
            $display("");
            $display("[TEST 1] Initialize and read all memory locations");

            // Explicit initialization is required because the
            // memory array itself has no reset initialization.
            for (address_index = 0;
                 address_index < DEPTH;
                 address_index = address_index + 1) begin

                expected = data_pattern(address_index);

                write_word(
                    address_index[ADDR_WIDTH-1:0],
                    expected
                );
            end

            for (address_index = 0;
                 address_index < DEPTH;
                 address_index = address_index + 1) begin

                expected = data_pattern(address_index);

                read_word(address_index[ADDR_WIDTH-1:0]);

                check_result(
                    (got_data === expected) &&
                    (got_valid === 1'b1) &&
                    (got_detected === 1'b0) &&
                    (got_corrected === 1'b0) &&
                    (got_uncorrectable === 1'b0),
                    $sformatf(
                        "Clean memory read at address %0d",
                        address_index
                    )
                );

                clean_cases = clean_cases + 1;
            end

            $display(
                "Clean memory locations checked: %0d",
                clean_cases
            );
        end
    endtask

    // ------------------------------------------------
    // Test 2: all 39 single-bit codeword positions
    // ------------------------------------------------

    task automatic test_all_single_bit_errors;
        integer bit_index;
        logic [38:0] one_bit_mask;

        begin
            $display("");
            $display("[TEST 2] Single-bit correction across all 39 positions");

            for (bit_index = 0;
                 bit_index < 39;
                 bit_index = bit_index + 1) begin

                // Restore a clean codeword before every trial.
                write_word(TEST_ADDR, TEST_DATA);

                one_bit_mask = 39'b1 << bit_index;

                inject_fault(TEST_ADDR, one_bit_mask);

                read_word(TEST_ADDR);

                check_result(
                    (got_data === TEST_DATA) &&
                    (got_valid === 1'b1) &&
                    (got_detected === 1'b1) &&
                    (got_corrected === 1'b1) &&
                    (got_uncorrectable === 1'b0),
                    $sformatf(
                        "Single-bit correction at codeword bit %0d",
                        bit_index
                    )
                );

                single_cases = single_cases + 1;
            end

            $display(
                "Single-bit correction cases: %0d / 39",
                single_cases
            );
        end
    endtask

    // ------------------------------------------------
    // Test 3: all distinct double-bit combinations
    // ------------------------------------------------

    task automatic test_all_double_bit_errors;
        integer first_bit;
        integer second_bit;
        logic [38:0] two_bit_mask;

        begin
            $display("");
            $display("[TEST 3] Double-bit detection across all 741 pairs");

            for (first_bit = 0;
                 first_bit < 39;
                 first_bit = first_bit + 1) begin

                for (second_bit = first_bit + 1;
                     second_bit < 39;
                     second_bit = second_bit + 1) begin

                    // Restore a clean codeword before each pair.
                    write_word(TEST_ADDR, TEST_DATA);

                    two_bit_mask =
                        (39'b1 << first_bit) |
                        (39'b1 << second_bit);

                    inject_fault(TEST_ADDR, two_bit_mask);

                    read_word(TEST_ADDR);

                    check_result(
                        (got_valid === 1'b0) &&
                        (got_detected === 1'b1) &&
                        (got_corrected === 1'b0) &&
                        (got_uncorrectable === 1'b1),
                        $sformatf(
                            "Double-bit detection at positions %0d and %0d",
                            first_bit,
                            second_bit
                        )
                    );

                    double_cases = double_cases + 1;
                end
            end

            $display(
                "Double-bit detection cases: %0d / 741",
                double_cases
            );
        end
    endtask

    // ------------------------------------------------
    // Test 4: scrubber raw codeword read interface
    // ------------------------------------------------

    task automatic test_scrubber_read_interface;
        begin
            $display("");
            $display("[TEST 4] Scrubber raw codeword read interface");

            write_word(TEST_ADDR, TEST_DATA);

            ref_data = TEST_DATA;
            scrub_address = TEST_ADDR;

            #1;

            check_result(
                scrub_codeword === ref_codeword,
                "Scrubber reads the stored 39-bit codeword"
            );
        end
    endtask

    // ------------------------------------------------
    // Test 5: write arbitration priority
    // ------------------------------------------------

    task automatic test_write_arbitration;
        begin
            $display("");
            $display("[TEST 5] Memory write arbitration");

            // -----------------------------------------
            // Case A:
            // User write > scrub write > fault injection
            // -----------------------------------------

            ref_data = ARBITRATION_SCRUB_DATA;
            #1;

            @(negedge clk);

            write_enable = 1'b1;
            write_address = TEST_ADDR;
            write_data = ARBITRATION_WRITE_DATA;

            scrub_address = TEST_ADDR;
            scrub_write_enable = 1'b1;
            scrub_write_codeword = ref_codeword;

            inject_enable = 1'b1;
            inject_address = TEST_ADDR;
            inject_mask = {39{1'b1}};

            @(posedge clk);
            #1;

            write_enable = 1'b0;
            scrub_write_enable = 1'b0;
            inject_enable = 1'b0;
            inject_mask = '0;

            read_word(TEST_ADDR);

            check_result(
                (got_data === ARBITRATION_WRITE_DATA) &&
                (got_valid === 1'b1) &&
                (got_uncorrectable === 1'b0),
                "User write has highest storage priority"
            );

            arbitration_cases = arbitration_cases + 1;

            // -----------------------------------------
            // Case B:
            // Scrub write > fault injection
            // -----------------------------------------

            ref_data = ARBITRATION_SCRUB_DATA_2;
            #1;

            @(negedge clk);

            write_enable = 1'b0;

            scrub_address = TEST_ADDR;
            scrub_write_enable = 1'b1;
            scrub_write_codeword = ref_codeword;

            inject_enable = 1'b1;
            inject_address = TEST_ADDR;
            inject_mask = {39{1'b1}};

            @(posedge clk);
            #1;

            scrub_write_enable = 1'b0;
            inject_enable = 1'b0;
            inject_mask = '0;

            read_word(TEST_ADDR);

            check_result(
                (got_data === ARBITRATION_SCRUB_DATA_2) &&
                (got_valid === 1'b1) &&
                (got_uncorrectable === 1'b0),
                "Scrub write has priority over fault injection"
            );

            arbitration_cases = arbitration_cases + 1;

            $display(
                "Arbitration cases passed: %0d / 2",
                arbitration_cases
            );
        end
    endtask

    // ------------------------------------------------
    // Main test sequence
    // ------------------------------------------------

    initial begin

        $dumpfile("sim/waveforms/day5_ecc_memory_full.vcd");
        $dumpvars(0, tb_day5_ecc_memory_full);

        checks = 0;
        failures = 0;

        clean_cases = 0;
        single_cases = 0;
        double_cases = 0;
        arbitration_cases = 0;

        initialize_controls();

        reset = 1'b1;

        $display("==================================================");
        $display(" ASTRA-FT DAY 5 ECC MEMORY VERIFICATION");
        $display("==================================================");
        $display("Memory depth       : %0d words", DEPTH);
        $display("Payload width      : 32 bits");
        $display("Stored codeword    : 39 bits");
        $display("Address width      : %0d bits", ADDR_WIDTH);
        $display("Single-bit positions: 39");
        $display("Double-bit pairs   : 741");

        repeat (3) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        // Run all verification groups.
        test_all_memory_locations();
        test_all_single_bit_errors();
        test_all_double_bit_errors();
        test_scrubber_read_interface();
        test_write_arbitration();

        // ------------------------------------------------
        // Final results
        // ------------------------------------------------

        $display("");
        $display("==================================================");
        $display(" ASTRA-FT DAY 5 ECC MEMORY RESULTS");
        $display("==================================================");

        $display(
            "Clean memory reads          : %0d",
            clean_cases
        );

        $display(
            "Single-bit correction cases : %0d",
            single_cases
        );

        $display(
            "Double-bit detection cases  : %0d",
            double_cases
        );

        $display(
            "Arbitration cases           : %0d",
            arbitration_cases
        );

        $display("------------------------------------------");

        $display(
            "Total assertions            : %0d",
            checks
        );

        $display(
            "Failed assertions           : %0d",
            failures
        );

        $display("==================================================");

        if ((failures == 0) &&
            (clean_cases == 16) &&
            (single_cases == 39) &&
            (double_cases == 741) &&
            (arbitration_cases == 2)) begin

            $display("DAY 5 ECC MEMORY STATUS: PASS");
            $display("==================================================");

            $finish;

        end else begin

            $display("DAY 5 ECC MEMORY STATUS: FAIL");
            $display("==================================================");

            $fatal(1, "Day 5 ECC memory verification failed");

        end

    end

endmodule
