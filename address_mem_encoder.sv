//
//  Author : Martin Donies
//
//
//                    GNU GENERAL PUBLIC LICENSE
//                       Version 2, June 1991
//
// Copyright (C) 1989, 1991 Free Software Foundation, Inc., <http://fsf.org/>
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
// Everyone is permitted to copy and distribute verbatim copies
// of this license document, but changing it is not allowed.  

    // ## PARAMETERS ##
    //
    // input_width      : the size of the global address
    // output_width     : the size of the local address and obiously 2^output_width = length of the associative array
    //
    // ## INPUT/OUTPUT ##
    //
    // we               : write enable to add the addr_in on the associative array and get an associated local address
    // clear            : remove the given addr_out from the associative array.
    // addr_in          : global address given to get the local address or the encoded address
    // addr_out         : the local or the encoded address. valid only if ~not_selected & ~address_conflict == 1; 
    // not_selected     : signal to know if addr_in is not found
    // address_conflict : signal to know if addr_in is found more than once 
    // free_space       : signal to know if it's possible to store a new address on the associative array
    //

module address_mem_encoder  #(  
        parameter int unsigned output_width = 3,
        parameter int unsigned input_width  = 16
    )(   
        input   logic                       clock, reset, we, clear,
        input   logic [input_width-1:0]     addr_in,
        output  logic [output_width-1:0]    addr_out,
        output  logic                       not_selected, address_conflict, free_space
    );

    // ## Combinational search ##
    //
    // sel              : indicate if the address is stored on position i 
    // sel_vector       : propagate sel from 0 to output_width
    // conflict_vector  : detect if more than one sel (if |conflict_vector == 1) -> there is a conflict
    // used_vector      : determine used registers to know if we have to compare addr_in with the stored address
    // addr_out_comb    : propagade the founded address from [0] -> [2^output_width]
    // task_lookup_reg  : registers to store all global addresses. 
    //
    // ## Sequencial write ##
    //
    // init             : indicate initialization phase. This phase use 2^output_width cycles.
    // pos_vector       : contain all free register, it's a fifo register
    // pos              : address of the first empty slot
    // start_ptr        : pointer to the first element in the fifo register pos_vector
    // end_ptr          : pointer to the last element +1 in the fifo register pos_vector
    // pos_start_ptr    :
    // pos_end_ptr      : like start_ptr and end_ptr with the overflow bit to keep start_ptr < end_ptr
    // 

    logic                          init, end_init;
    logic [output_width-1:0]       pos, start_ptr, end_ptr;
    logic [output_width-1:0]       pos_vector[2**output_width-1:0];
    logic [output_width:0]         pos_start_ptr, pos_end_ptr;
    wire  [2**output_width-1:0]    sel_vector;
    wire  [2**output_width-2:0]    conflict_vector, sel;
    logic [2**output_width-1:0]    used_vector;

    wire  [2**output_width-1:0]    addr_out_comb[2**output_width-1:0];
    logic [input_width-1:0]        task_lookup_reg[2**output_width-1:0];

    assign start_ptr    = pos_start_ptr[output_width-1:0];
    assign end_ptr      = pos_end_ptr[output_width-1:0];
    assign pos          = pos_vector[start_ptr];
    assign end_init     = &end_ptr;

    // reset overflow bit of pos_start_ptr and pos_end_ptr when start_ptr return to the position 0
    always_ff @(negedge clock)
        if(pos_start_ptr[output_width] & pos_end_ptr[output_width])
            begin
                pos_start_ptr[output_width] <= 1'd0;
                pos_end_ptr[output_width]   <= 1'd0;
            end

    always_ff @(negedge clock) 
        if (reset) begin
            used_vector                 <= 1'd0;
            init                        <= 1'd1;
            pos_start_ptr               <= {output_width{1'd0}};
            pos_end_ptr                 <= {output_width{1'd0}};
        end
        // store a global address to the first free position if free_space and not init
        else if (we & free_space & ~init) begin
            used_vector[pos]            <= 1'd1;
            task_lookup_reg[pos]        <= addr_in;
            pos_start_ptr               <= pos_start_ptr + 1'd1; 
        end
        // clear a global address
        else if (clear & ~init) begin
            used_vector[addr_out]       <= 1'd0;
            task_lookup_reg[addr_out]   <= {input_width{1'd0}};
            pos_vector[end_ptr]         <= addr_out;
            pos_end_ptr                 <= pos_end_ptr + 1'd1;
        end
        // write all local address to the pos_vector
        else if (init) begin
            init                        <= ~end_init;
            pos_vector[end_ptr]         <= pos_end_ptr[output_width-1:0];
            pos_end_ptr                 <= pos_end_ptr + 1'd1;
            task_lookup_reg[end_ptr]    <= {input_width{1'd0}};
        end

    // search the given global address throw the registers
 
            assign sel_vector[0]    = used_vector[0] & (addr_in == task_lookup_reg[0]);
            assign addr_out_comb[0] = {output_width{1'd0}};
            genvar i;
            generate
            for(i=0; i < 2**output_width-1; i=i+1)
                begin
                    assign sel[i]               = used_vector[i+1] && (addr_in == task_lookup_reg[i+1]);
                    assign sel_vector[i+1]      = sel[i] | sel_vector[i];
                    assign addr_out_comb[i+1]   = addr_out_comb[i] | (sel[i] ? i+1 : {output_width{1'd0}});
                    assign conflict_vector[i]   = sel_vector[i] & sel[i];
                end
            endgenerate
    

    assign addr_out             = addr_out_comb[2**output_width-1];
    assign not_selected         = ~|sel_vector;
    assign address_conflict     = |conflict_vector;
    assign free_space           = ~&used_vector;

endmodule 