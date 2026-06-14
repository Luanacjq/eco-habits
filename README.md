# 🌱 EcoHabits

Aplicação web colaborativa onde usuários registram e acompanham hábitos sustentáveis do cotidiano — como reduzir o uso de plástico, economizar água ou optar por transporte ativo — acumulando pontos e visualizando o engajamento da comunidade em tempo real.

Desenvolvida com **Elixir/Phoenix + LiveView** para a disciplina **Programação Funcional** da Universidade de Fortaleza (UNIFOR).

---

## Tecnologias

| Tecnologia | Versão | Uso |
|---|---|---|
| Elixir | 1.15+ | Linguagem principal |
| Phoenix Framework | 1.8 | Framework web |
| Phoenix LiveView | 1.2 | Interatividade em tempo real (RF07, RF09) |
| Ecto + PostgreSQL | 3.14 | Banco de dados relacional |
| Tailwind CSS + DaisyUI | — | Estilização |
| bcrypt_elixir | 3.x | Hash de senhas |
| Phoenix PubSub | 2.x | Feed da comunidade em tempo real (RF09) |

---

## Módulos e requisitos

| Módulo | Requisitos | Descrição |
|---|---|---|
| **A — Autenticação e Perfil** | RF01, RF02, RF03 | Cadastro, login/logout, página de perfil com bio e pontuação |
| **B — Gestão de Hábitos** | RF04, RF05, RF06 | Cadastro, listagem com filtro e edição/remoção de hábitos |
| **C — Registro e Acompanhamento** | RF07, RF08, RF09 | Check-ins diários, dashboard pessoal e feed da comunidade em tempo real |

---

## Pré-requisitos

- [Elixir 1.15+](https://elixir-lang.org/install.html)
- [Erlang/OTP 26+](https://www.erlang.org/downloads) (instalado junto com o Elixir)
- [PostgreSQL 14+](https://www.postgresql.org/download/)

### Windows — compilar bcrypt_elixir

A dependência `bcrypt_elixir` usa código nativo (C). No Windows é necessário ter o **Visual Studio Build Tools** com o componente **"Desenvolvimento para desktop com C++"**.

- Download: https://visualstudio.microsoft.com/visual-cpp-build-tools/

Após instalar, abra o terminal **como Administrador** pelo menos uma vez antes de rodar `mix deps.get`.

---

## Como rodar

### 1. Clonar o repositório

```bash
git clone <url-do-repositorio>
cd eco_habits
```

### 2. Instalar dependências

```bash
mix deps.get
```

### 3. Configurar banco de dados

Edite `config/dev.exs` se o usuário/senha do seu PostgreSQL for diferente:

```elixir
config :eco_habits, EcoHabits.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "eco_habits_dev"
```

### 4. Criar e migrar o banco

```bash
mix ecto.create
mix ecto.migrate
```

### 5. Iniciar o servidor

```bash
mix phx.server
```

Acesse em **[http://localhost:4000](http://localhost:4000)**

- Sem login → redireciona para a tela de login
- Com login → redireciona para a lista de hábitos

---

## Funcionalidades implementadas

### Módulo A — Autenticação e Perfil

- **RF01** — Cadastro com nome, e-mail e senha (gerado via `mix phx.gen.auth`)
- **RF02** — Login com sessão persistente ("lembrar de mim") e logout
- **RF03** — Página de perfil com nome, bio editável e pontuação total acumulada. Inclui sistema de níveis (🌱 → 🥈 → 🥇 → 🏆) com barra de progresso

### Módulo B — Gestão de Hábitos

- **RF04** — Cadastro de hábitos com nome, descrição, categoria e pontuação (1–100 pts)
- **RF05** — Listagem com filtro por categoria via pills clicáveis (Alimentação, Transporte, Energia, Água, Resíduos)
- **RF06** — Edição e remoção de hábitos próprios, com confirmação antes de excluir; proteção para que usuários não editem/removam hábitos alheios

### Módulo C — Registro e Acompanhamento

- **RF07** — Check-in diário: lista todos os hábitos disponíveis e permite registrar a prática do dia. Previne duplicatas por índice único no banco e desabilita o botão de hábitos já registrados hoje
- **RF08** — Dashboard pessoal com total de pontos, contagem de check-ins, semanas ativas, gráfico de barras da pontuação semanal e histórico completo de check-ins
- **RF09** — Feed da comunidade em tempo real via Phoenix PubSub: exibe os check-ins mais recentes de todos os usuários e se atualiza automaticamente (sem recarregar a página) sempre que qualquer usuário registra um novo hábito

---

## Rotas principais

| Rota | LiveView | Requisito |
|---|---|---|
| `/users/register` | `UserRegistrationLive` | RF01 |
| `/users/log_in` | `UserLoginLive` | RF02 |
| `/profile` | `ProfileLive` | RF03 |
| `/habitos` | `HabitLive.Index` | RF04, RF05, RF06 |
| `/checkin` | `CheckInLive.Index` | RF07 |
| `/dashboard` | `DashboardLive.Index` | RF08 |
| `/feed` | `FeedLive.Index` | RF09 |

---

## Comandos úteis

```bash
# Resetar banco de dados (apaga tudo e recria)
mix ecto.reset

# Console interativo com o app carregado
iex -S mix

# Rodar testes
mix test

# Verificar formatação do código
mix format --check-formatted

# Compilar assets para produção
mix assets.deploy
```

---

## Variáveis de ambiente em produção

```bash
SECRET_KEY_BASE=<gere com: mix phx.gen.secret>
DATABASE_URL=postgresql://usuario:senha@host/banco
PHX_HOST=seu-dominio.com
PORT=4000
```