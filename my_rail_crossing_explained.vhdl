-- Laboratory GdTi solutions/versuch9
-- (Erklärversion) Diese Datei enthält den gleichen VHDL-Code wie `my_rail_crossing.vhdl`,
-- aber jede relevante Zeile ist mit Motivation/Begründung kommentiert.
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

-- Wir nutzen die IEEE-Bibliothek, weil dort die Standard-Logiktypen definiert sind.
library IEEE; -- Bindet die IEEE-Library ein (Basis für Standards wie STD_LOGIC_1164).
-- STD_LOGIC_1164 liefert `std_logic`, `rising_edge`, logische Operatoren usw.
use IEEE.STD_LOGIC_1164.ALL; -- Importiert die üblichen Logik-Typen/Operatoren für Synthese/Simulation.

-- Entity = Black-Box-Schnittstelle des Bahnübergangs.
entity my_rail_crossing is -- Start der Schnittstellenbeschreibung (Entity).
    -- Die Ports entsprechen exakt der Aufgabenstellung/Testbench:
    -- - P_CLK: "schneller" Systemtakt für Zustandswechsel (State-Register).
    -- - P_CLK_1HZ: 1Hz-Takt nur für den Timer (5 Sekunden abmessen).
    -- - P_TRACK_OCCUPIED: Sensor, ob Zug im Gefahrenbereich ist.
    -- - P_TRAFFIC_LIGHT: Ampel (1 = rot an).
    -- - P_GATE: Schranke (1 = geschlossen).
    port ( -- Beginn der Portliste (Ein-/Ausgänge des Moduls).
        P_CLK : in std_logic;                -- Eingangsport: Takt für den Automaten (Zustand wird hier übernommen).
        P_CLK_1HZ : in std_logic;            -- Eingangsport: 1Hz-Takt nur für Zeitmessung (Timer).
        P_TRACK_OCCUPIED : in std_logic;     -- Eingangsport: Sensor (1 = Zug im Gefahrenbereich).
        P_TRAFFIC_LIGHT : out std_logic;     -- Ausgang: 1 = Ampel rot, 0 = aus.
        P_GATE : out std_logic               -- Ausgang: 1 = Schranke zu, 0 = offen.
    ); -- Ende der Portliste.
end entity; -- Ende der Entity-Deklaration.

-- Architecture `behavior`: Moore-Automat + Timer in Prozessform (behavioral).
architecture behavior of my_rail_crossing is -- Beginn der behavioral-Architektur (Implementierung).
    -- Zustandstyp: 3 Moore-Zustände aus der Aufgabenbeschreibung/Tabelle.
    -- Moore heißt: Ausgänge hängen nur vom aktuellen Zustand ab (nicht direkt vom Eingang).
    type state_type is (STANDBY, TRAFFIC_LIGHT_RED, GATE_CLOSED); -- Enumerierter Typ für die 3 Zustände.

    -- Aktueller Zustand (State-Register); Initialwert STANDBY für definierten Start.
    signal S_CURRENT_STATE : state_type := STANDBY; -- State-Register (aktueller Zustand).
    -- Nächster Zustand (kombinatorische Next-State-Logik).
    signal S_NEXT_STATE : state_type := STANDBY; -- Kombinatorisch berechneter Folgezustand.

    -- Steuersignal, ob der Timer laufen soll (wird aus dem Zustand abgeleitet).
    signal S_TIMER_RUN : std_logic := '0'; -- Timer-Enable: 1 => Timer zählt, 0 => Timer reset/steht.
    -- Interner Zähler für Sekunden: zählt 0..5 (5 Sekunden bis Schranke schließt).
    signal S_TIMER_INT : integer range 0 to 5 := 0; -- Sekundenzähler (0..5), begrenzt für Sicherheit/Lesbarkeit.
    -- Timer-Flag: wird '1', sobald 5 Sekunden erreicht sind.
    signal S_TIMER_OUT : std_logic := '0'; -- "Timer fertig"-Flag als std_logic (für einfache Logik).
begin -- Start des Architektur-Rumpfs (hier kommen Prozesse und Zuweisungen).
    -- Timer-Prozess:
    -- - Darf als einziger Prozess P_CLK_1HZ verwenden (Aufgabenhinweis).
    -- - Zählt nur, wenn S_TIMER_RUN='1' (d. h. im Zustand TRAFFIC_LIGHT_RED).
    -- - Wenn S_TIMER_RUN='0', wird sofort auf 0 zurückgesetzt (damit "sofort öffnen/aus"
    --   beim Freigeben des Sensors garantiert ist).
    timer_proc : process (P_CLK_1HZ, S_TIMER_RUN) -- Timer-Prozess mit 1Hz-Takt + asynchronem Reset über S_TIMER_RUN.
    begin -- Beginn des Timer-Prozesses.
        -- Asynchrones Rücksetzen des Timers, sobald der Timer nicht laufen soll.
        -- Motivation: Wenn der Zug weg ist, soll "sofort" alles auf Standby gehen und
        -- der Timer muss dabei direkt zurückgesetzt sein (keine Restzeit).
        if S_TIMER_RUN = '0' then -- Wenn Timer nicht laufen soll: sofort zurücksetzen.
            S_TIMER_INT <= 0; -- Timer steht/ist zurückgesetzt -> nächster Start beginnt wieder bei 0.
        -- Wenn Timer laufen soll, zählen wir bei jeder positiven Flanke des 1Hz-Taktes.
        elsif rising_edge(P_CLK_1HZ) then -- Sonst: bei jeder 1Hz-Positivflanke eine Sekunde weiterzählen.
            -- Sättigung bei 5: verhindert Überlauf und hält "Timer fertig" stabil.
            if S_TIMER_INT < 5 then -- Bis max. 5 zählen (Sättigung).
                S_TIMER_INT <= S_TIMER_INT + 1; -- Pro 1Hz-Flanke +1 Sekunde.
            end if; -- Ende der Sättigungsprüfung.
        end if; -- Ende der Reset/Count-Auswahl.
    end process; -- Ende des Timer-Prozesses.

    -- Kombinatorisches "Timer fertig"-Signal:
    -- Funktion: Ab Sekunde 5 ist S_TIMER_OUT='1' und bleibt es bis Timer-Reset.
    S_TIMER_OUT <= '1' when S_TIMER_INT = 5 else '0'; -- 1 genau dann, wenn 5 Sekunden erreicht sind.

    -- State-Register-Prozess:
    -- Bei jeder positiven Flanke von P_CLK wird der berechnete nächste Zustand übernommen.
    -- Motivation: Saubere, synchrone Zustandsmaschine (keine Glitches im Zustand).
    state_reg_proc : process (P_CLK) -- Zustandsregister: übernimmt S_NEXT_STATE synchron.
    begin -- Beginn des State-Register-Prozesses.
        if rising_edge(P_CLK) then -- Synchroner Zustandswechsel bei positiver Taktflanke.
            S_CURRENT_STATE <= S_NEXT_STATE; -- Zustand wird nur am Takt übernommen.
        end if; -- Ende der Flankenerkennung.
    end process; -- Ende des State-Register-Prozesses.

    -- Next-State-Logik (kombinatorisch):
    -- Abhängig von (aktueller Zustand, Sensor, Timer) wird S_NEXT_STATE bestimmt.
    next_state_proc : process (S_CURRENT_STATE, P_TRACK_OCCUPIED, S_TIMER_OUT) -- Kombinatorische Folgezustandslogik.
    begin -- Beginn der Next-State-Logik.
        -- Default: im Zustand bleiben. Motivation: Vollständige Zuweisung -> keine Latches.
        S_NEXT_STATE <= S_CURRENT_STATE; -- Default: Halten (wird bei erfüllten Bedingungen überschrieben).

        -- Zustandsabhängige Übergänge entsprechend Aufgabenbeschreibung:
        case S_CURRENT_STATE is -- Auswahl nach aktuellem Zustand (Moore-Automat).
            when STANDBY => -- Zustand: Standby (kein Zug).
                -- Standby: alles aus/offen. Wenn ein Zug kommt -> Ampel rot und Timer starten.
                if P_TRACK_OCCUPIED = '1' then -- Wenn Zug erkannt wird: in "Ampel rot" wechseln.
                    S_NEXT_STATE <= TRAFFIC_LIGHT_RED; -- Erst Ampel rot, Schranke bleibt zunächst offen.
                end if; -- Ende der Zug-Erkennung.

            when TRAFFIC_LIGHT_RED => -- Zustand: Ampel rot (Timer läuft, Schranke noch offen).
                -- Ampel rot: Wenn der Zug weg ist, sofort zurück (Ampel aus, Schranke offen).
                if P_TRACK_OCCUPIED = '0' then -- Wenn Zug weg: sofort zurück nach Standby.
                    S_NEXT_STATE <= STANDBY; -- "Ist der Gefahrenbereich frei, sofort ..."
                -- Wenn Zug noch da und Timer fertig -> Schranke schließen.
                elsif S_TIMER_OUT = '1' then -- Wenn 5 Sekunden abgelaufen: Schranke schließen.
                    S_NEXT_STATE <= GATE_CLOSED; -- Nach 5 Sekunden: Schranke zu.
                end if; -- Ende der Bedingungen im Zustand TRAFFIC_LIGHT_RED.

            when GATE_CLOSED => -- Zustand: Schranke zu (Ampel bleibt rot).
                -- Schranke zu: bleibt zu, solange der Zug im Gefahrenbereich ist.
                -- Sobald der Zug weg ist -> sofort Standby (öffnet Schranke und schaltet Ampel aus).
                if P_TRACK_OCCUPIED = '0' then -- Wenn Zug weg: sofort öffnen/aus -> Standby.
                    S_NEXT_STATE <= STANDBY; -- Zurück in sicheren Grundzustand (Ampel aus, Schranke offen).
                end if; -- Ende der Freigabe-Bedingung.
        end case; -- Ende der Zustandsfallunterscheidung.
    end process; -- Ende der Next-State-Logik.

    -- Output-Logik (Moore):
    -- Ausgänge hängen ausschließlich von S_CURRENT_STATE ab.
    -- Zusätzlich erzeugen wir S_TIMER_RUN aus dem Zustand (Timer läuft nur in TRAFFIC_LIGHT_RED).
    output_proc : process (S_CURRENT_STATE) -- Moore-Ausgänge: nur vom aktuellen Zustand abhängig.
    begin -- Beginn der Output-Logik.
        -- Defaultwerte (wieder: vollständige Zuweisung -> keine Latches).
        P_TRAFFIC_LIGHT <= '0'; -- Standard: Ampel aus.
        P_GATE <= '0';          -- Standard: Schranke offen.
        S_TIMER_RUN <= '0';     -- Standard: Timer aus (Timer wird dadurch sofort zurückgesetzt).

        case S_CURRENT_STATE is -- Ausgabe abhängig vom Zustand.
            when STANDBY => -- Standby-Ausgaben.
                -- Standby: alles aus/offen, Timer aus.
                P_TRAFFIC_LIGHT <= '0'; -- Ampel aus.
                P_GATE <= '0';          -- Schranke offen.
                S_TIMER_RUN <= '0';     -- Timer aus (und damit reset).

            when TRAFFIC_LIGHT_RED => -- Ampel-rot-Ausgaben.
                -- Ampel rot: Ampel an, Schranke bleibt offen, Timer läuft (zählt 5 Sekunden).
                P_TRAFFIC_LIGHT <= '1'; -- Rot an.
                P_GATE <= '0';          -- Schranke noch offen.
                S_TIMER_RUN <= '1';     -- Timer läuft (zählt 5 Sekunden).

            when GATE_CLOSED => -- Schranke-zu-Ausgaben.
                -- Schranke zu: Ampel bleibt rot, Schranke geschlossen, Timer muss nicht weiterlaufen.
                P_TRAFFIC_LIGHT <= '1'; -- Rot bleibt an, solange Schranke zu ist.
                P_GATE <= '1';          -- Schranke geschlossen.
                S_TIMER_RUN <= '0';     -- Timer aus (nicht mehr nötig).
        end case; -- Ende der Ausgabe-Fallunterscheidung.
    end process; -- Ende der Output-Logik.
end behavior; -- Ende der behavioral-Architektur.

-- Die folgenden Architekturen gehören zu Aufgabe 2/3/Knobelaufgabe.
-- Für Aufgabe 1 reicht `behavior`; hier bleiben sie leer, aber syntaktisch korrekt.
architecture dataflow_full of my_rail_crossing is -- Platzhalter für Aufgabe 2 (vollständige PLA).
-- begin solution:
-- end solution!!
begin -- Beginn (leer).
end dataflow_full; -- Ende.

architecture dataflow_min of my_rail_crossing is -- Platzhalter für Aufgabe 3 (minimierte PLA).
-- begin solution:
-- end solution!!
begin -- Beginn (leer).
end dataflow_min; -- Ende.

architecture dataflow_tff of my_rail_crossing is -- Platzhalter für Knobelaufgabe (T-FF Implementierung).
    -- begin solution:
    -- end solution!!
begin -- Beginn (leer).
end dataflow_tff; -- Ende.
