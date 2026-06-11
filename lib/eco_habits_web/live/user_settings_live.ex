defmodule EcoHabitsWeb.UserSettingsLive do
  use EcoHabitsWeb, :live_view

  alias EcoHabits.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Configurações da conta
        <:subtitle>Altere seu e-mail e senha</:subtitle>
      </.header>

      <div class="divider">Alterar e-mail</div>
      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input field={@email_form[:email]} type="email" label="Novo e-mail" required />
        <.input
          field={@email_form[:current_password]}
          name="current_password"
          id="current_password_for_email"
          type="password"
          label="Senha atual (para confirmar)"
          value={@email_form_current_password}
          required
        />
        <.button phx-disable-with="Salvando..." class="btn btn-primary">
          Alterar e-mail
        </.button>
      </.form>

      <div class="divider mt-8">Alterar senha</div>
      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/log_in?_action=password_updated"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          value={@current_email}
        />
        <.input
          field={@password_form[:current_password]}
          name="current_password"
          type="password"
          label="Senha atual"
          value={@current_password}
          required
        />
        <.input field={@password_form[:password]} type="password" label="Nova senha" required />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirmar nova senha"
        />
        <.button phx-disable-with="Salvando..." class="btn btn-primary">
          Alterar senha
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        :ok -> put_flash(socket, :info, "E-mail alterado com sucesso!")
        :error -> put_flash(socket, :error, "Link de confirmação inválido ou expirado.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", %{"current_password" => password, "user" => user_params}, socket) do
    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "Link de confirmação enviado para o novo e-mail."
        {:noreply, put_flash(socket, :info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", %{"current_password" => password, "user" => user_params}, socket) do
    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
