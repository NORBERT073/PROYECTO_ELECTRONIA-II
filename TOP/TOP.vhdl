library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_final is
    port(
        clk100  : in  std_logic;
        rst     : in  std_logic;
        sw      : in  std_logic_vector(3 downto 0);
        btnC    : in  std_logic;
        btnL    : in  std_logic;
        leds    : out std_logic_vector(4 downto 0);
        seg     : out std_logic_vector(6 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end entity;

architecture Structural of top_final is

    ---------------------------------------------------------------------
    -- Señales internas para conectar los dos módulos
    ---------------------------------------------------------------------
    signal clave_correcta_sig : std_logic := '0'; -- Activa el módulo 2

    -- Salidas del módulo 1 (3 LEDs + displays)
    signal leds_m1 : std_logic_vector(2 downto 0);
    signal seg_m1  : std_logic_vector(6 downto 0);
    signal an_m1   : std_logic_vector(3 downto 0);

    -- Salidas del módulo 2 (5 LEDs + displays)
    signal leds_m2 : std_logic_vector(4 downto 0);
    signal seg_m2  : std_logic_vector(6 downto 0);
    signal an_m2   : std_logic_vector(3 downto 0);

    -- Reset sincronizado para evitar glitches
    signal reset_sync : std_logic := '0';

begin

    ---------------------------------------------------------------------
    -- SINCRONIZACIÓN DEL RESET
    -- Se usa para garantizar que 'rst' cambie solo en un flanco de reloj.
    ---------------------------------------------------------------------
    process(clk100)
    begin
        if rising_edge(clk100) then
            reset_sync <= rst;
        end if;
    end process;

    ---------------------------------------------------------------------
    -- INSTANCIA DEL MÓDULO 1: seguridad_autenticacion
    -- Este módulo se usa primero. Si la clave es correcta, activa módulo 2.
    ---------------------------------------------------------------------
    U1: entity work.seguridad_autenticacion
        port map(
            clk100_m1        => clk100,
            rst_m1           => reset_sync,
            btn_config_m1    => btnL,      -- Botón para configurar clave
            btn_enter_m1     => btnC,      -- Botón para confirmar clave
            sw_m1            => sw,        -- Entrada de 4 bits de switches
            leds_m1          => leds_m1,   -- LEDs del módulo 1
            seg_m1           => seg_m1,    -- Display del módulo 1
            an_m1            => an_m1,
            clave_correcta_m1 => clave_correcta_sig -- Habilita módulo 2
        );

    ---------------------------------------------------------------------
    -- INSTANCIA DEL MÓDULO 2: adivina_numero
    -- Solo funciona cuando clave_correcta_sig = '1'.
    ---------------------------------------------------------------------
    U2: entity work.adivina_numero
        port map(
            clk_m2       => clk100,
            reset_m2     => reset_sync,
            habilitar_m2 => clave_correcta_sig, -- Activación desde módulo 1
            sw_m2        => sw,
            btnc_m2      => btnC,               -- Se reutiliza el botón
            leds_m2      => leds_m2,
            seg_m2       => seg_m2,
            an_m2        => an_m2
        );

    ---------------------------------------------------------------------
    -- MULTIPLEXACIÓN DE SALIDAS
    -- Antes de acertar la clave → se muestran LEDs y displays del módulo 1
    -- Después de acertar → se muestran LEDs y displays del módulo 2
    ---------------------------------------------------------------------
    leds <= ("00" & leds_m1) when clave_correcta_sig = '0' else leds_m2;
    seg  <= seg_m1           when clave_correcta_sig = '0' else seg_m2;
    an   <= an_m1            when clave_correcta_sig = '0' else an_m2;

end Structural;
