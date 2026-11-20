`timescale 1ns/1ps

module tb_majority_voter;

    localparam WIDTH = 32;

    logic [WIDTH-1:0] replica_a;
    logic [WIDTH-1:0] replica_b;
    logic [WIDTH-1:0] replica_c;

    logic [WIDTH-1:0] voted_output;
    logic mismatch_detected;

    integer tests_passed;
    integer tests_failed;

    majority_voter #(
        .WIDTH(WIDTH)
    ) dut (
        .replica_a(replica_a),
        .replica_b(replica_b),
        .replica_c(replica_c),
        .voted_output(voted_output),
        .mismatch_detected(mismatch_detected)
    );

    task automatic check_result(
        input logic [WIDTH-1:0] expected_output,
        input logic expected_mismatch
    );
        begin
            #1;

            if (
                voted_output === expected_output &&
                mismatch_detected === expected_mismatch
            ) begin
                tests_passed = tests_passed + 1;

                $display(
                    "PASS | A=%h B=%h C=%h | OUT=%h | MISMATCH=%b",
                    replica_a,
                    replica_b,
                    replica_c,
                    voted_output,
                    mismatch_detected
                );
            end
            else begin
                tests_failed = tests_failed + 1;

                $display(
                    "FAIL | A=%h B=%h C=%h | OUT=%h | EXPECTED=%h",
                    replica_a,
                    replica_b,
                    replica_c,
                    voted_output,
                    expected_output
                );
            end
        end
    endtask

    initial begin
        $dumpfile("sim/waveforms/majority_voter.vcd");
        $dumpvars(0, tb_majority_voter);

        tests_passed = 0;
        tests_failed = 0;

        replica_a = 0;
        replica_b = 0;
        replica_c = 0;

        // Test 1: All replicas agree on zero.
        #5;
        check_result(32'h00000000, 1'b0);

        // Test 2: All replicas agree on one.
        replica_a = 32'hFFFFFFFF;
        replica_b = 32'hFFFFFFFF;
        replica_c = 32'hFFFFFFFF;

        #5;
        check_result(32'hFFFFFFFF, 1'b0);

        // Test 3: Replica C disagrees.
        replica_a = 32'h12345678;
        replica_b = 32'h12345678;
        replica_c = 32'h87654321;

        #5;
        check_result(32'h12345678, 1'b1);

        // Test 4: Replica B disagrees.
        replica_a = 32'hAAAAAAAA;
        replica_b = 32'h55555555;
        replica_c = 32'hAAAAAAAA;

        #5;
        check_result(32'hAAAAAAAA, 1'b1);

        // Test 5: Replica A disagrees.
        replica_a = 32'h00000000;
        replica_b = 32'hFFFFFFFF;
        replica_c = 32'hFFFFFFFF;

        #5;
        check_result(32'hFFFFFFFF, 1'b1);

        // Test 6: Only one bit differs.
        replica_a = 32'h00000001;
        replica_b = 32'h00000001;
        replica_c = 32'h00000000;

        #5;
        check_result(32'h00000001, 1'b1);

        // Test 7: Mixed bit patterns.
        replica_a = 32'hF0F0A5A5;
        replica_b = 32'hF0F0A5A5;
        replica_c = 32'h0F0F5A5A;

        #5;
        check_result(32'hF0F0A5A5, 1'b1);

        // Test 8: Two replicas disagree from each other
        // and there is no majority agreement.
        replica_a = 32'hAAAAAAAA;
        replica_b = 32'h55555555;
        replica_c = 32'h00000000;

        #5;
        check_result(32'h00000000, 1'b1);

        // Test 9: Two replicas agree with mixed pattern.
        replica_a = 32'h13572468;
        replica_b = 32'h13572468;
        replica_c = 32'h24681357;

        #5;
        check_result(32'h13572468, 1'b1);

        // Test 10: A different mixed pattern.
        replica_a = 32'hDEADBEEF;
        replica_b = 32'hDEADBEEF;
        replica_c = 32'hDEADBEEF;

        #5;
        check_result(32'hDEADBEEF, 1'b0);

        $display("-------------------------------------");
        $display("TESTS PASSED: %0d", tests_passed);
        $display("TESTS FAILED: %0d", tests_failed);
        $display("-------------------------------------");

        if (tests_failed == 0) begin
            $display("ALL TESTS PASSED");
        end
        else begin
            $display("TEST FAILURE DETECTED");
        end

        $finish;
    end

endmodule