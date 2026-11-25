module watchdog_recovery_fsm #(
    parameter integer HEARTBEAT_TIMEOUT = 20,
    parameter integer RECOVERY_TIMEOUT = 10,
    parameter integer MAX_RETRIES = 3
)(
    input  logic clk,
    input  logic reset,

    input  logic heartbeat,

    output logic recovery_request,
    output logic safe_mode,
    output logic system_reset_request,

    output logic [1:0] recovery_state,
    output logic [31:0] timeout_count,
    output logic [31:0] recovery_attempt_count
);

    localparam logic [1:0] IDLE            = 2'd0;
    localparam logic [1:0] MONITOR         = 2'd1;
    localparam logic [1:0] RECOVERY        = 2'd2;
    localparam logic [1:0] WAIT_HEARTBEAT  = 2'd3;

    localparam integer HB_WIDTH =
        (HEARTBEAT_TIMEOUT < 2) ? 1 : $clog2(HEARTBEAT_TIMEOUT + 1);

    localparam integer REC_WIDTH =
        (RECOVERY_TIMEOUT < 2) ? 1 : $clog2(RECOVERY_TIMEOUT + 1);

    logic [HB_WIDTH-1:0] heartbeat_counter;
    logic [REC_WIDTH-1:0] recovery_counter;

    logic heartbeat_previous;
    logic heartbeat_edge;

    logic [31:0] retry_count;

    assign heartbeat_edge = heartbeat && !heartbeat_previous;

    always_comb begin
        recovery_request = (recovery_state == RECOVERY);
        safe_mode = (recovery_state == IDLE) && (retry_count >= MAX_RETRIES);
        system_reset_request = recovery_request;
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            recovery_state          <= IDLE;
            heartbeat_counter       <= '0;
            recovery_counter        <= '0;
            heartbeat_previous      <= 1'b0;
            timeout_count           <= 32'd0;
            recovery_attempt_count  <= 32'd0;
            retry_count             <= 32'd0;
        end else begin
            heartbeat_previous <= heartbeat;

            case (recovery_state)

                IDLE: begin
                    heartbeat_counter <= '0;
                    recovery_counter  <= '0;

                    if (retry_count < MAX_RETRIES)
                        recovery_state <= MONITOR;
                    else
                        recovery_state <= IDLE;
                end

                MONITOR: begin
                    recovery_counter <= '0;

                    if (heartbeat_edge) begin
                        heartbeat_counter <= '0;
                    end else if (heartbeat_counter >= HEARTBEAT_TIMEOUT - 1) begin
                        heartbeat_counter <= '0;
                        timeout_count <= timeout_count + 1'b1;
                        recovery_state <= RECOVERY;
                    end else begin
                        heartbeat_counter <= heartbeat_counter + 1'b1;
                    end
                end

                RECOVERY: begin
                    recovery_attempt_count <= recovery_attempt_count + 1'b1;
                    retry_count <= retry_count + 1'b1;
                    recovery_counter <= '0;
                    recovery_state <= WAIT_HEARTBEAT;
                end

                WAIT_HEARTBEAT: begin
                    if (heartbeat_edge) begin
                        heartbeat_counter <= '0;
                        recovery_counter <= '0;
                        retry_count <= '0;
                        recovery_state <= MONITOR;
                    end else if (recovery_counter >= RECOVERY_TIMEOUT - 1) begin
                        recovery_counter <= '0;

                        if (retry_count >= MAX_RETRIES)
                            recovery_state <= IDLE;
                        else
                            recovery_state <= RECOVERY;
                    end else begin
                        recovery_counter <= recovery_counter + 1'b1;
                    end
                end

                default: begin
                    recovery_state <= IDLE;
                    heartbeat_counter <= '0;
                    recovery_counter <= '0;
                end

            endcase
        end
    end

endmodule
