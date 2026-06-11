defmodule EcoHabits.Accounts.UserNotifier do
  import Swoosh.Email
  alias EcoHabits.Mailer

  # Envia o e-mail usando Swoosh. Em dev, o e-mail aparece em /dev/mailbox
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"EcoHabits", "no-reply@ecohabits.app"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Envia link de confirmação de e-mail para novos cadastros
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirme seu e-mail no EcoHabits", """
    Olá #{user.name},

    Bem-vindo ao EcoHabits! Para ativar sua conta, clique no link abaixo:

    #{url}

    O link expira em 7 dias. Se você não criou essa conta, ignore este e-mail.
    """)
  end

  # Envia link para redefinição de senha
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Redefinir senha - EcoHabits", """
    Olá #{user.name},

    Recebemos uma solicitação para redefinir sua senha. Clique no link abaixo:

    #{url}

    O link expira em 1 dia. Se você não fez essa solicitação, ignore este e-mail.
    """)
  end

  # Envia link para confirmar troca de e-mail
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Confirmar novo e-mail - EcoHabits", """
    Olá #{user.name},

    Para confirmar a troca do seu e-mail, clique no link abaixo:

    #{url}

    O link expira em 7 dias.
    """)
  end
end
