module replica_core #(
    parameter WIDTH = 32
)(
    input  logic [2:0]        opcode,
    input  logic [WIDTH-1:0]  operand_a,
    input  logic [WIDTH-1:0]  operand_b,

    output logic [WIDTH-1:0]  result
);

    always_comb begin

        result = '0;

        case (opcode)

            // 000: Addition
            3'b000:
                result = operand_a + operand_b;

            // 001: XOR
            3'b001:
                result = operand_a ^ operand_b;

            // 010: AND
            3'b010:
                result = operand_a & operand_b;

            // 011: OR
            3'b011:
                result = operand_a | operand_b;

            // 100: Rotate-left
            3'b100:
                result =
                    (operand_a << operand_b[4:0]) |
                    (operand_a >> (WIDTH - operand_b[4:0]));

            // 101: Equality comparison
            3'b101:
                result = (operand_a == operand_b) ?
                         {{(WIDTH-1){1'b0}}, 1'b1} :
                         '0;

            // 110: Pass operand A
            3'b110:
                result = operand_a;

            // 111: Pass operand B
            3'b111:
                result = operand_b;

            default:
                result = '0;

        endcase

    end

endmodule
