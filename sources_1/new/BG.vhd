----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 08.02.2016 20:12:11
-- Design Name:
-- Module Name: proj_4 - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity proj_4 is
    Port ( clk       : in STD_LOGIC;
		       enable    : in STD_LOGIC;
		       Beam_input     : in STD_LOGIC;
           output1   : out STD_LOGIC;
           output1_gnd   : out STD_LOGIC;
           output2   : out STD_LOGIC;
           output3   : out STD_LOGIC;
           output3_gnd   : out STD_LOGIC

         );
end proj_4;

architecture Behavioral of proj_4 is
signal counter1, counter2                          :  std_logic_vector(7 downto 0) := (others=>'0');
signal clear_time_limit_pre                        :  integer :=20;
signal clear_time_limit_post                       :  integer :=20;
signal out_pulse_width_limit                       :  integer :=5;
signal out_pulse_width                             :  std_logic_vector(2 downto 0) := (others=>'0');
signal counter1_flag, counter2_flag                :  STD_LOGIC := '0';
signal second_counter_allowed                      :  STD_LOGIC := '0';
signal out_flag,PLL_CLK_t                          :  STD_LOGIC := '0';
signal clkin                                       :  STD_LOGIC;

type state_values1 is (count1, reset_counter1, waiter, run_count2);
signal pres_state1, next_state1 : state_values1;
type state_values2 is (wait_in_allowed, count2, out_allowed, reset_counter2);
signal pres_state2, next_state2 : state_values2;


component clk_wiz
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;
 attribute DONT_TOUCH : string;
 attribute DONT_TOUCH of pres_state1, next_state1, pres_state2, next_state2: signal is "TRUE";

begin
output1_gnd <= '0';
output3_gnd <= '0';
output3 <= second_counter_allowed;
clkin <= clk;
output2 <= out_flag;
output1 <= out_flag;

IP_clock : clk_wiz
  port map (
 -- Clock out ports
  clk_out1 => PLL_CLK_t,
  -- Clock in ports
  clk_in1 =>  clkin
);


--
-- SYNC_PROC: process (PLL_CLK_t, next_state1, next_state2, pres_state1, pres_state2)
--    begin
--       if (rising_edge(PLL_CLK_t)) then
--
--             pres_state1 <= next_state1;
--             pres_state2 <= next_state2;
--          -- assign other outputs to internal signals
--
--       end if;
--    end process;

   -- OUTPUT_DECODE: process (clk, out_flag)
   -- begin
   --    --insert statements to decode internal output signals
   --    --below is simple example
   --    if rising_edge(PLL_CLK_t)  then
   --
   --       output2 <= out_flag;
   --       output1 <= out_flag;
   --
   --    end if;
   -- end process;

      Count1_fsm: process (pres_state1, next_state1, Beam_input, PLL_CLK_t, out_flag)
      begin
        if (rising_edge(PLL_CLK_t)) then
              pres_state1 <= next_state1;
        end if;
         case (pres_state1) is
            when count1 =>

            if   rising_edge(PLL_CLK_t)   then
              if counter1 >= clear_time_limit_pre and counter1_flag = '0' then
                 counter1_flag <= '1';
                 next_state1 <= waiter;
                   elsif ( counter1_flag = '0' and Beam_input = '1' ) then
                   next_state1 <= reset_counter1;
                    elsif ( counter1_flag = '0' and Beam_input = '0' ) then
                       counter1 <= counter1 +'1';
              end if;
            end if;

            when waiter =>
            if Beam_input = '1' then --rising_edge(Beam_input) then  counter1_flag <= '1' and
                next_state1 <= run_count2;
              end if;

            when run_count2 =>

            if  ( Beam_input = '1') then
              second_counter_allowed <= '0';
              elsif ( Beam_input = '0') then
                second_counter_allowed <= '1';
            end if;

            if ( rising_edge(PLL_CLK_t) and second_counter_allowed = '1') then
              next_state1 <=  reset_counter1;
              second_counter_allowed <= '0';
            end if;

            when reset_counter1 =>
                 counter1 <= (others=>'0');
                 counter1_flag <= '0';
                 next_state1 <= count1;
            when others =>
               next_state1 <= reset_counter1;
         end case;
      end process;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

   Count2_fsm: process (pres_state2, next_state2, second_counter_allowed, Beam_input, PLL_CLK_t)
   begin
     if (rising_edge(PLL_CLK_t)) then
       pres_state2 <= next_state2;
     end if;

      case (pres_state2) is

        when wait_in_allowed =>

        if  (rising_edge(PLL_CLK_t)) then
            if second_counter_allowed = '1' then
              next_state2 <= count2;
          end if;
              end if;

         when count2 =>
         if  rising_edge(PLL_CLK_t) then
           if counter2 >= clear_time_limit_post then
             counter2_flag <= '1';
             next_state2 <= out_allowed;
            elsif  counter2_flag = '0' and Beam_input = '1' then
                  next_state2 <= wait_in_allowed;
                else
                    counter2 <= counter2 +'1';
            end if;
         end if;

         when out_allowed =>
          if  rising_edge(PLL_CLK_t) then
            if (out_pulse_width > out_pulse_width_limit) then
              next_state2 <= reset_counter2;
              out_pulse_width <= (others=>'0');
            else
              out_pulse_width <= out_pulse_width + '1';
              counter2 <= (others=>'0');
              out_flag <= '1';
            end if;
          end if;
         when reset_counter2 =>
             counter2_flag <= '0';
             out_flag <= '0';
            next_state2 <= wait_in_allowed;

         when others =>
            next_state2 <= reset_counter2;
      end case;
   end process;

end Behavioral;
