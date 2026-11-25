
`timescale 1ns/1ps

module tb_astra_ft_system;

    localparam integer DEPTH = 16;
    localparam integer ADDR_WIDTH = 4;

    logic clk = 0;
    logic reset = 1;

    logic [2:0] opcode = 0;
    logic [31:0] operand_a = 0;
    logic [31:0] operand_b = 0;

    logic [31:0] fault_mask_a = 0;
    logic [31:0] fault_mask_b = 0;
    logic [31:0] fault_mask_c = 0;

    logic memory_write_enable = 0;
    logic memory_write_from_tmr = 0;
    logic [ADDR_WIDTH-1:0] memory_write_address = 0;
    logic [31:0] memory_write_data = 0;

    logic memory_read_enable = 0;
    logic [ADDR_WIDTH-1:0] memory_read_address = 0;

    wire [31:0] memory_read_data;
    wire memory_read_data_valid;
    wire memory_read_error_detected;
    wire memory_read_error_corrected;
    wire memory_read_uncorrectable_error;

    logic scrub_start = 0;
    wire scrub_busy;
    wire scrub_done;
    wire [ADDR_WIDTH:0] scrub_words_scanned;
    wire [31:0] scrub_corrected_count;
    wire [31:0] scrub_uncorrectable_count;

    logic memory_inject_enable = 0;
    logic [ADDR_WIDTH-1:0] memory_inject_address = 0;
    logic [38:0] memory_inject_mask = 0;

    logic heartbeat = 0;
    wire watchdog_recovery_request;
    wire watchdog_reset_request;
    wire safe_mode;
    wire [1:0] watchdog_state;
    wire [31:0] watchdog_timeout_count;
    wire [31:0] watchdog_recovery_attempt_count;

    wire [31:0] replica_a;
    wire [31:0] replica_b;
    wire [31:0] replica_c;
    wire [31:0] tmr_voted_result;
    wire tmr_mismatch_detected;
    wire lane_a_mismatch;
    wire lane_b_mismatch;
    wire lane_c_mismatch;

    integer tests = 0;
    integer passed = 0;
    integer failed = 0;
    integer init_index;

    astra_ft_system #(
        .MEMORY_DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HEARTBEAT_TIMEOUT(8),
        .RECOVERY_TIMEOUT(5),
        .MAX_RECOVERY_RETRIES(2)
    ) dut (
        .clk(clk),
        .reset(reset),

        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),

        .fault_mask_a(fault_mask_a),
        .fault_mask_b(fault_mask_b),
        .fault_mask_c(fault_mask_c),

        .memory_write_enable(memory_write_enable),
        .memory_write_from_tmr(memory_write_from_tmr),
        .memory_write_address(memory_write_address),
        .memory_write_data(memory_write_data),

        .memory_read_enable(memory_read_enable),
        .memory_read_address(memory_read_address),

        .memory_read_data(memory_read_data),
        .memory_read_data_valid(memory_read_data_valid),
        .memory_read_error_detected(memory_read_error_detected),
        .memory_read_error_corrected(memory_read_error_corrected),
        .memory_read_uncorrectable_error(memory_read_uncorrectable_error),

        .scrub_start(scrub_start),
        .scrub_busy(scrub_busy),
        .scrub_done(scrub_done),
        .scrub_words_scanned(scrub_words_scanned),
        .scrub_corrected_count(scrub_corrected_count),
        .scrub_uncorrectable_count(scrub_uncorrectable_count),

        .memory_inject_enable(memory_inject_enable),
        .memory_inject_address(memory_inject_address),
        .memory_inject_mask(memory_inject_mask),

        .heartbeat(heartbeat),
        .watchdog_recovery_request(watchdog_recovery_request),
        .watchdog_reset_request(watchdog_reset_request),
        .safe_mode(safe_mode),
        .watchdog_state(watchdog_state),
        .watchdog_timeout_count(watchdog_timeout_count),
        .watchdog_recovery_attempt_count(watchdog_recovery_attempt_count),

        .replica_a(replica_a),
        .replica_b(replica_b),
        .replica_c(replica_c),
        .tmr_voted_result(tmr_voted_result),
        .tmr_mismatch_detected(tmr_mismatch_detected),
        .lane_a_mismatch(lane_a_mismatch),
        .lane_b_mismatch(lane_b_mismatch),
        .lane_c_mismatch(lane_c_mismatch)
    );

    always #5 clk = ~clk;

    task automatic check(
        input logic condition,
        input string description
    );
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

    task automatic wait_cycles(input integer count);
        begin
            repeat(count) @(posedge clk);
            #1;
        end
    endtask

    task automatic memory_write(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            memory_write_enable = 1;
            memory_write_from_tmr = 0;
            memory_write_address = address;
            memory_write_data = data;

            @(negedge clk);
            memory_write_enable = 0;
        end
    endtask

    task automatic memory_read(
        input logic [ADDR_WIDTH-1:0] address
    );
        begin
            @(negedge clk);
            memory_read_enable = 1;
            memory_read_address = address;

            @(negedge clk);
            memory_read_enable = 0;
            #1;
        end
    endtask

    task automatic inject_memory_fault(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [38:0] mask
    );
        begin
            @(negedge clk);
            memory_inject_enable = 1;
            memory_inject_address = address;
            memory_inject_mask = mask;

            @(negedge clk);
            memory_inject_enable = 0;
            memory_inject_mask = 0;
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

    task automatic start_scrub;
        begin
            @(negedge clk);
            scrub_start = 1;
            @(negedge clk);
            scrub_start = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/waveforms/astra_ft_integration.vcd");
        $dumpvars(0, tb_astra_ft_system);

        // Reset and initialize
        repeat(3) @(posedge clk);
        @(negedge clk);
        reset = 0;
        wait_cycles(2);
        // Initialize all ECC memory locations to known values.
        for (init_index = 0; init_index < DEPTH; init_index = init_index + 1) begin
            memory_write(init_index[ADDR_WIDTH-1:0], 32'h00000000);
            pulse_heartbeat();
        end

        wait_cycles(1);

        // ------------------------------------------------
        // Test 1: startup/reset state
        // ------------------------------------------------
        check(!safe_mode && !watchdog_recovery_request,
              "Startup state is operational");

        // ------------------------------------------------
        // Test 2: TMR normal operation
        // opcode 000 = addition
        // ------------------------------------------------
        opcode = 3'b000;
        operand_a = 32'd100;
        operand_b = 32'd25;
        fault_mask_a = 0;
        fault_mask_b = 0;
        fault_mask_c = 0;
        #1;

        check(tmr_voted_result == 32'd125,
              "TMR normal arithmetic result");

        // ------------------------------------------------
        // Test 3: Single-replica output corruption
        // ------------------------------------------------
        fault_mask_b = 32'h00000001;
        #1;

        check(tmr_voted_result == 32'd125 &&
              tmr_mismatch_detected,
              "TMR tolerates one replica fault and flags mismatch");

        check(lane_b_mismatch,
              "Faulty TMR lane identified");

        fault_mask_b = 0;
        #1;

        // ------------------------------------------------
        // Test 4: Store TMR result in ECC memory
        // ------------------------------------------------
        @(negedge clk);
        memory_write_enable = 1;
        memory_write_from_tmr = 1;
        memory_write_address = 4'd2;
        memory_write_data = 32'hDEADBEEF;

        @(negedge clk);
        memory_write_enable = 0;
        memory_write_from_tmr = 0;

        memory_read(4'd2);

        check(memory_read_data_valid &&
              memory_read_data == 32'd125,
              "TMR voted result stored and read through ECC memory");

        // ------------------------------------------------
        // Test 5: Correctable ECC error
        // ------------------------------------------------
        inject_memory_fault(4'd2, 39'h000000001);

        memory_read(4'd2);

        check(memory_read_data_valid &&
              memory_read_error_corrected &&
              memory_read_data == 32'd125,
              "ECC read path corrects a single-bit memory error");

        // ------------------------------------------------
        // Test 6: Scrubber corrects injected single-bit error
        // ------------------------------------------------
        start_scrub();

        wait(scrub_done);
        #1;

        check(scrub_words_scanned == DEPTH &&
              scrub_corrected_count == 1 &&
              scrub_uncorrectable_count == 0,
              "Scrubber scanned memory and repaired single-bit fault");

        // Scrubber returns to idle after DONE
        wait_cycles(2);

        memory_read(4'd2);

        check(memory_read_data_valid &&
              !memory_read_error_detected &&
              memory_read_data == 32'd125,
              "Scrubbed memory location is clean");

        // ------------------------------------------------
        // Test 7: Uncorrectable double-bit ECC error
        // ------------------------------------------------
        memory_write(4'd3, 32'hCAFEBABE);

        inject_memory_fault(4'd3, 39'h000000003);

        memory_read(4'd3);

        check(!memory_read_data_valid &&
              memory_read_uncorrectable_error,
              "Double-bit ECC error rejected");

        // ------------------------------------------------
        // Test 8: Scrubber records uncorrectable word
        // ------------------------------------------------
        start_scrub();

        wait(scrub_done);
        #1;

        check(scrub_uncorrectable_count == 1,
              "Scrubber records uncorrectable memory word");

        // ------------------------------------------------
     // Test 9: Watchdog heartbeat
     // ------------------------------------------------
     begin
         integer timeouts_before_test9;
         pulse_heartbeat();
         timeouts_before_test9 = watchdog_timeout_count;
         wait_cycles(2);
         pulse_heartbeat();
         wait_cycles(2);

         check(watchdog_timeout_count == timeouts_before_test9,
               "Heartbeat activity prevents watchdog timeout");
     end

        // ------------------------------------------------
        // Test 10: Missing heartbeat causes recovery
        // ------------------------------------------------
        wait_cycles(10);

        check(watchdog_timeout_count >= 1 &&
              watchdog_recovery_attempt_count >= 1,
              "Heartbeat loss triggers watchdog recovery");

        check(watchdog_reset_request == watchdog_recovery_request,
              "Recovery/reset request outputs agree");

        // ------------------------------------------------
        // Test 11: Recovery succeeds
        // ------------------------------------------------
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        reset = 0;
        wait_cycles(10); // 1 timeout -> RECOVERY -> WAIT_HEARTBEAT (retry_count = 1 < 2)
        pulse_heartbeat();
        wait_cycles(1);

        check(watchdog_state == 2'd1 &&
              !safe_mode,
              "Heartbeat restoration returns watchdog to MONITOR");
        // ------------------------------------------------
        // Test 12: Repeated watchdog failures reach safe mode
        // ------------------------------------------------
        wait_cycles(50);

        check(safe_mode,
              "Repeated heartbeat failures eventually enter safe mode");

        // ------------------------------------------------
        // Summary
        // ------------------------------------------------

        $display("\n==============================================");
        $display(" ASTRA-FT DAY 8 INTEGRATION SUMMARY");
        $display("==============================================");
        $display("Tests  : %0d", tests);
        $display("Passed : %0d", passed);
        $display("Failed : %0d", failed);

        if (failed == 0)
            $display("INTEGRATION STATUS: PASS");
        else
            $display("INTEGRATION STATUS: FAIL");

        $display("==============================================");

        $finish;
    end

    // Safety timeout to catch a stuck testbench.
    initial begin
        #10000;
        $display("FATAL: Integration testbench timeout");
        $finish;
    end

endmodule
