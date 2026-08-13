module alu_4_bit (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [2:0] op,      // operation select
    output logic [3:0] result,
    output logic       zero,    // result == 0
    output logic       carry,   // carry/borrow out
    output logic       overflow // signed overflow (add/sub only)
);

    // Operation encoding
    localparam logic [2:0] OP_ADD  = 3'b000;
    localparam logic [2:0] OP_SUB  = 3'b001;
    localparam logic [2:0] OP_AND  = 3'b010;
    localparam logic [2:0] OP_OR   = 3'b011;
    localparam logic [2:0] OP_XOR  = 3'b100;
    localparam logic [2:0] OP_NOT  = 3'b101; // ~a
    localparam logic [2:0] OP_SHL  = 3'b110; // a << 1
    localparam logic [2:0] OP_SHR  = 3'b111; // a >> 1 (logical)

    logic [4:0] add_ext, sub_ext; // extra bit captures carry/borrow

    always_comb begin
        add_ext = {1'b0, a} + {1'b0, b};
        sub_ext = {1'b0, a} - {1'b0, b};

        // Defaults
        result   = 4'b0000;
        carry    = 1'b0;
        overflow = 1'b0;

        case (op)
            OP_ADD: begin
                result = add_ext[3:0];
                carry  = add_ext[4];
                // signed overflow: operands same sign, result differs
                overflow = (a[3] == b[3]) && (result[3] != a[3]);
            end

            OP_SUB: begin
                result = sub_ext[3:0];
                carry  = sub_ext[4]; // acts as borrow flag here
                overflow = (a[3] != b[3]) && (result[3] != a[3]);
            end

            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_XOR:  result = a ^ b;
            OP_NOT:  result = ~a;

            OP_SHL: begin
                result = a << 1;
                carry  = a[3]; // bit shifted out
            end

            OP_SHR: begin
                result = a >> 1;
                carry  = a[0]; // bit shifted out
            end

            default: result = 4'b0000;
        endcase
    end

    assign zero = (result == 4'b0000);

endmodule


// Registered wrapper for the ALU which pipes I/O through flip flops
// Adds a sequential module that we can work with as opposed to just
// a purely combinational one
module alu_4_bit_reg (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [2:0] op,
    output logic [3:0] result,
    output logic       zero,
    output logic       carry,
    output logic       overflow
);

    logic [3:0] a_q, b_q;
    logic [2:0] op_q;
    logic [3:0] result_c;
    logic       zero_c, carry_c, overflow_c;

    // Input register stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q  <= 4'b0;
            b_q  <= 4'b0;
            op_q <= 3'b0;
        end else begin
            a_q  <= a;
            b_q  <= b;
            op_q <= op;
        end
    end

    alu_4_bit u_alu (
        .a        (a_q),
        .b        (b_q),
        .op       (op_q),
        .result   (result_c),
        .zero     (zero_c),
        .carry    (carry_c),
        .overflow (overflow_c)
    );

    // Output register stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result   <= 4'b0;
            zero     <= 1'b0;
            carry    <= 1'b0;
            overflow <= 1'b0;
        end else begin
            result   <= result_c;
            zero     <= zero_c;
            carry    <= carry_c;
            overflow <= overflow_c;
        end
    end

endmodule
