
module formal_tmr;

    localparam WIDTH = 32;

    (* anyconst *) logic [2:0] opcode;
    (* anyconst *) logic [WIDTH-1:0] operand_a;
    (* anyconst *) logic [WIDTH-1:0] operand_b;

    (* anyconst *) logic [WIDTH-1:0] fault_mask_a;
    (* anyconst *) logic [WIDTH-1:0] fault_mask_b;
    (* anyconst *) logic [WIDTH-1:0] fault_mask_c;

    logic [WIDTH-1:0] replica_a;
    logic [WIDTH-1:0] replica_b;
    logic [WIDTH-1:0] replica_c;

    logic [WIDTH-1:0] voted_output;

    logic mismatch_detected;
    logic lane_a_mismatch;
    logic lane_b_mismatch;
    logic lane_c_mismatch;

    logic [WIDTH-1:0] reference_result;
    logic [WIDTH-1:0] expected_a;
    logic [WIDTH-1:0] expected_b;
    logic [WIDTH-1:0] expected_c;
    logic [WIDTH-1:0] expected_vote;

    logic expected_mismatch;
    logic expected_lane_a;
    logic expected_lane_b;
    logic expected_lane_c;

    // Independent behavioral reference model.
    function automatic [31:0] reference_operation(
        input logic [2:0] op,
        input logic [31:0] a,
        input logic [31:0] b
    );

        logic [4:0] shift_amount;

        begin
            shift_amount = b[4:0];

            case (op)

                3'b000:
                    reference_operation = a + b;

                3'b001:
                    reference_operation = a ^ b;

                3'b010:
                    reference_operation = a & b;

                3'b011:
                    reference_operation = a | b;

                3'b100: begin
                    if (shift_amount == 0)
                        reference_operation = a;
                    else
                        reference_operation =
                            (a << shift_amount) |
                            (a >> (32 - shift_amount));
                end

                3'b101:
                    reference_operation =
                        (a == b) ? 32'd1 : 32'd0;

                3'b110:
                    reference_operation = a;

                3'b111:
                    reference_operation = b;

                default:
                    reference_operation = 32'd0;

            endcase
        end

    endfunction

    // DUT
    astra_tmr_subsystem #(
        .WIDTH(WIDTH)
    ) dut (
        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),

        .fault_mask_a(fault_mask_a),
        .fault_mask_b(fault_mask_b),
        .fault_mask_c(fault_mask_c),

        .replica_a(replica_a),
        .replica_b(replica_b),
        .replica_c(replica_c),

        .voted_output(voted_output),

        .mismatch_detected(mismatch_detected),

        .lane_a_mismatch(lane_a_mismatch),
        .lane_b_mismatch(lane_b_mismatch),
        .lane_c_mismatch(lane_c_mismatch)
    );

    // Independent reference calculations.
    always_comb begin

        reference_result =
            reference_operation(opcode, operand_a, operand_b);

        expected_a = reference_result ^ fault_mask_a;
        expected_b = reference_result ^ fault_mask_b;
        expected_c = reference_result ^ fault_mask_c;

        expected_vote =
            (expected_a & expected_b) |
            (expected_a & expected_c) |
            (expected_b & expected_c);

        expected_mismatch =
            (expected_a != expected_b) ||
            (expected_b != expected_c) ||
            (expected_a != expected_c);

        expected_lane_a = (expected_a != expected_vote);
        expected_lane_b = (expected_b != expected_vote);
        expected_lane_c = (expected_c != expected_vote);

    end

    // Formal properties.
    always_comb begin

        // P1-P3: Individual replica correctness.
        assert(replica_a == expected_a);
        assert(replica_b == expected_b);
        assert(replica_c == expected_c);

        // P4: Majority voter correctness.
        assert(voted_output == expected_vote);

        // P5: Global mismatch detection.
        assert(mismatch_detected == expected_mismatch);

        // P6-P8: Individual lane mismatch indicators.
        assert(lane_a_mismatch == expected_lane_a);
        assert(lane_b_mismatch == expected_lane_b);
        assert(lane_c_mismatch == expected_lane_c);

        // P9: When all fault masks are zero,
        // all three replicas must agree with the reference.
        if ((fault_mask_a == 0) &&
            (fault_mask_b == 0) &&
            (fault_mask_c == 0)) begin

            assert(replica_a == reference_result);
            assert(replica_b == reference_result);
            assert(replica_c == reference_result);

            assert(voted_output == reference_result);
            assert(mismatch_detected == 0);

        end

        // P10: When all replicas receive the same mask,
        // their outputs agree, even if the common result is corrupted.
        if ((fault_mask_a == fault_mask_b) &&
            (fault_mask_b == fault_mask_c)) begin

            assert(replica_a == replica_b);
            assert(replica_b == replica_c);
            assert(mismatch_detected == 0);

        end

    end

endmodule

