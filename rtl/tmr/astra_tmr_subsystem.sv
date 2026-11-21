module astra_tmr_subsystem #(
    parameter WIDTH = 32
)(
    input  logic [2:0]        opcode,
    input  logic [WIDTH-1:0]  operand_a,
    input  logic [WIDTH-1:0]  operand_b,

    // XOR masks used only for fault-injection experiments.
    input  logic [WIDTH-1:0]  fault_mask_a,
    input  logic [WIDTH-1:0]  fault_mask_b,
    input  logic [WIDTH-1:0]  fault_mask_c,

    output logic [WIDTH-1:0]  replica_a,
    output logic [WIDTH-1:0]  replica_b,
    output logic [WIDTH-1:0]  replica_c,

    output logic [WIDTH-1:0]  voted_output,

    output logic              mismatch_detected,
    output logic              lane_a_mismatch,
    output logic              lane_b_mismatch,
    output logic              lane_c_mismatch
);

    logic [WIDTH-1:0] core_a_result;
    logic [WIDTH-1:0] core_b_result;
    logic [WIDTH-1:0] core_c_result;

    // ------------------------------------------------
    // Replica A
    // ------------------------------------------------

    replica_core #(
        .WIDTH(WIDTH)
    ) core_a (
        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .result(core_a_result)
    );

    // ------------------------------------------------
    // Replica B
    // ------------------------------------------------

    replica_core #(
        .WIDTH(WIDTH)
    ) core_b (
        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .result(core_b_result)
    );

    // ------------------------------------------------
    // Replica C
    // ------------------------------------------------

    replica_core #(
        .WIDTH(WIDTH)
    ) core_c (
        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .result(core_c_result)
    );

    // ------------------------------------------------
    // Fault injection
    //
    // XOR masks simulate corruption at replica outputs.
    // A zero mask means no injected corruption.
    // ------------------------------------------------

    assign replica_a = core_a_result ^ fault_mask_a;
    assign replica_b = core_b_result ^ fault_mask_b;
    assign replica_c = core_c_result ^ fault_mask_c;

    // ------------------------------------------------
    // Majority voter
    // ------------------------------------------------

    majority_voter #(
        .WIDTH(WIDTH)
    ) voter (
        .replica_a(replica_a),
        .replica_b(replica_b),
        .replica_c(replica_c),
        .voted_output(voted_output),
        .mismatch_detected(mismatch_detected)
    );

    // ------------------------------------------------
    // Replica mismatch indicators
    // ------------------------------------------------

    assign lane_a_mismatch = (replica_a != voted_output);
    assign lane_b_mismatch = (replica_b != voted_output);
    assign lane_c_mismatch = (replica_c != voted_output);

endmodule
