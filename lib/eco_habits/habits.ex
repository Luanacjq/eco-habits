defmodule EcoHabits.Habits do
  @moduledoc """
  Contexto responsável pelo gerenciamento de hábitos sustentáveis.
  """

  import Ecto.Query
  alias EcoHabits.Repo
  alias EcoHabits.Habits.Habit

  # Retorna todos os hábitos, ordenados do mais recente para o mais antigo
  def list_habits do
    Repo.all(from h in Habit, order_by: [desc: h.inserted_at], preload: [:user])
  end

  # Retorna hábitos filtrados por categoria. Se a categoria for nil ou vazia, retorna todos (RF05)
  def list_habits(nil), do: list_habits()
  def list_habits(""), do: list_habits()

  def list_habits(category) do
    Repo.all(
      from h in Habit,
        where: h.category == ^category,
        order_by: [desc: h.inserted_at],
        preload: [:user]
    )
  end

  # Retorna todos os hábitos de um usuário específico
  def list_user_habits(user_id) do
    Repo.all(from h in Habit, where: h.user_id == ^user_id, order_by: [desc: h.inserted_at])
  end

  # Busca um hábito pelo id, levanta erro se não existir
  def get_habit!(id), do: Repo.get!(Habit, id)

  # Cria um novo hábito associado ao usuário logado (RF04)
  def create_habit(attrs \\ %{}) do
    %Habit{}
    |> Habit.changeset(attrs)
    |> Repo.insert()
  end

  # Atualiza um hábito existente (RF06 - do colega)
  def update_habit(%Habit{} = habit, attrs) do
    habit
    |> Habit.changeset(attrs)
    |> Repo.update()
  end

  # Remove um hábito do banco de dados (RF06 - do colega)
  def delete_habit(%Habit{} = habit) do
    Repo.delete(habit)
  end

  # Retorna um changeset vazio para o formulário de criação
  def change_habit(%Habit{} = habit, attrs \\ %{}) do
    Habit.changeset(habit, attrs)
  end
end
