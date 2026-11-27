`timescale 1ns/1ps

module tb_watchdog_recovery;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset = 1;
    reg heartbeat = 0;

    wire recovery_request;
    wire safe_mode;
    wire system_reset_request;
    wire [1:0] recovery_state;
    wire [31:0] timeout_count;
    wire [31:0] recovery_attempt_count;

    integer cycles;

    localparam IDLE = 2'd0;
    localparam MONITOR = 2'd1;
    localparam RECOVERY = 2'd2;
    localparam WAIT_HEARTBEAT = 2'd3;

    watchdog_recovery_fsm #(
        .HEARTBEAT_TIMEOUT(3),
        .RECOVERY_TIMEOUT(2),
        .MAX_RETRIES(2)
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

    task automatic pulse_heartbeat;
        begin
            @(negedge clk);
            heartbeat = 1;
            @(negedge clk);
            heartbeat = 0;
        end
    endtask

    task automatic wait_for_state(input [1:0] expected_state,
                                  input integer limit);
        begin
            cycles = 0;
            while (recovery_state !== expected_state &&
                   cycles < limit) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            if (recovery_state !== expected_state)
                $fatal(1, "FAIL: state timeout, expected=%0d actual=%0d",
                       expected_state, recovery_state);
        end
    endtask

    initial begin
        $display("======================================");
        $display(" ASTRA-FT WATCHDOG RECOVERY TEST");
        $display("======================================");

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Enter monitoring.
        wait_for_state(MONITOR, 5);
        $display("PASS: watchdog enters MONITOR");

        // Heartbeat edges prevent timeout.
        repeat (2) begin
            pulse_heartbeat();
            repeat (1) @(negedge clk);
        end

        if (recovery_request !== 1'b0)
            $fatal(1, "FAIL: recovery requested despite heartbeat");

        $display("PASS: heartbeat prevents recovery timeout");

        // Stop heartbeats and wait for timeout.
        wait_for_state(RECOVERY, 10);

        if (recovery_request !== 1'b1 ||
            system_reset_request !== 1'b1)
            $fatal(1, "FAIL: recovery/reset request not asserted");

        if (timeout_count !== 32'd1)
            $fatal(1, "FAIL: first timeout counter incorrect");

        $display("PASS: timeout triggers recovery request");

        // Recovery state advances into WAIT_HEARTBEAT.
        wait_for_state(WAIT_HEARTBEAT, 5);

        // A heartbeat edge during the wait restores monitoring.
        pulse_heartbeat();
        wait_for_state(MONITOR, 5);

        if (recovery_attempt_count !== 32'd1)
            $fatal(1, "FAIL: first recovery attempt not counted");

        $display("PASS: heartbeat restores MONITOR after recovery");

        // Now allow two recovery attempts to fail.
        wait_for_state(RECOVERY, 10);
        wait_for_state(WAIT_HEARTBEAT, 5);

        wait_for_state(RECOVERY, 10);
        wait_for_state(WAIT_HEARTBEAT, 5);

        // With retries exhausted, WAIT_HEARTBEAT returns to IDLE.
        wait_for_state(IDLE, 10);

        if (recovery_attempt_count !== 32'd3)
            $fatal(1, "FAIL: expected three total recovery attempts, got %0d",
                   recovery_attempt_count);

        if (safe_mode !== 1'b1)
            $fatal(1, "FAIL: safe mode not asserted after retry exhaustion");

        if (recovery_request !== 1'b0 ||
            system_reset_request !== 1'b0)
            $fatal(1, "FAIL: recovery request should be inactive in safe mode");

        $display("PASS: retry exhaustion enters safe mode");
        $display("PASS: recovery attempt count = %0d",
                 recovery_attempt_count);
        $display("PASS: timeout count = %0d", timeout_count);

        $display("======================================");
        $display(" WATCHDOG RECOVERY TEST: PASS");
        $display("======================================");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL: testbench timeout");
    end

endmodule
