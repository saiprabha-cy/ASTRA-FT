
`timescale 1ns/1ps

module astra_ft_system #(
    parameter integer MEMORY_DEPTH = 16,
    parameter integer ADDR_WIDTH = 4,
    parameter integer HEARTBEAT_TIMEOUT = 20,
    parameter integer RECOVERY_TIMEOUT = 10,
    parameter integer MAX_RECOVERY_RETRIES = 3
)(
    input logic clk,
    input logic reset,

    // TMR processing interface
    input logic [2:0] opcode,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,

    // Simulation-only replica fault injection
    input logic [31:0] fault_mask_a,
    input logic [31:0] fault_mask_b,
    input logic [31:0] fault_mask_c,

    // Memory write interface
    input logic memory_write_enable,
    input logic memory_write_from_tmr,
    input logic [ADDR_WIDTH-1:0] memory_write_address,
    input logic [31:0] memory_write_data,

    // Memory read interface
    input logic memory_read_enable,
    input logic [ADDR_WIDTH-1:0] memory_read_address,

    output logic [31:0] memory_read_data,
    output logic memory_read_data_valid,
    output logic memory_read_error_detected,
    output logic memory_read_error_corrected,
    output logic memory_read_uncorrectable_error,

    // Scrubber control
    input logic scrub_start,
    output logic scrub_busy,
    output logic scrub_done,
    output logic [ADDR_WIDTH:0] scrub_words_scanned,
    output logic [31:0] scrub_corrected_count,
    output logic [31:0] scrub_uncorrectable_count,

    // Memory fault injection
    input logic memory_inject_enable,
    input logic [ADDR_WIDTH-1:0] memory_inject_address,
    input logic [38:0] memory_inject_mask,

    // Heartbeat/watchdog
    input logic heartbeat,
    output logic watchdog_recovery_request,
    output logic watchdog_reset_request,
    output logic safe_mode,
    output logic [1:0] watchdog_state,
    output logic [31:0] watchdog_timeout_count,
    output logic [31:0] watchdog_recovery_attempt_count,

    // TMR visibility
    output logic [31:0] replica_a,
    output logic [31:0] replica_b,
    output logic [31:0] replica_c,
    output logic [31:0] tmr_voted_result,
    output logic tmr_mismatch_detected,
    output logic lane_a_mismatch,
    output logic lane_b_mismatch,
    output logic lane_c_mismatch
);

    // --------------------------------------------------
    // TMR subsystem
    // --------------------------------------------------

    astra_tmr_subsystem #(
        .WIDTH(32)
    ) tmr (
        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),

        .fault_mask_a(fault_mask_a),
        .fault_mask_b(fault_mask_b),
        .fault_mask_c(fault_mask_c),

        .replica_a(replica_a),
        .replica_b(replica_b),
        .replica_c(replica_c),

        .voted_output(tmr_voted_result),

        .mismatch_detected(tmr_mismatch_detected),
        .lane_a_mismatch(lane_a_mismatch),
        .lane_b_mismatch(lane_b_mismatch),
        .lane_c_mismatch(lane_c_mismatch)
    );

    // --------------------------------------------------
    // Memory write-data selection
    // --------------------------------------------------

    logic [31:0] selected_memory_write_data;
    logic selected_memory_write_enable;

    always_comb begin
        selected_memory_write_enable = memory_write_enable;

        if (memory_write_from_tmr)
            selected_memory_write_data = tmr_voted_result;
        else
            selected_memory_write_data = memory_write_data;
    end

    // --------------------------------------------------
    // ECC memory
    // --------------------------------------------------

    logic [ADDR_WIDTH-1:0] scrub_address;
    logic [38:0] scrub_codeword;
    logic scrub_write_enable;
    logic [38:0] scrub_write_codeword;

    ecc_memory_32 #(
        .DEPTH(MEMORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory (
        .clk(clk),
        .reset(reset),

        .write_enable(selected_memory_write_enable),
        .write_address(memory_write_address),
        .write_data(selected_memory_write_data),

        .read_enable(memory_read_enable),
        .read_address(memory_read_address),

        .read_data(memory_read_data),
        .read_data_valid(memory_read_data_valid),

        .read_error_detected(memory_read_error_detected),
        .read_error_corrected(memory_read_error_corrected),
        .read_uncorrectable_error(memory_read_uncorrectable_error),

        .scrub_address(scrub_address),
        .scrub_codeword(scrub_codeword),

        .scrub_write_enable(scrub_write_enable),
        .scrub_write_codeword(scrub_write_codeword),

        .inject_enable(memory_inject_enable),
        .inject_address(memory_inject_address),
        .inject_mask(memory_inject_mask)
    );

    // --------------------------------------------------
    // ECC scrubber
    // --------------------------------------------------

    ecc_scrubber_32 #(
        .DEPTH(MEMORY_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) scrubber (
        .clk(clk),
        .reset(reset),

        .start(scrub_start),

        .busy(scrub_busy),
        .done(scrub_done),

        .scrub_address(scrub_address),
        .scrub_codeword(scrub_codeword),

        .scrub_write_enable(scrub_write_enable),
        .scrub_write_codeword(scrub_write_codeword),

        .words_scanned(scrub_words_scanned),
        .corrected_count(scrub_corrected_count),
        .uncorrectable_count(scrub_uncorrectable_count)
    );

    // --------------------------------------------------
    // Watchdog/recovery
    // --------------------------------------------------

    watchdog_recovery_fsm #(
        .HEARTBEAT_TIMEOUT(HEARTBEAT_TIMEOUT),
        .RECOVERY_TIMEOUT(RECOVERY_TIMEOUT),
        .MAX_RETRIES(MAX_RECOVERY_RETRIES)
    ) watchdog (
        .clk(clk),
        .reset(reset),
        .heartbeat(heartbeat),

        .recovery_request(watchdog_recovery_request),
        .safe_mode(safe_mode),
        .system_reset_request(watchdog_reset_request),

        .recovery_state(watchdog_state),
        .timeout_count(watchdog_timeout_count),
        .recovery_attempt_count(watchdog_recovery_attempt_count)
    );

endmodule
