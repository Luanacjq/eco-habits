defmodule EcoHabitsWeb.HabitLive.Index do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Habits
  alias EcoHabits.Habits.Habit

  @category_labels %{
    "alimentacao" => {"🥗", "Alimentação"},
    "transporte"  => {"🚲", "Transporte"},
    "energia"     => {"💡", "Energia"},
    "agua"        => {"💧", "Água"},
    "residuos"    => {"♻️", "Resíduos"}
  }

  # Cor de fundo sutil para cada categoria
  @category_colors %{
    "alimentacao" => "bg-green-500/10  dark:bg-green-500/15",
    "transporte"  => "bg-blue-500/10   dark:bg-blue-500/15",
    "energia"     => "bg-yellow-500/10 dark:bg-yellow-500/15",
    "agua"        => "bg-cyan-500/10   dark:bg-cyan-500/15",
    "residuos"    => "bg-emerald-500/10 dark:bg-emerald-500/15"
  }

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:category_filter, nil)
      |> assign(:category_labels, @category_labels)
      |> assign(:category_colors, @category_colors)
      |> assign(:habits, Habits.list_habits())
      |> assign(:user, socket.assigns.current_scope.user)
      |> assign(:show_form, false)
      |> assign(:form, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">

        <%!-- Cabeçalho --%>
        <div class="flex items-end justify-between gap-4 flex-wrap anim-fade-up">
          <div>
            <h1 class="text-2xl font-bold tracking-tight">Hábitos Sustentáveis</h1>
            <p class="text-sm text-base-content/40 mt-0.5">
              {length(@habits)} hábito{if length(@habits) != 1, do: "s", else: ""}
              {if @category_filter, do: " nessa categoria", else: " cadastrados"}
            </p>
          </div>
          <button
            phx-click="toggle_form"
            class={[
              "btn btn-sm rounded-xl transition-all",
              if(@show_form, do: "btn-ghost", else: "btn-primary shadow-lg shadow-primary/20")
            ]}
          >
            {if @show_form, do: "✕ Fechar", else: "+ Novo hábito"}
          </button>
        </div>

        <%!-- Formulário de cadastro (RF04) com animação de entrada --%>
        <div :if={@show_form} class="glass-card rounded-3xl p-6 anim-slide-down">
          <h2 class="font-semibold text-base mb-4 flex items-center gap-2">
            <span class="w-7 h-7 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-sm">+</span>
            Cadastrar novo hábito
          </h2>
          <.form for={@form} id="habit_form" phx-submit="save_habit" phx-change="validate_habit">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-5">
              <div class="sm:col-span-2">
                <.input field={@form[:name]} type="text" label="Nome do hábito" placeholder="Ex: Usar caneca reutilizável" required />
              </div>
              <div class="sm:col-span-2">
                <.input field={@form[:description]} type="textarea" label="Descrição (opcional)" placeholder="Descreva o impacto ambiental desse hábito..." rows="2" />
              </div>
              <.input field={@form[:category]} type="select" label="Categoria" options={category_options(@category_labels)} prompt="Selecione..." required />
              <.input field={@form[:points]} type="number" label="Pontos (1–100)" placeholder="10" min="1" max="100" required />
            </div>
            <.button class="btn btn-primary btn-sm rounded-xl mt-2 shadow-md shadow-primary/20" phx-disable-with="Salvando...">
              Salvar hábito
            </.button>
          </.form>
        </div>

        <%!-- Filtros por categoria (RF05) --%>
        <div class="flex flex-wrap gap-2 anim-fade-up anim-delay-1">
          <button
            phx-click="filter"
            phx-value-category=""
            class={[
              "filter-badge px-3 py-1.5 rounded-xl text-sm font-medium border transition-all",
              if(is_nil(@category_filter),
                do: "bg-primary text-primary-content border-primary shadow-md shadow-primary/20",
                else: "bg-base-100/60 border-base-300/60 text-base-content/60 hover:text-base-content hover:border-base-300")
            ]}
          >
            Todos
          </button>
          <button
            :for={{key, {icon, label}} <- Enum.sort_by(@category_labels, fn {k, _} -> k end)}
            phx-click="filter"
            phx-value-category={key}
            class={[
              "filter-badge px-3 py-1.5 rounded-xl text-sm font-medium border transition-all flex items-center gap-1.5",
              if(@category_filter == key,
                do: "bg-primary text-primary-content border-primary shadow-md shadow-primary/20",
                else: "bg-base-100/60 border-base-300/60 text-base-content/60 hover:text-base-content hover:border-base-300")
            ]}
          >
            <span>{icon}</span> {label}
          </button>
        </div>

        <%!-- Estado vazio --%>
        <div :if={@habits == []} class="text-center py-20 anim-fade-up">
          <div class="text-6xl mb-4 anim-float inline-block">🌿</div>
          <p class="text-base-content/40 text-sm">
            {if @category_filter, do: "Nenhum hábito nessa categoria ainda.", else: "Nenhum hábito cadastrado. Seja o primeiro!"}
          </p>
        </div>

        <%!-- Grade de hábitos --%>
        <div :if={@habits != []} class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div
            :for={{habit, idx} <- Enum.with_index(@habits)}
            class={[
              "habit-card glass-card rounded-2xl overflow-hidden cursor-default",
              "anim-fade-up",
              idx == 1 && "anim-delay-1",
              idx == 2 && "anim-delay-2",
              idx == 3 && "anim-delay-3",
              idx == 4 && "anim-delay-4",
              idx >= 5  && "anim-delay-5"
            ]}
          >
            <%!-- Faixa colorida no topo do card conforme a categoria --%>
            <div class={["h-1.5 w-full", Map.get(@category_colors, habit.category, "bg-base-300")]} />

            <div class="p-4 space-y-3">
              <div class="flex items-start justify-between gap-2">
                <h3 class="font-semibold text-sm leading-snug flex-1">{habit.name}</h3>
                <span class="badge badge-success badge-sm font-bold shrink-0">+{habit.points}pts</span>
              </div>

              <div class="flex items-center gap-1.5">
                <span class="text-base">{elem(Map.get(@category_labels, habit.category, {"🌱", ""}), 0)}</span>
                <span class="text-xs text-base-content/50">
                  {elem(Map.get(@category_labels, habit.category, {"", habit.category}), 1)}
                </span>
              </div>

              <p :if={habit.description && habit.description != ""} class="text-xs text-base-content/50 leading-relaxed line-clamp-2">
                {habit.description}
              </p>

              <div class="flex items-center gap-2 pt-1 border-t border-base-300/40">
                <div class="w-5 h-5 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold">
                  {String.first(habit.user.name) |> String.upcase()}
                </div>
                <span class="text-xs text-base-content/40 truncate">{habit.user.name}</span>
              </div>
            </div>
          </div>
        </div>

      </div>
    </Layouts.app>
    """
  end

  def handle_event("toggle_form", _params, socket) do
    if socket.assigns.show_form do
      {:noreply, assign(socket, show_form: false, form: nil)}
    else
      changeset = Habits.change_habit(%Habit{})
      {:noreply, assign(socket, show_form: true, form: to_form(changeset))}
    end
  end

  def handle_event("validate_habit", %{"habit" => params}, socket) do
    form =
      %Habit{}
      |> Habits.change_habit(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  # Salva o hábito vinculado ao usuário logado (RF04)
  def handle_event("save_habit", %{"habit" => params}, socket) do
    params = Map.put(params, "user_id", socket.assigns.user.id)

    case Habits.create_habit(params) do
      {:ok, _habit} ->
        socket =
          socket
          |> assign(:habits, Habits.list_habits(socket.assigns.category_filter))
          |> assign(:show_form, false)
          |> assign(:form, nil)
          |> put_flash(:info, "Hábito cadastrado!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # Atualiza a lista filtrada pela categoria clicada (RF05)
  def handle_event("filter", %{"category" => category}, socket) do
    filter = if category == "", do: nil, else: category
    {:noreply, assign(socket, category_filter: filter, habits: Habits.list_habits(filter))}
  end

  defp category_options(labels) do
    labels
    |> Enum.map(fn {key, {icon, label}} -> {"#{icon} #{label}", key} end)
    |> Enum.sort_by(fn {label, _} -> label end)
  end
end
