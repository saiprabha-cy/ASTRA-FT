module formal_voter;

    (* anyconst *) reg [31:0] a;
    (* anyconst *) reg [31:0] b;
    (* anyconst *) reg [31:0] c;

    wire [31:0] voted_output;
    wire mismatch_detected;

    wire [31:0] reference_majority;

    assign reference_majority =
        (a & b) |
        (a & c) |
        (b & c);

    majority_voter #(
        .WIDTH(32)
    ) dut (
        .replica_a(a),
        .replica_b(b),
        .replica_c(c),
        .voted_output(voted_output),
        .mismatch_detected(mismatch_detected)
    );

    always @* begin

        // Property 1:
        // DUT majority output must equal the independent specification.

        assert(voted_output == reference_majority);

        // Property 2:
        // If all replicas agree, the voter must return that value.

        if ((a == b) && (b == c)) begin
            assert(voted_output == a);
            assert(mismatch_detected == 1'b0);
        end

        // Property 3:
        // Any agreeing pair must determine the majority output.

        if (a == b) begin
            assert(voted_output == a);
        end

        if (a == c) begin
            assert(voted_output == a);
        end

        if (b == c) begin
            assert(voted_output == b);
        end

        // Property 4:
        // Mismatch detection specification.

        assert(
            mismatch_detected ==
            ((a != b) || (b != c) || (a != c))
        );

        // Property 5:
        // If replicas are not all equal, mismatch must be asserted.

        if (!((a == b) && (b == c))) begin
            assert(mismatch_detected == 1'b1);
        end

    end

endmodule
