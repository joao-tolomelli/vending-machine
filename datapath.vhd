library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
    port (
        clk           : in std_logic;
        reset         : in std_logic;
        
        moeda_25      : in std_logic;
        moeda_50      : in std_logic;
        moeda_100     : in std_logic;
        sel_produto   : in std_logic_vector(2 downto 0);
        valor_produto : in std_logic_vector(7 downto 0);
        
        ctrl_soma     : in std_logic;
        ctrl_zera     : in std_logic;
        ctrl_libera   : in std_logic;
        
        compra_ok     : out std_logic;
        dispenser     : out std_logic_vector(7 downto 0);
        troco_out     : out std_logic_vector(7 downto 0);
        
        saldo_out     : out std_logic_vector(7 downto 0) 
    );
end entity datapath;

architecture rtl of datapath is
    signal saldo_atual : unsigned(7 downto 0);
    signal valor_moeda : unsigned(7 downto 0);
begin

    saldo_out <= std_logic_vector(saldo_atual);

    process(moeda_25, moeda_50, moeda_100)
    begin
        if moeda_100 = '1' then
            valor_moeda <= to_unsigned(4, 8); 
        elsif moeda_50 = '1' then
            valor_moeda <= to_unsigned(2, 8); 
        elsif moeda_25 = '1' then
            valor_moeda <= to_unsigned(1, 8); 
        else
            valor_moeda <= to_unsigned(0, 8);
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            saldo_atual <= (others => '0');
        elsif rising_edge(clk) then
            if ctrl_zera = '1' then
                saldo_atual <= (others => '0');
            elsif ctrl_soma = '1' then
                saldo_atual <= saldo_atual + valor_moeda;
            end if;
        end if;
    end process;

    compra_ok <= '1' when saldo_atual >= unsigned(valor_produto) else '0';

    process(ctrl_libera, sel_produto)
    begin
        dispenser <= (others => '0');
        if ctrl_libera = '1' then
            case sel_produto is
                when "000" => dispenser(0) <= '1';
                when "001" => dispenser(1) <= '1';
                when "010" => dispenser(2) <= '1';
                when "011" => dispenser(3) <= '1';
                when "100" => dispenser(4) <= '1';
                when "101" => dispenser(5) <= '1';
                when "110" => dispenser(6) <= '1';
                when "111" => dispenser(7) <= '1';
                when others => dispenser <= (others => '0');
            end case;
        end if;
    end process;

    process(ctrl_libera, saldo_atual, valor_produto)
    begin
        if ctrl_libera = '1' then
            troco_out <= std_logic_vector(saldo_atual - unsigned(valor_produto));
        else
            troco_out <= (others => '0');
        end if;
    end process;

end architecture rtl;