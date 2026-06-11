defmodule EcoHabits.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  # Sessão dura 60 dias
  @session_validity_in_days 60

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string

    belongs_to :user, EcoHabits.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  # Gera o token de sessão e retorna {token_em_texto, registro_para_banco}
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(32)
    {token, %__MODULE__{token: :crypto.hash(@hash_algorithm, token), context: "session", user_id: user.id}}
  end

  # Query para buscar usuário a partir de um token de sessão válido
  def verify_session_token_query(token) do
    hashed = :crypto.hash(@hash_algorithm, token)
    days = @session_validity_in_days

    query =
      from t in __MODULE__,
        join: u in assoc(t, :user),
        where: t.token == ^hashed and t.context == "session",
        where: t.inserted_at > ago(^days, "day"),
        select: u

    {:ok, query}
  end

  # Gera token para e-mail (confirmação, reset de senha, troca de e-mail)
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(32)
    hashed = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{
       token: hashed,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  # Query para verificar token de e-mail dentro do prazo de validade
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded} ->
        hashed = :crypto.hash(@hash_algorithm, decoded)
        validity = days_for_context(context)

        query =
          from t in __MODULE__,
            join: u in assoc(t, :user),
            where: t.token == ^hashed,
            where: t.context == ^context,
            where: t.inserted_at > ago(^validity, "day"),
            select: {u, t}

        {:ok, query}

      :error ->
        :error
    end
  end

  # Query para verificar token de mudança de e-mail
  def verify_change_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded} ->
        hashed = :crypto.hash(@hash_algorithm, decoded)

        query =
          from t in __MODULE__,
            where: t.token == ^hashed and t.context == ^context

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: 7
  defp days_for_context("reset_password"), do: 1

  # Query para buscar tokens de um usuário por um ou mais contextos
  def by_user_and_contexts_query(user, :all) do
    from t in __MODULE__, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, contexts) when is_list(contexts) do
    from t in __MODULE__, where: t.user_id == ^user.id and t.context in ^contexts
  end

  # Query para buscar token pelo valor e contexto (usado no logout)
  def by_token_and_context_query(token, context) do
    from t in __MODULE__, where: t.token == ^token and t.context == ^context
  end
end
