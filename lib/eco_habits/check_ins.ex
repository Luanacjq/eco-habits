defmodule EcoHabits.CheckIns do
  @moduledoc """
  Contexto responsável pelos check-ins diários de hábitos.
  Implementado pelo Módulo C (RF07, RF08, RF09).
  """

  import Ecto.Query
  alias EcoHabits.Repo
  alias EcoHabits.CheckIns.CheckIn

  @feed_topic "community_feed"

  # ---- PubSub (RF09) ----

  @doc "Tópico usado pelo feed da comunidade em tempo real."
  def feed_topic, do: @feed_topic

  @doc "Inscreve o processo atual nas atualizações do feed da comunidade (RF09)."
  def subscribe_feed do
    Phoenix.PubSub.subscribe(EcoHabits.PubSub, @feed_topic)
  end

  # Notifica todos os LiveViews inscritos que um novo check-in foi criado (RF09)
  defp broadcast_new_check_in(check_in) do
    Phoenix.PubSub.broadcast(
      EcoHabits.PubSub,
      @feed_topic,
      {:new_check_in, check_in}
    )

    check_in
  end

  # ---- Registro de check-in (RF07) ----

  @doc """
  Registra um check-in para o usuário e hábito informados (RF07).

  A duplicidade no mesmo dia para o mesmo usuário/hábito é impedida pelo
  índice único do banco, refletido como erro no changeset. Em caso de
  sucesso, recarrega as associações e dispara o broadcast para o feed (RF09).
  """
  def create_check_in(attrs \\ %{}) do
    %CheckIn{}
    |> CheckIn.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, check_in} ->
        check_in = Repo.preload(check_in, [:user, :habit])
        broadcast_new_check_in(check_in)
        {:ok, check_in}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Verifica se o usuário já registrou determinado hábito na data informada (RF07).
  Usado para desabilitar o botão de check-in na interface.
  """
  def checked_in_today?(user_id, habit_id, date) do
    Repo.exists?(
      from ci in CheckIn,
        where:
          ci.user_id == ^user_id and
            ci.habit_id == ^habit_id and
            ci.date == ^date
    )
  end

  @doc "Retorna os ids dos hábitos já registrados pelo usuário na data informada (RF07)."
  def habit_ids_checked_in(user_id, date) do
    Repo.all(
      from ci in CheckIn,
        where: ci.user_id == ^user_id and ci.date == ^date,
        select: ci.habit_id
    )
  end

  # ---- Histórico e dashboard (RF08) ----

  @doc "Retorna todos os check-ins de um usuário, mais recentes primeiro (RF08)."
  def list_user_check_ins(user_id) do
    Repo.all(
      from ci in CheckIn,
        where: ci.user_id == ^user_id,
        order_by: [desc: ci.inserted_at],
        preload: [:habit]
    )
  end

  @doc """
  Calcula a pontuação acumulada por semana de um usuário (RF08).

  Retorna uma lista de mapas ordenada da semana mais recente para a mais antiga,
  cada um com a data de início da semana (segunda-feira), o total de pontos e a
  quantidade de check-ins daquela semana.
  """
  def weekly_points(user_id) do
    list_user_check_ins(user_id)
    |> Enum.group_by(fn ci -> week_start(ci.date) end)
    |> Enum.map(fn {week_start, check_ins} ->
      %{
        week_start: week_start,
        points: Enum.reduce(check_ins, 0, fn ci, acc -> acc + ci.habit.points end),
        count: length(check_ins)
      }
    end)
    |> Enum.sort_by(& &1.week_start, {:desc, Date})
  end

  @doc "Pontuação total acumulada pelo usuário com base nos check-ins (RF08)."
  def total_points(user_id) do
    Repo.one(
      from ci in CheckIn,
        join: h in assoc(ci, :habit),
        where: ci.user_id == ^user_id,
        select: coalesce(sum(h.points), 0)
    )
  end

  # Retorna a segunda-feira da semana de uma data (início da semana ISO).
  defp week_start(date) do
    Date.add(date, -(Date.day_of_week(date) - 1))
  end

  # ---- Feed da comunidade (RF09) ----

  @doc "Retorna os últimos check-ins de todos os usuários para o feed (RF09)."
  def list_recent_check_ins(limit \\ 20) do
    Repo.all(
      from ci in CheckIn,
        order_by: [desc: ci.inserted_at],
        limit: ^limit,
        preload: [:user, :habit]
    )
  end
end
