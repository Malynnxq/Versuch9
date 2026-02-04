-- Laboratory GdTi solutions/versuch9
-- Winter Semester 25/26
-- Group Details
-- Lab Date:
-- 1. Participant First and  Last Name: 
-- 2. Participant First and Last Name:
 
 
-- coding conventions
-- g_<name> Generics
-- p_<name> Ports
-- c_<name> Constants
-- s_<name> Signals
-- v_<name> Variables

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity my_rail_crossing_tb_tff is
end my_rail_crossing_tb_tff;

architecture tb_arch of my_rail_crossing_tb_tff is
    signal S_CLK, S_CLK_1HZ, S_TRACK_OCCUPIED, S_TRAFFIC_LIGHT, S_GATE: std_logic := '0';

    signal S_CLK_COUNTER: integer := 0;

    constant clock_period: time := 10 ns;
    constant clock_period_1hz: time := 1 ms;

begin
    -- Instantiate the behavior of my_rail_crossing
    dut: entity work.my_rail_crossing(dataflow_tff) port map(S_CLK, S_CLK_1HZ, S_TRACK_OCCUPIED, S_TRAFFIC_LIGHT, S_GATE);

    -- Clock process
    clock: process
    begin
        S_CLK <= '0';
        wait for clock_period / 2;
        S_CLK <= '1';
        wait for clock_period / 2;
    end process;

    clock_1hz: process
    begin
        S_CLK_1HZ <= '0';
        wait for clock_period_1hz / 2;
        S_CLK_1HZ <= '1';
        wait for clock_period_1hz / 2;
    end process;

    stimulus_process: process
    begin
        -- no train
        S_TRACK_OCCUPIED <= '0';
        wait for 2 * clock_period;

        -- train coming but signal gone before timer fires
        S_TRACK_OCCUPIED <= '1';
        wait for clock_period_1hz;
        S_TRACK_OCCUPIED <= '0';
        wait for 3 * clock_period_1hz;

        -- train is coming again and comes through
        S_TRACK_OCCUPIED <= '1';
        wait for 30 * clock_period_1hz;
        S_TRACK_OCCUPIED <= '0';

        wait;
    end process;

    monitor_process: process
    begin
        wait for clock_period;
        assert S_TRAFFIC_LIGHT = '0'
            report "Error: No train coming but traffic light on!" severity error;
        assert S_GATE = '0'
            report "Error: No train coming but gate closed!" severity error;

        wait for 3 * clock_period;
        assert S_TRAFFIC_LIGHT = '1'
            report "Error: Train coming but traffic light off!" severity error;
        assert S_GATE = '0'
            report "Error: Train coming, timer shouldn't be finished but gate closed!" severity error;

        wait for 2 * clock_period_1hz;
        assert S_TRAFFIC_LIGHT = '0'
            report "Error: No train coming but traffic light on!" severity error;
        assert S_GATE = '0'
            report "Error: No train coming but gate closed!" severity error;

        wait for 2 * clock_period_1hz;
        assert S_TRAFFIC_LIGHT = '1'
            report "Error: Train coming but traffic light off!" severity error;
        assert S_GATE = '0'
            report "Error: Train coming, timer shouldn't be finished but gate closed!" severity error;

         wait for 5 * clock_period_1hz;
         assert S_TRAFFIC_LIGHT = '1'
             report "Error: Train coming but traffic light off!" severity error;
         assert S_GATE = '1'
             report "Error: Train coming, timer should be finished but gate open!" severity error;

        wait for 30 * clock_period_1hz;
        assert S_TRAFFIC_LIGHT = '0'
            report "Error: No train coming but traffic light on!" severity error;
        assert S_GATE = '0'
            report "Error: No train coming but gate closed!" severity error;

        report "Test done!";
        wait;
    end process;
end tb_arch;
