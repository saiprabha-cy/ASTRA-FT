`timescale 1ns/1ps

module tb_day4_secded_full;

    // =========================================================
    // DUT INPUTS AND OUTPUTS
    // =========================================================

    reg  [31:0] data_in;
    reg  [38:0] received_codeword;

    wire [38:0] encoded_data;

    wire [31:0] corrected_data;
    wire [5:0]  syndrome;

    wire error_detected;
    wire error_corrected;
    wire uncorrectable_error;

    // =========================================================
    // TEST ACCOUNTING
    // =========================================================

    integer total_cases;
    integer passed_cases;
    integer failed_cases;

    integer clean_cases;
    integer single_bit_cases;
    integer double_bit_cases;

    integer encoder_structure_checks;
    integer encoder_structure_passed;
    integer encoder_structure_failures;

    integer pattern_index;
    integer bit_i;
    integer bit_j;

    integer parity_position;
    integer code_position;
    integer data_index;

    integer structure_errors;

    reg [31:0] test_pattern;
    reg [38:0] encoded_snapshot;
    reg [38:0] injected_codeword;

    reg [5:0] expected_syndrome;
    reg parity_value;

    // =========================================================
    // DUT INSTANTIATION
    // =========================================================

    secded_encoder_32 encoder (
        .data_in(data_in),
        .encoded_data(encoded_data)
    );

    secded_decoder_32 decoder (
        .encoded_data(received_codeword),

        .corrected_data(corrected_data),
        .syndrome(syndrome),

        .error_detected(error_detected),
        .error_corrected(error_corrected),
        .uncorrectable_error(uncorrectable_error)
    );

    // =========================================================
    // DETERMINISTIC TEST PATTERN GENERATOR
    //
    // 0..7  : Fixed patterns
    // 8..39 : Walking-one patterns
    // 40..71: Walking-zero patterns
    // 72..79: Deterministic mixed patterns
    // =========================================================

    function [31:0] make_pattern;
        input integer idx;

        begin
            case (idx)

                0: make_pattern = 32'h00000000;
                1: make_pattern = 32'hFFFFFFFF;
                2: make_pattern = 32'hAAAAAAAA;
                3: make_pattern = 32'h55555555;
                4: make_pattern = 32'hDEADBEEF;
                5: make_pattern = 32'h01234567;
                6: make_pattern = 32'h89ABCDEF;
                7: make_pattern = 32'h80000001;

                default: begin

                    if (idx >= 8 && idx < 40) begin

                        make_pattern =
                            (32'h00000001 << (idx - 8));

                    end

                    else if (idx >= 40 && idx < 72) begin

                        make_pattern =
                            ~(32'h00000001 << (idx - 40));

                    end

                    else begin

                        make_pattern =
                            (32'h9E3779B9 * (idx - 71)) ^
                            (32'hA5A5A5A5 >>
                             ((idx - 72) % 32));

                    end

                end

            endcase
        end

    endfunction

    // =========================================================
    // INDEPENDENT ENCODER STRUCTURE CHECK
    //
    // Checks:
    // 1. Six Hamming parity equations.
    // 2. Payload bit placement.
    // 3. Overall even parity across all 39 bits.
    //
    // This checks the generated codeword independently of
    // the decoder's syndrome/status outputs.
    // =========================================================

    task check_encoder_structure;

        integer ppos;
        integer cpos;
        integer didx;
        integer local_errors;

        reg parity_check;

        begin

            local_errors = 0;
            didx = 0;

            // -------------------------------------------------
            // Check six Hamming parity groups.
            // -------------------------------------------------

            for (ppos = 1;
                 ppos <= 32;
                 ppos = ppos * 2) begin

                parity_check = 1'b0;

                for (cpos = 1;
                     cpos <= 38;
                     cpos = cpos + 1) begin

                    if ((cpos & ppos) != 0) begin

                        parity_check =
                            parity_check ^
                            encoded_snapshot[cpos - 1];

                    end

                end

                if (parity_check !== 1'b0) begin

                    local_errors = local_errors + 1;

                    $display(
                        "FAIL ENCODER PARITY | PATTERN=%0d POSITION=%0d",
                        pattern_index,
                        ppos
                    );

                end

            end

            // -------------------------------------------------
            // Check payload bit placement.
            //
            // Parity positions:
            // 1, 2, 4, 8, 16, 32
            // -------------------------------------------------

            for (cpos = 1;
                 cpos <= 38;
                 cpos = cpos + 1) begin

                if ((cpos != 1)  &&
                    (cpos != 2)  &&
                    (cpos != 4)  &&
                    (cpos != 8)  &&
                    (cpos != 16) &&
                    (cpos != 32)) begin

                    if (encoded_snapshot[cpos - 1]
                        !== test_pattern[didx]) begin

                        local_errors = local_errors + 1;

                        $display(
                            "FAIL PAYLOAD MAPPING | PATTERN=%0d CODE_POSITION=%0d DATA_INDEX=%0d",
                            pattern_index,
                            cpos,
                            didx
                        );

                    end

                    didx = didx + 1;

                end

            end

            if (didx != 32) begin

                local_errors = local_errors + 1;

                $display(
                    "FAIL PAYLOAD COUNT | EXPECTED=32 ACTUAL=%0d",
                    didx
                );

            end

            // -------------------------------------------------
            // Check extended overall even parity.
            // -------------------------------------------------

            if ((^encoded_snapshot) !== 1'b0) begin

                local_errors = local_errors + 1;

                $display(
                    "FAIL OVERALL PARITY | PATTERN=%0d CODEWORD=%h",
                    pattern_index,
                    encoded_snapshot
                );

            end

            encoder_structure_checks =
                encoder_structure_checks + 1;

            if (local_errors == 0) begin

                encoder_structure_passed =
                    encoder_structure_passed + 1;

            end

            else begin

                encoder_structure_failures =
                    encoder_structure_failures + 1;

            end

        end

    endtask

    // =========================================================
    // CLEAN CODEWORD TEST
    // =========================================================

    task test_clean_codeword;

        begin

            received_codeword = encoded_snapshot;

            #1;

            total_cases = total_cases + 1;
            clean_cases = clean_cases + 1;

            if ((corrected_data === test_pattern) &&
                (syndrome === 6'b000000) &&
                (error_detected === 1'b0) &&
                (error_corrected === 1'b0) &&
                (uncorrectable_error === 1'b0)) begin

                passed_cases = passed_cases + 1;

            end

            else begin

                failed_cases = failed_cases + 1;

                $display(
                    "FAIL CLEAN | PATTERN=%0d DATA=%h DECODED=%h SYNDROME=%b",
                    pattern_index,
                    test_pattern,
                    corrected_data,
                    syndrome
                );

                $display(
                    "FLAGS DETECTED=%b CORRECTED=%b UNCORRECTABLE=%b",
                    error_detected,
                    error_corrected,
                    uncorrectable_error
                );

            end

        end

    endtask

    // =========================================================
    // SINGLE-BIT ERROR TEST
    //
    // Bit 0..37 : Hamming codeword positions 1..38
    // Bit 38    : Overall parity bit
    // =========================================================

    task test_single_bit_error;

        input integer error_bit;

        begin

            injected_codeword =
                encoded_snapshot ^
                (39'b1 << error_bit);

            received_codeword = injected_codeword;

            #1;

            expected_syndrome = 6'b000000;

            if (error_bit < 38) begin

                expected_syndrome = error_bit + 1;

            end

            total_cases = total_cases + 1;
            single_bit_cases = single_bit_cases + 1;

            if ((corrected_data === test_pattern) &&
                (syndrome === expected_syndrome) &&
                (error_detected === 1'b1) &&
                (error_corrected === 1'b1) &&
                (uncorrectable_error === 1'b0)) begin

                passed_cases = passed_cases + 1;

            end

            else begin

                failed_cases = failed_cases + 1;

                $display(
                    "FAIL SINGLE BIT | PATTERN=%0d BIT=%0d",
                    pattern_index,
                    error_bit
                );

                $display(
                    "EXPECTED DATA=%h SYNDROME=%0d",
                    test_pattern,
                    expected_syndrome
                );

                $display(
                    "ACTUAL DATA=%h SYNDROME=%0d",
                    corrected_data,
                    syndrome
                );

                $display(
                    "FLAGS DETECTED=%b CORRECTED=%b UNCORRECTABLE=%b",
                    error_detected,
                    error_corrected,
                    uncorrectable_error
                );

            end

        end

    endtask

    // =========================================================
    // DOUBLE-BIT ERROR TEST
    //
    // All C(39,2) = 741 distinct pairs are checked.
    //
    // Expected syndrome:
    // XOR of the two Hamming positions.
    // The overall parity bit has syndrome zero.
    //
    // A double-bit error must be detected and must not be
    // reported as corrected.
    // =========================================================

    task test_double_bit_error;

        input integer error_bit_a;
        input integer error_bit_b;

        begin

            injected_codeword =
                encoded_snapshot ^
                (39'b1 << error_bit_a) ^
                (39'b1 << error_bit_b);

            received_codeword = injected_codeword;

            #1;

            expected_syndrome = 6'b000000;

            if (error_bit_a < 38) begin

                expected_syndrome =
                    expected_syndrome ^
                    (error_bit_a + 1);

            end

            if (error_bit_b < 38) begin

                expected_syndrome =
                    expected_syndrome ^
                    (error_bit_b + 1);

            end

            total_cases = total_cases + 1;
            double_bit_cases = double_bit_cases + 1;

            if ((syndrome === expected_syndrome) &&
                (error_detected === 1'b1) &&
                (error_corrected === 1'b0) &&
                (uncorrectable_error === 1'b1)) begin

                passed_cases = passed_cases + 1;

            end

            else begin

                failed_cases = failed_cases + 1;

                $display(
                    "FAIL DOUBLE BIT | PATTERN=%0d BITS=%0d,%0d",
                    pattern_index,
                    error_bit_a,
                    error_bit_b
                );

                $display(
                    "EXPECTED SYNDROME=%0d",
                    expected_syndrome
                );

                $display(
                    "ACTUAL SYNDROME=%0d",
                    syndrome
                );

                $display(
                    "FLAGS DETECTED=%b CORRECTED=%b UNCORRECTABLE=%b",
                    error_detected,
                    error_corrected,
                    uncorrectable_error
                );

            end

        end

    endtask

    // =========================================================
    // MAIN TEST SEQUENCE
    // =========================================================

    initial begin

        data_in = 32'b0;
        received_codeword = 39'b0;

        total_cases = 0;
        passed_cases = 0;
        failed_cases = 0;

        clean_cases = 0;
        single_bit_cases = 0;
        double_bit_cases = 0;

        encoder_structure_checks = 0;
        encoder_structure_passed = 0;
        encoder_structure_failures = 0;

        pattern_index = 0;
        bit_i = 0;
        bit_j = 0;

        test_pattern = 32'b0;
        encoded_snapshot = 39'b0;
        injected_codeword = 39'b0;

        expected_syndrome = 6'b0;
        parity_value = 1'b0;

        $dumpfile("sim/waveforms/day4_secded_full.vcd");
        $dumpvars(1, tb_day4_secded_full);

        $display("");
        $display("==================================================");
        $display(" ASTRA-FT DAY 4 FULL SECDED VERIFICATION");
        $display("==================================================");

        $display("Payload width       : 32 bits");
        $display("Hamming parity      : 6 bits");
        $display("Overall parity      : 1 bit");
        $display("Encoded width       : 39 bits");
        $display("Data patterns       : 80");
        $display("Single-bit positions: 39");
        $display("Double-bit pairs    : 741");
        $display("");

        // -----------------------------------------------------
        // Run all 80 deterministic patterns.
        // -----------------------------------------------------

        for (pattern_index = 0;
             pattern_index < 80;
             pattern_index = pattern_index + 1) begin

            test_pattern = make_pattern(pattern_index);
            data_in = test_pattern;

            #1;

            encoded_snapshot = encoded_data;

            // Independent encoder structure verification.
            check_encoder_structure();

            // Clean codeword.
            test_clean_codeword();

            // All 39 single-bit error positions.
            for (bit_i = 0;
                 bit_i < 39;
                 bit_i = bit_i + 1) begin

                test_single_bit_error(bit_i);

            end

            // All 741 distinct double-bit combinations.
            for (bit_i = 0;
                 bit_i < 39;
                 bit_i = bit_i + 1) begin

                for (bit_j = bit_i + 1;
                     bit_j < 39;
                     bit_j = bit_j + 1) begin

                    test_double_bit_error(bit_i, bit_j);

                end

            end

            if (((pattern_index + 1) % 10) == 0) begin

                $display(
                    "Progress: %0d/80 patterns | cases=%0d | failures=%0d",
                    pattern_index + 1,
                    total_cases,
                    failed_cases
                );

            end

        end

        // -----------------------------------------------------
        // FINAL SUMMARY
        // -----------------------------------------------------

        $display("");
        $display("==================================================");
        $display(" ASTRA-FT DAY 4 SECDED RESULTS");
        $display("==================================================");

        $display("Clean codeword cases       : %0d", clean_cases);
        $display("Single-bit error cases     : %0d", single_bit_cases);
        $display("Double-bit error cases     : %0d", double_bit_cases);

        $display("------------------------------------------");

        $display("Total decoder test cases   : %0d", total_cases);
        $display("Passed decoder cases       : %0d", passed_cases);
        $display("Failed decoder cases       : %0d", failed_cases);

        $display("------------------------------------------");

        $display("Encoder structure checks   : %0d",
                 encoder_structure_checks);

        $display("Encoder structure passed   : %0d",
                 encoder_structure_passed);

        $display("Encoder structure failures : %0d",
                 encoder_structure_failures);

        $display("==================================================");

        if ((total_cases == 62480) &&
            (passed_cases == total_cases) &&
            (failed_cases == 0) &&
            (encoder_structure_checks == 80) &&
            (encoder_structure_passed == 80) &&
            (encoder_structure_failures == 0)) begin

            $display("DAY 4 SECDED STATUS: PASS");

        end

        else begin

            $display("DAY 4 SECDED STATUS: FAIL");

        end

        $display("==================================================");

        $finish;

    end

endmodule
