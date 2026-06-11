defmodule EcoHabitsWeb.UserResetPasswordLive do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-2xl justify-center mb-4">Nova senha</h1>

          <.form for={@form} id="reset_password_form" phx-submit="reset_password" phx-change="validate">
            <.input field={@form[:password]} type="password" label="Nova senha" required />
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirmar nova senha"
              required
            />
            <.button class="btn btn-primary w-full mt-4" phx-disable-with="Redefinindo...">
              Redefinir senha
            </.button>
          </.form>

          <p class="text-center text-sm mt-4">
            <.link navigate={~p"/users/log_in"} class="link link-primary">Voltar ao login</.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket = assign(socket, token: token)

    # Verifica o token antes de montar a página. Redireciona se inválido
    case Accounts.get_user_by_reset_password_token(token) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Link de recuperação inválido ou expirado.")
          |> redirect(to: ~p"/users/reset_password")

        {:ok, socket}

      user ->
        form = to_form(Accounts.change_user_password(user), as: "user")
        {:ok, assign(socket, form: form, user: user)}
    end
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      socket.assigns.user
      |> Accounts.change_user_password(params)
      |> Map.put(:action, :validate)
      |> to_form(as: "user")

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("reset_password", %{"user" => params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "Senha redefinida com sucesso!")
          |> redirect(to: ~p"/users/log_in")

        {:noreply, socket}

      {:error, changeset} ->
        form = to_form(changeset, as: "user")
        {:noreply, assign(socket, form: form)}
    end
  end
end
