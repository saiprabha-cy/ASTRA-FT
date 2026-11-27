`timescale 1ns/1ps

module tb_tmr_fault_campaign;

    localparam integer WIDTH = 32;

    logic [2:0] opcode;
    logic [WIDTH-1:0] operand_a;
    logic [WIDTH-1:0] operand_b;

    logic [WIDTH-1:0] fault_mask_a;
    logic [WIDTH-1:0] fault_mask_b;
    logic [WIDTH-1:0] fault_mask_c;

    wire [WIDTH-1:0] replica_a;
    wire [WIDTH-1:0] replica_b;
    wire [WIDTH-1:0] replica_c;

    wire [WIDTH-1:0] voted_output;

    wire mismatch_detected;
    wire lane_a_mismatch;
    wire lane_b_mismatch;
    wire lane_c_mismatch;

    integer single_bit_tests;
    integer single_bit_passes;

    integer random_tests;
    integer random_passes;

    integer two_lane_tests;
    integer two_lane_passes;

    integer common_mode_tests;
    integer common_mode_passes;

    integer total_tests;
    integer total_passes;
    integer total_failures;

    integer op;
    integer bit_index;
    integer lane;
    integer i;

    reg [31:0] rng_state;
    reg [31:0] random_mask_a;
    reg [31:0] random_mask_b;
    reg [31:0] random_mask_c;
    reg [31:0] expected_result;
    reg [31:0] expected_majority;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Independent golden reference model.
    // Mirrors the specified operations, not the DUT output.
    // ------------------------------------------------------------

    function automatic [31:0] golden_result;
        input [2:0] op_code;
        input [31:0] a;
        input [31:0] b;

        begin
            case (op_code)

                3'b000:
                    golden_result = a + b;

                3'b001:
                    golden_result = a ^ b;

                3'b010:
                    golden_result = a & b;

                3'b011:
                    golden_result = a | b;

                3'b100:
                    golden_result =
                        (a << b[4:0]) |
                        (a >> (32 - b[4:0]));

                3'b101:
                    golden_result = (a == b) ? 32'd1 : 32'd0;

                3'b110:
                    golden_result = a;

                3'b111:
                    golden_result = b;

                default:
                    golden_result = 32'd0;

            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // Deterministic pseudo-random number generator.
    // Linear congruential generator.
    // ------------------------------------------------------------

    task automatic next_random;
        begin
            rng_state =
                (rng_state * 32'd1664525) + 32'd1013904223;
        end
    endtask

    // ------------------------------------------------------------
    // Check majority equation and lane indicators.
    // Used for multi-lane and common-mode characterization.
    // ------------------------------------------------------------

    task automatic check_internal_consistency;
        reg [31:0] majority_reference;
        reg expected_mismatch;
        begin

            majority_reference =
                (replica_a & replica_b) |
                (replica_a & replica_c) |
                (replica_b & replica_c);

            expected_mismatch =
                (replica_a != replica_b) ||
                (replica_b != replica_c) ||
                (replica_a != replica_c);

            if (voted_output !== majority_reference) begin
                $display("FAIL: majority equation mismatch");
                $display("A=%h B=%h C=%h", replica_a,
                         replica_b, replica_c);
                $display("DUT=%h EXPECTED=%h",
                         voted_output, majority_reference);
                total_failures = total_failures + 1;
            end

            if (mismatch_detected !== expected_mismatch) begin
                $display("FAIL: mismatch_detected incorrect");
                total_failures = total_failures + 1;
            end

            if (lane_a_mismatch !== (replica_a != voted_output)) begin
                $display("FAIL: lane A mismatch indicator incorrect");
                total_failures = total_failures + 1;
            end

            if (lane_b_mismatch !== (replica_b != voted_output)) begin
                $display("FAIL: lane B mismatch indicator incorrect");
                total_failures = total_failures + 1;
            end

            if (lane_c_mismatch !== (replica_c != voted_output)) begin
                $display("FAIL: lane C mismatch indicator incorrect");
                total_failures = total_failures + 1;
            end

        end
    endtask

    // ------------------------------------------------------------
    // Single-bit fault campaign.
    // Exactly one replica is corrupted by one bit.
    // The other two replicas must preserve the golden result.
    // ------------------------------------------------------------

    task automatic run_single_bit_test;
        input [2:0] op_code;
        input [31:0] a;
        input [31:0] b;
        input integer selected_lane;
        input integer selected_bit;

        reg [31:0] mask;
        reg [31:0] golden;

        begin

            opcode = op_code;
            operand_a = a;
            operand_b = b;

            fault_mask_a = 32'd0;
            fault_mask_b = 32'd0;
            fault_mask_c = 32'd0;

            mask = 32'd1 << selected_bit;

            case (selected_lane)
                0: fault_mask_a = mask;
                1: fault_mask_b = mask;
                2: fault_mask_c = mask;
            endcase

            golden = golden_result(op_code, a, b);

            #1;

            single_bit_tests = single_bit_tests + 1;
            total_tests = total_tests + 1;

            if (voted_output !== golden) begin
                $display(
                    "FAIL SINGLE BIT: op=%b lane=%0d bit=%0d",
                    op_code, selected_lane, selected_bit
                );
                $display("Golden=%h Voted=%h",
                         golden, voted_output);
                total_failures = total_failures + 1;
            end
            else if (mismatch_detected !== 1'b1) begin
                $display(
                    "FAIL SINGLE BIT: mismatch not detected"
                );
                total_failures = total_failures + 1;
            end
            else if (
                (selected_lane == 0 &&
                 !(lane_a_mismatch && !lane_b_mismatch &&
                   !lane_c_mismatch)) ||

                (selected_lane == 1 &&
                 !(!lane_a_mismatch && lane_b_mismatch &&
                   !lane_c_mismatch)) ||

                (selected_lane == 2 &&
                 !(!lane_a_mismatch && !lane_b_mismatch &&
                   lane_c_mismatch))
            ) begin
                $display(
                    "FAIL SINGLE BIT: incorrect lane identification"
                );
                $display("A=%b B=%b C=%b",
                         lane_a_mismatch,
                         lane_b_mismatch,
                         lane_c_mismatch);
                total_failures = total_failures + 1;
            end
            else begin
                single_bit_passes = single_bit_passes + 1;
                total_passes = total_passes + 1;
            end

        end
    endtask

    // ------------------------------------------------------------
    // Randomized multi-bit fault in exactly one lane.
    // ------------------------------------------------------------

    task automatic run_random_single_lane_test;
        input [2:0] op_code;
        input [31:0] a;
        input [31:0] b;
        input integer selected_lane;
        input [31:0] mask;

        reg [31:0] golden;

        begin

            opcode = op_code;
            operand_a = a;
            operand_b = b;

            fault_mask_a = 32'd0;
            fault_mask_b = 32'd0;
            fault_mask_c = 32'd0;

            case (selected_lane)
                0: fault_mask_a = mask;
                1: fault_mask_b = mask;
                2: fault_mask_c = mask;
            endcase

            golden = golden_result(op_code, a, b);

            #1;

            random_tests = random_tests + 1;
            total_tests = total_tests + 1;

            if ((mask == 0) || (voted_output !== golden) ||
                (mismatch_detected !== 1'b1)) begin

                $display(
                    "FAIL RANDOM SINGLE-LANE: op=%b lane=%0d mask=%h",
                    op_code, selected_lane, mask
                );
                $display("Golden=%h Voted=%h",
                         golden, voted_output);

                total_failures = total_failures + 1;

            end
            else begin

                case (selected_lane)

                    0: begin
                        if (!(lane_a_mismatch &&
                              !lane_b_mismatch &&
                              !lane_c_mismatch)) begin
                            $display("FAIL RANDOM: lane A flags");
                            total_failures = total_failures + 1;
                        end
                        else begin
                            random_passes = random_passes + 1;
                            total_passes = total_passes + 1;
                        end
                    end

                    1: begin
                        if (!(!lane_a_mismatch &&
                              lane_b_mismatch &&
                              !lane_c_mismatch)) begin
                            $display("FAIL RANDOM: lane B flags");
                            total_failures = total_failures + 1;
                        end
                        else begin
                            random_passes = random_passes + 1;
                            total_passes = total_passes + 1;
                        end
                    end

                    2: begin
                        if (!(!lane_a_mismatch &&
                              !lane_b_mismatch &&
                              lane_c_mismatch)) begin
                            $display("FAIL RANDOM: lane C flags");
                            total_failures = total_failures + 1;
                        end
                        else begin
                            random_passes = random_passes + 1;
                            total_passes = total_passes + 1;
                        end
                    end

                endcase

            end

        end
    endtask

    // ------------------------------------------------------------
    // Two-lane fault characterization.
    //
    // No claim is made that the golden result must survive.
    // The test checks the majority equation and detector outputs.
    // ------------------------------------------------------------

    task automatic run_two_lane_test;
        input [2:0] op_code;
        input [31:0] a;
        input [31:0] b;
        input integer pair_select;
        input [31:0] mask_1;
        input [31:0] mask_2;

        begin

            opcode = op_code;
            operand_a = a;
            operand_b = b;

            fault_mask_a = 32'd0;
            fault_mask_b = 32'd0;
            fault_mask_c = 32'd0;

            case (pair_select)
                0: begin
                    fault_mask_a = mask_1;
                    fault_mask_b = mask_2;
                end

                1: begin
                    fault_mask_a = mask_1;
                    fault_mask_c = mask_2;
                end

                2: begin
                    fault_mask_b = mask_1;
                    fault_mask_c = mask_2;
                end
            endcase

            #1;

            two_lane_tests = two_lane_tests + 1;
            total_tests = total_tests + 1;

            expected_majority =
                (replica_a & replica_b) |
                (replica_a & replica_c) |
                (replica_b & replica_c);

            if (mismatch_detected !== 1'b1 ||
                voted_output !== expected_majority) begin

                $display(
                    "FAIL TWO-LANE CHARACTERIZATION: case=%0d",
                    pair_select
                );
                total_failures = total_failures + 1;

            end
            else begin

                two_lane_passes = two_lane_passes + 1;
                total_passes = total_passes + 1;

            end

            check_internal_consistency();

        end
    endtask

    // ------------------------------------------------------------
    // Common-mode fault characterization.
    //
    // Identical masks corrupt all replicas identically.
    // The voter may return a corrupted result while reporting
    // no mismatch. This is an expected limitation of TMR.
    // ------------------------------------------------------------

    task automatic run_common_mode_test;
        input [2:0] op_code;
        input [31:0] a;
        input [31:0] b;
        input [31:0] common_mask;

        reg [31:0] golden;

        begin

            opcode = op_code;
            operand_a = a;
            operand_b = b;

            fault_mask_a = common_mask;
            fault_mask_b = common_mask;
            fault_mask_c = common_mask;

            golden = golden_result(op_code, a, b);

            #1;

            common_mode_tests = common_mode_tests + 1;
            total_tests = total_tests + 1;

            if ((replica_a !== replica_b) ||
                (replica_b !== replica_c) ||
                (voted_output !== (golden ^ common_mask)) ||
                (mismatch_detected !== 1'b0)) begin

                $display(
                    "FAIL COMMON-MODE CHARACTERIZATION: op=%b",
                    op_code
                );
                total_failures = total_failures + 1;

            end
            else begin

                common_mode_passes = common_mode_passes + 1;
                total_passes = total_passes + 1;

                if (common_mask != 0 &&
                    voted_output != golden) begin
                    $display(
                        "EXPECTED LIMITATION: common-mode fault escaped detection, op=%b",
                        op_code
                    );
                end

            end

            check_internal_consistency();

        end
    endtask

    // ------------------------------------------------------------
    // Main campaign
    // ------------------------------------------------------------

    initial begin

        $dumpfile("sim/waveforms/tmr_fault_campaign.vcd");
        $dumpvars(0, tb_tmr_fault_campaign);

        opcode = 0;
        operand_a = 0;
        operand_b = 0;

        fault_mask_a = 0;
        fault_mask_b = 0;
        fault_mask_c = 0;

        single_bit_tests = 0;
        single_bit_passes = 0;

        random_tests = 0;
        random_passes = 0;

        two_lane_tests = 0;
        two_lane_passes = 0;

        common_mode_tests = 0;
        common_mode_passes = 0;

        total_tests = 0;
        total_passes = 0;
        total_failures = 0;

        rng_state = 32'hA57A_F123;

        $display("==============================================");
        $display(" ASTRA-FT DAY 3 TMR FAULT-INJECTION CAMPAIGN");
        $display("==============================================");

        // --------------------------------------------------------
        // CAMPAIGN 1: Exhaustive single-bit fault locations.
        // 8 opcodes x 32 bits x 3 lanes = 768 tests.
        // --------------------------------------------------------

        $display("");
        $display("[1/4] SINGLE-BIT FAULT CAMPAIGN");

        for (op = 0; op < 8; op = op + 1) begin

            for (bit_index = 0;
                 bit_index < WIDTH;
                 bit_index = bit_index + 1) begin

                for (lane = 0; lane < 3; lane = lane + 1) begin

                    next_random();
                    operand_a = rng_state;

                    next_random();
                    operand_b = rng_state;

                    run_single_bit_test(
                        op[2:0],
                        operand_a,
                        operand_b,
                        lane,
                        bit_index
                    );

                end

            end

        end

        $display(
            "Single-bit results: %0d / %0d",
            single_bit_passes,
            single_bit_tests
        );

        // --------------------------------------------------------
        // CAMPAIGN 2: 200 randomized multi-bit single-lane faults.
        // --------------------------------------------------------

        $display("");
        $display("[2/4] RANDOMIZED SINGLE-LANE MULTI-BIT CAMPAIGN");

        for (i = 0; i < 200; i = i + 1) begin

            next_random();
            operand_a = rng_state;

            next_random();
            operand_b = rng_state;

            next_random();
            random_mask_a = rng_state | 32'h00000003;

            next_random();
            random_mask_b = rng_state | 32'h0000000C;

            next_random();
            random_mask_c = rng_state | 32'h00000030;

            case (i % 3)
                0: run_random_single_lane_test(
                       i[2:0], operand_a, operand_b,
                       0, random_mask_a
                   );

                1: run_random_single_lane_test(
                       i[2:0], operand_a, operand_b,
                       1, random_mask_b
                   );

                2: run_random_single_lane_test(
                       i[2:0], operand_a, operand_b,
                       2, random_mask_c
                   );
            endcase

        end

        $display(
            "Random single-lane results: %0d / %0d",
            random_passes,
            random_tests
        );

        // --------------------------------------------------------
        // CAMPAIGN 3: 100 two-lane characterization cases.
        // --------------------------------------------------------

        $display("");
        $display("[3/4] TWO-LANE FAULT CHARACTERIZATION");

        for (i = 0; i < 100; i = i + 1) begin

            next_random();
            operand_a = rng_state;

            next_random();
            operand_b = rng_state;

            next_random();
            random_mask_a = rng_state | 32'h00000001;

            next_random();
            random_mask_b = rng_state | 32'h00000002;

            run_two_lane_test(
                i[2:0],
                operand_a,
                operand_b,
                i % 3,
                random_mask_a,
                random_mask_b
            );

        end

        $display(
            "Two-lane characterization consistency: %0d / %0d",
            two_lane_passes,
            two_lane_tests
        );

        // --------------------------------------------------------
        // CAMPAIGN 4: 8 common-mode cases, one per opcode.
        // --------------------------------------------------------

        $display("");
        $display("[4/4] COMMON-MODE FAULT CHARACTERIZATION");

        for (op = 0; op < 8; op = op + 1) begin

            next_random();
            operand_a = rng_state;

            next_random();
            operand_b = rng_state;

            next_random();
            random_mask_a = rng_state | 32'h00000001;

            run_common_mode_test(
                op[2:0],
                operand_a,
                operand_b,
                random_mask_a
            );

        end

        $display(
            "Common-mode characterization consistency: %0d / %0d",
            common_mode_passes,
            common_mode_tests
        );

        // --------------------------------------------------------
        // FINAL RESULTS
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display(" DAY 3 CAMPAIGN SUMMARY");
        $display("==============================================");

        $display("Single-bit tests       : %0d / %0d",
                 single_bit_passes, single_bit_tests);

        $display("Random single-lane     : %0d / %0d",
                 random_passes, random_tests);

        $display("Two-lane characterization: %0d / %0d",
                 two_lane_passes, two_lane_tests);

        $display("Common-mode characterization: %0d / %0d",
                 common_mode_passes, common_mode_tests);

        $display("----------------------------------------------");
        $display("Total checks executed  : %0d", total_tests);
        $display("Total checks passed    : %0d", total_passes);
        $display("Total failures         : %0d", total_failures);
        $display("----------------------------------------------");

        if (single_bit_passes != 768 ||
            random_passes != 200 ||
            two_lane_passes != 100 ||
            common_mode_passes != 8 ||
            total_tests != 1076 ||
            total_failures != 0) begin

            $display("DAY 3 CAMPAIGN: FAIL");
            $fatal(1, "Fault campaign acceptance criteria failed.");

        end
        else begin

            $display("DAY 3 CAMPAIGN: PASS");
            $display("All campaign checks completed.");
            $display("Single-lane TMR recovery verified under tested masks.");
            $display("Multi-lane and common-mode limitations characterized.");

        end

        $display("==============================================");

        #1;
        $finish;

    end

endmodule
