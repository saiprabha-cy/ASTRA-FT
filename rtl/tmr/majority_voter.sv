module majority_voter #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0] replica_a,
    input  logic [WIDTH-1:0] replica_b,
    input  logic [WIDTH-1:0] replica_c,

    output logic [WIDTH-1:0] voted_output,
    output logic             mismatch_detected
);

    // Bitwise majority voting.
    always_comb begin
        voted_output =
            (replica_a & replica_b) |
            (replica_a & replica_c) |
            (replica_b & replica_c);
    end

    // Detect any disagreement between replicas.
    always_comb begin
        mismatch_detected =
            (replica_a != replica_b) ||
            (replica_b != replica_c) ||
            (replica_a != replica_c);
    end

endmodule
