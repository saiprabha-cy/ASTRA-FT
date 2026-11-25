`timescale 1ns/1ps

module tb_watchdog_recovery_fsm;

    localparam integer HB_TIMEOUT = 8;
    localparam integer REC_TIMEOUT = 5;
    localparam integer MAX_RETRIES = 2;

    logic clk = 0;
    logic reset = 1;
    logic heartbeat = 0;

    wire recovery_request;
    wire safe_mode;
    wire system_reset_request;
    wire [1:0] recovery_state;
    wire [31:0] timeout_count;
    wire [31:0] recovery_attempt_count;

    integer tests = 0;
    integer passed = 0;
    integer failed = 0;

    watchdog_recovery_fsm #(
        .HEARTBEAT_TIMEOUT(HB_TIMEOUT),
        .RECOVERY_TIMEOUT(REC_TIMEOUT),
        .MAX_RETRIES(MAX_RETRIES)
    ) dut (
        .clk(clk),
        .reset(reset),
        .heartbeat(heartbeat),
        .recovery_request(recovery_request),
        .safe_mode(safe_mode),
        .system_reset_request(system_reset_request),
        .recovery_state(recovery_state),
        .timeout_count(timeout_count),
        .recovery_attempt_count(recovery_attempt_count)
    );

    always #5 clk = ~clk;

    task automatic check(input logic condition, input string description);
        begin
            tests = tests + 1;
            if (condition) begin
                passed = passed + 1;
                $display("PASS | %s", description);
            end else begin
                failed = failed + 1;
                $display("FAIL | %s", description);
            end
        end
    endtask

    task automatic pulse_heartbeat;
        begin
            @(negedge clk);
            heartbeat = 1;
            @(negedge clk);
            heartbeat = 0;
        end
    endtask

    task automatic wait_cycles(input integer count);
        begin
            repeat(count) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("sim/waveforms/watchdog_recovery_fsm.vcd");
        $dumpvars(0, tb_watchdog_recovery_fsm);

        repeat(3) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Test 1: Startup enters monitoring
        wait_cycles(2);
        check(recovery_state == 2'd1,
              "FSM enters MONITOR after reset");

        // Test 2: Periodic heartbeat prevents timeout
        pulse_heartbeat();
        wait_cycles(3);
        pulse_heartbeat();
        wait_cycles(3);
        check(timeout_count == 0,
              "Heartbeat prevents watchdog timeout");

        // Test 3: Stop heartbeat and wait for timeout
        wait_cycles(HB_TIMEOUT + 2);
        check(timeout_count >= 1,
              "Missing heartbeat causes timeout");
        check(recovery_attempt_count >= 1,
              "Timeout causes recovery attempt");

        // Test 4: Heartbeat restored during recovery window
        pulse_heartbeat();
        wait_cycles(2);
        check(recovery_state == 2'd1,
              "Restored heartbeat returns FSM to MONITOR");

        // Test 5: Trigger another failure
        wait_cycles(HB_TIMEOUT + 3);
        check(recovery_attempt_count >= 2,
              "Second timeout triggers another recovery attempt");

        // Test 6: Repeated failure eventually reaches safe mode
        wait_cycles((REC_TIMEOUT + HB_TIMEOUT + 3) * 4);
        check(safe_mode,
              "Repeated failures eventually trigger SAFE MODE");

        // Test 7: Recovery reset request is associated with recovery state
        check(!system_reset_request || recovery_request,
              "Reset request is asserted only during recovery");

        $display("\n======================================");
        $display(" DAY 7 WATCHDOG SUMMARY");
        $display("======================================");
        $display("Tests  : %0d", tests);
        $display("Passed : %0d", passed);
        $display("Failed : %0d", failed);
        if (failed == 0)
            $display("WATCHDOG STATUS: PASS");
        else
            $display("WATCHDOG STATUS: FAIL");
        $display("======================================");

        $finish;
    end

endmodule
