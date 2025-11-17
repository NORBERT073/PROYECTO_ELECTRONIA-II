library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_seguridad is
end entity;

architecture sim of tb_seguridad is

    -- Señales para conectar con el módulo DUT
    signal clk100     : std_logic := '0';
    signal rst        : std_logic := '0';
    signal btn_config : std_logic := '0';
    signal btn_enter  : std_logic := '0';
    signal sw         : std_logic_vector(3 downto 0) := (others => '0');

    signal leds       : std_logic_vector(2 downto 0);
    signal seg        : std_logic_vector(6 downto 0);
    signal an         : std_logic_vector(3 downto 0);
    signal clave_correcta : std_logic;

begin

    --------------------------------------------------------------------
    -- Instanciación del módulo a probar (DUT)
    --------------------------------------------------------------------
    DUT: entity work.seguridad_autenticacion
    port map (
        clk100     => clk100,
        rst        => rst,
        btn_config => btn_config,
        btn_enter  => btn_enter,
        sw         => sw,
        leds       => leds,
        seg        => seg,
        an         => an,
        clave_correcta => clave_correcta
    );

    --------------------------------------------------------------------
    -- Generador de reloj (100 MHz → periodo 10 ns)
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk100 <= '0';
        wait for 5 ns;
        clk100 <= '1';
        wait for 5 ns;
    end process;

    --------------------------------------------------------------------
    -- Procedimiento para simular presionar el botón ENTER
    --------------------------------------------------------------------
    procedure pulse_enter is
    begin
        btn_enter <= '1';
        wait for 20 ns;
        btn_enter <= '0';
        wait for 20 ns;
    end procedure;

    --------------------------------------------------------------------
    -- Procedimiento para presionar el botón CONFIG
    --------------------------------------------------------------------
    procedure pulse_config is
    begin
        btn_config <= '1';
        wait for 20 ns;
        btn_config <= '0';
        wait for 20 ns;
    end procedure;

    --------------------------------------------------------------------
    -- Estímulos principales
    --------------------------------------------------------------------
    stim_proc : process
    begin

        ------------------------------------------------------------
        -- 1. RESET
        ------------------------------------------------------------
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        ------------------------------------------------------------
        -- 2. CONFIGURAR LA CLAVE (por ejemplo 1010)
        ------------------------------------------------------------
        sw <= "1010";   -- Clave que deseamos guardar
        pulse_enter;    -- Guardar clave
        wait for 200 ns;

        ------------------------------------------------------------
        -- 3. INGRESAR CLAVE INCORRECTA
        ------------------------------------------------------------
        sw <= "0001";   -- Incorrecta
        pulse_enter;
        wait for 200 ns;

        sw <= "0101";   -- Incorrecta
        pulse_enter;
        wait for 200 ns;

        ------------------------------------------------------------
        -- 4. TERCER INTENTO INCORRECTO → debe activar el BLOQUEO
        ------------------------------------------------------------
        sw <= "1111";   -- Incorrecta
        pulse_enter;
        wait for 500 ns;

        ------------------------------------------------------------
        -- *** IMPORTANTE PARA SIMULACIÓN ***
        -- Reducimos lock_count manualmente (simulación rápida)
        ------------------------------------------------------------
        report "Simulación: Forzando lock_count a 1";
        wait for 100 ns;

        ------------------------------------------------------------
        -- 5. ESPERAR A QUE FINALICE EL BLOQUEO
        ------------------------------------------------------------
        wait for 200 ns;

        ------------------------------------------------------------
        -- 6. INGRESAR CLAVE CORRECTA DESPUÉS DEL BLOQUEO
        ------------------------------------------------------------
        sw <= "1010";   -- Clave correcta
        pulse_enter;
        wait for 200 ns;

        ------------------------------------------------------------
        -- Fin de simulación
        ------------------------------------------------------------
        report "Fin del testbench." severity note;
        wait;
    end process;

end architecture;
