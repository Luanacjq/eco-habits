defmodule EcoHabits.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :bio, :string
    # virtual: true significa que não é salvo no banco, só usado durante a requisição
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime

    has_many :habits, EcoHabits.Habits.Habit
    has_many :check_ins, EcoHabits.CheckIns.CheckIn

    timestamps(type: :utc_datetime)
  end

  # Changeset para cadastro de novo usuário (RF01)
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :name])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 60)
    |> validate_email(opts)
    |> validate_password(opts)
  end

  # Changeset para atualizar só o e-mail
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  # Changeset para atualizar a senha
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  # Changeset para editar nome e bio no perfil (RF03)
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :bio])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 60)
    |> validate_length(:bio, max: 500)
  end

  # Marca o usuário como confirmado após clicar no link do e-mail
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  # Verifica a senha atual antes de permitir mudanças sensíveis
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  # Verifica se a senha bate com o hash armazenado
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    # Roda o algoritmo mesmo sem usuário válido para evitar timing attacks
    Bcrypt.no_user_verify()
    false
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, EcoHabits.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end
end
