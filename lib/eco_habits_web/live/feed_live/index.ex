defmodule EcoHabitsWeb.FeedLive.Index do
  @moduledoc """
  RF09 — Feed da comunidade em tempo real.

  Exibe os check-ins mais recentes de todos os usuários e é atualizado
  automaticamente via Phoenix.PubSub: sempre que qualquer usuário registra um
  check-in (RF07), o contexto CheckIns transmite o evento `{:new_check_in, ci}`
  e este LiveView insere o novo registro no topo da lista sem recarregar a página.
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

  @max_feed 20

  def mount(_params, _session, socket) do
    # Inscreve-se nas atualizações do feed apenas quando o socket está conectado (RF09)
    if connected?(socket), do: CheckIns.subscribe_feed()

    socket =
      socket
      |> assign(:category_labels, @category_labels)
      |> assign(:check_ins, CheckIns.list_recent_check_ins(@max_feed))

    {:ok, socket}
  end

  # Recebe o broadcast de um novo check-in e o insere no topo do feed (RF09)
  def handle_info({:new_check_in, check_in}, socket) do
    updated =
      [check_in | socket.assigns.check_ins]
      |> Enum.take(@max_feed)

    {:noreply, assign(socket, :check_ins, updated)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">

        <%!-- Cabeçalho --%>
        <div class="flex items-center justify-between gap-4 anim-fade-up">
          <div>
            <h1 class="text-2xl font-bold tracking-tight">Feed da comunidade</h1>
            <p class="text-sm text-base-content/40 mt-0.5">
              Check-ins recentes de toda a comunidade, em tempo real
            </p>
          </div>
          <span class="badge badge-success gap-1.5 font-medium py-3">
            <span class="w-2 h-2 rounded-full bg-success animate-pulse" /> Ao vivo
          </span>
        </div>

        <%!-- Estado vazio --%>
        <div :if={@check_ins == []} class="text-center py-20 anim-fade-up">
          <div class="text-6xl mb-4 anim-float inline-block">🌍</div>
          <p class="text-base-content/40 text-sm">
            Nenhum check-in ainda. Seja o primeiro a registrar um hábito!
          </p>
        </div>

        <%!-- Lista do feed (RF09) --%>
        <div :if={@check_ins != []} id="feed" class="space-y-3">
          <div
            :for={ci <- @check_ins}
            id={"feed-item-#{ci.id}"}
            class="glass-card rounded-2xl p-4 flex items-center gap-3 anim-slide-down"
          >
            <%!-- Avatar do usuário --%>
            <div class="w-10 h-10 rounded-full bg-primary text-primary-content flex items-center justify-center text-sm font-bold shrink-0">
              {String.first(ci.user.name) |> String.upcase()}
            </div>

            <div class="flex-1 min-w-0">
              <p class="text-sm leading-snug">
                <span class="font-semibold">{ci.user.name}</span>
                <span class="text-base-content/50"> registrou </span>
                <span class="font-medium">{ci.habit.name}</span>
              </p>
              <div class="flex items-center gap-1.5 mt-0.5">
                <span class="text-sm">{elem(Map.get(@category_labels, ci.habit.category, {"🌱", ""}), 0)}</span>
                <span class="text-xs text-base-content/40">
                  {elem(Map.get(@category_labels, ci.habit.category, {"", ci.habit.category}), 1)}
                  · {relative_time(ci.inserted_at)}
                </span>
              </div>
            </div>

            <span class="badge badge-success badge-sm font-bold shrink-0">+{ci.habit.points}pts</span>
          </div>
        </div>

      </div>
    </Layouts.app>
    """
  end

  # Tempo relativo simples a partir do inserted_at (utc_datetime já é um DateTime)
  defp relative_time(%DateTime{} = inserted_at) do
    seconds = DateTime.diff(DateTime.utc_now(), inserted_at)

    cond do
      seconds < 60 -> "agora mesmo"
      seconds < 3600 -> "há #{div(seconds, 60)} min"
      seconds < 86_400 -> "há #{div(seconds, 3600)} h"
      true -> "há #{div(seconds, 86_400)} d"
    end
  end
end
