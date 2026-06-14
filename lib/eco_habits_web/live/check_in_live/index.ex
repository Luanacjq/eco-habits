defmodule EcoHabitsWeb.CheckInLive.Index do
  @moduledoc """
  RF07 — Registro diário de hábitos praticados (check-in).

  Lista todos os hábitos disponíveis e permite registrar um check-in para a
  data de hoje. A duplicidade no mesmo dia para o mesmo usuário/hábito é
  impedida tanto pelo índice único do banco quanto pela interface, que
  desabilita o botão de hábitos já registrados hoje.
  """
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Habits
  alias EcoHabits.CheckIns

  @category_labels %{
    "alimentacao" => {"🥗", "Alimentação"},
    "transporte"  => {"🚲", "Transporte"},
    "energia"     => {"💡", "Energia"},
    "agua"        => {"💧", "Água"},
    "residuos"    => {"♻️", "Resíduos"}
  }

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    today = Date.utc_today()

    socket =
      socket
      |> assign(:user, user)
      |> assign(:today, today)
      |> assign(:category_labels, @category_labels)
      |> assign(:habits, Habits.list_habits())
      |> assign(:checked_ids, MapSet.new(CheckIns.habit_ids_checked_in(user.id, today)))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">

        <%!-- Cabeçalho --%>
        <div class="anim-fade-up">
          <h1 class="text-2xl font-bold tracking-tight">Check-in diário</h1>
          <p class="text-sm text-base-content/40 mt-0.5">
            {format_date(@today)} · {MapSet.size(@checked_ids)} de {length(@habits)} hábitos registrados hoje
          </p>
        </div>

        <%!-- Estado vazio --%>
        <div :if={@habits == []} class="text-center py-20 anim-fade-up">
          <div class="text-6xl mb-4 anim-float inline-block">📋</div>
          <p class="text-base-content/40 text-sm">
            Nenhum hábito cadastrado ainda. Cadastre hábitos para começar a registrar check-ins.
          </p>
          <.link navigate={~p"/habitos"} class="btn btn-primary btn-sm rounded-xl mt-4">
            Ir para hábitos
          </.link>
        </div>

        <%!-- Lista de hábitos com botão de check-in --%>
        <div :if={@habits != []} class="grid gap-3 sm:grid-cols-2">
          <div
            :for={{habit, idx} <- Enum.with_index(@habits)}
            class={[
              "glass-card rounded-2xl p-4 flex items-center gap-3 anim-fade-up",
              idx == 1 && "anim-delay-1",
              idx == 2 && "anim-delay-2",
              idx == 3 && "anim-delay-3",
              idx >= 4 && "anim-delay-4"
            ]}
          >
            <span class="text-2xl shrink-0">
              {elem(Map.get(@category_labels, habit.category, {"🌱", ""}), 0)}
            </span>

            <div class="flex-1 min-w-0">
              <h3 class="font-semibold text-sm leading-snug truncate">{habit.name}</h3>
              <p class="text-xs text-base-content/40">
                {elem(Map.get(@category_labels, habit.category, {"", habit.category}), 1)} · +{habit.points} pts
              </p>
            </div>

            <%!-- Botão desabilitado quando já registrado hoje (RF07) --%>
            <button
              :if={not MapSet.member?(@checked_ids, habit.id)}
              phx-click="check_in"
              phx-value-id={habit.id}
              class="btn btn-primary btn-sm rounded-xl shrink-0 shadow-md shadow-primary/20"
            >
              ✓ Registrar
            </button>
            <span
              :if={MapSet.member?(@checked_ids, habit.id)}
              class="badge badge-success gap-1 shrink-0 font-medium py-3"
            >
              <.icon name="hero-check-circle-micro" class="size-4" /> Feito hoje
            </span>
          </div>
        </div>

      </div>
    </Layouts.app>
    """
  end

  # Registra o check-in do hábito para o dia de hoje (RF07)
  def handle_event("check_in", %{"id" => id}, socket) do
    habit_id = String.to_integer(id)
    user = socket.assigns.user
    today = socket.assigns.today

    attrs = %{"user_id" => user.id, "habit_id" => habit_id, "date" => today}

    case CheckIns.create_check_in(attrs) do
      {:ok, _check_in} ->
        socket =
          socket
          |> assign(:checked_ids, MapSet.put(socket.assigns.checked_ids, habit_id))
          |> put_flash(:info, "Check-in registrado! 🌿")

        {:noreply, socket}

      {:error, _changeset} ->
        # Captura a duplicidade (índice único) e qualquer outra falha de validação (RF07)
        socket =
          socket
          |> assign(:checked_ids, MapSet.put(socket.assigns.checked_ids, habit_id))
          |> put_flash(:error, "Você já registrou esse hábito hoje.")

        {:noreply, socket}
    end
  end

  defp format_date(date) do
    dias = ~w(Segunda Terça Quarta Quinta Sexta Sábado Domingo)
    meses = ~w(janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro)
    dia_semana = Enum.at(dias, Date.day_of_week(date) - 1)
    mes = Enum.at(meses, date.month - 1)
    "#{dia_semana}, #{date.day} de #{mes} de #{date.year}"
  end
end
