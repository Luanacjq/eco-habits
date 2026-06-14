defmodule EcoHabitsWeb.DashboardLive.Index do
  @moduledoc """
  RF08 — Dashboard pessoal exibindo o histórico de check-ins do usuário e a
  pontuação acumulada por semana.
  """
  use EcoHabitsWeb, :live_view

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

    socket =
      socket
      |> assign(:user, user)
      |> assign(:category_labels, @category_labels)
      |> assign(:check_ins, CheckIns.list_user_check_ins(user.id))
      |> assign(:weekly, CheckIns.weekly_points(user.id))
      |> assign(:total_points, CheckIns.total_points(user.id))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">

        <%!-- Cabeçalho --%>
        <div class="anim-fade-up">
          <h1 class="text-2xl font-bold tracking-tight">Meu painel</h1>
          <p class="text-sm text-base-content/40 mt-0.5">
            {length(@check_ins)} check-in{if length(@check_ins) != 1, do: "s", else: ""} ·
            {@total_points} pontos acumulados
          </p>
        </div>

        <%!-- Cartões de resumo --%>
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 anim-fade-up anim-delay-1">
          <div class="glass-card rounded-3xl p-5 text-center">
            <div class="text-4xl font-bold text-primary">{@total_points}</div>
            <div class="text-xs text-base-content/50 mt-1 font-medium">pontos totais</div>
          </div>
          <div class="glass-card rounded-3xl p-5 text-center">
            <div class="text-4xl font-bold text-primary">{length(@check_ins)}</div>
            <div class="text-xs text-base-content/50 mt-1 font-medium">check-ins</div>
          </div>
          <div class="glass-card rounded-3xl p-5 text-center col-span-2 sm:col-span-1">
            <div class="text-4xl font-bold text-primary">{length(@weekly)}</div>
            <div class="text-xs text-base-content/50 mt-1 font-medium">semanas ativas</div>
          </div>
        </div>

        <%!-- Pontuação acumulada por semana (RF08) --%>
        <div class="glass-card rounded-3xl p-6 anim-fade-up anim-delay-2">
          <h2 class="font-semibold text-base mb-4 flex items-center gap-2">
            <span class="w-7 h-7 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-sm">📊</span>
            Pontuação por semana
          </h2>

          <div :if={@weekly == []} class="text-sm text-base-content/40 py-6 text-center">
            Nenhum check-in ainda. Registre hábitos para acompanhar sua evolução semanal.
          </div>

          <div :if={@weekly != []} class="space-y-3">
            <div :for={week <- @weekly} class="flex items-center gap-3">
              <div class="w-28 shrink-0 text-xs text-base-content/60 font-medium">
                {format_week(week.week_start)}
              </div>
              <div class="flex-1 bg-base-300 rounded-full h-3 overflow-hidden">
                <div
                  class="bg-primary h-3 rounded-full transition-all duration-700"
                  style={"width: #{bar_width(week.points, @weekly)}%"}
                />
              </div>
              <div class="w-20 shrink-0 text-right">
                <span class="text-sm font-bold text-primary">{week.points} pts</span>
                <span class="block text-[10px] text-base-content/40">{week.count} check-in{if week.count != 1, do: "s", else: ""}</span>
              </div>
            </div>
          </div>
        </div>

        <%!-- Histórico de check-ins (RF08) --%>
        <div class="glass-card rounded-3xl p-6 anim-fade-up anim-delay-3">
          <h2 class="font-semibold text-base mb-4 flex items-center gap-2">
            <span class="w-7 h-7 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-sm">🗓️</span>
            Histórico de check-ins
          </h2>

          <div :if={@check_ins == []} class="text-sm text-base-content/40 py-6 text-center">
            Você ainda não registrou nenhum hábito.
          </div>

          <ul :if={@check_ins != []} class="divide-y divide-base-300/40">
            <li :for={ci <- @check_ins} class="flex items-center gap-3 py-3">
              <span class="text-xl shrink-0">
                {elem(Map.get(@category_labels, ci.habit.category, {"🌱", ""}), 0)}
              </span>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium truncate">{ci.habit.name}</p>
                <p class="text-xs text-base-content/40">{format_full_date(ci.date)}</p>
              </div>
              <span class="badge badge-success badge-sm font-bold shrink-0">+{ci.habit.points}pts</span>
            </li>
          </ul>
        </div>

      </div>
    </Layouts.app>
    """
  end

  # Largura proporcional da barra em relação à semana de maior pontuação
  defp bar_width(_points, []), do: 0

  defp bar_width(points, weekly) do
    max_points = weekly |> Enum.map(& &1.points) |> Enum.max(fn -> 1 end)
    max_points = if max_points == 0, do: 1, else: max_points
    round(points / max_points * 100)
  end

  defp format_week(week_start) do
    week_end = Date.add(week_start, 6)
    "#{pad(week_start.day)}/#{pad(week_start.month)} – #{pad(week_end.day)}/#{pad(week_end.month)}"
  end

  defp format_full_date(date) do
    meses = ~w(jan fev mar abr mai jun jul ago set out nov dez)
    "#{pad(date.day)} de #{Enum.at(meses, date.month - 1)}. de #{date.year}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
