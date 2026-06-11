defmodule EcoHabits.CheckIns.CheckIn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "check_ins" do
    field :date, :date

    belongs_to :user, EcoHabits.Accounts.User
    belongs_to :habit, EcoHabits.Habits.Habit

    timestamps(type: :utc_datetime)
  end

  # Changeset para registrar um check-in diário (RF07 - implementado pelo colega)
  def changeset(check_in, attrs) do
    check_in
    |> cast(attrs, [:date, :user_id, :habit_id])
    |> validate_required([:date, :user_id, :habit_id])
    |> unique_constraint([:user_id, :habit_id, :date],
        name: :check_ins_user_id_habit_id_date_index,
        message: "você já registrou esse hábito hoje")
  end
end
