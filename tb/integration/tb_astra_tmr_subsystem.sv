`timescale 1ns/1ps

module tb_astra_tmr_subsystem;

    localparam WIDTH = 32;

    logic [2:0] opcode;
    logic [WIDTH-1:0] operand_a;
    logic [WIDTH-1:0] operand_b;

    logic [WIDTH-1:0] fault_mask_a;
    logic [WIDTH-1:0] fault_mask_b;
    logic [WIDTH-1:0] fault_mask_c;

    logic [WIDTH-1:0] replica_a;
    logic [WIDTH-1:0] replica_b;
    logic [WIDTH-1:0] replica_c;

    logic [WIDTH-1:0] voted_output;

    logic mismatch_detected;
    logic lane_a_mismatch;
    logic lane_b_mismatch;
    logic lane_c_mismatch;

    integer tests_passed;
    integer tests_failed;

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

    task automatic run_case(
        input logic [2:0] op,
        input logic [WIDTH-1:0] a,
        input logic [WIDTH-1:0] b,

        input logic [WIDTH-1:0] mask_a,
        input logic [WIDTH-1:0] mask_b,
        input logic [WIDTH-1:0] mask_c,

        input logic [WIDTH-1:0] expected_output,
        input logic expected_mismatch,

        input logic expected_lane_a,
        input logic expected_lane_b,
        input logic expected_lane_c
    );

        begin

            opcode = op;
            operand_a = a;
            operand_b = b;

            fault_mask_a = mask_a;
            fault_mask_b = mask_b;
            fault_mask_c = mask_c;

            #2;

            if (
                voted_output === expected_output &&
                mismatch_detected === expected_mismatch &&
                lane_a_mismatch === expected_lane_a &&
                lane_b_mismatch === expected_lane_b &&
                lane_c_mismatch === expected_lane_c
            ) begin

                tests_passed = tests_passed + 1;

                $display(
                    {
                        "PASS | OP=%b A=%h B=%h | ",
                        "RA=%h RB=%h RC=%h | OUT=%h | ",
                        "MISMATCH=%b | LANES=%b%b%b"
                    },

                    opcode,
                    operand_a,
                    operand_b,

                    replica_a,
                    replica_b,
                    replica_c,

                    voted_output,
                    mismatch_detected,

                    lane_a_mismatch,
                    lane_b_mismatch,
                    lane_c_mismatch
                );

            end
            else begin

                tests_failed = tests_failed + 1;

                $display("FAIL");

                $display("OPCODE: %b", opcode);

                $display(
                    "Expected output: %h | Actual: %h",
                    expected_output,
                    voted_output
                );

                $display(
                    "Expected mismatch: %b | Actual: %b",
                    expected_mismatch,
                    mismatch_detected
                );

                $display(
                    {
                        "Expected lanes: %b%b%b | ",
                        "Actual: %b%b%b"
                    },
                    expected_lane_a,
                    expected_lane_b,
                    expected_lane_c,

                    lane_a_mismatch,
                    lane_b_mismatch,
                    lane_c_mismatch
                );

            end

        end

    endtask

    initial begin

        tests_passed = 0;
        tests_failed = 0;

        opcode = 0;
        operand_a = 0;
        operand_b = 0;

        fault_mask_a = 0;
        fault_mask_b = 0;
        fault_mask_c = 0;

        $dumpfile("sim/waveforms/astra_tmr_subsystem.vcd");
        $dumpvars(0, tb_astra_tmr_subsystem);

        // --------------------------------------------
        // NORMAL OPERATION
        // --------------------------------------------

        // Test 1: ADD
        run_case(
            3'b000, 32'd5, 32'd3,
            0, 0, 0,
            32'd8, 0,
            0, 0, 0
        );

        // Test 2: ADD overflow / wraparound
        run_case(
            3'b000, 32'hFFFFFFFF, 32'h00000001,
            0, 0, 0,
            32'h00000000, 0,
            0, 0, 0
        );

        // Test 3: XOR
        run_case(
            3'b001, 32'hAAAA5555, 32'hFFFF0000,
            0, 0, 0,
            32'h55555555, 0,
            0, 0, 0
        );

        // Test 4: AND
        run_case(
            3'b010, 32'hF0F0F0F0, 32'h0FF00FF0,
            0, 0, 0,
            32'h00F000F0, 0,
            0, 0, 0
        );

        // Test 5: OR
        run_case(
            3'b011, 32'hF0000000, 32'h0000000F,
            0, 0, 0,
            32'hF000000F, 0,
            0, 0, 0
        );

        // Test 6: Rotate left by one
        run_case(
            3'b100, 32'h80000001, 32'd1,
            0, 0, 0,
            32'h00000003, 0,
            0, 0, 0
        );

        // Test 7: Rotate left by zero
        run_case(
            3'b100, 32'h12345678, 32'd0,
            0, 0, 0,
            32'h12345678, 0,
            0, 0, 0
        );

        // Test 8: Compare equal
        run_case(
            3'b101, 32'h12345678, 32'h12345678,
            0, 0, 0,
            32'h00000001, 0,
            0, 0, 0
        );

        // Test 9: Compare not equal
        run_case(
            3'b101, 32'h12345678, 32'h87654321,
            0, 0, 0,
            32'h00000000, 0,
            0, 0, 0
        );

        // Test 10: Pass A
        run_case(
            3'b110, 32'hDEADBEEF, 32'h00000000,
            0, 0, 0,
            32'hDEADBEEF, 0,
            0, 0, 0
        );

        // Test 11: Pass B
        run_case(
            3'b111, 32'h00000000, 32'hCAFEBABE,
            0, 0, 0,
            32'hCAFEBABE, 0,
            0, 0, 0
        );

        // --------------------------------------------
        // SINGLE-REPLICA FAULT INJECTION
        // --------------------------------------------

        // Test 12: Corrupt replica A.
        run_case(
            3'b000, 32'd10, 32'd5,
            32'h00000001, 0, 0,
            32'd15, 1,
            1, 0, 0
        );

        // Test 13: Corrupt replica B.
        run_case(
            3'b001, 32'hAAAA0000, 32'h55550000,
            0, 32'h00000001, 0,
            32'hFFFF0000, 1,
            0, 1, 0
        );

        // Test 14: Corrupt replica C.
        run_case(
            3'b010, 32'hFFFF00FF, 32'h0F0F0F0F,
            0, 0, 32'h000000FF,
            32'h0F0F000F, 1,
            0, 0, 1
        );

        // --------------------------------------------
        // TWO-REPLICA FAULT LIMITATION
        // --------------------------------------------

        // Test 15: A and B are corrupted identically.
        // Voter selects the corrupted majority.
        run_case(
            3'b000, 32'd10, 32'd5,
            32'h00000001, 32'h00000001, 0,
            32'd14, 1,
            0, 0, 1
        );

        // Test 16: Three different corrupted outputs.
        // No pair agrees on the entire word.
        // Bitwise majority still produces zero here.
        run_case(
            3'b000, 32'd0, 32'd0,
            32'h00000001, 32'h00000002, 32'h00000004,
            32'h00000000, 1,
            1, 1, 1
        );

        // --------------------------------------------
        // SUMMARY
        // --------------------------------------------

        $display("---------------------------------------------");
        $display("ASTRA-FT TMR SUBSYSTEM TEST SUMMARY");
        $display("TESTS PASSED: %0d", tests_passed);
        $display("TESTS FAILED: %0d", tests_failed);
        $display("---------------------------------------------");

        if (tests_failed == 0) begin
            $display("ALL TESTS PASSED");
        end
        else begin
            $display("TEST FAILURE DETECTED");
        end

        $finish;

    end

endmodule