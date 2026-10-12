// Synchronous FIFO, 16 x 8, spec v1.1
module fifo (
    input            clk,
    input            rst_n,
    input            wr_en,
    input            rd_en,
    input      [7:0] wr_data,
    output reg [7:0] rd_data,
    output reg       rd_valid,
    output           full,
    output           empty,
    output reg       overflow,
    output reg       underflow
);

    reg [3:0] wptr;
    reg [3:0] rptr;
    reg [4:0] count;
    reg [7:0] mem [0:15];

    wire write_accepted = wr_en && !full;
    wire read_accepted  = rd_en && !empty;

    assign full  = (count == 5'd16);
    assign empty = (count == 5'd0);

    // Memory write (no reset)
    always @(posedge clk) begin
        if (write_accepted) mem[wptr] <= wr_data;
    end

    // Pointers, count, read data and flags
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr      <= 4'd0;
            rptr      <= 4'd0;
            count     <= 5'd0;
            rd_data   <= 8'd0;
            rd_valid  <= 1'b0;
        end else begin
            rd_valid  <= read_accepted;
            overflow  <= wr_en && full && !rd_en;
            underflow <= rd_en && empty && !wr_en;

            if (rd_en) rd_data <= mem[rptr];
            if (read_accepted) begin
                rptr    <= rptr + 4'd1;
            end
            if (write_accepted) begin
                wptr <= wptr + 4'd1;
            end

            case ({write_accepted, read_accepted})
                2'b10:   count <= count + 5'd1;
                2'b01:   count <= count - 5'd1;
                default: count <= count;
            endcase
        end
    end

endmodule
