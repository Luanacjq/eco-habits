defmodule EcoHabitsWeb.UserRegistrationLive do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Accounts
  alias EcoHabits.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="auth-bg min-h-screen flex items-center justify-center p-4">
      <div class="w-full max-w-sm anim-fade-up">

        <div class="text-center mb-8">
          <span class="text-6xl anim-float inline-block">🌿</span>
          <h1 class="text-3xl font-bold mt-3 text-base-content">Criar conta</h1>
          <p class="text-base-content/50 text-sm mt-1">Junte-se à comunidade sustentável</p>
        </div>

        <div class="glass-card rounded-3xl p-6 shadow-2xl anim-scale-in anim-delay-1">
          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <div class="space-y-1">
              <.input field={@form[:name]} type="text" label="Nome" placeholder="Como quer ser chamado?" />
              <.input field={@form[:email]} type="email" label="E-mail" placeholder="seu@email.com" />
              <.input field={@form[:password]} type="password" label="Senha" placeholder="Mínimo 12 caracteres" />
            </div>
            <.button class="btn btn-primary w-full rounded-xl mt-5 shadow-lg shadow-primary/20 hover:shadow-primary/30 transition-shadow" phx-disable-with="Criando...">
              Criar conta
            </.button>
          </.form>

          <div class="divider text-xs text-base-content/30 my-4">ou</div>

          <p class="text-center text-sm text-base-content/60">
            Já tem conta?
            <.link navigate={~p"/users/log_in"} class="text-primary font-semibold hover:underline">
              Entrar
            </.link>
          </p>
        </div>

      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  # Cria o usuário e redireciona para o login (RF01)
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Conta criada com sucesso! Faça login para continuar.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
