defmodule EcoHabits.CheckIns do
  @moduledoc """
  Contexto responsável pelos check-ins diários de hábitos.
  Implementado pelo Módulo C (RF07, RF08, RF09).
  """

  import Ecto.Query
  alias EcoHabits.Repo
  alias EcoHabits.CheckIns.CheckIn

  # Registra um check-in para o usuário e hábito informados (RF07 - colega)
  def create_check_in(attrs \\ %{}) do
    %CheckIn{}
    |> CheckIn.changeset(attrs)
    |> Repo.insert()
  end

  # Retorna todos os check-ins de um usuário, mais recentes primeiro (RF08 - colega)
  def list_user_check_ins(user_id) do
    Repo.all(
      from ci in CheckIn,
        where: ci.user_id == ^user_id,
        order_by: [desc: ci.inserted_at],
        preload: [:habit]
    )
  end

  # Retorna os últimos check-ins de todos os usuários para o feed (RF09 - colega)
  def list_recent_check_ins(limit \\ 20) do
    Repo.all(
      from ci in CheckIn,
        order_by: [desc: ci.inserted_at],
        limit: ^limit,
        preload: [:user, :habit]
    )
  end
end
