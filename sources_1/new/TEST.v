`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.10.2018 15:09:11
// Design Name: 
// Module Name: TEST
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TEST(
//TrigIn,reset, TrigOut clk, pll_clk

  input i_beam_input_reg,
  input clk,
  input reset,
output TrigOut 
    


  );
      
wire clkin, pll_clk;


   clk_wiz_0 CLK_500MHz
   (
    // Clock out ports
    .clk_out1(pll_clk),     // output clk_out1
   // Clock in ports
    .clk_in1(clkin));      // input clk_in1
 //-------------Internal Constants--------------------------
  //Counter1 parameters      
          parameter reset_counter1       = 2'b00;
          parameter count1               = 2'b01;
          parameter waiter               = 2'b10;
          parameter run_count2           = 2'b11;
          parameter clear_time_limit_pre = 10;
  // Counter1 reg
 reg [1:0] Counter1_state = reset_counter1; //инициализация переменной состояний FSM
 reg [7:0] counter1;
 reg [1:0] counter1_flag;  
 reg [1:0] second_counter_allowed ;
 initial  second_counter_allowed = 1'b0;  
 wire second_counter_start;
 assign clkin = clk;
 assign second_counter_start = second_counter_allowed;
 
 //Counter2 parameters
            parameter reset_counter2        = 2'b00;
            parameter wait_in_allowed       = 2'b01;
            parameter count2                = 2'b10;
            parameter out_allowed           = 2'b11;
            parameter clear_time_limit_post = 10;
            parameter out_pulse_width_limit = 5 ;
 // Counter2 reg
 reg [1:0] Counter2_state = reset_counter2; //инициализация переменной состояний FSM
 reg [1:0] out_flag = 1'b0;
 reg [1:0] second_counter_work_flag = 1'b0;
 reg [7:0] counter2;
 wire counter2_work;
 reg [3:0] out_pulse_width;
 initial out_pulse_width = 4'b0000; 
 //assign reset = zero ; 
 assign TrigOut = out_flag;             
 assign counter2_work = second_counter_work_flag;               
//--------------Counter pre trigger time-----------
          always @(posedge pll_clk)
             if (reset) begin
                Counter1_state <= reset_counter1;
             end
             else
                case (Counter1_state)
reset_counter1 : begin
                        second_counter_allowed = 1'b0;  
                        counter1 = 0;
                        counter1_flag = 0;
                        Counter1_state <= count1;
                 end
        count1 : begin
                   if ( counter2_work == 1)
                      Counter1_state <= reset_counter1;
                   else if (counter1 > clear_time_limit_pre )   
                      Counter1_state <= waiter;
                   else if (i_beam_input_reg == 1 )
                      Counter1_state <= reset_counter1;
                   else
                      counter1 <= counter1 + 1;
                      
                 end
        waiter : begin
                   if (i_beam_input_reg == 1 ) begin
                   Counter1_state <= run_count2;
                   end
                 end
    run_count2 : begin
                   if  (i_beam_input_reg == 0)  begin  
                       second_counter_allowed <= 1'b1;
                       Counter1_state <= reset_counter1;  
                   end
                 end 
                endcase
//---------------Counter post trigger time ------------------
          always @(posedge pll_clk)
   if (reset) begin
      Counter2_state <= reset_counter2;
   end
   else
      case (Counter2_state)
wait_in_allowed : begin
                      if (second_counter_start == 1) begin
                      Counter2_state <= count2;
                      end   
                  end
         count2 : begin
                      if (counter2 > clear_time_limit_post)   
                         Counter2_state <= out_allowed;
                      else if (i_beam_input_reg == 1)
                         Counter2_state <= reset_counter2;
                      else
                         second_counter_work_flag <= 1;   
                         counter2 <= counter2 + 1;
                  end
         out_allowed : begin
//            while  (out_pulse_width < out_pulse_width_limit) begin
//                out_flag <= 1;
//                second_counter_work_flag <= 0; 
//                out_pulse_width <= out_pulse_width + 1;
//            end
//            out_pulse_width <= 0;
//            Counter2_state <= reset_counter2;
            
            if (out_pulse_width > out_pulse_width_limit ) begin
                Counter2_state <= reset_counter2;
                out_pulse_width <= 0;
                out_flag <= 0;
            end 
            else begin
            
            
                out_pulse_width <= out_pulse_width + 1;
                out_flag <= 1;
                second_counter_work_flag <= 0;
            end 
         end
          reset_counter2 : begin
             if  (i_beam_input_reg == 0)  begin  
                 second_counter_work_flag <= 0;
                 out_flag <= 0;
                 counter2 = 0;
                 Counter2_state <= wait_in_allowed;  
             end
         end 
      endcase
endmodule
