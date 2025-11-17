library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_seguridad is
end entity;

architecture sim of tb_seguridad is

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
    -- Instancia del módulo DUT
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
    -- Reloj 100 MHz
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk100 <= '0';
        wait for 5 ns;
        clk100 <= '1';
        wait for 5 ns;
    end process;

    --------------------------------------------------------------------
    -- ESTÍMULOS (SIN PROCEDURES)
    --------------------------------------------------------------------
    stim_proc : process
    begin

        --------------------------------------------------------
        -- RESET
        --------------------------------------------------------
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        --------------------------------------------------------
        -- CONFIGURAR CLAVE 1010
        --------------------------------------------------------
        sw <= "1010";
        btn_enter <= '1';
        wait for 20 ns;
        btn_enter <= '0';
        wait for 200 ns;

        --------------------------------------------------------
        -- INTENTO INCORRECTO 1
        --------------------------------------------------------
        sw <= "0001";
        btn_enter <= '1';
        wait for 20 ns;
        btn_enter <= '0';
        wait for 200 ns;

        --------------------------------------------------------
        -- INTENTO INCORRECTO 2
        --------------------------------------------------------
        sw <= "0011";
        btn_enter <= '1';
        wait for 20 ns;
        btn_enter <= '0';
        wait for 200 ns;

        --------------------------------------------------------
        -- INTENTO INCORRECTO 3 → LOCK
        --------------------------------------------------------
        sw <= "1111";
        btn_enter <= '1';
        wait for 20 ns;
        btn_enter <= '0';

        --------------------------------------------------------
        -- ESPERAR A QUE TERMINE EL BLOQUEO
        -- (tu versión de simulación debe tener contadores pequeños)
        --------------------------------------------------------
        wait for 5 ms;

        --------------------------------------------------------
        -- CLAVE CORRECTA
        --------------------------------------------------------
        sw <= "1010";
        btn_enter <= '1';
        wait for 20 ns;
        btn_enter <= '0';
        wait for 200 ns;

        --------------------------------------------------------
        -- FIN
        --------------------------------------------------------
        report "Fin de simulación" severity note;
        wait;

    end process;

end architecture;

