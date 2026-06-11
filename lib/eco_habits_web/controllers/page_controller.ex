defmodule EcoHabitsWeb.PageController do
  use EcoHabitsWeb, :controller

  # Redireciona para hábitos se logado, ou para login se não estiver
  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/habitos")
    else
      redirect(conn, to: ~p"/users/log_in")
    end
  end
end
