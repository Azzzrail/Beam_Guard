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
signal shift_SCA                                   :  integer :=1;
signal out_pulse_width                             :  std_logic_vector(2 downto 0) := (others=>'0');
signal counter1_flag, counter2_flag                :  STD_LOGIC := '0';
signal second_counter_allowed, Dout                      :  std_logic_vector (1 downto 0) := "01";
signal out_flag,PLL_CLK_t                          :  STD_LOGIC := '0';
signal clkin                                       :  STD_LOGIC;
signal i_beam_input_reg                            :  STD_LOGIC;
signal Out3,Out2                                   :  STD_LOGIC;


type state_values1 is (count1, reset_counter1, waiter, run_count2);
signal pres_state1, next_state1 : state_values1;
type state_values2 is (wait_in_allowed, count2, out_allowed, reset_counter2);
signal pres_state2, next_state2 : state_values2;

--Clock IPCore
component clk_wiz
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;


--  attribute DONT_TOUCH : string;
--  attribute DONT_TOUCH of pres_state1, next_state1, pres_state2, next_state2,
--                          second_counter_allowed: signal is "TRUE";

begin
output1_gnd <= '0';
output3_gnd <= '0';
output3 <= Out3;
Out3 <= second_counter_allowed(1);
clkin <= clk;
output2<= Out2;
Out2 <= second_counter_allowed(0);
output1 <= out_flag;

IP_clock : clk_wiz
  port map (
 -- Clock out ports
  clk_out1 => PLL_CLK_t,
  -- Clock in ports
  clk_in1 =>  clkin
);

-- Count1_fsm: process (pres_state1, next_state1, Beam_input, PLL_CLK_t, out_flag, second_counter_allowed)
--   begin
--
--
--   end process;
--Synchronization process for input signal
SYNC_PROC: process (PLL_CLK_t)
   begin
      if (rising_edge(PLL_CLK_t)) then
          i_beam_input_reg <= Beam_input;

         -- assign other outputs to internal signals

      end if;
   end process;
   --
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
   --
--FSM, определяющая, есть ли достаточно пустого времени без импульсов "перед" возможным кандидатом
--на "чистое событие"
-- FSM, which determines whether there is enough empty time without impulses "before" a possible
--candidate for a "clean event"
     Count1_fsm: process (pres_state1, next_state1, i_beam_input_reg, PLL_CLK_t, out_flag, second_counter_allowed)
      begin
--Переключение состояний FSM по синхроимпульсам из IPCore
--Switching FSM states by sync pulses from IPCore
        if (rising_edge(PLL_CLK_t)) then
              pres_state1 <= next_state1;
        end if;
         case (pres_state1) is
--Проверка условий и работа счётчика времени "до" кандидата в "чистое событие"
--Checking the conditions and the work of time counter "before"  for candidate to a "clean event"
            when count1 =>
            if   rising_edge(PLL_CLK_t)   then
--Переход в состояние ожидания входного импульса, если счётчик "пустого" времени больше предела
--Transition to the state of waiting input pulse, if "empty" time counter is greater than the limit
             if counter1 >= clear_time_limit_pre then
                next_state1 <= waiter;
--Переход в состояние сброса счётчика "пустого" времени, если входной импульс пришёл раньше достижения его предела
--Transition to the reset state of the "empty" time counter, if the input pulse has come before reaching its limit
                  elsif ( i_beam_input_reg = '1' ) then
                  next_state1 <= reset_counter1;
--Инкрементация счётчика "пустого" времени, если нет входных импульсов
--An increment of the "empty" time counter, if there are no input pulses
                elsif ( i_beam_input_reg = '0' ) then
                      counter1 <= counter1 +'1';
             end if;
              -- if counter1 >= clear_time_limit_pre and counter1_flag = '0' then
              --    counter1_flag <= '1';
              --    next_state1 <= waiter;
              --      elsif ( counter1_flag = '0' and i_beam_input_reg = '1' ) then
              --      next_state1 <= reset_counter1;
              --       elsif ( counter1_flag = '0' and i_beam_input_reg = '0' ) then
              --          counter1 <= counter1 +'1';
              -- end if;
            end if;
--Состояние ожидания входного импульса, если "чистое" время равно или больше предела
--The state of waiting for an input pulse if the "clean" time is equal to or greater than the limit
            when waiter =>
            if i_beam_input_reg = '1' then
                next_state1 <= run_count2;
              end if;
--Состояние для запуска счетчика для "чистого" времени "после"
--State for starting the counter for "clean" time "after"
            when run_count2 =>
            if  (rising_edge(PLL_CLK_t) ) then
              if (  i_beam_input_reg = '0' and second_counter_allowed = "10"  )  then
                second_counter_allowed <= "01";
                next_state1 <=  reset_counter1;
              else
                  second_counter_allowed <= std_logic_vector(unsigned(Dout) sll 1);
              end if;
            end if;

            -- if ( rising_edge(PLL_CLK_t) and second_counter_allowed = '1') then
            --   second_counter_allowed <= '0';
            --   next_state1 <=  reset_counter1;
            -- end if;

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

   Count2_fsm: process (pres_state2, next_state2, second_counter_allowed, i_beam_input_reg, PLL_CLK_t)
   begin
     if (rising_edge(PLL_CLK_t)) then
       pres_state2 <= next_state2;
     end if;

      case (pres_state2) is

        when wait_in_allowed =>

        if  (rising_edge(PLL_CLK_t)) then
            if second_counter_allowed(0) = '1' then
              next_state2 <= count2;
          end if;
              end if;

         when count2 =>
         if  rising_edge(PLL_CLK_t) then
           if counter2 >= clear_time_limit_post then
             counter2_flag <= '1';
             next_state2 <= out_allowed;
            elsif  counter2_flag = '0' and i_beam_input_reg = '1' then
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
