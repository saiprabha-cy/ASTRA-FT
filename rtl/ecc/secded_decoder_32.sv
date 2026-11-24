`timescale 1ns/1ps
module secded_decoder_32 (
    input  logic [38:0] encoded_data,

    output logic [31:0] corrected_data,
    output logic [5:0]  syndrome,

    output logic error_detected,
    output logic error_corrected,
    output logic uncorrectable_error
);

    logic [38:1] hamming_codeword;
    logic [38:1] corrected_codeword;

    integer code_position;
    integer parity_position;
    integer data_index;

    logic [5:0] syndrome_value;
    logic parity_check;
    logic overall_parity;

    always_comb begin

        // -----------------------------------------------------
        // Initialize internal state
        // -----------------------------------------------------

        hamming_codeword    = '0;
        corrected_codeword  = '0;

        corrected_data     = '0;
        syndrome           = '0;

        error_detected     = 1'b0;
        error_corrected    = 1'b0;
        uncorrectable_error = 1'b0;

        syndrome_value     = 6'b000000;
        overall_parity    = 1'b0;
        data_index         = 0;

        // -----------------------------------------------------
        // Map encoded Hamming bits into positions 1..38
        // -----------------------------------------------------

        for (code_position = 1;
             code_position <= 38;
             code_position = code_position + 1) begin

            hamming_codeword[code_position] =
                encoded_data[code_position - 1];

        end

        corrected_codeword = hamming_codeword;

        // -----------------------------------------------------
// Calculate six individual parity-check results.
//
// Each parity check becomes one syndrome bit.
// -----------------------------------------------------

syndrome_value = 6'b000000;

        for (parity_position = 1;
             parity_position <= 32;
             parity_position = parity_position * 2) begin

            parity_check = 1'b0;

            for (code_position = 1;
                 code_position <= 38;
                 code_position = code_position + 1) begin

                if ((code_position & parity_position) != 0) begin

                    parity_check =
                        parity_check ^
                        hamming_codeword[code_position];

                end

            end

            case (parity_position)

                1:  syndrome_value[0] = parity_check;
                2:  syndrome_value[1] = parity_check;
                4:  syndrome_value[2] = parity_check;
                8:  syndrome_value[3] = parity_check;
                16: syndrome_value[4] = parity_check;
                32: syndrome_value[5] = parity_check;

                default: ;

            endcase

        end

        syndrome = syndrome_value;

        // -----------------------------------------------------
        // Overall parity check
        // -----------------------------------------------------

        overall_parity = encoded_data[38];

        for (code_position = 1;
             code_position <= 38;
             code_position = code_position + 1) begin

            overall_parity =
                overall_parity ^
                hamming_codeword[code_position];

        end

        // -----------------------------------------------------
        // SECDED decision
        // -----------------------------------------------------

        if ((syndrome_value == 0) &&
            (overall_parity == 0)) begin

            // No error detected.

            error_detected = 1'b0;
            error_corrected = 1'b0;
            uncorrectable_error = 1'b0;

        end

        else if ((syndrome_value != 0) &&
                 (overall_parity == 1)) begin

            // Odd number of errors.
            // A valid syndrome identifies a Hamming position.

            error_detected = 1'b1;

            if (syndrome_value <= 38) begin

                corrected_codeword[syndrome_value] =
                    ~corrected_codeword[syndrome_value];

                error_corrected = 1'b1;
                uncorrectable_error = 1'b0;

            end

            else begin

                // Syndrome points outside the valid codeword.

                error_corrected = 1'b0;
                uncorrectable_error = 1'b1;

            end

        end

        else if ((syndrome_value == 0) &&
                 (overall_parity == 1)) begin

            // Error in the overall parity bit.
            // Payload data itself is unaffected.

            error_detected = 1'b1;
            error_corrected = 1'b1;
            uncorrectable_error = 1'b0;

        end

        else begin

            // Nonzero syndrome with even overall parity.
            // Detects a double-bit error under the SECDED model.

            error_detected = 1'b1;
            error_corrected = 1'b0;
            uncorrectable_error = 1'b1;

        end

        // -----------------------------------------------------
        // Extract corrected data bits from codeword positions
        // -----------------------------------------------------

        data_index = 0;

        for (code_position = 1;
             code_position <= 38;
             code_position = code_position + 1) begin

            if ((code_position != 1)  &&
                (code_position != 2)  &&
                (code_position != 4)  &&
                (code_position != 8)  &&
                (code_position != 16) &&
                (code_position != 32)) begin

                corrected_data[data_index] =
                    corrected_codeword[code_position];

                data_index = data_index + 1;

            end

        end

    end

endmodule
