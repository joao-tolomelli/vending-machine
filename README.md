# Vending Machine RTL (FPGA Altera DE0)

![VHDL](https://img.shields.io/badge/VHDL-100%25-blue)
![FPGA](https://img.shields.io/badge/FPGA-Altera_DE0-orange)
![Status](https://img.shields.io/badge/Status-Concluído-success)

Este repositório contém o código-fonte e a documentação do projeto de uma **Máquina de Vendas Automática (Vending Machine)** digital, desenvolvida em VHDL utilizando a abordagem **RTL (Register-Transfer Level)** para a disciplina de Circuitos Digitais (UNIFOR). 

O projeto foi sintetizado e validado fisicamente em uma placa de desenvolvimento **Altera DE0** (família Cyclone III).


---

## ⚙️ Funcionalidades

* **Processamento Monetário:** Aceita inserções de moedas simuladas de R$ 0,25, R$ 0,50 e R$ 1,00, convertendo-as para uma lógica unificada para economia de portas lógicas.
* **Cálculo de Troco:** Subtrator em hardware que calcula e devolve a quantidade exata de moedas de troco.
* **Displays Multiplexados:** Utilização de displays de 7 segmentos para exibir o saldo inserido em tempo real e, no momento da aprovação, alterar dinamicamente para exibir o troco (formatado em Reais e Centavos, ex: `01.50`).
* **Intertravamento Lógico (Anti-Bounce):** A Máquina de Estados (FSM) possui estados dedicados para evitar múltiplas leituras mecânicas indesejadas (*bounce*) durante a inserção de chaves físicas.
* **Temporizadores em Hardware:** Divisores de *clock* implementados para gerenciar animações de LEDs (acionamento do dispenser por exatos 2 segundos e emissão de pulsos visuais proporcionais às moedas de troco).

---

## 🏗️ Arquitetura do Sistema

O projeto foi modularizado em três arquivos principais para garantir o isolamento entre o controle lógico e o fluxo de dados:

1. **`datapath.vhd` (Bloco Operacional):** Coração matemático do projeto. Contém o acumulador síncrono de saldo, comparador combinacional de preço e subtrator de troco.
2. **`fsm_vending.vhd` (Bloco de Controle):** Máquina de Estados Finita responsável por orquestrar a transição entre 8 estados lógicos (Espera, Soma, Liberação, Entrega, etc.) e enviar os sinais de controle corretos ao Datapath.
3. **`vending_top.vhd` (Top-Level):** Módulo superior que integra o Datapath e a FSM, conectando os sinais internos aos pinos físicos da placa DE0. Também contém a lógica de decodificação para displays de 7 segmentos e os divisores de frequência.

---

## 📍 Mapeamento de Pinos (Pinout)

O projeto foi configurado para os periféricos nativos da Altera DE0. A tabela abaixo indica a função de cada componente na interface de usuário:

| Componente Físico | Tipo | Função no Sistema |
| :--- | :--- | :--- |
| **`SW[0]`** | Entrada | Inserção de moeda de R$ 0,25. |
| **`SW[1]`** | Entrada | Inserção de moeda de R$ 0,50. |
| **`SW[2]`** | Entrada | Inserção de moeda de R$ 1,00. |
| **`SW[5:3]`** | Entrada | Seleção do produto via código binário (Ex: `101` = Produto 5). |
| **`KEY[0]`** | Entrada | Reset Global assíncrono (força o sistema ao estado inicial). |
| **`KEY[2]`** | Entrada | Confirmar Compra (autoriza a avaliação do saldo). |
| **`KEY[1]`** | Entrada | Retirar Produto (inicia os *timers* de entrega e troco). |
| **`LEDG[7:0]`** | Saída | Dispenser. O LED correspondente ao produto selecionado piscará por 2s. |
| **`LEDG[8]`** | Saída | Status `compra_ok`: acende ao aprovar saldo suficiente (>= R$ 1,50). |
| **`LEDG[9]`** | Saída | Status de Troco: emite pulsos visuais equivalentes à quantidade de moedas devolvidas. |
| **`HEX3..HEX2`**| Saída | Display Decimal: exibe a dezena e unidade dos Reais (com ponto decimal). |
| **`HEX1..HEX0`**| Saída | Display Decimal: exibe as casas dos Centavos (`00`, `25`, `50`, `75`). |

---

## 🚀 Como Executar e Simular

### Pré-requisitos
* **Quartus II** (ou versão mais recente do Quartus Prime compatível com Cyclone III).
* Placa FPGA Altera DE0 (para testes em hardware).

### Passos para Compilação
1. Clone este repositório:
   ```bash
   git clone https://github.com/joao-tolomelli/vending-machine
   ```
2. Abra o Quartus e crie um novo projeto no diretório clonado.

3. Adicione os arquivos datapath.vhd, fsm_vending.vhd e vending_top.vhd ao projeto.

4. Defina o arquivo vending_top.vhd como Top-Level Entity.

5. Importe o arquivo de atribuição de pinos (.qsf) apropriado para a placa DE0.

6. Execute a compilação completa (Processing > Start Compilation).

7. Transfira o código gerado (.sof) para a placa utilizando o Programmer via cabo USB-Blaster.