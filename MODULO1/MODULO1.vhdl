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
        clk100_m1     : in  std_logic;                   -- Reloj principal 100 MHz
        rst_m1        : in  std_logic;                   -- Reset global
        btn_config_m1 : in  std_logic;                   -- Botón para reconfigurar clave
        btn_enter_m1  : in  std_logic;                   -- Botón ENTER con antirrebote
        sw_m1         : in  std_logic_vector(3 downto 0);-- Entrada de clave (SW0-SW3)
        leds_m1       : out std_logic_vector(2 downto 0);-- LEDs que muestran intentos restantes
        seg_m1        : out std_logic_vector(6 downto 0);-- Segmentos display
        an_m1         : out std_logic_vector(3 downto 0);-- Ánodos display
        clave_correcta_m1 : out std_logic                -- Señal que habilita módulo 2
    );
end entity;

architecture Behavioral of seguridad_autenticacion is

--------------------------------------------------------------------------
-- ESTADOS DE LA FSM
--------------------------------------------------------------------------
type state_t is (
    S_CONFIG,    -- Configuración inicial de clave
    S_VERIFY,    -- Ingreso de clave por el usuario
    S_CHECK,     -- Comparación entre clave ingresada y clave guardada
    S_FAIL,      -- Fallo normal
    S_LOCK,      -- Bloqueo por fallar demasiadas veces
    S_UNLOCK     -- Clave correcta → habilita módulo 2
);
signal state : state_t := S_CONFIG; -- Estado inicial

--------------------------------------------------------------------------
-- VARIABLES PRINCIPALES
--------------------------------------------------------------------------
signal stored_key  : std_logic_vector(3 downto 0) := (others=>'0'); -- Clave guardada
signal user_key    : std_logic_vector(3 downto 0) := (others=>'0'); -- Clave ingresada
signal attempts    : integer range 0 to 3 := 3;                     -- Intentos restantes

--------------------------------------------------------------------------
-- TIMER PARA GENERAR 1 Hz
--------------------------------------------------------------------------
constant ONEHZ : integer := 100_000_000 - 1; -- divisor de 100 MHz → 1 Hz
signal div_cnt    : unsigned(31 downto 0) := (others=>'0'); -- contador del divisor
signal tick_1Hz   : std_logic := '0';                       -- pulso de 1 Hz
signal lock_count : integer range 0 to 30 := 30;            -- contador del bloqueo

--------------------------------------------------------------------------
-- MUX DEL DISPLAY 7 SEG
--------------------------------------------------------------------------
signal mux_cnt  : unsigned(15 downto 0) := (others=>'0');
signal mux_tick : std_logic := '0';

-- Valores de cada dígito
type digit_array_t is array (0 to 3) of integer range -1 to 9;
signal digit_vals : digit_array_t := (-1, -1, -1, -1);

signal disp_idx : integer range 0 to 3 := 0;        -- índice activo
signal seg_raw : std_logic_vector(6 downto 0) := (others=>'1');
signal an_out  : std_logic_vector(3 downto 0) := (others=>'1');

-- Mapa de ánodos
type an_map_t is array (0 to 3) of std_logic_vector(3 downto 0);
constant AN_MAP : an_map_t := (
    0 => "0111",
    1 => "1011",
    2 => "1101",
    3 => "1110"
);

--------------------------------------------------------------------------
-- ANTIREBOTE DE ENTER
--------------------------------------------------------------------------
signal btn_enter_ff : std_logic := '0'; -- flip-flop 1
signal btn_enter_r  : std_logic := '0'; -- pulso limpio

begin

--------------------------------------------------------------------------
-- PROCESO ANTIREBOTE DEL BOTÓN ENTER
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then
        btn_enter_r <= '0';             -- por defecto, no hay pulso
        if (btn_enter_ff = '0') and (btn_enter_m1 = '1') then
            btn_enter_r <= '1';         -- detecta flanco limpio
        end if;
        btn_enter_ff <= btn_enter_m1;
    end if;
end process;

--------------------------------------------------------------------------
-- DIVISOR DE FRECUENCIA PARA GENERAR 1 Hz
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
                tick_1Hz <= '1';        -- pulso de un ciclo
            else
                div_cnt  <= div_cnt + 1;
                tick_1Hz <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- MAQUINA DE ESTADOS PRINCIPAL
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then

        -- RESET DEL SISTEMA
        if rst_m1='1' then
            state <= S_CONFIG;                 -- estado inicial
            attempts <= 3;                     -- reinicia intentos
            stored_key <= (others=>'0');       -- borra clave
            clave_correcta_m1 <= '0';          -- sin habilitar módulo 2

        else

            case state is

                ------------------------------------------------------------------
                -- ESTADO: CONFIGURAR CLAVE
                ------------------------------------------------------------------
                when S_CONFIG =>
                    clave_correcta_m1 <= '0';   -- aún NO habilita módulo 2
                    if btn_enter_r='1' then     -- enter presionado
                        stored_key <= sw_m1;    -- guarda la clave
                        attempts <= 3;          -- reinicia intentos
                        state <= S_VERIFY;      -- pasa a verificar
                    end if;

                ------------------------------------------------------------------
                -- ESTADO: INGRESAR CLAVE
                ------------------------------------------------------------------
                when S_VERIFY =>
                    if btn_config_m1='1' then   -- si presiona CONFIG
                        state <= S_CONFIG;      -- permite cambiar clave
                    elsif btn_enter_r='1' then
                        user_key <= sw_m1;      -- toma clave ingresada
                        state <= S_CHECK;       -- va a comparar
                    end if;

                ------------------------------------------------------------------
                -- ESTADO: COMPARAR CLAVES
                ------------------------------------------------------------------
                when S_CHECK =>
                    if user_key = stored_key then
                        clave_correcta_m1 <= '1';  -- clave correcta
                        attempts <= 3;
                        state <= S_UNLOCK;        -- estado final
                    else
                        if attempts > 0 then
                            attempts <= attempts - 1; -- reduce intento
                        end if;

                        if attempts = 1 then   -- si queda 1 → bloquear
                            lock_count <= 30;  -- 30 segundos
                            state <= S_LOCK;
                        else
                            state <= S_FAIL;   -- fallo normal
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- ESTADO: FALLO NORMAL (VUELVE A INGRESO)
                ------------------------------------------------------------------
                when S_FAIL =>
                    state <= S_VERIFY;

                ------------------------------------------------------------------
                -- ESTADO: BLOQUEO 30 SEGUNDOS
                ------------------------------------------------------------------
                when S_LOCK =>
                    if tick_1Hz='1' then
                        if lock_count > 0 then
                            lock_count <= lock_count - 1; -- cuenta regresiva
                        else
                            attempts <= 3;      -- restablece intentos
                            state <= S_VERIFY;  -- regresa a ingreso
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- ESTADO: CLAVE CORRECTA (FINAL PERMANENTE)
                ------------------------------------------------------------------
                when S_UNLOCK =>
                    clave_correcta_m1 <= '1';  -- habilita módulo 2
                    state <= S_UNLOCK;         -- estado permanente

            end case;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- LEDS SEGÚN INTENTOS RESTANTES
--------------------------------------------------------------------------
with attempts select
    leds_m1 <= "111" when 3,  -- 3 intentos
               "110" when 2,  -- 2 intentos
               "100" when 1,  -- 1 intento
               "000" when others; -- bloqueado

--------------------------------------------------------------------------
-- MUX DEL DISPLAY A 1 kHz
--------------------------------------------------------------------------
process(clk100_m1)
begin
    if rising_edge(clk100_m1) then
        if mux_cnt = 9999 then          -- genera tick de 1 kHz
            mux_cnt  <= (others=>'0');
            mux_tick <= '1';
        else
            mux_cnt  <= mux_cnt + 1;
            mux_tick <= '0';
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- LÓGICA DEL DISPLAY 7-SEG PARA MOSTRAR TIMER DE BLOQUEO
--------------------------------------------------------------------------
process(clk100_m1)
    variable dig  : integer;
    variable segv : std_logic_vector(6 downto 0);
    variable val  : integer;
begin
    if rising_edge(clk100_m1) then

        -- Selección del dígito activo
        if mux_tick='1' then
            if disp_idx = 3 then
                disp_idx <= 0;
            else
                disp_idx <= disp_idx + 1;
            end if;
        end if;

        -- valor del contador de bloqueo (solo en LOCK)
        val := lock_count;

        -- asignar dígitos
        digit_vals(0) <= -1;
        digit_vals(1) <= -1;
        digit_vals(2) <= val / 10;  -- decenas
        digit_vals(3) <= val mod 10;-- unidades

        dig := digit_vals(disp_idx);

        -- decodificador BCD a 7 segmentos
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
            when others => segv := "1111111"; -- display apagado
        end case;

        seg_raw <= segv;

        -- activar ánodos solo durante bloqueo
        if state = S_LOCK then
            an_out <= AN_MAP(disp_idx);
        else
            an_out <= "1111"; -- display apagado
        end if;

    end if;
end process;

-- Salidas finales del display
an_m1  <= an_out;
seg_m1 <= seg_raw;

end Behavioral;
