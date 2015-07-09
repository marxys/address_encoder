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

`timescale 1ns/1ps

module testbench();
    
        logic                       clk, reset, we, clear;
        logic [15:0]                addr_in;
        logic [2:0]                 addr_out;
        logic                       not_selected, address_conflict, free_space;
    

address_mem_encoder  #(3,16) task_index (
        .clock(clk),
        .reset(reset),
        .we(we),
        .clear(clear),
        .addr_in(addr_in),
        .addr_out(addr_out),
        .not_selected(not_selected),
        .address_conflict(address_conflict),
        .free_space(free_space)
        );
    
    //Test Clock
    always  #10 clk = ~clk;
    
    initial begin
        reset   = 1'b0;
        we      = 1'b0;
        clear   = 1'b0;
        addr_in = 16'd0;
        clk     = 1'b0; #10;
        reset   = 1'b1; #20;
        reset   = 1'b0; #2000;

        // write address 0;
        we      = 1'b1;
        addr_in = 16'd10; #20;

        // write address 1;
        addr_in = 16'd20; #20;

        // write address 2;
        addr_in = 16'd30; #20;

        // write address 3;
        addr_in = 16'd40; #20;

        // write address 4;
        addr_in = 16'd50; #20;

        // write address 5;
        addr_in = 16'd60; #20;

        // write address 6;
        addr_in = 16'd70; #20;

        // write address 7;
        addr_in = 16'd80; #20;

        // write address 7;
        addr_in = 16'd80; #20;

        we      = 1'b0; #20;

        addr_in = 16'd60;
        clear   = 1'b1;#20;
        clear   = 1'b0;#20;

        // write address 0;
        we      = 1'b1;
        addr_in = 16'd90; #20;
        we      = 1'b0; #20;

        addr_in = 16'd90;  #20;
        addr_in = 16'd80;  #20;
        addr_in = 16'd70;  #20;
        addr_in = 16'd60;  #20;
        addr_in = 16'd50;  #20;
        addr_in = 16'd40;  #20;
        addr_in = 16'd30;  #20;
        addr_in = 16'd20;  #20;
        addr_in = 16'd10;  #20;
    end
        
    // synthesis translate_on
endmodule


