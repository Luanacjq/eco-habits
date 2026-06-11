defmodule EcoHabitsWeb.UserForgotPasswordLive do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-2xl justify-center mb-2">Recuperar senha</h1>
          <p class="text-center text-base-content/60 text-sm mb-6">
            Informe seu e-mail e enviaremos um link de redefinição.
          </p>

          <.form for={@form} id="reset_password_form" phx-submit="send_email">
            <.input field={@form[:email]} type="email" label="E-mail" required />
            <.button class="btn btn-primary w-full mt-4" phx-disable-with="Enviando...">
              Enviar link de recuperação
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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  # Envia o e-mail de reset, mas sempre exibe a mesma mensagem para não revelar cadastros
  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info = "Se o e-mail existir em nossa base, você receberá um link em breve."
    {:noreply, put_flash(socket, :info, info)}
  end
end
