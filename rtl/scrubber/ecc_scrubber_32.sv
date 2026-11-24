`timescale 1ns/1ps
module ecc_scrubber_32 #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input logic clk,
    input logic reset,

    input logic start,

    output logic busy,
    output logic done,

    // Memory scrub interface
    output logic [ADDR_WIDTH-1:0] scrub_address,
    input logic [38:0] scrub_codeword,


    output logic scrub_write_enable,
    output logic [38:0] scrub_write_codeword,

    // Counters
    output logic [ADDR_WIDTH:0] words_scanned,
    output logic [31:0] corrected_count,
    output logic [31:0] uncorrectable_count
);

    // -----------------------------------------
    // FSM
    // -----------------------------------------
    typedef enum logic [1:0] {
        IDLE,
        SCAN,
        DONE_STATE
    } scrub_state_t;

    scrub_state_t state;

    logic [ADDR_WIDTH-1:0] current_address;

    // -----------------------------------------
    // Scrub writeback encoder
    //
    // Corrected data is obtained from the
    // memory's ECC decoder. Re-encode it so the
    // stored codeword is fully repaired.
    // -----------------------------------------
    logic [31:0] corrected_data;
    logic [5:0] syndrome;

    logic error_detected;
    logic error_corrected;
    logic uncorrectable_error;

    secded_decoder_32 decoder (
    .encoded_data(scrub_codeword),

    .corrected_data(corrected_data),
    .syndrome(syndrome),

    .error_detected(error_detected),
    .error_corrected(error_corrected),
    .uncorrectable_error(uncorrectable_error)
);

wire _unused_ok = &{1'b0, syndrome, error_detected};

    secded_encoder_32 encoder (
        .data_in(corrected_data),
        .encoded_data(scrub_write_codeword)
    );

    // -----------------------------------------
    // Controller outputs
    // -----------------------------------------
    always_comb begin

        scrub_address = current_address;

        busy = (state == SCAN);

        done = (state == DONE_STATE);

        // Write back only a correctable error.
        scrub_write_enable =
            (state == SCAN) &&
            error_corrected &&
            !uncorrectable_error;

    end

    // -----------------------------------------
    // FSM
    // -----------------------------------------
    always_ff @(posedge clk) begin

        if (reset) begin

            state <= IDLE;

            current_address <= '0;

            words_scanned <= '0;
            corrected_count <= '0;
            uncorrectable_count <= '0;

        end

        else begin

            case (state)

                IDLE: begin

                    current_address <= '0;

                    if (start) begin

                        words_scanned <= '0;
                        corrected_count <= '0;
                        uncorrectable_count <= '0;

                        state <= SCAN;

                    end

                end

                SCAN: begin

                    words_scanned <= words_scanned + 1'b1;

                    if (error_corrected &&
                        !uncorrectable_error) begin

                        corrected_count <=
                            corrected_count + 1'b1;

                    end

                    if (uncorrectable_error) begin

                        uncorrectable_count <=
                            uncorrectable_count + 1'b1;

                    end

                    if (current_address == ADDR_WIDTH'(DEPTH - 1)) begin

                        state <= DONE_STATE;

                    end

                    else begin

                        current_address <=
                            current_address + 1'b1;

                    end

                end

                DONE_STATE: begin

                    state <= IDLE;

                    current_address <= '0;

                end

                default: begin

                    state <= IDLE;

                    current_address <= '0;

                end

            endcase

        end

    end

endmodule
