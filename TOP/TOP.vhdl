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

    -- Señal directa del módulo 1
    signal clave_correcta_sig : std_logic := '0';

    -- Salidas módulo 1
    signal leds_m1 : std_logic_vector(2 downto 0);
    signal seg_m1  : std_logic_vector(6 downto 0);
    signal an_m1   : std_logic_vector(3 downto 0);

    -- Salidas módulo 2
    signal leds_m2 : std_logic_vector(4 downto 0);
    signal seg_m2  : std_logic_vector(6 downto 0);
    signal an_m2   : std_logic_vector(3 downto 0);

begin

    ---------------------------------------------------------------------
    -- INSTANCIA MÓDULO 1
    ---------------------------------------------------------------------
    U1: entity work.seguridad_autenticacion
        port map(
            clk100_m1     => clk100,
            rst_m1        => rst,
            btn_config_m1 => btnL,
            btn_enter_m1  => btnC,
            sw_m1         => sw,
            leds_m1       => leds_m1,
            seg_m1        => seg_m1,
            an_m1         => an_m1,
            clave_correcta_m1 => clave_correcta_sig
        );

    ---------------------------------------------------------------------
    -- INSTANCIA MÓDULO 2
    ---------------------------------------------------------------------
    U2: entity work.adivina_numero
        port map(
            clk_m2      => clk100,
            reset_m2    => rst,
            habilitar_m2 => clave_correcta_sig,
            sw_m2       => sw,
            btnc_m2     => btnC,
            leds_m2     => leds_m2,
            seg_m2      => seg_m2,
            an_m2       => an_m2
        );

    ---------------------------------------------------------------------
    -- SELECCIONAR SALIDA SEGÚN MÓDULO ACTIVO
    ---------------------------------------------------------------------
    leds <= 
        ("00" & leds_m1) when clave_correcta_sig = '0' else
        leds_m2;

    seg <= seg_m1 when clave_correcta_sig = '0' else seg_m2;
    an  <= an_m1  when clave_correcta_sig = '0' else an_m2;

end Structural;
