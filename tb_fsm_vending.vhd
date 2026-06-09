library ieee;
use ieee.std_logic_1164.all;

entity tb_fsm_vending is
end entity tb_fsm_vending;

architecture sim of tb_fsm_vending is

    -- Sinais para conectar na FSM
    signal clk_tb         : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal moeda_25_tb    : std_logic := '0';
    signal moeda_50_tb    : std_logic := '0';
    signal moeda_100_tb   : std_logic := '0';
    signal compra_ok_tb   : std_logic := '0';
    
    signal ctrl_soma_tb   : std_logic;
    signal ctrl_zera_tb   : std_logic;
    signal ctrl_libera_tb : std_logic;

    -- Constante para o período do clock (50 MHz)
    constant clk_period : time := 20 ns;

begin

    -- Instancia a FSM que criamos
    uut: entity work.fsm_vending
        port map (
            clk         => clk_tb,
            reset       => reset_tb,
            moeda_25    => moeda_25_tb,
            moeda_50    => moeda_50_tb,
            moeda_100   => moeda_100_tb,
            compra_ok   => compra_ok_tb,
            ctrl_soma   => ctrl_soma_tb,
            ctrl_zera   => ctrl_zera_tb,
            ctrl_libera => ctrl_libera_tb
        );

    -- Processo gerador de Clock infinito
    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- Processo de estímulos (Simulando o usuário)
    stim_process: process
    begin
        -- 1. Reset inicial
        reset_tb <= '1';
        wait for 40 ns;
        reset_tb <= '0';
        wait for 40 ns;

        -- 2. Insere moeda de R$ 0,50
        moeda_50_tb <= '1';
        wait for 40 ns; -- Mantém pressionado um pouco
        moeda_50_tb <= '0'; -- Solta a moeda
        wait for 60 ns;

        -- 3. Insere moeda de R$ 1,00
        moeda_100_tb <= '1';
        wait for 40 ns;
        moeda_100_tb <= '0';
        wait for 60 ns;

        -- 4. Simula o Datapath avisando que o saldo foi atingido
        compra_ok_tb <= '1';
        wait for 100 ns;

        -- 5. Finaliza a simulação
        compra_ok_tb <= '0';
        wait;
    end process;

end architecture sim;