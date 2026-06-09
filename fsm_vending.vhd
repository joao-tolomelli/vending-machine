library ieee;
use ieee.std_logic_1164.all;

entity fsm_vending is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        moeda_25    : in std_logic;
        moeda_50    : in std_logic;
        moeda_100   : in std_logic;
        btn_comprar : in std_logic; 
        btn_retirar : in std_logic;
        compra_ok   : in std_logic;
        
        -- Sinal que avisa que todos os LEDs pararam de piscar
        fim_entrega : in std_logic; 
        
        ctrl_soma   : out std_logic;
        ctrl_zera   : out std_logic;
        ctrl_libera : out std_logic;
        ctrl_entrega: out std_logic -- Aciona as animações de luz
    );
end entity fsm_vending;

architecture bhv of fsm_vending is
    type state_type is (ESPERA, SOMA, ESPERA_SOLTAR, AVALIA, ESPERA_SOLTAR_BTN, AGUARDA_RETIRADA, ENTREGA, ZERA);
    signal state, next_state : state_type;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= ZERA;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    process(state, moeda_25, moeda_50, moeda_100, compra_ok, btn_retirar, btn_comprar, fim_entrega)
        variable tem_moeda : std_logic;
    begin
        ctrl_soma    <= '0';
        ctrl_zera    <= '0';
        ctrl_libera  <= '0';
        ctrl_entrega <= '0';
        next_state   <= state;
        
        tem_moeda := moeda_25 or moeda_50 or moeda_100;

        case state is
            when ESPERA =>
                if tem_moeda = '1' then
                    next_state <= SOMA;
                elsif btn_comprar = '1' then
                    next_state <= AVALIA;
                end if;

            when SOMA =>
                ctrl_soma <= '1';
                next_state <= ESPERA_SOLTAR;

            when ESPERA_SOLTAR =>
                if tem_moeda = '0' then
                    next_state <= ESPERA;
                end if;

            when AVALIA =>
                if compra_ok = '1' then
                    next_state <= AGUARDA_RETIRADA;
                else
                    next_state <= ESPERA_SOLTAR_BTN;
                end if;
                
            when ESPERA_SOLTAR_BTN =>
                if btn_comprar = '0' then
                    next_state <= ESPERA;
                end if;

            -- A máquina trava aqui esperando a KEY[1]. A tela já mostra o troco, mas nada pisca.
            when AGUARDA_RETIRADA =>
                ctrl_libera <= '1'; 
                if btn_retirar = '1' then
                    next_state <= ENTREGA; 
                end if;

            -- Inicia os efeitos visuais e espera os temporizadores avisarem que terminaram
            when ENTREGA =>
                ctrl_libera <= '1'; 
                ctrl_entrega <= '1'; 
                if fim_entrega = '1' then
                    next_state <= ZERA; 
                end if;

            when ZERA =>
                ctrl_zera <= '1';
                next_state <= ESPERA;

            when others =>
                next_state <= ZERA;
        end case;
    end process;

end architecture bhv;