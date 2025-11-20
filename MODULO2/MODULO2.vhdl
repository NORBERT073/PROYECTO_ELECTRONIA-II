--------------------------------------------------------------------------
-- LIBRERIAS
--------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------------
-- ENTIDAD
-- Módulo “Adivina el Número”:
-- - Genera número pseudoaleatorio
-- - Compara intentos del usuario
-- - Muestra SUBE / BAJA / OH / FAIL
-- - Maneja bloqueo de 15 s
-- - Controla displays y LEDs
--------------------------------------------------------------------------
entity adivina_numero is
    Port ( 
        clk_m2 : in STD_LOGIC;
        reset_m2 : in STD_LOGIC;
        habilitar_m2 : in STD_LOGIC;  -- solo funciona si el módulo 1 habilita
        sw_m2 : in STD_LOGIC_VECTOR (3 downto 0);  -- intento ingresado
        btnc_m2 : in STD_LOGIC;  -- ENTER del intento
        leds_m2 : out STD_LOGIC_VECTOR (4 downto 0);
        seg_m2 : out STD_LOGIC_VECTOR (6 downto 0);
        an_m2  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end adivina_numero;

architecture Behavioral of adivina_numero is

--------------------------------------------------------------------------
-- TIPOS Y SEÑALES PRINCIPALES
-- Máquina de estados del juego
--------------------------------------------------------------------------
type estado_juego is (
    INICIO, ESPERANDO_INTENTO, VALIDAR_INTENTO,
    MOSTRAR_SUBE, MOSTRAR_BAJA, MOSTRAR_OH,
    MOSTRAR_FAIL, BLOQUEO, REINICIO
);
signal estado_actual : estado_juego := INICIO;

-- Intentos y número objetivo
signal numero_objetivo : STD_LOGIC_VECTOR (3 downto 0) := "0000";
signal intento_actual  : STD_LOGIC_VECTOR (3 downto 0) := "0000";
signal intentos_restantes : integer range 0 to 5 := 5;

-- Contadores de tiempo para duración de mensajes y bloqueo
signal contador_segundos : integer range 0 to 15 := 0;
signal contador_tiempo   : integer range 0 to 100000000 := 0;
signal tiempo_cumplido   : std_logic := '0';

-- Multiplexado del display
signal contador_display : unsigned(19 downto 0) := (others => '0');
signal display_index : integer range 0 to 3 := 0;

-- Antirrebote del botón
signal btnc_sync : STD_LOGIC := '0';
signal btnc_prev : STD_LOGIC := '0';

-- Buffers para 7 segmentos
signal seg0, seg1, seg2, seg3 : STD_LOGIC_VECTOR (6 downto 0) := (others => '1');

-- Registro de LEDs
signal led_reg : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');

-- LFSR (pseudoaleatorio)
signal rnd_reg : unsigned(3 downto 0) := "1101";  -- semilla válida

constant ONE_SECOND : integer := 100000000;

--------------------------------------------------------------------------
-- FUNCIÓN DE DÍGITOS A DISPLAY 7 SEGMENTOS
--------------------------------------------------------------------------
function to_7seg(digit : in integer range 0 to 15)
return STD_LOGIC_VECTOR is
begin
    case digit is
        when 0 => return "0000001";
        when 1 => return "1001111";
        when 2 => return "0010010";
        when 3 => return "0000110";
        when 4 => return "1001100";
        when 5 => return "0100100";
        when 6 => return "0100000";
        when 7 => return "0001111";
        when 8 => return "0000000";
        when 9 => return "0000100";
        when others => return "1111111";
    end case;
end function;

begin

--------------------------------------------------------------------------
-- ANTIRREBOTE Y DETECCIÓN DE FLANCO DEL BOTÓN ENTER
--------------------------------------------------------------------------
process(clk_m2)
begin
    if rising_edge(clk_m2) then
        if reset_m2 = '1' then
            btnc_prev <= '0';
            btnc_sync <= '0';
        else
            btnc_prev <= btnc_m2;
            -- Detecta flanco ascendente (presión del botón)
            if (btnc_m2 = '1') and (btnc_prev = '0') then
                btnc_sync <= '1';
            else
                btnc_sync <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- MÁQUINA DE ESTADOS PRINCIPAL DEL JUEGO
--------------------------------------------------------------------------
process(clk_m2, reset_m2)
begin
    if reset_m2 = '1' then
        -- Reset general del juego
        estado_actual <= INICIO;
        intentos_restantes <= 5;
        numero_objetivo <= "0000";
        intento_actual <= "0000";
        contador_tiempo <= 0;
        contador_segundos <= 0;
        tiempo_cumplido <= '0';
        rnd_reg <= to_unsigned(3, 4);
        led_reg <= (others => '0');
        
    elsif rising_edge(clk_m2) then

        -- Pulso de 1 segundo
        tiempo_cumplido <= '0';
        if contador_tiempo < ONE_SECOND - 1 then
            contador_tiempo <= contador_tiempo + 1;
        else
            contador_tiempo <= 0;
            tiempo_cumplido <= '1';
        end if;

        -- Si módulo está deshabilitado, reinicia
        if habilitar_m2 = '0' then
            estado_actual <= INICIO;
            intentos_restantes <= 5;
            contador_tiempo <= 0;
            contador_segundos <= 0;
            led_reg <= (others => '0');

        else
            --------------------------------------------------------------
            -- CONTROL GENERAL DE ESTADOS
            --------------------------------------------------------------
            case estado_actual is

                ------------------------------------------------------------------
                -- INICIO: generar número pseudoaleatorio
                ------------------------------------------------------------------
                when INICIO =>
                    -- LFSR real
                    rnd_reg <= rnd_reg(2 downto 0) & (rnd_reg(3) xor rnd_reg(2));

                    -- Evitar número 0
                    if rnd_reg = "0000" then
                        rnd_reg <= "1101";
                    end if;

                    numero_objetivo <= std_logic_vector(rnd_reg);

                    -- Reinicio de intentos y LEDs
                    intentos_restantes <= 5;
                    led_reg <= "11111";

                    estado_actual <= ESPERANDO_INTENTO;

                ------------------------------------------------------------------
                -- ESPERAR al usuario presionar ENTER
                ------------------------------------------------------------------
                when ESPERANDO_INTENTO =>
                    if btnc_sync = '1' then
                        intento_actual <= sw_m2;
                        estado_actual <= VALIDAR_INTENTO;
                    end if;

                ------------------------------------------------------------------
                -- VERIFICAR intento ingresado
                ------------------------------------------------------------------
                when VALIDAR_INTENTO =>
                    if intento_actual = numero_objetivo then
                        estado_actual <= MOSTRAR_OH;
                    elsif unsigned(intento_actual) < unsigned(numero_objetivo) then
                        intentos_restantes <= intentos_restantes - 1;
                        estado_actual <= MOSTRAR_SUBE;
                    else
                        intentos_restantes <= intentos_restantes - 1;
                        estado_actual <= MOSTRAR_BAJA;
                    end if;

                ------------------------------------------------------------------
                -- MOSTRAR SUBE / BAJA por 1 segundo
                ------------------------------------------------------------------
                when MOSTRAR_SUBE | MOSTRAR_BAJA =>
                    -- Actualiza LEDs según intentos restantes
                    case intentos_restantes is
                        when 5 => led_reg <= "11111";
                        when 4 => led_reg <= "01111";
                        when 3 => led_reg <= "00111";
                        when 2 => led_reg <= "00011";
                        when 1 => led_reg <= "00001";
                        when others => led_reg <= "00000";
                    end case;

                    if tiempo_cumplido = '1' then
                        if intentos_restantes = 0 then
                            estado_actual <= MOSTRAR_FAIL;
                        else
                            estado_actual <= ESPERANDO_INTENTO;
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- MOSTRAR "OH" cuando acierta
                ------------------------------------------------------------------
                when MOSTRAR_OH =>
                    led_reg <= "11111";
                    if tiempo_cumplido = '1' then
                        estado_actual <= REINICIO;
                    end if;

                ------------------------------------------------------------------
                -- MOSTRAR FAIL 3 segundos
                ------------------------------------------------------------------
                when MOSTRAR_FAIL =>
                    led_reg <= "00000";

                    if tiempo_cumplido = '1' then
                        if contador_segundos < 3 then
                            contador_segundos <= contador_segundos + 1;
                        else
                            contador_segundos <= 15; -- para bloqueo
                            estado_actual <= BLOQUEO;
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- BLOQUEO 15 segundos
                ------------------------------------------------------------------
                when BLOQUEO =>
                    if tiempo_cumplido = '1' then
                        if contador_segundos > 0 then
                            contador_segundos <= contador_segundos - 1;
                        else
                            estado_actual <= REINICIO;
                        end if;
                    end if;

                ------------------------------------------------------------------
                -- REINICIO COMPLETO
                ------------------------------------------------------------------
                when REINICIO =>
                    estado_actual <= INICIO;

                when others =>
                    estado_actual <= INICIO;

            end case;
        end if;
    end if;
end process;

-- LEDS hacia salida
leds_m2 <= led_reg;

--------------------------------------------------------------------------
-- MULTIPLEXADO DE DISPLAYS + MENSAJES DE TEXTO
--------------------------------------------------------------------------
process(clk_m2)
begin
    if rising_edge(clk_m2) then

        -- Contador para refresco del display
        if contador_display < 100000 then
            contador_display <= contador_display + 1;
        else
            contador_display <= (others => '0');
            if display_index < 3 then
                display_index <= display_index + 1;
            else
                display_index <= 0;
            end if;
        end if;

        --------------------------------------------------------------
        -- TEXTO A MOSTRAR SEGÚN ESTADO DEL JUEGO
        --------------------------------------------------------------
        if habilitar_m2 = '0' then
            seg0 <= "1111111";
            seg1 <= "1111111";
            seg2 <= "1111111";
            seg3 <= "1111111";

        else
            case estado_actual is

                when INICIO | ESPERANDO_INTENTO =>
                    seg0 <= "1111110"; -- -
                    seg1 <= "1111110";
                    seg2 <= "1111110";
                    seg3 <= "1111110";

                when MOSTRAR_SUBE =>
                    seg0 <= "0110000"; -- E
                    seg1 <= "1100000"; -- b
                    seg2 <= "1000001"; -- U
                    seg3 <= "0100100"; -- S

                when MOSTRAR_BAJA =>
                    seg0 <= "0001000"; -- A
                    seg1 <= "1000011"; -- J
                    seg2 <= "0001000"; -- A
                    seg3 <= "1100000"; -- b

                when MOSTRAR_OH =>
                    seg0 <= "0110000"; -- E
                    seg1 <= "0110001"; -- C
                    seg2 <= "1111001"; -- I
                    seg3 <= "0001001"; -- N

                when MOSTRAR_FAIL =>
                    seg0 <= "1110001"; -- L
                    seg1 <= "1001111"; -- I
                    seg2 <= "0001000"; -- A
                    seg3 <= "0111000"; -- F

                when BLOQUEO =>
                    if contador_segundos >= 10 then
                        seg0 <= to_7seg(contador_segundos mod 10);
                        seg1 <= to_7seg(contador_segundos / 10);
                        seg2 <= "1111111";
                        seg3 <= "1111111";
                    else
                        seg0 <= to_7seg(contador_segundos);
                        seg1 <= "1111111";
                        seg2 <= "1111111";
                        seg3 <= "1111111";
                    end if;

                when others =>
                    seg0 <= "1111111";
                    seg1 <= "1111111";
                    seg2 <= "1111111";
                    seg3 <= "1111111";
            end case;
        end if;

        --------------------------------------------------------------
        -- MUX PARA ILUMINAR UN DISPLAY A LA VEZ
        --------------------------------------------------------------
        case display_index is
            when 0 => an_m2 <= "1110"; seg_m2 <= seg0;
            when 1 => an_m2 <= "1101"; seg_m2 <= seg1;
            when 2 => an_m2 <= "1011"; seg_m2 <= seg2;
            when 3 => an_m2 <= "0111"; seg_m2 <= seg3;
            when others =>
                an_m2 <= "1111";
                seg_m2 <= "1111111";
        end case;

    end if;
end process;

end Behavioral;
