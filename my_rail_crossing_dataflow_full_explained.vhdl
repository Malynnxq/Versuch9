-- Laboratory GdTi solutions/versuch9                                      -- Header: Kontext der Abgabe/Datei.
-- (Erklaerversion Aufgabe 2)                                              -- Hinweis: Datei dient dem Verstaendnis, nicht zum Mitkompilieren.
-- Diese Datei enthaelt den gleichen Code wie `my_rail_crossing.vhdl`,      -- Motivation: identischer Funktionsumfang, aber mit Erklaerungen.
-- jedoch ist jede relevante Codezeile kommentiert (Warum/Wie/Funktion).    -- Forderung aus der Aufgabe "wie vorher": Zeile fuer Zeile erklaeren.
-- Winter Semester 25/26                                                   -- Kontext.
-- Group Details                                                           -- Kontext.
-- Lab Date:                                                               -- Kontext.
-- 1. Participant First and  Last Name:                                    -- Kontext.
-- 2. Participant First and Last Name:                                     -- Kontext.

-- coding conventions                                                      -- Stil: Namensregeln (wie im Template).
-- g_<name> Generics                                                       -- Stil.
-- p_<name> Ports                                                          -- Stil.
-- c_<name> Constants                                                      -- Stil.
-- s_<name> Signals                                                        -- Stil.
-- v_<name> Variables                                                      -- Stil.

library IEEE;                                                             -- Warum: Standardbibliothek einbinden.
use IEEE.STD_LOGIC_1164.ALL;                                              -- Warum: `std_logic`, `rising_edge`, logische Operatoren.

entity my_rail_crossing is                                                -- Was: Entity beschreibt nur die Schnittstelle (Ports).
    port (                                                                -- Warum: Testbenches binden per `port map` genau diese Reihenfolge an.
        P_CLK : in std_logic;                                             -- Systemtakt: Zustand wird auf positiver Flanke uebernommen.
        P_CLK_1HZ : in std_logic;                                         -- 1Hz-Takt: nur fuer den Timer (Aufgabenhinweis).
        P_TRACK_OCCUPIED : in std_logic;                                  -- Eingang: Sensor (1 = Zug im Gefahrenbereich).
        P_TRAFFIC_LIGHT : out std_logic;                                  -- Ausgang: Ampel (1 = rot an).
        P_GATE : out std_logic                                            -- Ausgang: Schranke (1 = geschlossen).
    );                                                                    -- Ende Portliste.
end entity;                                                               -- Ende Entity.

-- ---------------------------------------------------------------------   -- Trenner fuer bessere Lesbarkeit.
-- Aufgabe 1 (behavior): Moore-Automat als Referenz/Verifikation.          -- Motivation: Dient als funktionale Referenz; Aufgabe 2 soll gleiches Verhalten haben.
-- ---------------------------------------------------------------------   -- Trenner.
architecture behavior of my_rail_crossing is                               -- Behavioral-Implementierung (prozessbasiert).
    type state_type is (STANDBY, TRAFFIC_LIGHT_RED, GATE_CLOSED);          -- Moore-Zustaende: 3 Zustaende aus der Aufgabenbeschreibung.

    signal S_CURRENT_STATE : state_type := STANDBY;                       -- Zustandsspeicher (aktueller Zustand), initial Standby.
    signal S_NEXT_STATE : state_type := STANDBY;                          -- Kombinatorischer Folgezustand.

    signal S_TIMER_RUN : std_logic := '0';                                -- Timer-Enable: laeuft nur im Zustand TRAFFIC_LIGHT_RED.
    signal S_TIMER_INT : integer range 0 to 5 := 0;                       -- Sekundenzähler 0..5 (5 Sekunden bis Schranke schliesst).
    signal S_TIMER_OUT : std_logic := '0';                                -- Timer-Fertig-Flag (1 wenn 5 Sekunden erreicht).
begin                                                                     -- Beginn der Architektur.
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)                         -- Timerprozess mit 1Hz-Flanke + asynchronem Reset ueber S_TIMER_RUN.
    begin                                                                 -- Beginn Timerprozess.
        if S_TIMER_RUN = '0' then                                         -- Warum: Wenn Timer nicht laufen soll, sofort auf 0 setzen (sofortige Rueckkehr bei Track=0).
            S_TIMER_INT <= 0;                                             -- Effekt: Timer wird zurueckgesetzt.
        elsif rising_edge(P_CLK_1HZ) then                                 -- Warum: Bei jeder 1Hz-Positivflanke eine Sekunde zaehlen.
            if S_TIMER_INT < 5 then                                       -- Warum: Sättigung verhindert Ueberlauf und haelt "fertig" stabil.
                S_TIMER_INT <= S_TIMER_INT + 1;                           -- Effekt: +1 Sekunde.
            end if;                                                       -- Ende Sättigungspruefung.
        end if;                                                           -- Ende Reset/Count-Auswahl.
    end process;                                                          -- Ende Timerprozess.

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';                     -- Timer ist "fertig" genau bei Zaehlerstand 5.

    state_reg_proc : process (P_CLK)                                      -- Zustandsregister: synchroner Zustandswechsel.
    begin                                                                 -- Beginn State-Register.
        if rising_edge(P_CLK) then                                        -- Warum: Zustandsbits sollen nur auf Taktflanke wechseln (stabil/ohne Glitches).
            S_CURRENT_STATE <= S_NEXT_STATE;                               -- Effekt: Folgezustand wird aktueller Zustand.
        end if;                                                           -- Ende Flankenerkennung.
    end process;                                                          -- Ende State-Register.

    next_state_proc : process (S_CURRENT_STATE, P_TRACK_OCCUPIED, S_TIMER_OUT) -- Kombinatorische Folgezustandslogik (vollstaendige Sensitivitaetsliste).
    begin                                                                 -- Beginn Next-State.
        S_NEXT_STATE <= S_CURRENT_STATE;                                   -- Default: Halten (verhindert Latches).

        case S_CURRENT_STATE is                                           -- Auswahl nach aktuellem Zustand.
            when STANDBY =>                                               -- Standby: Ampel aus, Schranke offen.
                if P_TRACK_OCCUPIED = '1' then                            -- Wenn Zug kommt:
                    S_NEXT_STATE <= TRAFFIC_LIGHT_RED;                     -- Zuerst Ampel rot (Timer startet ueber Output-Logik).
                end if;                                                   -- Ende Bedingung.

            when TRAFFIC_LIGHT_RED =>                                     -- Ampel rot: Timer laeuft.
                if P_TRACK_OCCUPIED = '0' then                            -- Wenn Zug weg:
                    S_NEXT_STATE <= STANDBY;                               -- Sofort zurueck (Ampel aus, Schranke offen).
                elsif S_TIMER_OUT = '1' then                              -- Wenn Timer fertig (5s):
                    S_NEXT_STATE <= GATE_CLOSED;                           -- Schranke schliessen.
                end if;                                                   -- Ende Bedingungen.

            when GATE_CLOSED =>                                           -- Schranke ist geschlossen.
                if P_TRACK_OCCUPIED = '0' then                            -- Sobald Zug weg:
                    S_NEXT_STATE <= STANDBY;                               -- Sofort Standby (oeffnet Schranke und schaltet Ampel aus).
                end if;                                                   -- Ende Bedingung.
        end case;                                                         -- Ende Case.
    end process;                                                          -- Ende Next-State.

    output_proc : process (S_CURRENT_STATE)                                -- Moore-Ausgaenge: nur vom aktuellen Zustand.
    begin                                                                 -- Beginn Output-Logik.
        P_TRAFFIC_LIGHT <= '0';                                           -- Default: Ampel aus.
        P_GATE <= '0';                                                    -- Default: Schranke offen.
        S_TIMER_RUN <= '0';                                               -- Default: Timer aus (-> Reset im Timerprozess).

        case S_CURRENT_STATE is                                           -- Ausgaenge je Zustand:
            when STANDBY =>                                               -- Standby:
                P_TRAFFIC_LIGHT <= '0';                                   -- Ampel aus.
                P_GATE <= '0';                                            -- Schranke offen.
                S_TIMER_RUN <= '0';                                       -- Timer aus.

            when TRAFFIC_LIGHT_RED =>                                     -- Ampel rot:
                P_TRAFFIC_LIGHT <= '1';                                   -- Rot an.
                P_GATE <= '0';                                            -- Schranke noch offen.
                S_TIMER_RUN <= '1';                                       -- Timer an (zaehlt bis 5s).

            when GATE_CLOSED =>                                           -- Schranke zu:
                P_TRAFFIC_LIGHT <= '1';                                   -- Rot bleibt an.
                P_GATE <= '1';                                            -- Schranke geschlossen.
                S_TIMER_RUN <= '0';                                       -- Timer aus (nicht mehr noetig).
        end case;                                                         -- Ende Case.
    end process;                                                          -- Ende Output-Logik.
end behavior;                                                             -- Ende behavioral-Architektur.

-- ---------------------------------------------------------------------   -- Trenner.
-- Aufgabe 2 (dataflow_full): PLA (AND/OR) + D-Flipflops + Timer.           -- Motivation: Die Kombinatorik soll als PLA in Dataflow stehen.
-- ---------------------------------------------------------------------   -- Trenner.
architecture dataflow_full of my_rail_crossing is                          -- Dataflow-Architektur fuer die vollstaendige PLA.
    -- Zustandscodierung (Tabelle 1):                                       -- Warum: Binäre Codierung ist Basis fuer PLA-Eingaenge.
    -- Standby       = S1S0 = 00                                            -- Definition.
    -- Ampel rot     = S1S0 = 01                                            -- Definition.
    -- Schranke zu   = S1S0 = 10                                            -- Definition.
    -- 11 ist unbenutzt -> wird sicherheitshalber nach 00 gefuehrt.         -- Motivation: Unbenutzter Zustand soll in sicheren Zustand fallen.
    --                                                                        -- Leerzeile fuer Lesbarkeit.
    -- Vollstaendige Zustandsuebergangs- und Ausgabetabelle (Moore):         -- Warum: Daraus leiten wir Minterme und OR-Verknuepfungen ab.
    -- S1 S0 Track Timer | S1' S0' | TIMER_RUN TRAFFIC_LIGHT GATE            -- Kopf.
    -- 0  0   0     0    |  0   0  |    0          0         0               -- 00 + kein Zug -> bleibt 00; Ausgaenge Standby.
    -- 0  0   0     1    |  0   0  |    0          0         0               -- Timer spielt in Standby keine Rolle.
    -- 0  0   1     0    |  0   1  |    0          0         0               -- Zug kommt -> in 01.
    -- 0  0   1     1    |  0   1  |    0          0         0               -- Ebenso: in 01.
    -- 0  1   0     0    |  0   0  |    1          1         0               -- 01 + Zug weg -> sofort 00; Ausgaenge von aktuellem Zustand 01.
    -- 0  1   0     1    |  0   0  |    1          1         0               -- Gleich, Timer egal wenn Track=0.
    -- 0  1   1     0    |  0   1  |    1          1         0               -- 01 + Zug da + Timer nicht fertig -> bleibt 01.
    -- 0  1   1     1    |  1   0  |    1          1         0               -- 01 + Zug da + Timer fertig -> in 10.
    -- 1  0   0     0    |  0   0  |    0          1         1               -- 10 + Zug weg -> 00; Ausgaenge von aktuellem Zustand 10.
    -- 1  0   0     1    |  0   0  |    0          1         1               -- Gleich.
    -- 1  0   1     0    |  1   0  |    0          1         1               -- 10 + Zug da -> bleibt 10.
    -- 1  0   1     1    |  1   0  |    0          1         1               -- Gleich.
    -- 1  1   0     0    |  0   0  |    0          0         0               -- 11 unbenutzt -> 00, sichere Ausgaenge.
    -- 1  1   0     1    |  0   0  |    0          0         0               -- Gleich.
    -- 1  1   1     0    |  0   0  |    0          0         0               -- Gleich.
    -- 1  1   1     1    |  0   0  |    0          0         0               -- Gleich.

    signal S_S1 : std_logic := '0';                                        -- State-Bit S1 (D-FF Ausgang), initial 0.
    signal S_S0 : std_logic := '0';                                        -- State-Bit S0 (D-FF Ausgang), initial 0.
    signal S_D1 : std_logic := '0';                                        -- D-Eingang fuer S1 (Folgezustand).
    signal S_D0 : std_logic := '0';                                        -- D-Eingang fuer S0 (Folgezustand).

    signal S_TIMER_RUN : std_logic := '0';                                 -- Timer-Enable (Moore: abhaengig vom Zustand 01).
    signal S_TIMER_INT : integer range 0 to 5 := 0;                        -- Timer-Zaehler 0..5 (Sekunden).
    signal S_TIMER_OUT : std_logic := '0';                                 -- Timer-fertig (1 bei 5).

    signal S_N_S1 : std_logic;                                             -- Invertierte Spalte ~S1 fuer AND-Ebene (PLA).
    signal S_N_S0 : std_logic;                                             -- Invertierte Spalte ~S0 fuer AND-Ebene (PLA).
    signal S_N_TRACK : std_logic;                                          -- Invertierte Spalte ~Track fuer AND-Ebene (PLA).
    signal S_N_TIMER : std_logic;                                          -- Invertierte Spalte ~Timer fuer AND-Ebene (PLA).

    -- PLA: Minterme (vollstaendig fuer 4 Eingaenge: S1,S0,Track,Timer)      -- Warum: Vollstaendig = alle 16 Kombinationen als AND-Produkte.
    signal S_MT_0 : std_logic;                                             -- Minterm 0  fuer (00,0,0).
    signal S_MT_1 : std_logic;                                             -- Minterm 1  fuer (00,0,1).
    signal S_MT_2 : std_logic;                                             -- Minterm 2  fuer (00,1,0).
    signal S_MT_3 : std_logic;                                             -- Minterm 3  fuer (00,1,1).
    signal S_MT_4 : std_logic;                                             -- Minterm 4  fuer (01,0,0).
    signal S_MT_5 : std_logic;                                             -- Minterm 5  fuer (01,0,1).
    signal S_MT_6 : std_logic;                                             -- Minterm 6  fuer (01,1,0).
    signal S_MT_7 : std_logic;                                             -- Minterm 7  fuer (01,1,1).
    signal S_MT_8 : std_logic;                                             -- Minterm 8  fuer (10,0,0).
    signal S_MT_9 : std_logic;                                             -- Minterm 9  fuer (10,0,1).
    signal S_MT_10 : std_logic;                                            -- Minterm 10 fuer (10,1,0).
    signal S_MT_11 : std_logic;                                            -- Minterm 11 fuer (10,1,1).
    signal S_MT_12 : std_logic;                                            -- Minterm 12 fuer (11,0,0).
    signal S_MT_13 : std_logic;                                            -- Minterm 13 fuer (11,0,1).
    signal S_MT_14 : std_logic;                                            -- Minterm 14 fuer (11,1,0).
    signal S_MT_15 : std_logic;                                            -- Minterm 15 fuer (11,1,1).
begin                                                                     -- Beginn Dataflow-Architektur.
    -- Invertierte Signale (PLA-Eingangsspalten):                            -- Warum: PLA nutzt typischerweise beide Polaritaeten.
    S_N_S1 <= not S_S1;                                                    -- ~S1 fuer AND-Produkte.
    S_N_S0 <= not S_S0;                                                    -- ~S0 fuer AND-Produkte.
    S_N_TRACK <= not P_TRACK_OCCUPIED;                                     -- ~Track fuer AND-Produkte.
    S_N_TIMER <= not S_TIMER_OUT;                                          -- ~Timer fuer AND-Produkte.

    -- Timer (5 Takte von P_CLK_1HZ), darf ausschliesslich hier P_CLK_1HZ verwenden -- Aufgabenhinweis: 1Hz nur im Timerprozess.
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN)                          -- Timerprozess wie in behavior, nur lokale Signale.
    begin                                                                 -- Beginn Timer.
        if S_TIMER_RUN = '0' then                                         -- Wenn Timer aus: sofort reset.
            S_TIMER_INT <= 0;                                             -- Reset.
        elsif rising_edge(P_CLK_1HZ) then                                 -- Wenn Timer an: jede 1Hz-Flanke zaehlen.
            if S_TIMER_INT < 5 then                                       -- Sättigung bei 5.
                S_TIMER_INT <= S_TIMER_INT + 1;                           -- +1 Sekunde.
            end if;                                                       -- Ende Sättigung.
        end if;                                                           -- Ende Reset/Count.
    end process;                                                          -- Ende Timer.

    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0';                     -- Timer-fertig Flag (wird PLA-Eingang "Timer" in Tabelle).

    -- D-Flipflops (Speicher) fuer den Zustand (S1,S0):                      -- Warum: Aufgabe 2 fordert Speicher als D-FF (PLA + D-FF).
    state_reg_proc : process (P_CLK)                                      -- State-Register synchron zu P_CLK.
    begin                                                                 -- Beginn State-Register.
        if rising_edge(P_CLK) then                                        -- Zustandsbits wechseln nur auf Flanke.
            S_S1 <= S_D1;                                                 -- D->Q fuer Bit S1.
            S_S0 <= S_D0;                                                 -- D->Q fuer Bit S0.
        end if;                                                           -- Ende Flankenerkennung.
    end process;                                                          -- Ende State-Register.

    -- PLA AND-Ebene (Minterme):                                             -- Warum: Jede Zeile ist ein AND aus (S1/S0/Track/Timer) in passender Polaritaet.
    S_MT_0  <= S_N_S1 and S_N_S0 and S_N_TRACK and S_N_TIMER;             -- 00 0 0 (S1=0,S0=0,Track=0,Timer=0).
    S_MT_1  <= S_N_S1 and S_N_S0 and S_N_TRACK and S_TIMER_OUT;           -- 00 0 1 (Timer=1 statt ~Timer).
    S_MT_2  <= S_N_S1 and S_N_S0 and P_TRACK_OCCUPIED and S_N_TIMER;      -- 00 1 0 (Track=1 statt ~Track).
    S_MT_3  <= S_N_S1 and S_N_S0 and P_TRACK_OCCUPIED and S_TIMER_OUT;    -- 00 1 1.
    S_MT_4  <= S_N_S1 and S_S0  and S_N_TRACK and S_N_TIMER;              -- 01 0 0 (S0=1).
    S_MT_5  <= S_N_S1 and S_S0  and S_N_TRACK and S_TIMER_OUT;            -- 01 0 1.
    S_MT_6  <= S_N_S1 and S_S0  and P_TRACK_OCCUPIED and S_N_TIMER;       -- 01 1 0.
    S_MT_7  <= S_N_S1 and S_S0  and P_TRACK_OCCUPIED and S_TIMER_OUT;     -- 01 1 1.
    S_MT_8  <= S_S1  and S_N_S0 and S_N_TRACK and S_N_TIMER;              -- 10 0 0 (S1=1).
    S_MT_9  <= S_S1  and S_N_S0 and S_N_TRACK and S_TIMER_OUT;            -- 10 0 1.
    S_MT_10 <= S_S1  and S_N_S0 and P_TRACK_OCCUPIED and S_N_TIMER;       -- 10 1 0.
    S_MT_11 <= S_S1  and S_N_S0 and P_TRACK_OCCUPIED and S_TIMER_OUT;     -- 10 1 1.
    S_MT_12 <= S_S1  and S_S0  and S_N_TRACK and S_N_TIMER;               -- 11 0 0 (unbenutzt, aber definiert).
    S_MT_13 <= S_S1  and S_S0  and S_N_TRACK and S_TIMER_OUT;             -- 11 0 1.
    S_MT_14 <= S_S1  and S_S0  and P_TRACK_OCCUPIED and S_N_TIMER;        -- 11 1 0.
    S_MT_15 <= S_S1  and S_S0  and P_TRACK_OCCUPIED and S_TIMER_OUT;      -- 11 1 1.

    -- PLA OR-Ebene fuer Folgezustand:                                       -- Warum: D1/D0 sind Disjunktionen der Minterme, die in der Tabelle S1'/S0'=1 haben.
    S_D1 <= S_MT_7 or S_MT_10 or S_MT_11;                                 -- S1' ist 1 bei (01,1,1) sowie (10,1,0)/(10,1,1) -> bleibt in 10 oder wechselt zu 10.
    S_D0 <= S_MT_2 or S_MT_3 or S_MT_6;                                   -- S0' ist 1 bei (00,1,*) und (01,1,0) -> in 01 bleiben/wechseln.

    -- Moore-Ausgaenge aus dem aktuellen Zustand (glitchfrei):               -- Warum: Moore -> Ausgaenge nur vom Zustand; robust gegen Eingangsglitches.
    S_TIMER_RUN <= S_N_S1 and S_S0;                                       -- Timer laeuft nur im Zustand 01 (Ampel rot, Schranke noch offen).
    P_TRAFFIC_LIGHT <= (S_N_S1 and S_S0) or (S_S1 and S_N_S0);            -- Ampel rot in 01 und 10 (Ampel rot + Schranke zu).
    P_GATE <= S_S1 and S_N_S0;                                            -- Schranke zu nur in 10.
end dataflow_full;                                                        -- Ende dataflow_full-Architektur.

-- Aufgabe 3 Platzhalter: wird in `dataflow_min` umgesetzt.                 -- Motivation: Datei bleibt syntaktisch komplett, aber Aufgabe 3 ist separat.
architecture dataflow_min of my_rail_crossing is                           -- Architecture fuer minimierte PLA (noch leer).
-- begin solution:                                                         -- Marker aus Template (wird spaeter gefuellt).
-- end solution!!                                                          -- Marker.
begin                                                                     -- Beginn (leer).
end dataflow_min;                                                         -- Ende.

-- Knobelaufgabe Platzhalter: `dataflow_tff` mit T-Flipflops.               -- Motivation: bleibt hier leer, weil Aufgabe 4.
architecture dataflow_tff of my_rail_crossing is                           -- Architecture fuer TFF-Variante (noch leer).
    -- begin solution:                                                     -- Marker.
    -- end solution!!                                                      -- Marker.
begin                                                                     -- Beginn (leer).
end dataflow_tff;                                                         -- Ende.

