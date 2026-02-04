-- Laboratory GdTi solutions/versuch9                                      -- Kontext: Laborprojekt Versuch 9.
-- (Erklaerversion Aufgabe 3)                                              -- Zweck: Gleicher Code wie `my_rail_crossing.vhdl`, aber zeilenweise erklaert.
-- Hinweis: Diese Datei nicht zusammen mit `my_rail_crossing.vhdl` kompilieren, -- Grund: Doppelte Entity-Definition `my_rail_crossing`.
-- sondern als Lesedokument/Abgabeerklaerung verwenden.                     -- Motivation: Nachvollziehbarkeit der minimierten PLA (6 Zeilen).
-- Winter Semester 25/26                                                   -- Kontext.
-- Group Details                                                           -- Kontext.
-- Lab Date:                                                               -- Kontext.
-- 1. Participant First and  Last Name:                                    -- Kontext.
-- 2. Participant First and Last Name:                                     -- Kontext.

-- coding conventions                                                      -- Stil: Namenskonventionen aus dem Template.
-- g_<name> Generics                                                       -- Stil.
-- p_<name> Ports                                                          -- Stil.
-- c_<name> Constants                                                      -- Stil.
-- s_<name> Signals                                                        -- Stil.
-- v_<name> Variables                                                      -- Stil.

library IEEE;                                                             -- Warum: Standard-IEEE-Library.
use IEEE.STD_LOGIC_1164.ALL;                                              -- Warum: `std_logic`, `rising_edge`, logische Operatoren.

entity my_rail_crossing is                                                -- Was: Schnittstelle des Bahnuebergangs.
    port (                                                                -- Warum: Testbenches binden diese Portreihenfolge an.
        P_CLK : in std_logic;                                             -- Systemtakt fuer Zustandsregister (D-FF).
        P_CLK_1HZ : in std_logic;                                         -- 1Hz-Takt fuer Timer (nur im Timerprozess).
        P_TRACK_OCCUPIED : in std_logic;                                  -- Sensor: 1 wenn Zug im Gefahrenbereich.
        P_TRAFFIC_LIGHT : out std_logic;                                  -- Ampel: 1 = rot.
        P_GATE : out std_logic                                            -- Schranke: 1 = geschlossen.
    );                                                                    -- Ende Portliste.
end entity;                                                               -- Ende Entity.

-- ---------------------------------------------------------------------   -- Trenner.
-- Aufgabe 1 (behavior): Referenz-Moore-Automat (prozessbasiert).           -- Motivation: Aufgabe 3 muss funktional identisch sein.
-- ---------------------------------------------------------------------   -- Trenner.
architecture behavior of my_rail_crossing is                               -- Behavioral-Architektur.
    type state_type is (STANDBY, TRAFFIC_LIGHT_RED, GATE_CLOSED);          -- 3 Zustaende gemaess Aufgabenbeschreibung.

    signal S_CURRENT_STATE : state_type := STANDBY;                       -- Aktueller Zustand (Register).
    signal S_NEXT_STATE : state_type := STANDBY;                          -- Naechster Zustand (kombinatorisch).

    signal S_TIMER_RUN : std_logic := '0';                                -- Timer-Enable (Moore-Ausgang aus Zustand).
    signal S_TIMER_INT : integer range 0 to 5 := 0;                       -- Timer-Zaehler (0..5 Sekunden).
    signal S_TIMER_OUT : std_logic := '0';                                -- Timer-fertig Flag (1 bei 5).
begin                                                                     -- Beginn Architektur.
    -- Timer (5 ticks of P_CLK_1HZ)                                         -- Warum: 5 Sekunden Wartezeit bis Schranke schliesst.
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)                         -- Prozess: 1Hz-Flankenzaehler + asynchroner Reset ueber S_TIMER_RUN.
    begin                                                                 -- Beginn Timerprozess.
        if S_TIMER_RUN = '0' then                                         -- Wenn Timer nicht laufen soll:
            S_TIMER_INT <= 0;                                             -- sofort reset (wichtig fuer "sofort" beim Freigeben).
        elsif rising_edge(P_CLK_1HZ) then                                 -- Wenn Timer laufen soll, pro 1Hz-Positivflanke zaehlen:
            if S_TIMER_INT < 5 then                                       -- Saettigung bei 5 verhindert Ueberlauf.
                S_TIMER_INT <= S_TIMER_INT + 1;                           -- +1 Sekunde.
            end if;                                                       -- Ende Saettigung.
        end if;                                                           -- Ende Reset/Count.
    end process;                                                          -- Ende Timerprozess.

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';                     -- Timer-Out entspricht Tabelle (Timer-Spalte).

    -- State register                                                       -- Warum: synchroner Zustandswechsel, stabiler Moore-Automat.
    state_reg_proc : process (P_CLK)                                      -- Zustandsregisterprozess.
    begin                                                                 -- Beginn Register.
        if rising_edge(P_CLK) then                                        -- Positivflanke: Zustand uebernehmen.
            S_CURRENT_STATE <= S_NEXT_STATE;                               -- Update des Registers.
        end if;                                                           -- Ende Flankenerkennung.
    end process;                                                          -- Ende Registerprozess.

    -- Next-state logic                                                     -- Warum: Abhaengig von (State, Track, Timer) wird Folgezustand berechnet.
    next_state_proc : process (S_CURRENT_STATE, P_TRACK_OCCUPIED, S_TIMER_OUT) -- Kombinatorischer Prozess.
    begin                                                                 -- Beginn Next-State.
        S_NEXT_STATE <= S_CURRENT_STATE;                                   -- Default: Halten (keine Latches).

        case S_CURRENT_STATE is                                           -- Uebergaenge je Zustand:
            when STANDBY =>                                               -- 00: kein Zug.
                if P_TRACK_OCCUPIED = '1' then                            -- Zug kommt:
                    S_NEXT_STATE <= TRAFFIC_LIGHT_RED;                     -- -> 01 (Ampel rot, Timer startet).
                end if;                                                   -- Ende Bedingung.

            when TRAFFIC_LIGHT_RED =>                                     -- 01: Ampel rot, Timer laeuft.
                if P_TRACK_OCCUPIED = '0' then                            -- Zug weg:
                    S_NEXT_STATE <= STANDBY;                               -- -> 00 sofort.
                elsif S_TIMER_OUT = '1' then                              -- Timer fertig:
                    S_NEXT_STATE <= GATE_CLOSED;                           -- -> 10 (Schranke zu).
                end if;                                                   -- Ende Bedingungen.

            when GATE_CLOSED =>                                           -- 10: Schranke zu.
                if P_TRACK_OCCUPIED = '0' then                            -- Zug weg:
                    S_NEXT_STATE <= STANDBY;                               -- -> 00 sofort.
                end if;                                                   -- Ende Bedingung.
        end case;                                                         -- Ende Case.
    end process;                                                          -- Ende Next-State.

    -- Output logic (Moore)                                                 -- Warum: Ausgaenge nur vom aktuellen Zustand.
    output_proc : process (S_CURRENT_STATE)                               -- Kombinatorische Ausgabe.
    begin                                                                 -- Beginn Output.
        P_TRAFFIC_LIGHT <= '0';                                           -- Default: aus.
        P_GATE <= '0';                                                    -- Default: offen.
        S_TIMER_RUN <= '0';                                               -- Default: Timer aus.

        case S_CURRENT_STATE is                                           -- Moore-Ausgaben je Zustand:
            when STANDBY =>                                               -- 00:
                P_TRAFFIC_LIGHT <= '0';                                   -- Ampel aus.
                P_GATE <= '0';                                            -- Schranke offen.
                S_TIMER_RUN <= '0';                                       -- Timer aus.

            when TRAFFIC_LIGHT_RED =>                                     -- 01:
                P_TRAFFIC_LIGHT <= '1';                                   -- Ampel rot an.
                P_GATE <= '0';                                            -- Schranke noch offen.
                S_TIMER_RUN <= '1';                                       -- Timer laeuft.

            when GATE_CLOSED =>                                           -- 10:
                P_TRAFFIC_LIGHT <= '1';                                   -- Ampel bleibt rot.
                P_GATE <= '1';                                            -- Schranke geschlossen.
                S_TIMER_RUN <= '0';                                       -- Timer aus.
        end case;                                                         -- Ende Case.
    end process;                                                          -- Ende Output.
end behavior;                                                             -- Ende behavior.

-- ---------------------------------------------------------------------   -- Trenner.
-- Aufgabe 2 (dataflow_full): Vollstaendige PLA (hier wie im Original).     -- Motivation: Vollstaendige Version bleibt enthalten, Fokus ist aber Aufgabe 3.
-- ---------------------------------------------------------------------   -- Trenner.
architecture dataflow_full of my_rail_crossing is                          -- Dataflow full Architektur.

    -- Zustandscodierung (Tabelle 1):                                       -- Basis fuer Binaercodierung.
    -- Standby       = S1S0 = 00                                            -- Definition.
    -- Ampel rot     = S1S0 = 01                                            -- Definition.
    -- Schranke zu   = S1S0 = 10                                            -- Definition.
    -- 11 ist unbenutzt -> wird sicherheitshalber nach 00 gefuehrt.         -- Sicherheit: unbenutzter Zustand wird abgefangen.
    --                                                                        -- Leerzeile.
    -- Vollstaendige Zustandsuebergangs- und Ausgabetabelle (Moore):         -- Herleitung der PLA.
    -- S1 S0 Track Timer | S1' S0' | TIMER_RUN TRAFFIC_LIGHT GATE            -- Tabellenkopf.
    -- 0  0   0     0    |  0   0  |    0          0         0               -- Zeile 0.
    -- 0  0   0     1    |  0   0  |    0          0         0               -- Zeile 1.
    -- 0  0   1     0    |  0   1  |    0          0         0               -- Zeile 2.
    -- 0  0   1     1    |  0   1  |    0          0         0               -- Zeile 3.
    -- 0  1   0     0    |  0   0  |    1          1         0               -- Zeile 4.
    -- 0  1   0     1    |  0   0  |    1          1         0               -- Zeile 5.
    -- 0  1   1     0    |  0   1  |    1          1         0               -- Zeile 6.
    -- 0  1   1     1    |  1   0  |    1          1         0               -- Zeile 7.
    -- 1  0   0     0    |  0   0  |    0          1         1               -- Zeile 8.
    -- 1  0   0     1    |  0   0  |    0          1         1               -- Zeile 9.
    -- 1  0   1     0    |  1   0  |    0          1         1               -- Zeile 10.
    -- 1  0   1     1    |  1   0  |    0          1         1               -- Zeile 11.
    -- 1  1   0     0    |  0   0  |    0          0         0               -- Zeile 12.
    -- 1  1   0     1    |  0   0  |    0          0         0               -- Zeile 13.
    -- 1  1   1     0    |  0   0  |    0          0         0               -- Zeile 14.
    -- 1  1   1     1    |  0   0  |    0          0         0               -- Zeile 15.

    signal S_S1 : std_logic := '0';                                        -- Zustandsbit S1 (Q).
    signal S_S0 : std_logic := '0';                                        -- Zustandsbit S0 (Q).
    signal S_D1 : std_logic := '0';                                        -- D fuer S1.
    signal S_D0 : std_logic := '0';                                        -- D fuer S0.

    signal S_TIMER_RUN : std_logic := '0';                                 -- Timer enable.
    signal S_TIMER_INT : integer range 0 to 5 := 0;                        -- Timer counter.
    signal S_TIMER_OUT : std_logic := '0';                                 -- Timer done.

    signal S_N_S1 : std_logic;                                             -- ~S1.
    signal S_N_S0 : std_logic;                                             -- ~S0.
    signal S_N_TRACK : std_logic;                                          -- ~Track.
    signal S_N_TIMER : std_logic;                                          -- ~Timer.

    -- PLA: Minterme (vollstaendig fuer 4 Eingaenge: S1,S0,Track,Timer)      -- 16 AND-Zeilen.
    signal S_MT_0 : std_logic;                                             -- Minterm 0.
    signal S_MT_1 : std_logic;                                             -- Minterm 1.
    signal S_MT_2 : std_logic;                                             -- Minterm 2.
    signal S_MT_3 : std_logic;                                             -- Minterm 3.
    signal S_MT_4 : std_logic;                                             -- Minterm 4.
    signal S_MT_5 : std_logic;                                             -- Minterm 5.
    signal S_MT_6 : std_logic;                                             -- Minterm 6.
    signal S_MT_7 : std_logic;                                             -- Minterm 7.
    signal S_MT_8 : std_logic;                                             -- Minterm 8.
    signal S_MT_9 : std_logic;                                             -- Minterm 9.
    signal S_MT_10 : std_logic;                                            -- Minterm 10.
    signal S_MT_11 : std_logic;                                            -- Minterm 11.
    signal S_MT_12 : std_logic;                                            -- Minterm 12.
    signal S_MT_13 : std_logic;                                            -- Minterm 13.
    signal S_MT_14 : std_logic;                                            -- Minterm 14.
    signal S_MT_15 : std_logic;                                            -- Minterm 15.
begin                                                                     -- Beginn dataflow_full.
    -- Invertierte Signale (PLA-Eingangsspalten)                             -- Warum: AND-Produkte brauchen beide Polaritaeten.
    S_N_S1 <= not S_S1;                                                    -- ~S1.
    S_N_S0 <= not S_S0;                                                    -- ~S0.
    S_N_TRACK <= not P_TRACK_OCCUPIED;                                     -- ~Track.
    S_N_TIMER <= not S_TIMER_OUT;                                          -- ~Timer.

    -- Timer (5 Takte von P_CLK_1HZ), darf ausschliesslich hier P_CLK_1HZ verwenden -- Aufgabenregel.
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)                          -- Timerprozess.
    begin                                                                 -- Beginn Timer.
        if S_TIMER_RUN = '0' then                                         -- Reset wenn Timer aus.
            S_TIMER_INT <= 0;                                             -- Reset.
        elsif rising_edge(P_CLK_1HZ) then                                 -- Zaehlen bei 1Hz.
            if S_TIMER_INT < 5 then                                       -- Bis 5.
                S_TIMER_INT <= S_TIMER_INT + 1;                           -- +1.
            end if;                                                       -- Ende Saettigung.
        end if;                                                           -- Ende Reset/Count.
    end process;                                                          -- Ende Timer.

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';                     -- Timer done.

    -- D-Flipflops (Speicher) fuer den Zustand (S1,S0)                       -- Zustandsspeicher.
    state_reg_proc : process (P_CLK)                                      -- State register.
    begin                                                                 -- Beginn Register.
        if rising_edge(P_CLK) then                                        -- Flanke.
            S_S1 <= S_D1;                                                 -- Q1 <= D1.
            S_S0 <= S_D0;                                                 -- Q0 <= D0.
        end if;                                                           -- Ende.
    end process;                                                          -- Ende Register.

    -- PLA AND-Ebene (Minterme)                                             -- 16 Vollminterme.
    S_MT_0  <= S_N_S1 and S_N_S0 and S_N_TRACK and S_N_TIMER;             -- 00 0 0.
    S_MT_1  <= S_N_S1 and S_N_S0 and S_N_TRACK and S_TIMER_OUT;           -- 00 0 1.
    S_MT_2  <= S_N_S1 and S_N_S0 and P_TRACK_OCCUPIED and S_N_TIMER;      -- 00 1 0.
    S_MT_3  <= S_N_S1 and S_N_S0 and P_TRACK_OCCUPIED and S_TIMER_OUT;    -- 00 1 1.
    S_MT_4  <= S_N_S1 and S_S0  and S_N_TRACK and S_N_TIMER;              -- 01 0 0.
    S_MT_5  <= S_N_S1 and S_S0  and S_N_TRACK and S_TIMER_OUT;            -- 01 0 1.
    S_MT_6  <= S_N_S1 and S_S0  and P_TRACK_OCCUPIED and S_N_TIMER;       -- 01 1 0.
    S_MT_7  <= S_N_S1 and S_S0  and P_TRACK_OCCUPIED and S_TIMER_OUT;     -- 01 1 1.
    S_MT_8  <= S_S1  and S_N_S0 and S_N_TRACK and S_N_TIMER;              -- 10 0 0.
    S_MT_9  <= S_S1  and S_N_S0 and S_N_TRACK and S_TIMER_OUT;            -- 10 0 1.
    S_MT_10 <= S_S1  and S_N_S0 and P_TRACK_OCCUPIED and S_N_TIMER;       -- 10 1 0.
    S_MT_11 <= S_S1  and S_N_S0 and P_TRACK_OCCUPIED and S_TIMER_OUT;     -- 10 1 1.
    S_MT_12 <= S_S1  and S_S0  and S_N_TRACK and S_N_TIMER;               -- 11 0 0.
    S_MT_13 <= S_S1  and S_S0  and S_N_TRACK and S_TIMER_OUT;             -- 11 0 1.
    S_MT_14 <= S_S1  and S_S0  and P_TRACK_OCCUPIED and S_N_TIMER;        -- 11 1 0.
    S_MT_15 <= S_S1  and S_S0  and P_TRACK_OCCUPIED and S_TIMER_OUT;      -- 11 1 1.

    -- PLA OR-Ebene (Disjunktion der Minterme) fuer Folgezustand             -- Next-state Bits aus Mintermen.
    S_D1 <= S_MT_7 or S_MT_10 or S_MT_11;                                 -- S1' = 1 fuer (01,1,1) und (10,1,*).
    S_D0 <= S_MT_2 or S_MT_3 or S_MT_6;                                   -- S0' = 1 fuer (00,1,*) und (01,1,0).

    -- Moore-Ausgaenge (nur abhaengig vom aktuellen Zustand, nicht von Track/Timer). -- Moore: keine Abhaengigkeit von Eingangswechseln.
    S_TIMER_RUN <= S_N_S1 and S_S0;                                       -- Timer nur in Zustand 01.
    P_TRAFFIC_LIGHT <= (S_N_S1 and S_S0) or (S_S1 and S_N_S0);            -- Ampel rot in 01 oder 10.
    P_GATE <= S_S1 and S_N_S0;                                            -- Gate zu in 10.
end dataflow_full;                                                        -- Ende dataflow_full.

-- ---------------------------------------------------------------------   -- Trenner.
-- Aufgabe 3 (dataflow_min): Minimierte PLA auf 6 Zeilen.                   -- Fokus dieser Datei: Herleitung/Warum 6 AND-Terme genuegen.
-- ---------------------------------------------------------------------   -- Trenner.
architecture dataflow_min of my_rail_crossing is                           -- Minimierte PLA als Dataflow (mit Timer/FF weiterhin behavioral).
-- begin solution:                                                         -- Marker: Start Loesungsteil (wie im Template).
    -- Minimierte PLA auf 6 Zeilen (Produktterme). Ziel: gleiches Verhalten wie `dataflow_full`, -- Motivation: gleiche Funktion, weniger AND-Zeilen.
    -- aber mit geteilten und minimierten AND-Termen.                        -- Idee: gemeinsame Teilterme wie State-Decodes wiederverwenden.
    --                                                                        -- Leerzeile.
    -- Zustandscodierung:                                                    -- Wiederholung fuer Klarheit.
    -- 00 Standby, 01 Traffic light red, 10 Gate closed, 11 unused -> 00     -- Definition.

    signal S_S1 : std_logic := '0';                                        -- Zustandsbit S1 (Q), initial Standby.
    signal S_S0 : std_logic := '0';                                        -- Zustandsbit S0 (Q), initial Standby.
    signal S_D1 : std_logic := '0';                                        -- D fuer S1 (S1').
    signal S_D0 : std_logic := '0';                                        -- D fuer S0 (S0').

    signal S_TIMER_RUN : std_logic := '0';                                 -- Timer enable (Moore: Zustand 01).
    signal S_TIMER_INT : integer range 0 to 5 := 0;                        -- Timer-Zaehler 0..5.
    signal S_TIMER_OUT : std_logic := '0';                                 -- Timer-fertig (1 bei 5).

    -- 6 PLA lines (AND plane)                                               -- Genau 6 Produktterme: das ist die Minimierungsanforderung.
    signal S_L0_P01 : std_logic;                                           -- Linie 0: ~S1 & S0   (Zustand 01-Decoder).
    signal S_L1_P10 : std_logic;                                           -- Linie 1:  S1 & ~S0  (Zustand 10-Decoder).
    signal S_L2_P00T : std_logic;                                          -- Linie 2: ~S1 & ~S0 & Track (00 mit Zug -> nach 01).
    signal S_L3_N1TNT : std_logic;                                         -- Linie 3: ~S1 & Track & ~Timer (faengt 00->01 und 01 bleibt 01 bei Timer=0).
    signal S_L4_01TT : std_logic;                                          -- Linie 4: (01) & Track & Timer (01 und Timer fertig -> nach 10).
    signal S_L5_10T : std_logic;                                           -- Linie 5: (10) & Track (10 und Zug da -> bleibt 10).
-- end solution!!                                                          -- Marker: Ende Loesungsteil (Deklarationen).
begin                                                                     -- Beginn Implementierung von dataflow_min.
-- begin solution:                                                         -- Marker: Start Loesungsteil (Implementierung).
    -- Timer (5 ticks of P_CLK_1HZ), only place where P_CLK_1HZ is used      -- Aufgabenregel: P_CLK_1HZ nur im Timer.
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)                          -- Timerprozess wie in den anderen Architekturen.
    begin                                                                 -- Beginn Timer.
        if S_TIMER_RUN = '0' then                                         -- Timer aus -> Reset.
            S_TIMER_INT <= 0;                                             -- Reset.
        elsif rising_edge(P_CLK_1HZ) then                                 -- Timer an -> pro 1Hz-Flanke zaehlen.
            if S_TIMER_INT < 5 then                                       -- Bis 5.
                S_TIMER_INT <= S_TIMER_INT + 1;                           -- +1 Sekunde.
            end if;                                                       -- Ende Saettigung.
        end if;                                                           -- Ende Reset/Count.
    end process;                                                          -- Ende Timerprozess.

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';                     -- Timer-fertig Flag fuer die PLA-Bedingungen.

    -- D-Flipflops (state storage)                                          -- Speicher ist weiterhin D-FF, wie gefordert.
    state_reg_proc : process (P_CLK)                                      -- Zustandsregister.
    begin                                                                 -- Beginn.
        if rising_edge(P_CLK) then                                        -- Positivflanke.
            S_S1 <= S_D1;                                                 -- Q1 <= D1.
            S_S0 <= S_D0;                                                 -- Q0 <= D0.
        end if;                                                           -- Ende.
    end process;                                                          -- Ende Zustandsregister.

    -- AND plane: 6 product terms                                           -- Hier steht die minimierte AND-Ebene.
    S_L0_P01 <= (not S_S1) and S_S0;                                      -- 01-Decoder: wahr genau in Zustand 01.
    S_L1_P10 <= S_S1 and (not S_S0);                                      -- 10-Decoder: wahr genau in Zustand 10.
    S_L2_P00T <= (not S_S1) and (not S_S0) and P_TRACK_OCCUPIED;          -- 00 & Track: Standby + Zug -> naechster Zustand S0'=1.
    S_L3_N1TNT <= (not S_S1) and P_TRACK_OCCUPIED and (not S_TIMER_OUT);  -- ~S1 & Track & ~Timer: deckt (00,Track=1,Timer=0/1?) und (01,Track=1,Timer=0) fuer S0'=1.
    S_L4_01TT <= S_L0_P01 and P_TRACK_OCCUPIED and S_TIMER_OUT;           -- 01 & Track & Timer: genau der Uebergang 01 -> 10.
    S_L5_10T <= S_L1_P10 and P_TRACK_OCCUPIED;                            -- 10 & Track: Zustand 10 halten solange Zug da.

    -- OR plane: next-state bits                                            -- Aus den 6 Linien werden D1/D0 gebildet.
    S_D1 <= S_L4_01TT or S_L5_10T;                                        -- S1' ist 1 bei (01&Track&Timer) oder (10&Track) -> ergibt 10.
    S_D0 <= S_L2_P00T or S_L3_N1TNT;                                      -- S0' ist 1 bei (00&Track) oder (~S1&Track&~Timer) -> ergibt 01 wenn Timer noch nicht fertig.

    -- Moore outputs (derived only from state decode terms)                 -- Outputs nur aus Zustandsdecodes: Moore-konform und glitchfrei.
    S_TIMER_RUN <= S_L0_P01;                                              -- Timer laeuft nur in Zustand 01 (Ampel rot).
    P_TRAFFIC_LIGHT <= S_L0_P01 or S_L1_P10;                              -- Ampel rot in 01 oder 10.
    P_GATE <= S_L1_P10;                                                   -- Schranke zu in 10.
-- end solution!!                                                          -- Marker: Ende Loesungsteil.
end dataflow_min;                                                         -- Ende dataflow_min.

architecture dataflow_tff of my_rail_crossing is                           -- Platzhalter fuer Knobelaufgabe (T-FF).
    -- begin solution:                                                     -- Marker.
    -- end solution!!                                                      -- Marker.
begin                                                                     -- Beginn (leer).
end dataflow_tff;                                                         -- Ende (leer).

