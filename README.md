# ⚙️ Matter Strike: Coordenadas de Precisão

**Matter Strike** é um jogo tático de artilharia 2D por turnos que redefine o gênero ao substituir a mira analógica tradicional por comandos matemáticos diretos e lógica de física de materiais. Desenvolvido na **Godot Engine**, o projeto desafia os jogadores a dominarem o plano cartesiano e as fórmulas de densidade para vencer duelos de precisão.

![Trajetória no Plano Cartesiano](https://images.unsplash.com/photo-1635070041078-e363dbe005cb?auto=format&fit=crop&w=800&q=80) _(Substitua pelo link da imagem real do seu gameplay)_

## 🚀 O Conceito

Diferente de shooters tradicionais, o sucesso em _Matter Strike_ não depende de reflexos motores, mas sim da capacidade analítica do jogador. No papel de um engenheiro na **Estação Arquimedes**, você deve operar um terminal de comando para lançar projéteis de matéria programável, ajustando variáveis como massa, volume e densidade para atingir o oponente.

## 🏗️ Pilares de Design

- **Precisão Determinística:** O resultado de cada ação é fruto de cálculos; se as coordenadas e a densidade estiverem corretas, o impacto é garantido.
- **Física Dinâmica de Materiais:** O comportamento do projétil (inércia, arrasto e trajetória) muda conforme o material selecionado (Cortiça, Ferro, Chumbo), exigindo aplicação real da fórmula `d = m / V`.
- **Estratégia Espacial (Grid-Based):** O campo de batalha é um plano cartesiano vivo onde cada movimento nos eixos X e Y possui um custo tático e de energia.

## 🛠️ Tecnologias Utilizadas

- **Engine:** Godot 4.x
- **Linguagem:** GDScript (Arquitetura orientada a nós e sinais)
- **Física:** Sistema de balística customizado (determinístico)
- **Plataforma:** PC (Windows/Linux)

## 🔄 Loop de Gameplay

1. **Fase de Análise:** Observação do grid e variáveis ambientais (como vento).
2. **Fase de Manobra:** Posicionamento estratégico consumindo Unidades de Energia (UE).
3. **Fase de Cálculo e Input:** Seleção de material e inserção de coordenadas `(x, y)` via terminal.
4. **Fase de Resolução:** Execução da parábola baseada na física de materiais e validação do impacto.

## 📖 Contexto Narrativo

Após uma falha catastrófica no núcleo da Estação Arquimedes, o setor principal foi selado. Dois assistentes de engenharia, Léo e Sophie, competem em um duelo tático para provar quem possui o "Método Tático Superior", única forma de obter a chave de escape liberada pela IA da estação.

---

## 💻 Como Rodar o Projeto

### Pré-requisitos

- [Godot Engine 4.x](https://godotengine.org/) instalado.
- Git para clonagem do repositório.

### Instalação

1. Clone este repositório em sua máquina local:
   ```bash
   git clone [https://github.com/seu-usuario/matter-strike.git](https://github.com/seu-usuario/matter-strike.git)
   ```
