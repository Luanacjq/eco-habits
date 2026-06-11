defmodule EcoHabits.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  # Categorias permitidas para um hábito sustentável (RF04)
  @categories ~w(alimentacao transporte energia agua residuos)

  schema "habits" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :points, :integer

    belongs_to :user, EcoHabits.Accounts.User
    has_many :check_ins, EcoHabits.CheckIns.CheckIn

    timestamps(type: :utc_datetime)
  end

  # Retorna a lista de categorias válidas para uso nos formulários
  def categories, do: @categories

  # Changeset principal para criação e edição de hábitos
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :description, :category, :points, :user_id])
    |> validate_required([:name, :category, :points, :user_id])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_inclusion(:category, @categories, message: "must be a valid category")
    |> validate_number(:points, greater_than: 0, less_than_or_equal_to: 100,
        message: "must be between 1 and 100")
  end
end
