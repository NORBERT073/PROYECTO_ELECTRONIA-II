--------------------------------------------------------------------------
-- LIBRERIAS
--------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------------
-- ENTIDAD
--------------------------------------------------------------------------
entity seguridad_autenticacion is
    port(
        clk100_m1     : in  std_logic;                  -- Reloj 100 MHz 
        rst_m1        : in  std_logic;                  -- Reset del sistema
        btn_config_m1 : in  std_logic;                  -- Botón para configurar clave(BTNL)
        btn_enter_m1  : in  std_logic;                  -- Botón para confirmar entrada(BTNC)
        sw_m1         : in  std_logic_vector(3 downto 0); -- Switches con la clave(SW0-SW3)
        leds_m1       : out std_logic_vector(2 downto 0); -- LEDs para intentos restantes
        seg_m1        : out std_logic_vector(6 downto 0); -- Segmentos del display
        an_m1         : out std_logic_vector(3 downto 0); -- Ánodos del display
        clave_correcta_m1 : out std_logic               -- Señal que habilita el módulo 2
    );
end entity;

architecture Behavioral of seguridad_autenticacion is

--------------------------------------------------------------------------
-- ESTADOS
--------------------------------------------------------------------------
type state_t is (
    S_CONFIG, --El usuario define la clave
    S_VERIFY, --El usuario intenta ingresar la clave
    S_CHECK,  --Se compara la clave ingresada con la guardada
    S_FAIL,   --Falló un intento
    S_LOCK,   --Sistema bloqueado y inicia la cuenta regresiva
    S_UNLOCK  --Estado final después de clave correcta
);
signal state : state_t := S_CONFIG;

--------------------------------------------------------------------------
-- VARIABLES
--------------------------------------------------------------------------
signal stored_key  : std_logic_vector(3 downto 0) := (others=>'0'); --Clave guardada
signal user_key    : std_logic_vector(3 downto 0) := (others=>'0'); --Clave ingresada
signal attempts    : integer range 0 to 3 := 3;                     --Intentos restantes

--------------------------------------------------------------------------
-- TIMER 1 Hz
--------------------------------------------------------------------------
constant ONEHZ : integer := 100_000_000 - 1;
signal div_cnt    : unsigned(31 downto 0) := (others=>'0');
signal tick_1Hz   : std_logic := '0';
signal lock_count : integer range 0 to 30 := 30;

--------------------------------------------------------------------------
-- DISPLAY
--------------------------------------------------------------------------
signal mux_cnt  : unsigned(15 downto 0) := (others=>'0');
signal mux_tick : std_logic := '0';

type digit_array_t is array (0 to 3) of integer range -1 to 9;
signal digit_vals : digit_array_t := (-1, -1, -1, -1);
--Genera refresco del display a ~1kHz, ademas digit_vals contiene los valores 
--que se mostrarán en cada dígito.

signal disp_idx : integer range 0 to 3 := 0;
signal seg_raw : std_logic_vector(6 downto 0) := (others=>'1');
signal an_out  : std_logic_vector(3 downto 0) := (others=>'1');

type an_map_t is array (0 to 3) of std_logic_vector(3 downto 0);
constant AN_MAP : an_map_t := (
    0 => "0111",
    1 => "1011",
    2 => "1101",
    3 => "1110"
);
--Mapa para seleccionar el display correcto en la Basys 3.

--------------------------------------------------------------------------
-- ANTIREBOTE ENTER
--------------------------------------------------------------------------
signal btn_enter_ff : std_logic := '0';
signal btn_enter_r  : std_logic := '0';
--Detecta flanco de subida limpio evitando múltiples lecturas.

begin

--------------------------------------------------------------------------
-- ANTIREBOTE
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then
        btn_enter_r <= '0';
        if (btn_enter_ff = '0') and (btn_enter_m1 = '1') then
            btn_enter_r <= '1';
        end if;
        btn_enter_ff <= btn_enter_m1;
    end if;
end process;

--------------------------------------------------------------------------
-- DIVISOR 1 Hz
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then
        if rst_m1='1' then
            div_cnt  <= (others=>'0');
            tick_1Hz <= '0';
        else
            if div_cnt = to_unsigned(ONEHZ, 32) then
                div_cnt  <= (others=>'0');
                tick_1Hz <= '1';
            else
                div_cnt  <= div_cnt + 1;
                tick_1Hz <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- MÁQUINA DE ESTADOS
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then

        if rst_m1='1' then
            state <= S_CONFIG;
            attempts <= 3;
            stored_key <= (others=>'0');
            clave_correcta_m1 <= '0';

        else

            case state is

                ------------------------------------------------------------------
                -- CONFIGURAR CLAVE
                ------------------------------------------------------------------
                when S_CONFIG =>
                    clave_correcta_m1 <= '0';
                    if btn_enter_r='1' then
                        stored_key <= sw_m1;
                        attempts <= 3;
                        state <= S_VERIFY;
                    end if;

                ------------------------------------------------------------------
                -- INGRESAR CLAVE
                ------------------------------------------------------------------
                when S_VERIFY =>
                    if btn_config_m1='1' then
                        state <= S_CONFIG;
                    elsif btn_enter_r='1' then
                        user_key <= sw_m1;
                        state <= S_CHECK;
                    end if;

                ------------------------------------------------------------------
                -- COMPARAR
                ------------------------------------------------------------------
                when S_CHECK =>
                    if user_key = stored_key then
                        clave_correcta_m1 <= '1';   -- ← ESTABLE EN 1
                        attempts <= 3;
                        state <= S_UNLOCK;       -- ← Estado final estable
                    else
                        if attempts > 0 then
                            attempts <= attempts - 1;
                        end if;

                        if attempts = 1 then
                            lock_count <= 30;
                            state <= S_LOCK;
                        else
                            state <= S_FAIL;
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- FALLO NORMAL
                ------------------------------------------------------------------
                when S_FAIL =>
                    state <= S_VERIFY;

                ------------------------------------------------------------------
                -- BLOQUEO 30s
                ------------------------------------------------------------------
                when S_LOCK =>
                    if tick_1Hz='1' then
                        if lock_count > 0 then
                            lock_count <= lock_count - 1;
                        else
                            attempts <= 3;
                            state <= S_VERIFY;
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- ESTADO FINAL DESPUÉS DE ACIERTO
                ------------------------------------------------------------------
                when S_UNLOCK =>
                    -- Una vez aquí, NO se regresa jamás
                    clave_correcta_m1 <= '1';
                    state <= S_UNLOCK;

            end case;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- LEDS SEGÚN INTENTOS
--------------------------------------------------------------------------
with attempts select
    leds_m1 <= "111" when 3,
            "110" when 2,
            "100" when 1,
            "000" when others;

--------------------------------------------------------------------------
-- MUX DISPLAY 1 kHz
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then
        if mux_cnt = 9999 then
            mux_cnt  <= (others=>'0');
            mux_tick <= '1';
        else
            mux_cnt  <= mux_cnt + 1;
            mux_tick <= '0';
        end if;
    end if;
end process;
--Refresca cada dígito a 1 kHz para evitar parpadeo
-- y Solo muestra algo cuando el sistema está BLOQUEADO.
        
--------------------------------------------------------------------------
-- DISPLAY BLOQUEO
--------------------------------------------------------------------------
process(clk100_m1)
    variable dig  : integer;
    variable segv : std_logic_vector(6 downto 0);
    variable val  : integer;
begin
    if rising_edge(clk100_m1) then

        if mux_tick='1' then
            if disp_idx = 3 then
                disp_idx <= 0;
            else
                disp_idx <= disp_idx + 1;
            end if;
        end if;

        val := lock_count;

        digit_vals(0) <= -1;
        digit_vals(1) <= -1;
        digit_vals(2) <= val / 10;
        digit_vals(3) <= val mod 10;

        dig := digit_vals(disp_idx);

        case dig is
            when 0 => segv := "0000001";
            when 1 => segv := "1001111";
            when 2 => segv := "0010010";
            when 3 => segv := "0000110";
            when 4 => segv := "1001100";
            when 5 => segv := "0100100";
            when 6 => segv := "0100000";
            when 7 => segv := "0001111";
            when 8 => segv := "0000000";
            when 9 => segv := "0000100";
            when others => segv := "1111111";
        end case;
--Tabla completa de números del 0 al 9,
--Si el dígito es -1 → display apagado.
        seg_raw <= segv;

        if state = S_LOCK then
            an_out <= AN_MAP(disp_idx);
        else
            an_out <= "1111";
        end if;

    end if;
end process;

an_m1  <= an_out;
seg_m1 <= seg_raw;
--Se envían al display 7 segmentos.
end Behavioral;
