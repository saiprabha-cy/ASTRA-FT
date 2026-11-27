module formal_secded;

    (* anyconst *) logic [31:0] data_in;
    (* anyconst *) logic [5:0] single_bit;
    (* anyconst *) logic [5:0] double_bit_a;
    (* anyconst *) logic [5:0] double_bit_b;

    logic [38:0] encoded_data;

    logic [31:0] clean_data;
    logic [5:0] clean_syndrome;
    logic clean_detected, clean_corrected, clean_uncorrectable;

    logic [38:0] single_fault_codeword;
    logic [31:0] single_data;
    logic [5:0] single_syndrome;
    logic single_detected, single_corrected, single_uncorrectable;

    logic [38:0] double_fault_codeword;
    logic [31:0] double_data;
    logic [5:0] double_syndrome;
    logic double_detected, double_corrected, double_uncorrectable;

    // Reference encoder
    secded_encoder_32 encoder (
        .data_in(data_in),
        .encoded_data(encoded_data)
    );

    // No-error decoder
    secded_decoder_32 clean_decoder (
        .encoded_data(encoded_data),
        .corrected_data(clean_data),
        .syndrome(clean_syndrome),
        .error_detected(clean_detected),
        .error_corrected(clean_corrected),
        .uncorrectable_error(clean_uncorrectable)
    );

    // Inject one arbitrary encoded-bit error.
    assign single_fault_codeword =
        encoded_data ^ (39'b1 << single_bit);

    secded_decoder_32 single_decoder (
        .encoded_data(single_fault_codeword),
        .corrected_data(single_data),
        .syndrome(single_syndrome),
        .error_detected(single_detected),
        .error_corrected(single_corrected),
        .uncorrectable_error(single_uncorrectable)
    );

    // Inject two arbitrary, distinct encoded-bit errors.
    assign double_fault_codeword =
        encoded_data ^
        (39'b1 << double_bit_a) ^
        (39'b1 << double_bit_b);

    secded_decoder_32 double_decoder (
        .encoded_data(double_fault_codeword),
        .corrected_data(double_data),
        .syndrome(double_syndrome),
        .error_detected(double_detected),
        .error_corrected(double_corrected),
        .uncorrectable_error(double_uncorrectable)
    );

    always_comb begin

        // P1-P3: clean codeword must decode exactly.
        assert(clean_data == data_in);
        assert(clean_syndrome == 6'b0);
        assert(clean_detected == 1'b0 &&
               clean_corrected == 1'b0 &&
               clean_uncorrectable == 1'b0);

        // P4-P8: every valid single-bit error is corrected.
        if (single_bit < 39) begin
            assert(single_data == data_in);
            assert(single_detected == 1'b1);
            assert(single_corrected == 1'b1);
            assert(single_uncorrectable == 1'b0);

            // Encoded bits 0..37 map to Hamming positions 1..38.
            // Encoded bit 38 is the overall parity bit.
            if (single_bit < 38)
                assert(single_syndrome == (single_bit + 1));
            else
                assert(single_syndrome == 0);
        end

        // P9-P13: every pair of distinct valid bit errors is detected.
        if ((double_bit_a < 39) &&
            (double_bit_b < 39) &&
            (double_bit_a != double_bit_b)) begin

            assert(double_detected == 1'b1);
            assert(double_corrected == 1'b0);
            assert(double_uncorrectable == 1'b1);
            assert(double_syndrome != 0);
        end

    end

endmodule
