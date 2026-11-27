`timescale 1ns/1ps

module tb_tmr_fault_campaign;

    // ---------------------------------------------------------
    // DUT inputs
    // ---------------------------------------------------------
    reg  [2:0]  opcode;
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;

    reg  [31:0] fault_mask_a;
    reg  [31:0] fault_mask_b;
    reg  [31:0] fault_mask_c;

    // ---------------------------------------------------------
    // DUT outputs
    // ---------------------------------------------------------
    wire [31:0] replica_a;
    wire [31:0] replica_b;
    wire [31:0] replica_c;

    wire [31:0] voted_output;
    wire        mismatch_detected;

    wire lane_a_mismatch;
    wire lane_b_mismatch;
    wire lane_c_mismatch;

    // ---------------------------------------------------------
    // Test accounting
    // ---------------------------------------------------------
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer exhaustive_tests;
    integer random_single_lane_tests;
    integer double_lane_tests;
    integer common_mode_tests;

    integer double_lane_correct;
    integer double_lane_incorrect;
    integer double_lane_detected;
    integer double_lane_undetected;

    integer opcode_index;
    integer bit_index;
    integer lane_index;
    integer random_index;

    reg [31:0] expected_result;
    reg [31:0] random_mask;

    reg [31:0] saved_mask_a;
    reg [31:0] saved_mask_b;
    reg [31:0] saved_mask_c;

    reg [31:0] random_a;
    reg [31:0] random_b;

    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------
    astra_tmr_subsystem dut (
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

    // ---------------------------------------------------------
    // Golden reference model
    //
    // Independent behavioral reference for the 8 operations.
    // ---------------------------------------------------------
    function automatic [31:0] reference_operation;
        input [2:0]  op;
        input [31:0] a;
        input [31:0] b;

        reg [4:0] shift_amount;

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
                    reference_operation = (a == b) ? 32'd1 : 32'd0;

                3'b110:
                    reference_operation = a;

                3'b111:
                    reference_operation = b;

                default:
                    reference_operation = 32'd0;

            endcase
        end
    endfunction

    // ---------------------------------------------------------
    // Common checking task
    // ---------------------------------------------------------
    task check_recovery;
        input [31:0] expected;
        input [31:0] mask_a;
        input [31:0] mask_b;
        input [31:0] mask_c;

        begin

            fault_mask_a = mask_a;
            fault_mask_b = mask_b;
            fault_mask_c = mask_c;

            #2;

            total_tests = total_tests + 1;

            if ((voted_output === expected) &&
                (mismatch_detected ===
                    ((mask_a != 0) ||
                     (mask_b != 0) ||
                     (mask_c != 0)))) begin

                passed_tests = passed_tests + 1;

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL | OP=%b A=%h B=%h | MA=%h MB=%h MC=%h",
                    opcode, operand_a, operand_b,
                    mask_a, mask_b, mask_c
                );

                $display(
                    "EXPECTED=%h ACTUAL=%h MISMATCH=%b",
                    expected, voted_output, mismatch_detected
                );

            end

        end
    endtask

    // ---------------------------------------------------------
    // Initialize
    // ---------------------------------------------------------
    initial begin

        opcode = 0;
        operand_a = 0;
        operand_b = 0;

        fault_mask_a = 0;
        fault_mask_b = 0;
        fault_mask_c = 0;

        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;

        exhaustive_tests = 0;
        random_single_lane_tests = 0;
        double_lane_tests = 0;
        common_mode_tests = 0;

        double_lane_correct = 0;
        double_lane_incorrect = 0;
        double_lane_detected = 0;
        double_lane_undetected = 0;

        random_mask = 0;
        random_a = 0;
        random_b = 0;

        $dumpfile("sim/waveforms/tmr_fault_campaign.vcd");

        $dumpvars(0, tb_tmr_fault_campaign);

        $display("");
        $display("==================================================");
        $display(" ASTRA-FT DAY 3 TMR FAULT INJECTION CAMPAIGN");
        $display("==================================================");
        $display("");

        // -----------------------------------------------------
        // CAMPAIGN 1:
        // Exhaustive single-bit fault injection
        //
        // 8 opcodes x 32 bits x 3 lanes = 768 tests
        // -----------------------------------------------------

        $display("[CAMPAIGN 1] Exhaustive single-bit injection");

        for (opcode_index = 0;
             opcode_index < 8;
             opcode_index = opcode_index + 1) begin

            opcode = opcode_index;

            // New operands for every opcode
            random_a = $urandom;
            random_b = $urandom;

            operand_a = random_a;
            operand_b = random_b;

            expected_result =
                reference_operation(opcode, operand_a, operand_b);

            for (lane_index = 0;
                 lane_index < 3;
                 lane_index = lane_index + 1) begin

                for (bit_index = 0;
                     bit_index < 32;
                     bit_index = bit_index + 1) begin

                    random_mask = 32'h00000001 << bit_index;

                    if (lane_index == 0) begin

                        check_recovery(
                            expected_result,
                            random_mask,
                            32'h00000000,
                            32'h00000000
                        );

                    end
                    else if (lane_index == 1) begin

                        check_recovery(
                            expected_result,
                            32'h00000000,
                            random_mask,
                            32'h00000000
                        );

                    end
                    else begin

                        check_recovery(
                            expected_result,
                            32'h00000000,
                            32'h00000000,
                            random_mask
                        );

                    end

                    exhaustive_tests = exhaustive_tests + 1;

                end

            end

        end

        $display(
            "Exhaustive single-bit tests completed: %0d",
            exhaustive_tests
        );

        // -----------------------------------------------------
        // CAMPAIGN 2:
        // Random multi-bit fault affecting one lane only
        //
        // Any one lane may be arbitrarily corrupted.
        // The two remaining correct lanes must dominate.
        // -----------------------------------------------------

        $display("");
        $display("[CAMPAIGN 2] Random single-lane multi-bit faults");

        for (random_index = 0;
             random_index < 200;
             random_index = random_index + 1) begin

            opcode = $urandom;
            random_a = $urandom;
            random_b = $urandom;

            operand_a = random_a;
            operand_b = random_b;

            expected_result =
                reference_operation(opcode, operand_a, operand_b);

            random_mask = $urandom;

            // Ensure the injected fault is nonzero.
            if (random_mask == 0)
                random_mask = 32'h00000001;

            lane_index = random_index % 3;

            if (lane_index == 0) begin

                check_recovery(
                    expected_result,
                    random_mask,
                    32'h00000000,
                    32'h00000000
                );

            end
            else if (lane_index == 1) begin

                check_recovery(
                    expected_result,
                    32'h00000000,
                    random_mask,
                    32'h00000000
                );

            end
            else begin

                check_recovery(
                    expected_result,
                    32'h00000000,
                    32'h00000000,
                    random_mask
                );

            end

            random_single_lane_tests =
                random_single_lane_tests + 1;

        end

        // -----------------------------------------------------
        // CAMPAIGN 3:
        // Two lanes faulty simultaneously
        //
        // TMR is not guaranteed to recover.
        // We record the result instead of assuming success.
        // -----------------------------------------------------

        $display("");
        $display("[CAMPAIGN 3] Simultaneous two-lane faults");

        for (random_index = 0;
             random_index < 100;
             random_index = random_index + 1) begin

            opcode = $urandom;
            random_a = $urandom;
            random_b = $urandom;

            operand_a = random_a;
            operand_b = random_b;

            expected_result =
                reference_operation(opcode, operand_a, operand_b);

            random_mask = $urandom;

            if (random_mask == 0)
                random_mask = 32'h00000001;

            saved_mask_a = $urandom;
            saved_mask_b = $urandom;
            saved_mask_c = $urandom;

            // Force two faulty replicas.
            // Third replica remains fault-free.
            case (random_index % 3)

                0: begin
                    fault_mask_a = random_mask;
                    fault_mask_b = saved_mask_b | 1;
                    fault_mask_c = 0;
                end

                1: begin
                    fault_mask_a = 0;
                    fault_mask_b = random_mask;
                    fault_mask_c = saved_mask_c | 1;
                end

                2: begin
                    fault_mask_a = saved_mask_a | 1;
                    fault_mask_b = 0;
                    fault_mask_c = random_mask;
                end

            endcase

            #2;

            total_tests = total_tests + 1;
            double_lane_tests = double_lane_tests + 1;

            if (voted_output == expected_result)
                double_lane_correct = double_lane_correct + 1;
            else
                double_lane_incorrect = double_lane_incorrect + 1;

            if (mismatch_detected)
                double_lane_detected = double_lane_detected + 1;
            else
                double_lane_undetected = double_lane_undetected + 1;

            // These are characterization tests.
            // Two-fault recovery is not a requirement.
            // We still ensure the subsystem's outputs are not X/Z.
            if ((^voted_output === 1'bx) ||
                (mismatch_detected === 1'bx)) begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL | Two-lane fault produced unknown output"
                );

            end
            else begin

                passed_tests = passed_tests + 1;

            end

        end

        // -----------------------------------------------------
        // CAMPAIGN 4:
        // Common-mode identical faults
        //
        // Same mask applied to all replicas.
        // The voter may produce the wrong result while the
        // mismatch detector reports no disagreement.
        // -----------------------------------------------------

        $display("");
        $display("[CAMPAIGN 4] Common-mode identical faults");

        for (opcode_index = 0;
             opcode_index < 8;
             opcode_index = opcode_index + 1) begin

            opcode = opcode_index;

            random_a = $urandom;
            random_b = $urandom;

            operand_a = random_a;
            operand_b = random_b;

            expected_result =
                reference_operation(opcode, operand_a, operand_b);

            // Deliberately apply identical nonzero masks.
            random_mask = 32'h00000001;

            fault_mask_a = random_mask;
            fault_mask_b = random_mask;
            fault_mask_c = random_mask;

            #2;

            total_tests = total_tests + 1;
            common_mode_tests = common_mode_tests + 1;

            // All three replicas are corrupted identically.
            // The voter cannot distinguish this from correct data.
            if ((replica_a == replica_b) &&
                (replica_b == replica_c) &&
                (mismatch_detected == 0) &&
                (voted_output != expected_result)) begin

                passed_tests = passed_tests + 1;

                $display(
                    "EXPECTED LIMITATION | OP=%b | COMMON OUTPUT=%h | ERROR NOT DETECTED",
                    opcode, voted_output
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL | Common-mode behavior unexpected"
                );

            end

        end

        // -----------------------------------------------------
        // Final report
        // -----------------------------------------------------

        $display("");
        $display("==================================================");
        $display(" ASTRA-FT FAULT CAMPAIGN SUMMARY");
        $display("==================================================");

        $display("Total campaign tests       : %0d", total_tests);
        $display("Tests passed               : %0d", passed_tests);
        $display("Tests failed               : %0d", failed_tests);

        $display("");
        $display("Exhaustive single-bit      : %0d", exhaustive_tests);
        $display("Random single-lane         : %0d", random_single_lane_tests);
        $display("Double-lane tests          : %0d", double_lane_tests);
        $display("Common-mode tests          : %0d", common_mode_tests);

        $display("");
        $display("Double fault correct       : %0d", double_lane_correct);
        $display("Double fault incorrect     : %0d", double_lane_incorrect);

        $display("Double fault detected     : %0d", double_lane_detected);
        $display("Double fault undetected   : %0d", double_lane_undetected);

        $display("");
        $display("==================================================");

        if (failed_tests == 0) begin
            $display("CAMPAIGN STATUS: PASS");
        end
        else begin
            $display("CAMPAIGN STATUS: FAIL");
        end

        $display("==================================================");

        $finish;

    end

endmodule
