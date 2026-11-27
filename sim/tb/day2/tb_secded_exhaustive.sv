`timescale 1ns/1ps

module tb_secded_exhaustive;

    reg  [31:0] data_in;
    wire [38:0] encoded_data;

    reg  [38:0] received_data;
    wire [31:0] corrected_data;
    wire [5:0]  syndrome;
    wire error_detected;
    wire error_corrected;
    wire uncorrectable_error;

    integer p, i, j;
    integer clean_cases;
    integer single_cases;
    integer double_cases;

    reg [31:0] test_pattern;

    secded_encoder_32 encoder (
        .data_in(data_in),
        .encoded_data(encoded_data)
    );

    secded_decoder_32 decoder (
        .encoded_data(received_data),
        .corrected_data(corrected_data),
        .syndrome(syndrome),
        .error_detected(error_detected),
        .error_corrected(error_corrected),
        .uncorrectable_error(uncorrectable_error)
    );

    initial begin
        clean_cases  = 0;
        single_cases = 0;
        double_cases = 0;

        $display("==========================================");
        $display(" ASTRA-FT SECDED VERIFICATION CAMPAIGN");
        $display("==========================================");

        // 64 deterministic data patterns
        for (p = 0; p < 64; p = p + 1) begin

            case (p)
                0: test_pattern = 32'h00000000;
                1: test_pattern = 32'hFFFFFFFF;
                2: test_pattern = 32'hAAAAAAAA;
                3: test_pattern = 32'h55555555;
                default:
                    test_pattern =
                        (32'h9E3779B9 * p) ^
                        (32'hA5A5A5A5 >> (p % 32));
            endcase

            data_in = test_pattern;
            #1;

            // CLEAN CODEWORD
            received_data = encoded_data;
            #1;

            if (corrected_data !== data_in ||
                syndrome !== 6'b0 ||
                error_detected !== 1'b0 ||
                error_corrected !== 1'b0 ||
                uncorrectable_error !== 1'b0) begin
                $display("FAIL: clean codeword, pattern=%0d", p);
                $fatal(1);
            end

            clean_cases = clean_cases + 1;

            // ALL 39 SINGLE-BIT ERROR POSITIONS
            for (i = 0; i < 39; i = i + 1) begin

                received_data = encoded_data ^ (39'b1 << i);
                #1;

                if (corrected_data !== data_in ||
                    error_detected !== 1'b1 ||
                    error_corrected !== 1'b1 ||
                    uncorrectable_error !== 1'b0) begin
                    $display(
                        "FAIL: single-bit error, pattern=%0d bit=%0d",
                        p, i
                    );
                    $fatal(1);
                end

                if (i < 38 && syndrome !== (i + 1)) begin
                    $display(
                        "FAIL: single-bit syndrome, pattern=%0d bit=%0d syndrome=%0d",
                        p, i, syndrome
                    );
                    $fatal(1);
                end

                if (i == 38 && syndrome !== 6'b0) begin
                    $display("FAIL: overall parity-bit syndrome");
                    $fatal(1);
                end

                single_cases = single_cases + 1;
            end

            // ALL DISTINCT DOUBLE-BIT ERROR COMBINATIONS
            for (i = 0; i < 39; i = i + 1) begin
                for (j = i + 1; j < 39; j = j + 1) begin

                    received_data =
                        encoded_data ^
                        (39'b1 << i) ^
                        (39'b1 << j);

                    #1;

                    if (error_detected !== 1'b1 ||
                        error_corrected !== 1'b0 ||
                        uncorrectable_error !== 1'b1 ||
                        syndrome === 6'b0) begin

                        $display(
                            "FAIL: double-bit error, pattern=%0d bits=%0d,%0d syndrome=%0d",
                            p, i, j, syndrome
                        );
                        $fatal(1);
                    end

                    double_cases = double_cases + 1;
                end
            end

            if ((p % 8) == 7)
                $display("Completed data patterns: %0d/64", p + 1);
        end

        $display("");
        $display("==========================================");
        $display(" SECDED VERIFICATION: PASS");
        $display("==========================================");
        $display("Clean codewords       : %0d", clean_cases);
        $display("Single-bit cases      : %0d", single_cases);
        $display("Double-bit cases      : %0d", double_cases);
        $display("Total test cases      : %0d",
                 clean_cases + single_cases + double_cases);
        $display("==========================================");

        $finish;
    end

endmodule
