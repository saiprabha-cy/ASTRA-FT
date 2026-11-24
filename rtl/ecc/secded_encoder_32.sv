`timescale 1ns/1ps
module secded_encoder_32 (
    input  logic [31:0] data_in,
    output logic [38:0] encoded_data
);

    logic [38:1] hamming_codeword;

    integer data_index;
    integer code_position;
    integer parity_position;
    logic overall_parity;

    always_comb begin

        hamming_codeword = '0;
        encoded_data     = '0;

        data_index = 0;

        // -----------------------------------------------------
        // Insert 32 data bits into non-parity positions.
        // Parity positions: 1, 2, 4, 8, 16, 32
        // -----------------------------------------------------

        for (code_position = 1;
             code_position <= 38;
             code_position = code_position + 1) begin

            if ((code_position != 1)  &&
                (code_position != 2)  &&
                (code_position != 4)  &&
                (code_position != 8)  &&
                (code_position != 16) &&
                (code_position != 32)) begin

                hamming_codeword[code_position] =
                    data_in[data_index];

                data_index = data_index + 1;

            end

        end

        // -----------------------------------------------------
        // Generate six Hamming parity bits.
        //
        // Each parity bit checks positions whose binary position
        // includes that parity bit's corresponding bit.
        //
        // Even parity convention.
        // -----------------------------------------------------

        for (parity_position = 1;
             parity_position <= 32;
             parity_position = parity_position * 2) begin

            hamming_codeword[parity_position] = 1'b0;

            for (code_position = 1;
                 code_position <= 38;
                 code_position = code_position + 1) begin

                if ((code_position & parity_position) != 0) begin

                    hamming_codeword[parity_position] =
                        hamming_codeword[parity_position] ^
                        hamming_codeword[code_position];

                end

            end

        end

        // -----------------------------------------------------
        // Map Hamming positions 1..38 into encoded_data[37:0]
        // encoded_data[38] is the overall parity bit.
        // -----------------------------------------------------

        for (code_position = 1;
             code_position <= 38;
             code_position = code_position + 1) begin

            encoded_data[code_position - 1] =
                hamming_codeword[code_position];

        end

        // -----------------------------------------------------
        // Extended parity over the complete 38-bit Hamming
        // codeword.
        //
        // Overall parity bit is encoded_data[38].
        // -----------------------------------------------------

        overall_parity = 1'b0;

        for (code_position = 1;
             code_position <= 38;
             code_position = code_position + 1) begin

            overall_parity =
                overall_parity ^
                hamming_codeword[code_position];

        end

        encoded_data[38] = overall_parity;

    end

endmodule
