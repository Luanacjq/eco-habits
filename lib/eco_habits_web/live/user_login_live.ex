defmodule EcoHabitsWeb.UserLoginLive do
  use EcoHabitsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="auth-bg min-h-screen flex items-center justify-center p-4">
      <div class="w-full max-w-sm anim-fade-up">

        <div class="text-center mb-8 anim-fade-up">
          <span class="text-6xl anim-float inline-block">🌱</span>
          <h1 class="text-3xl font-bold mt-3 text-base-content">EcoHabits</h1>
          <p class="text-base-content/50 text-sm mt-1">Bem-vindo de volta!</p>
        </div>

        <div class="glass-card rounded-3xl p-6 shadow-2xl anim-scale-in anim-delay-1">
          <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <div class="space-y-1">
              <.input field={@form[:email]} type="email" label="E-mail" placeholder="seu@email.com" />
              <.input field={@form[:password]} type="password" label="Senha" placeholder="••••••••••••" />
            </div>

            <div class="flex items-center justify-between mt-3 mb-5">
              <label class="flex items-center gap-2 cursor-pointer select-none">
                <input type="checkbox" name="remember_me" class="checkbox checkbox-xs checkbox-primary" />
                <span class="text-xs text-base-content/60">Lembrar de mim</span>
              </label>
              <.link navigate={~p"/users/reset_password"} class="text-xs text-primary hover:underline">
                Esqueci a senha
              </.link>
            </div>

            <.button class="btn btn-primary w-full rounded-xl shadow-lg shadow-primary/20 hover:shadow-primary/30 transition-shadow" phx-disable-with="Entrando...">
              Entrar
            </.button>
          </.form>

          <div class="divider text-xs text-base-content/30 my-4">ou</div>

          <p class="text-center text-sm text-base-content/60">
            Não tem conta?
            <.link navigate={~p"/users/register"} class="text-primary font-semibold hover:underline">
              Criar conta grátis
            </.link>
          </p>
        </div>

      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
