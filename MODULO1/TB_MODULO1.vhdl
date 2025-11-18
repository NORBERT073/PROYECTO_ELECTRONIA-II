library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_seguridad_autenticacion is
end entity;

architecture sim of tb_seguridad_autenticacion is

    -- Señales para conectar al DUT
    signal clk100_m1     : std_logic := '0';
    signal rst_m1        : std_logic := '1';
    signal btn_config_m1 : std_logic := '0';
    signal btn_enter_m1  : std_logic := '0';
    signal sw_m1         : std_logic_vector(3 downto 0) := (others => '0');

    signal leds_m1       : std_logic_vector(2 downto 0);
    signal seg_m1        : std_logic_vector(6 downto 0);
    signal an_m1         : std_logic_vector(3 downto 0);
    signal clave_correcta_m1 : std_logic;

begin

    ----------------------------------------------------------
    -- INSTANCIA DEL MÓDULO A PROBAR
    ----------------------------------------------------------
    DUT: entity work.seguridad_autenticacion
        port map(
            clk100_m1     => clk100_m1,
            rst_m1        => rst_m1,
            btn_config_m1 => btn_config_m1,
            btn_enter_m1  => btn_enter_m1,
            sw_m1         => sw_m1,
            leds_m1       => leds_m1,
            seg_m1        => seg_m1,
            an_m1         => an_m1,
            clave_correcta_m1 => clave_correcta_m1
        );

    ----------------------------------------------------------
    -- GENERADOR DE RELOJ 100 MHz (10 ns periodo)
    ----------------------------------------------------------
    clk_process : process
    begin
        clk100_m1 <= '0';
        wait for 5 ns;
        clk100_m1 <= '1';
        wait for 5 ns;
    end process;

    ----------------------------------------------------------
    -- ESTÍMULOS
    ----------------------------------------------------------
    stim_proc : process
    begin

        -- RESET INICIAL
        rst_m1 <= '1';
        wait for 50 ns;
        rst_m1 <= '0';
        wait for 50 ns;

        ------------------------------------------------------
        -- CONFIGURAR CLAVE: 1010
        ------------------------------------------------------
        sw_m1 <= "1010";
        btn_enter_m1 <= '1';  -- Pulse enter
        wait for 20 ns;
        btn_enter_m1 <= '0';
        wait for 200 ns;

        ------------------------------------------------------
        -- INTENTO 1 (INCORRECTO)
        ------------------------------------------------------
        sw_m1 <= "0001";       -- incorrecto
        btn_enter_m1 <= '1';
        wait for 20 ns;
        btn_enter_m1 <= '0';
        wait for 200 ns;

        ------------------------------------------------------
        -- INTENTO 2 (INCORRECTO)
        ------------------------------------------------------
        sw_m1 <= "1111";       -- incorrecto
        btn_enter_m1 <= '1';
        wait for 20 ns;
        btn_enter_m1 <= '0';
        wait for 200 ns;

        ------------------------------------------------------
        -- INTENTO CORRECTO
        ------------------------------------------------------
        sw_m1 <= "1010";       -- correcto
        btn_enter_m1 <= '1';
        wait for 20 ns;
        btn_enter_m1 <= '0';

        wait for 200 ns;

        ------------------------------------------------------
        -- FIN DE LA PRUEBA
        ------------------------------------------------------
        wait;
    end process;

end architecture;
