defmodule EcoHabitsWeb.UserSessionController do
  use EcoHabitsWeb, :controller

  alias EcoHabits.Accounts
  alias EcoHabitsWeb.UserAuth

  # Processa o login via POST do formulário de login (RF02)
  def create(conn, %{"_action" => "password_updated"} = params) do
    create(conn, params, "Senha alterada com sucesso! Faça login novamente.")
  end

  def create(conn, params) do
    create(conn, params, "Bem-vindo de volta!")
  end

  defp create(conn, %{"user" => user_params} = _params, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      conn
      |> put_flash(:error, "E-mail ou senha inválidos.")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  # Efetua o logout removendo o token de sessão (RF02)
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Você saiu da conta.")
    |> UserAuth.log_out_user()
  end
end
