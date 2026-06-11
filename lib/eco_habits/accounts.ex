defmodule EcoHabits.Accounts do
  @moduledoc """
  Contexto responsável por usuários e autenticação.
  """

  import Ecto.Query
  alias EcoHabits.Repo
  alias EcoHabits.Accounts.{User, UserToken, UserNotifier}

  # ---- Consultas de usuário ----

  # Retorna o usuário pelo e-mail, ou nil se não existir
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  # Retorna o usuário pelo e-mail e verifica a senha. Usado no login (RF02)
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  # Retorna o usuário pelo id, levanta erro se não encontrar
  def get_user!(id), do: Repo.get!(User, id)

  # ---- Cadastro ----

  # Cria um novo usuário com validação completa (RF01)
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  # Retorna um changeset vazio para renderizar o formulário de cadastro
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  # ---- Perfil ----

  # Retorna um changeset para edição do perfil (nome e bio)
  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  # Salva as alterações de perfil do usuário (RF03)
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  # Calcula a pontuação total acumulada pelo usuário com base nos check-ins (RF03)
  def get_total_points(user_id) do
    from(ci in EcoHabits.CheckIns.CheckIn,
      join: h in assoc(ci, :habit),
      where: ci.user_id == ^user_id,
      select: sum(h.points)
    )
    |> Repo.one()
    |> Kernel.||(0)
  end

  # ---- Troca de e-mail ----

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = User.email_changeset(user, %{email: email})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  # ---- Troca de senha ----

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  # ---- Sessão / Tokens ----

  # Cria um token de sessão e persiste no banco (RF02)
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  # Busca o usuário a partir do token de sessão (usado na autenticação de cada request)
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  # Remove o token de sessão, efetivando o logout (RF02)
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  # ---- Confirmação de e-mail ----

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         {user, _token} when not is_nil(user.confirmed_at) <- Repo.one(query) do
      {:error, :already_confirmed}
    else
      _ ->
        with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
             {user, token_struct} when is_nil(user.confirmed_at) <- Repo.one(query) do
          confirm_user_multi(user, token_struct)
          |> Repo.transaction()
          |> case do
            {:ok, %{user: user}} -> {:ok, user}
            _ -> :error
          end
        else
          _ -> :error
        end
    end
  end

  defp confirm_user_multi(user, token) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete(:token, token)
  end

  # ---- Reset de senha ----

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         {user, _} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
