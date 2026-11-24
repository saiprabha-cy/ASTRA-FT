`timescale 1ns/1ps
module ecc_memory_32 #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input logic clk,
    input logic reset,

    // User write
    input logic write_enable,
    input logic [ADDR_WIDTH-1:0] write_address,
    input logic [31:0] write_data,

    // User read
    input logic read_enable,
    input logic [ADDR_WIDTH-1:0] read_address,

    output logic [31:0] read_data,
    output logic read_data_valid,

    output logic read_error_detected,
    output logic read_error_corrected,
    output logic read_uncorrectable_error,

    // Scrubber read
    input logic [ADDR_WIDTH-1:0] scrub_address,
    output logic [38:0] scrub_codeword,

    // Scrubber writeback
    input logic scrub_write_enable,
    input logic [38:0] scrub_write_codeword,

    // Fault injection
    input logic inject_enable,
    input logic [ADDR_WIDTH-1:0] inject_address,
    input logic [38:0] inject_mask
);

    logic [38:0] memory [0:DEPTH-1];

    logic [38:0] encoded_write_data;

    logic [38:0] user_read_codeword;

    logic [31:0] user_corrected_data;
    

    logic user_error_detected;
    logic user_error_corrected;
    logic user_uncorrectable_error;

    // Write encoder
    secded_encoder_32 encoder (
        .data_in(write_data),
        .encoded_data(encoded_write_data)
    );

    // Read decoder
    assign user_read_codeword = memory[read_address];
    logic [5:0] user_syndrome;

    secded_decoder_32 user_decoder (
        .encoded_data(user_read_codeword),

        .corrected_data(user_corrected_data),
        .syndrome(user_syndrome),

        .error_detected(user_error_detected),
        .error_corrected(user_error_corrected),
        .uncorrectable_error(user_uncorrectable_error)
    );
    wire _unused_ok = &{1'b0, user_syndrome};


    // Scrubber read path
    always_comb begin
        scrub_codeword = memory[scrub_address];
    end

    // User read capture
    always_ff @(posedge clk) begin

        if (reset) begin

            read_data <= 32'b0;
            read_data_valid <= 1'b0;

            read_error_detected <= 1'b0;
            read_error_corrected <= 1'b0;
            read_uncorrectable_error <= 1'b0;

        end

        else if (read_enable) begin

            read_data <= user_corrected_data;

            read_error_detected <= user_error_detected;
            read_error_corrected <= user_error_corrected;
            read_uncorrectable_error <= user_uncorrectable_error;

            read_data_valid <= !user_uncorrectable_error;

        end

    end

    // Storage write arbitration
    always_ff @(posedge clk) begin

        if (!reset) begin

            if (write_enable) begin

                memory[write_address] <= encoded_write_data;

            end

            else if (scrub_write_enable) begin

                memory[scrub_address] <= scrub_write_codeword;

            end

            else if (inject_enable) begin

                memory[inject_address] <=
                    memory[inject_address] ^ inject_mask;

            end

        end

    end

endmodule
