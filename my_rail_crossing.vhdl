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

entity my_rail_crossing is
    port (
        P_CLK : in std_logic;
        P_CLK_1HZ : in std_logic;
        P_TRACK_OCCUPIED : in std_logic;
        P_TRAFFIC_LIGHT : out std_logic;
        P_GATE : out std_logic
    );
end entity;

--stucture
architecture behavior of my_rail_crossing is
    type state_type is (STANDBY, TRAFFIC_LIGHT_RED, GATE_CLOSED);

    signal S_CURRENT_STATE : state_type := STANDBY;
    signal S_NEXT_STATE : state_type := STANDBY;

    signal S_TIMER_RUN : std_logic := '0';
    signal S_TIMER_INT : integer range 0 to 5 := 0;
    signal S_TIMER_OUT : std_logic := '0';
begin
    -- Timer (5 ticks of P_CLK_1HZ)
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)
    begin
        if S_TIMER_RUN = '0' then
            S_TIMER_INT <= 0;
        elsif rising_edge(P_CLK_1HZ) then
            if S_TIMER_INT < 5 then
                S_TIMER_INT <= S_TIMER_INT + 1;
            end if;
        end if;
    end process;

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';

    -- State register
    state_reg_proc : process (P_CLK)
    begin
        if rising_edge(P_CLK) then
            S_CURRENT_STATE <= S_NEXT_STATE;
        end if;
    end process;

    -- Next-state logic
    next_state_proc : process (S_CURRENT_STATE, P_TRACK_OCCUPIED, S_TIMER_OUT)
    begin
        S_NEXT_STATE <= S_CURRENT_STATE;

        case S_CURRENT_STATE is
            when STANDBY =>
                if P_TRACK_OCCUPIED = '1' then
                    S_NEXT_STATE <= TRAFFIC_LIGHT_RED;
                end if;

            when TRAFFIC_LIGHT_RED =>
                if P_TRACK_OCCUPIED = '0' then
                    S_NEXT_STATE <= STANDBY;
                elsif S_TIMER_OUT = '1' then
                    S_NEXT_STATE <= GATE_CLOSED;
                end if;

            when GATE_CLOSED =>
                if P_TRACK_OCCUPIED = '0' then
                    S_NEXT_STATE <= STANDBY;
                end if;
        end case;
    end process;

    -- Output logic (Moore)
    output_proc : process (S_CURRENT_STATE)
    begin
        P_TRAFFIC_LIGHT <= '0';
        P_GATE <= '0';
        S_TIMER_RUN <= '0';

        case S_CURRENT_STATE is
            when STANDBY =>
                P_TRAFFIC_LIGHT <= '0';
                P_GATE <= '0';
                S_TIMER_RUN <= '0';

            when TRAFFIC_LIGHT_RED =>
                P_TRAFFIC_LIGHT <= '1';
                P_GATE <= '0';
                S_TIMER_RUN <= '1';

            when GATE_CLOSED =>
                P_TRAFFIC_LIGHT <= '1';
                P_GATE <= '1';
                S_TIMER_RUN <= '0';
        end case;
    end process;
end behavior;

architecture dataflow_full of my_rail_crossing is

    -- Zustandscodierung (Tabelle 1):
    -- Standby       = S1S0 = 00
    -- Ampel rot     = S1S0 = 01
    -- Schranke zu   = S1S0 = 10
    -- 11 ist unbenutzt -> wird sicherheitshalber nach 00 gefuehrt.
    --
    -- Vollstaendige Zustandsuebergangs- und Ausgabetabelle (Moore):
    -- S1 S0 Track Timer | S1' S0' | TIMER_RUN TRAFFIC_LIGHT GATE
    -- 0  0   0     0    |  0   0  |    0          0         0
    -- 0  0   0     1    |  0   0  |    0          0         0
    -- 0  0   1     0    |  0   1  |    0          0         0
    -- 0  0   1     1    |  0   1  |    0          0         0
    -- 0  1   0     0    |  0   0  |    1          1         0
    -- 0  1   0     1    |  0   0  |    1          1         0
    -- 0  1   1     0    |  0   1  |    1          1         0
    -- 0  1   1     1    |  1   0  |    1          1         0
    -- 1  0   0     0    |  0   0  |    0          1         1
    -- 1  0   0     1    |  0   0  |    0          1         1
    -- 1  0   1     0    |  1   0  |    0          1         1
    -- 1  0   1     1    |  1   0  |    0          1         1
    -- 1  1   0     0    |  0   0  |    0          0         0
    -- 1  1   0     1    |  0   0  |    0          0         0
    -- 1  1   1     0    |  0   0  |    0          0         0
    -- 1  1   1     1    |  0   0  |    0          0         0

    signal S_S1 : std_logic := '0';
    signal S_S0 : std_logic := '0';
    signal S_D1 : std_logic := '0';
    signal S_D0 : std_logic := '0';

    signal S_TIMER_RUN : std_logic := '0';
    signal S_TIMER_INT : integer range 0 to 5 := 0;
    signal S_TIMER_OUT : std_logic := '0';

    signal S_N_S1 : std_logic;
    signal S_N_S0 : std_logic;
    signal S_N_TRACK : std_logic;
    signal S_N_TIMER : std_logic;

    -- PLA: Minterme (vollstaendig fuer 4 Eingaenge: S1,S0,Track,Timer)
    signal S_MT_0 : std_logic;
    signal S_MT_1 : std_logic;
    signal S_MT_2 : std_logic;
    signal S_MT_3 : std_logic;
    signal S_MT_4 : std_logic;
    signal S_MT_5 : std_logic;
    signal S_MT_6 : std_logic;
    signal S_MT_7 : std_logic;
    signal S_MT_8 : std_logic;
    signal S_MT_9 : std_logic;
    signal S_MT_10 : std_logic;
    signal S_MT_11 : std_logic;
    signal S_MT_12 : std_logic;
    signal S_MT_13 : std_logic;
    signal S_MT_14 : std_logic;
    signal S_MT_15 : std_logic;
begin
    -- Invertierte Signale (PLA-Eingangsspalten)
    S_N_S1 <= not S_S1;
    S_N_S0 <= not S_S0;
    S_N_TRACK <= not P_TRACK_OCCUPIED;
    S_N_TIMER <= not S_TIMER_OUT;

    -- Timer (5 Takte von P_CLK_1HZ), darf ausschliesslich hier P_CLK_1HZ verwenden
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)
    begin
        if S_TIMER_RUN = '0' then
            S_TIMER_INT <= 0;
        elsif rising_edge(P_CLK_1HZ) then
            if S_TIMER_INT < 5 then
                S_TIMER_INT <= S_TIMER_INT + 1;
            end if;
        end if;
    end process;

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';

    -- D-Flipflops (Speicher) fuer den Zustand (S1,S0)
    state_reg_proc : process (P_CLK)
    begin
        if rising_edge(P_CLK) then
            S_S1 <= S_D1;
            S_S0 <= S_D0;
        end if;
    end process;

    -- PLA AND-Ebene (Minterme)
    S_MT_0  <= S_N_S1 and S_N_S0 and S_N_TRACK and S_N_TIMER;  -- 00 0 0
    S_MT_1  <= S_N_S1 and S_N_S0 and S_N_TRACK and S_TIMER_OUT;-- 00 0 1
    S_MT_2  <= S_N_S1 and S_N_S0 and P_TRACK_OCCUPIED and S_N_TIMER; -- 00 1 0
    S_MT_3  <= S_N_S1 and S_N_S0 and P_TRACK_OCCUPIED and S_TIMER_OUT; -- 00 1 1
    S_MT_4  <= S_N_S1 and S_S0  and S_N_TRACK and S_N_TIMER;   -- 01 0 0
    S_MT_5  <= S_N_S1 and S_S0  and S_N_TRACK and S_TIMER_OUT; -- 01 0 1
    S_MT_6  <= S_N_S1 and S_S0  and P_TRACK_OCCUPIED and S_N_TIMER; -- 01 1 0
    S_MT_7  <= S_N_S1 and S_S0  and P_TRACK_OCCUPIED and S_TIMER_OUT; -- 01 1 1
    S_MT_8  <= S_S1  and S_N_S0 and S_N_TRACK and S_N_TIMER;   -- 10 0 0
    S_MT_9  <= S_S1  and S_N_S0 and S_N_TRACK and S_TIMER_OUT; -- 10 0 1
    S_MT_10 <= S_S1  and S_N_S0 and P_TRACK_OCCUPIED and S_N_TIMER; -- 10 1 0
    S_MT_11 <= S_S1  and S_N_S0 and P_TRACK_OCCUPIED and S_TIMER_OUT; -- 10 1 1
    S_MT_12 <= S_S1  and S_S0  and S_N_TRACK and S_N_TIMER;    -- 11 0 0
    S_MT_13 <= S_S1  and S_S0  and S_N_TRACK and S_TIMER_OUT;  -- 11 0 1
    S_MT_14 <= S_S1  and S_S0  and P_TRACK_OCCUPIED and S_N_TIMER; -- 11 1 0
    S_MT_15 <= S_S1  and S_S0  and P_TRACK_OCCUPIED and S_TIMER_OUT; -- 11 1 1

    -- PLA OR-Ebene (Disjunktion der Minterme) fuer Folgezustand und Ausgaenge
    S_D1 <= S_MT_7 or S_MT_10 or S_MT_11;
    S_D0 <= S_MT_2 or S_MT_3 or S_MT_6;

    -- Moore-Ausgaenge (nur abhaengig vom aktuellen Zustand, nicht von Track/Timer).
    -- Wichtig: Dadurch vermeiden wir Glitches (z. B. wenn S_TIMER_OUT umschaltet).
    S_TIMER_RUN <= S_N_S1 and S_S0; -- Zustand 01
    P_TRAFFIC_LIGHT <= (S_N_S1 and S_S0) or (S_S1 and S_N_S0); -- Zustand 01 oder 10
    P_GATE <= S_S1 and S_N_S0; -- Zustand 10
end dataflow_full;

architecture dataflow_min of my_rail_crossing is
-- begin solution:
    -- Minimierte PLA auf 6 Zeilen (Produktterme). Ziel: gleiches Verhalten wie `dataflow_full`,
    -- aber mit geteilten und minimierten AND-Termen.
    --
    -- Zustandscodierung:
    -- 00 Standby, 01 Traffic light red, 10 Gate closed, 11 unused -> 00

    signal S_S1 : std_logic := '0';
    signal S_S0 : std_logic := '0';
    signal S_D1 : std_logic := '0';
    signal S_D0 : std_logic := '0';

    signal S_TIMER_RUN : std_logic := '0';
    signal S_TIMER_INT : integer range 0 to 5 := 0;
    signal S_TIMER_OUT : std_logic := '0';

    -- 6 PLA lines (AND plane)
    signal S_L0_P01 : std_logic; -- ~S1 & S0
    signal S_L1_P10 : std_logic; -- S1 & ~S0
    signal S_L2_P00T : std_logic; -- ~S1 & ~S0 & Track
    signal S_L3_N1TNT : std_logic; -- ~S1 & Track & ~Timer
    signal S_L4_01TT : std_logic; -- (~S1 & S0) & Track & Timer
    signal S_L5_10T : std_logic; -- (S1 & ~S0) & Track
-- end solution!!
begin
-- begin solution:
    -- Timer (5 ticks of P_CLK_1HZ), only place where P_CLK_1HZ is used
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)
    begin
        if S_TIMER_RUN = '0' then
            S_TIMER_INT <= 0;
        elsif rising_edge(P_CLK_1HZ) then
            if S_TIMER_INT < 5 then
                S_TIMER_INT <= S_TIMER_INT + 1;
            end if;
        end if;
    end process;

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';

    -- D-Flipflops (state storage)
    state_reg_proc : process (P_CLK)
    begin
        if rising_edge(P_CLK) then
            S_S1 <= S_D1;
            S_S0 <= S_D0;
        end if;
    end process;

    -- AND plane: 6 product terms
    S_L0_P01 <= (not S_S1) and S_S0;
    S_L1_P10 <= S_S1 and (not S_S0);
    S_L2_P00T <= (not S_S1) and (not S_S0) and P_TRACK_OCCUPIED;
    S_L3_N1TNT <= (not S_S1) and P_TRACK_OCCUPIED and (not S_TIMER_OUT);
    S_L4_01TT <= S_L0_P01 and P_TRACK_OCCUPIED and S_TIMER_OUT;
    S_L5_10T <= S_L1_P10 and P_TRACK_OCCUPIED;

    -- OR plane: next-state bits
    S_D1 <= S_L4_01TT or S_L5_10T;
    S_D0 <= S_L2_P00T or S_L3_N1TNT;

    -- Moore outputs (derived only from state decode terms)
    S_TIMER_RUN <= S_L0_P01;
    P_TRAFFIC_LIGHT <= S_L0_P01 or S_L1_P10;
    P_GATE <= S_L1_P10;
-- end solution!!
end dataflow_min;

architecture dataflow_tff of my_rail_crossing is
    -- begin solution:
    -- end solution!!
begin
end dataflow_tff;
