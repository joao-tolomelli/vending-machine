library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vending_top is
    port (
        CLOCK_50 : in std_logic;
        KEY      : in std_logic_vector(2 downto 0);
        SW       : in std_logic_vector(9 downto 0);
        LEDG     : out std_logic_vector(9 downto 0);
        HEX0     : out std_logic_vector(7 downto 0);
        HEX1     : out std_logic_vector(7 downto 0);
        HEX2     : out std_logic_vector(7 downto 0);
        HEX3     : out std_logic_vector(7 downto 0)
    );
end entity vending_top;

architecture estrutural of vending_top is
    signal w_ctrl_soma   : std_logic;
    signal w_ctrl_zera   : std_logic;
    signal w_ctrl_libera : std_logic;
    signal w_ctrl_entrega: std_logic;
    signal w_compra_ok   : std_logic;
    signal w_troco       : std_logic_vector(7 downto 0);
    signal w_saldo       : std_logic_vector(7 downto 0);
    signal w_dispenser   : std_logic_vector(7 downto 0);
    
    signal rst           : std_logic;
    signal m_25          : std_logic;
    signal m_50          : std_logic;
    signal m_100         : std_logic;
    signal s_produto     : std_logic_vector(2 downto 0);
    signal v_produto     : std_logic_vector(7 downto 0);
    
    signal w_btn_retirar : std_logic;
    signal w_btn_comprar : std_logic;

    -- Sinais de temporização para as luzes
    signal clk_div         : unsigned(23 downto 0) := (others => '0');
    signal blink_base      : std_logic := '0';
    signal blink_base_d    : std_logic := '0';
    
    signal prod_timer      : unsigned(26 downto 0) := (others => '0');
    signal prod_blinking   : std_logic := '0';
    signal fim_produto     : std_logic := '0';
    
    signal troco_pulse_cnt : integer range 0 to 15 := 0;
    signal fim_troco       : std_logic := '0';
    signal w_fim_entrega   : std_logic := '0';

    type hex_array is array(0 to 9) of std_logic_vector(7 downto 0);
    constant decode_7seg : hex_array := (
        "11000000", "11111001", "10100100", "10110000", "10011001", 
        "10010010", "10000010", "11111000", "10000000", "10010000"
    );

begin

    rst           <= not KEY(0); 
    w_btn_retirar <= not KEY(1); 
    w_btn_comprar <= not KEY(2); 
    
    m_25          <= SW(0);
    m_50          <= SW(1);
    m_100         <= SW(2);
    s_produto     <= SW(5 downto 3);
    v_produto     <= "00000110"; -- R$ 1,50

    -- 1. Gerador de frequência base para os piscas
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if clk_div = 12499999 then
                clk_div <= (others => '0');
                blink_base <= not blink_base;
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;

    -- 2. Temporizador de 2 segundos do Produto
    process(CLOCK_50, rst)
    begin
        if rst = '1' then
            prod_timer <= (others => '0');
            prod_blinking <= '0';
            fim_produto <= '0';
        elsif rising_edge(CLOCK_50) then
            if w_ctrl_entrega = '1' then
                if prod_timer < 100000000 then -- 2 segundos a 50MHz
                    prod_timer <= prod_timer + 1;
                    prod_blinking <= '1';
                    fim_produto <= '0';
                else
                    prod_blinking <= '0';
                    fim_produto <= '1';
                end if;
            else
                prod_timer <= (others => '0');
                prod_blinking <= '0';
                fim_produto <= '0';
            end if;
        end if;
    end process;

    -- 3. Modulador do LED do Produto (Fixo na aprovação, pisca na entrega)
    process(prod_blinking, blink_base, w_dispenser, w_ctrl_libera, w_ctrl_entrega)
    begin
        if w_ctrl_entrega = '1' then
            -- Animação de entrega rodando (depois de apertar KEY1)
            if prod_blinking = '1' then
                if blink_base = '1' then
                    LEDG(7 downto 0) <= w_dispenser;
                else
                    LEDG(7 downto 0) <= (others => '0');
                end if;
            else
                LEDG(7 downto 0) <= (others => '0');
            end if;
        elsif w_ctrl_libera = '1' then
            -- Compra recém aprovada (apertou KEY2). Fica aceso avisando o usuário.
            LEDG(7 downto 0) <= w_dispenser;
        else
            -- Repouso absoluto
            LEDG(7 downto 0) <= (others => '0');
        end if;
    end process;

    -- 4. Contador de Pulsos de Troco
    process(CLOCK_50, rst)
        variable num_moedas : integer range 0 to 15;
    begin
        if rst = '1' then
            troco_pulse_cnt <= 0;
            fim_troco <= '0';
            blink_base_d <= '0';
        elsif rising_edge(CLOCK_50) then
            blink_base_d <= blink_base;
            num_moedas := to_integer(unsigned(w_troco(3 downto 0)));
            
            if w_ctrl_entrega = '1' then
                if num_moedas = 0 then
                    fim_troco <= '1';
                else
                    if (blink_base_d = '1' and blink_base = '0') then
                        if troco_pulse_cnt < num_moedas - 1 then
                            troco_pulse_cnt <= troco_pulse_cnt + 1;
                        else
                            fim_troco <= '1';
                        end if;
                    end if;
                end if;
            else
                troco_pulse_cnt <= 0;
                fim_troco <= '0';
            end if;
        end if;
    end process;

    -- Sincronizador de Finalização: A máquina só reseta quando produto e troco terminam de piscar
    w_fim_entrega <= fim_produto and fim_troco;

    -- Acionamento do LED9 do Troco
    LEDG(9) <= blink_base when (w_ctrl_entrega = '1' and fim_troco = '0' and w_troco /= "00000000") else '0';
    
    -- Status visual de saldo aprovado
    LEDG(8) <= w_compra_ok;

    inst_datapath: entity work.datapath
        port map (
            clk           => CLOCK_50,
            reset         => rst,
            moeda_25      => m_25,
            moeda_50      => m_50,
            moeda_100     => m_100,
            sel_produto   => s_produto,
            valor_produto => v_produto,
            ctrl_soma     => w_ctrl_soma,
            ctrl_zera     => w_ctrl_zera,
            ctrl_libera   => w_ctrl_libera,
            compra_ok     => w_compra_ok,
            dispenser     => w_dispenser,
            troco_out     => w_troco,
            saldo_out     => w_saldo
        );

    inst_fsm: entity work.fsm_vending
        port map (
            clk         => CLOCK_50,
            reset       => rst,
            moeda_25    => m_25,
            moeda_50    => m_50,
            moeda_100   => m_100,
            btn_comprar => w_btn_comprar,
            btn_retirar => w_btn_retirar,
            compra_ok   => w_compra_ok,
            fim_entrega => w_fim_entrega,
            
            ctrl_soma   => w_ctrl_soma,
            ctrl_zera   => w_ctrl_zera,
            ctrl_libera => w_ctrl_libera,
            ctrl_entrega=> w_ctrl_entrega
        );

    -- Multiplexação de Tela
    process(w_saldo, w_troco, w_ctrl_libera)
        variable int_valor : integer range 0 to 255;
        variable reais     : integer range 0 to 63;
        variable resto     : integer range 0 to 3;
        variable dez_reais, uni_reais : integer range 0 to 9;
        variable dez_cent,  uni_cent  : integer range 0 to 9;
    begin
        if w_ctrl_libera = '1' then
            int_valor := to_integer(unsigned(w_troco));
        else
            int_valor := to_integer(unsigned(w_saldo));
        end if;
        
        reais := int_valor / 4;
        resto := int_valor mod 4;
        dez_reais := reais / 10;
        uni_reais := reais mod 10;
        
        if resto = 0 then
            dez_cent := 0; uni_cent := 0;
        elsif resto = 1 then
            dez_cent := 2; uni_cent := 5;
        elsif resto = 2 then
            dez_cent := 5; uni_cent := 0;
        else
            dez_cent := 7; uni_cent := 5;
        end if;
        
        HEX3 <= decode_7seg(dez_reais);
        HEX2 <= decode_7seg(uni_reais) and "01111111"; 
        HEX1 <= decode_7seg(dez_cent);
        HEX0 <= decode_7seg(uni_cent);
    end process;

end architecture estrutural;