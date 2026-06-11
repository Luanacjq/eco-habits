defmodule EcoHabitsWeb.UserConfirmationLive do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body text-center">
          <h1 class="card-title text-2xl justify-center mb-4">Confirmar e-mail</h1>
          <.form for={@form} id="confirmation_form" phx-submit="confirm_account">
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <.button class="btn btn-primary w-full" phx-disable-with="Confirmando...">
              Confirmar minha conta
            </.button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "Conta confirmada com sucesso!")
          |> redirect(to: ~p"/users/log_in")

        {:noreply, socket}

      :error ->
        socket =
          if socket.assigns[:current_scope] do
            socket
            |> put_flash(:error, "Link inválido ou já utilizado.")
            |> redirect(to: ~p"/habitos")
          else
            socket
            |> put_flash(:error, "Link de confirmação inválido ou expirado.")
            |> redirect(to: ~p"/users/log_in")
          end

        {:noreply, socket}
    end
  end
end
