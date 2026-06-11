defmodule EcoHabitsWeb.ProfileLive do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    total_points = Accounts.get_total_points(user.id)
    changeset = Accounts.change_user_profile(user)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:total_points, total_points)
      |> assign(:editing, false)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto space-y-5">

        <%!-- Card de perfil --%>
        <div class="glass-card rounded-3xl p-6 anim-fade-up">
          <div class="flex items-start gap-4">
            <div class="relative shrink-0">
              <div class="w-16 h-16 rounded-2xl bg-primary text-primary-content flex items-center justify-center text-2xl font-bold shadow-lg shadow-primary/30">
                {String.first(@user.name) |> String.upcase()}
              </div>
              <span class="absolute -bottom-1 -right-1 text-lg">{nivel_emoji(@total_points)}</span>
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between gap-2 flex-wrap">
                <h2 class="text-xl font-bold">{@user.name}</h2>
                <div class="badge badge-primary gap-1 font-semibold">
                  🌿 {@total_points} pts
                </div>
              </div>
              <p class="text-xs text-base-content/40 mt-0.5">{@user.email}</p>
              <p class="text-xs text-primary/80 font-medium mt-1">{descricao_nivel(@total_points)}</p>
            </div>
          </div>

          <%!-- Bio estática --%>
          <div :if={not @editing} class="mt-5">
            <div class="bg-base-200/60 rounded-2xl px-4 py-3 min-h-[52px]">
              <p class="text-sm text-base-content/70 leading-relaxed">
                {if @user.bio && @user.bio != "",
                  do: @user.bio,
                  else: "Sem bio ainda. Clique em editar para se apresentar!"}
              </p>
            </div>
            <button phx-click="start_edit" class="btn btn-ghost btn-xs mt-3 gap-1 text-base-content/50 hover:text-base-content">
              <.icon name="hero-pencil-square-micro" class="size-3.5" /> Editar perfil
            </button>
          </div>

          <%!-- Formulário de edição --%>
          <div :if={@editing} class="mt-5 anim-slide-down">
            <.form for={@form} id="profile_form" phx-submit="save_profile" phx-change="validate_profile">
              <.input field={@form[:name]} type="text" label="Nome" required />
              <.input
                field={@form[:bio]}
                type="textarea"
                label="Bio"
                placeholder="Fale sobre seus hábitos, motivações..."
                rows="3"
              />
              <div class="flex gap-2 mt-2">
                <.button class="btn btn-primary btn-sm rounded-xl" phx-disable-with="Salvando...">
                  Salvar
                </.button>
                <button type="button" phx-click="cancel_edit" class="btn btn-ghost btn-sm rounded-xl">
                  Cancelar
                </button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Stats --%>
        <div class="grid grid-cols-2 gap-4 anim-fade-up anim-delay-1">
          <div class="glass-card rounded-3xl p-5 text-center">
            <div class="text-4xl font-bold text-primary">{@total_points}</div>
            <div class="text-xs text-base-content/50 mt-1 font-medium">pontos totais</div>
          </div>
          <div class="glass-card rounded-3xl p-5 text-center">
            <div class="text-4xl">{nivel_emoji(@total_points)}</div>
            <div class="text-xs text-base-content/50 mt-1 font-medium">{descricao_nivel(@total_points)}</div>
          </div>
        </div>

        <%!-- Barra de progresso para próximo nível --%>
        <div class="glass-card rounded-3xl p-5 anim-fade-up anim-delay-2">
          <div class="flex items-center justify-between text-sm mb-2">
            <span class="font-medium text-base-content/70">Progresso para o próximo nível</span>
            <span class="text-xs text-base-content/40">{progresso_texto(@total_points)}</span>
          </div>
          <div class="w-full bg-base-300 rounded-full h-2.5 overflow-hidden">
            <div
              class="bg-primary h-2.5 rounded-full transition-all duration-700"
              style={"width: #{progresso_percent(@total_points)}%"}
            />
          </div>
          <p class="text-xs text-base-content/40 mt-2">{proxima_descricao(@total_points)}</p>
        </div>

      </div>
    </Layouts.app>
    """
  end

  def handle_event("start_edit", _params, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.user)
    {:noreply, assign(socket, editing: true, form: to_form(changeset))}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false)}
  end

  def handle_event("validate_profile", %{"user" => params}, socket) do
    form =
      socket.assigns.user
      |> Accounts.change_user_profile(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  # Salva alterações de nome e bio do usuário (RF03)
  def handle_event("save_profile", %{"user" => params}, socket) do
    case Accounts.update_user_profile(socket.assigns.user, params) do
      {:ok, updated_user} ->
        socket =
          socket
          |> assign(:user, updated_user)
          |> assign(:editing, false)
          |> put_flash(:info, "Perfil atualizado!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp nivel_emoji(p) when p >= 500, do: "🏆"
  defp nivel_emoji(p) when p >= 200, do: "🥇"
  defp nivel_emoji(p) when p >= 50,  do: "🥈"
  defp nivel_emoji(_),                do: "🌱"

  defp descricao_nivel(p) when p >= 500, do: "Eco Mestre"
  defp descricao_nivel(p) when p >= 200, do: "Eco Avançado"
  defp descricao_nivel(p) when p >= 50,  do: "Eco Iniciante"
  defp descricao_nivel(_),                do: "Começando"

  # Calcula o percentual dentro da faixa atual para exibir na barra
  defp progresso_percent(p) when p >= 500, do: 100
  defp progresso_percent(p) when p >= 200, do: min(round((p - 200) / 3), 100)
  defp progresso_percent(p) when p >= 50,  do: min(round((p - 50) / 1.5), 100)
  defp progresso_percent(p),                do: min(round(p * 2), 100)

  defp progresso_texto(p) when p >= 500, do: "Nível máximo!"
  defp progresso_texto(p) when p >= 200, do: "#{p}/500 pts"
  defp progresso_texto(p) when p >= 50,  do: "#{p}/200 pts"
  defp progresso_texto(p),                do: "#{p}/50 pts"

  defp proxima_descricao(p) when p >= 500, do: "Você chegou ao nível máximo 🎉"
  defp proxima_descricao(p) when p >= 200, do: "#{500 - p} pontos para Eco Mestre 🏆"
  defp proxima_descricao(p) when p >= 50,  do: "#{200 - p} pontos para Eco Avançado 🥇"
  defp proxima_descricao(p),                do: "#{50 - p} pontos para Eco Iniciante 🥈"
end
