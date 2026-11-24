`timescale 1ns/1ps

module tb_secded_32;

    // ---------------------------------------------------------
    // Inputs
    // ---------------------------------------------------------
    reg [31:0] data_in;

    reg [38:0] received_codeword;

    // ---------------------------------------------------------
    // Encoder output
    // ---------------------------------------------------------
    wire [38:0] encoded_data;

    // ---------------------------------------------------------
    // Decoder outputs
    // ---------------------------------------------------------
    wire [31:0] corrected_data;
    wire [5:0] syndrome;

    wire error_detected;
    wire error_corrected;
    wire uncorrectable_error;

    // ---------------------------------------------------------
    // Test accounting
    // ---------------------------------------------------------
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer clean_tests;
    integer single_bit_tests;
    integer double_bit_tests;

    integer bit_i;
    integer bit_j;
    integer pattern_i;

    reg [31:0] test_pattern;
    reg [38:0] injected_codeword;

    // ---------------------------------------------------------
    // DUTs
    // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // Test helper
    // ---------------------------------------------------------
    task report_pass;
        input [255:0] message;

        begin
            total_tests = total_tests + 1;
            passed_tests = passed_tests + 1;
        end
    endtask

    // ---------------------------------------------------------
    // Clean data verification
    // ---------------------------------------------------------
    task test_clean_data;
        input [31:0] test_data;

        begin

            data_in = test_data;

            #1;

            received_codeword = encoded_data;

            #1;

            total_tests = total_tests + 1;
            clean_tests = clean_tests + 1;

            if ((corrected_data === test_data) &&
                (error_detected === 1'b0) &&
                (error_corrected === 1'b0) &&
                (uncorrectable_error === 1'b0) &&
                (syndrome === 6'b000000)) begin

                passed_tests = passed_tests + 1;

                $display(
                    "PASS CLEAN | DATA=%h CODE=%h",
                    test_data, encoded_data
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL CLEAN | DATA=%h DECODED=%h SYNDROME=%b",
                    test_data, corrected_data, syndrome
                );

            end

        end

    endtask

    // ---------------------------------------------------------
    // Single-bit fault verification
    // ---------------------------------------------------------
    task test_single_bit_error;
        input [31:0] test_data;
        input integer error_bit;

        begin

            data_in = test_data;

            #1;

            injected_codeword =
                encoded_data ^ (39'b1 << error_bit);

            received_codeword = injected_codeword;

            #1;

            total_tests = total_tests + 1;
            single_bit_tests = single_bit_tests + 1;

            if ((corrected_data === test_data) &&
                (error_detected === 1'b1) &&
                (error_corrected === 1'b1) &&
                (uncorrectable_error === 1'b0) &&
                ((error_bit == 38 && syndrome === 6'b000000) ||
                 (error_bit < 38 && syndrome === 6'(error_bit + 1)))) begin

                passed_tests = passed_tests + 1;

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL SINGLE BIT | DATA=%h BIT=%0d",
                    test_data, error_bit
                );

                $display(
                    "EXPECTED=%h ACTUAL=%h SYNDROME=%b",
                    test_data, corrected_data, syndrome
                );

                $display(
                    "DETECTED=%b CORRECTED=%b UNCORRECTABLE=%b",
                    error_detected,
                    error_corrected,
                    uncorrectable_error
                );

            end

        end

    endtask

    // ---------------------------------------------------------
    // Double-bit fault verification
    // ---------------------------------------------------------
    task test_double_bit_error;
        input [31:0] test_data;
        input integer error_bit_a;
        input integer error_bit_b;

        begin

            data_in = test_data;

            #1;

            injected_codeword =
                encoded_data ^
                (39'b1 << error_bit_a) ^
                (39'b1 << error_bit_b);

            received_codeword = injected_codeword;

            #1;

            total_tests = total_tests + 1;
            double_bit_tests = double_bit_tests + 1;

            if ((error_detected === 1'b1) &&
                (error_corrected === 1'b0) &&
                (uncorrectable_error === 1'b1) &&
                (syndrome !== 6'b000000)) begin

                passed_tests = passed_tests + 1;

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL DOUBLE BIT | DATA=%h BIT_A=%0d BIT_B=%0d",
                    test_data, error_bit_a, error_bit_b
                );

                $display(
                    "SYNDROME=%b DETECTED=%b CORRECTED=%b UNCORRECTABLE=%b",
                    syndrome,
                    error_detected,
                    error_corrected,
                    uncorrectable_error
                );

            end

        end

    endtask

    // ---------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------
    initial begin

        data_in = 0;
        received_codeword = 0;

        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;

        clean_tests = 0;
        single_bit_tests = 0;
        double_bit_tests = 0;

        bit_i = 0;
        bit_j = 0;
        pattern_i = 0;

        test_pattern = 0;
        injected_codeword = 0;

        $dumpfile("sim/waveforms/secded_32.vcd");
        $dumpvars(0, tb_secded_32);

        $display("");
        $display("===============================================");
        $display(" ASTRA-FT DAY 4 SECDED VERIFICATION");
        $display("===============================================");
        $display("");

        // -----------------------------------------------------
        // Pattern set
        // -----------------------------------------------------

        for (pattern_i = 0;
             pattern_i < 5;
             pattern_i = pattern_i + 1) begin

            case (pattern_i)

                0: test_pattern = 32'h00000000;
                1: test_pattern = 32'hFFFFFFFF;
                2: test_pattern = 32'hAAAAAAAA;
                3: test_pattern = 32'h55555555;
                4: test_pattern = 32'hDEADBEEF;

                default: test_pattern = 32'h00000000;

            endcase

            // -------------------------------------------------
            // CLEAN CODEWORD
            // -------------------------------------------------

            test_clean_data(test_pattern);

            // -------------------------------------------------
            // All 39 single-bit errors
            //
            // Bit 0..37: Hamming codeword bits
            // Bit 38: overall parity bit
            // -------------------------------------------------

            for (bit_i = 0;
                 bit_i < 39;
                 bit_i = bit_i + 1) begin

                test_single_bit_error(test_pattern, bit_i);

            end

        end

        // -----------------------------------------------------
        // All double-bit combinations for one representative
        // data pattern.
        //
        // C(39,2) = 741 combinations
        // -----------------------------------------------------

        test_pattern = 32'hA5C39E71;

        for (bit_i = 0;
             bit_i < 39;
             bit_i = bit_i + 1) begin

            for (bit_j = bit_i + 1;
                 bit_j < 39;
                 bit_j = bit_j + 1) begin

                test_double_bit_error(
                    test_pattern,
                    bit_i,
                    bit_j
                );

            end

        end

        // -----------------------------------------------------
        // Summary
        // -----------------------------------------------------

        $display("");
        $display("===============================================");
        $display(" ASTRA-FT SECDED TEST SUMMARY");
        $display("===============================================");

        $display("Total tests          : %0d", total_tests);
        $display("Passed               : %0d", passed_tests);
        $display("Failed               : %0d", failed_tests);

        $display("");
        $display("Clean words          : %0d", clean_tests);
        $display("Single-bit tests     : %0d", single_bit_tests);
        $display("Double-bit tests     : %0d", double_bit_tests);

        $display("");
        $display("===============================================");

        if (failed_tests == 0)
            $display("SECDED STATUS: PASS");
        else
            $display("SECDED STATUS: FAIL");

        $display("===============================================");

        $finish;

    end

endmodule
