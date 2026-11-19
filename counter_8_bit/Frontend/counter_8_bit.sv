module counter_8_bit (
    input  logic       clk,
    input  logic       rst_n,     // async-safe, sampled synchronously below
    input  logic        en,       // count enable
    input  logic        up_down,  // 1 = count up, 0 = count down
    input  logic        load,     // synchronous parallel load
    input  logic [7:0]  load_val,
    output logic [7:0]  count,
    output logic        tc_max,   // terminal count: count == 8'hFF
    output logic        tc_min    // terminal count: count == 8'h00
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'h00;
        end else if (load) begin
            count <= load_val;
        end else if (en) begin
            if (up_down)
                count <= count + 8'h01;
            else
                count <= count - 8'h01;
        end
        // else: hold current value
    end

    assign tc_max = (count == 8'hFF);
    assign tc_min = (count == 8'h00);

endmodule
