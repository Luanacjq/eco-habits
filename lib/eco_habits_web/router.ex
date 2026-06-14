defmodule EcoHabitsWeb.Router do
  use EcoHabitsWeb, :router

  import EcoHabitsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EcoHabitsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Rota pública da home
  scope "/", EcoHabitsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Rotas de autenticação — acessíveis só para quem NÃO está logado (RF01, RF02)
  scope "/", EcoHabitsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{EcoHabitsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  # Rotas de confirmação de e-mail — podem ser acessadas com ou sem login
  scope "/", EcoHabitsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{EcoHabitsWeb.UserAuth, :mount_current_scope}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  # Rotas protegidas — exigem usuário autenticado (RF02, RF03, RF04, RF05)
  scope "/", EcoHabitsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated,
      on_mount: [{EcoHabitsWeb.UserAuth, :require_authenticated}] do
      live "/perfil", ProfileLive, :show
      live "/habitos", HabitLive.Index, :index
      live "/check-in", CheckInLive.Index, :index
      live "/painel", DashboardLive.Index, :index
      live "/feed", FeedLive.Index, :index
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end

    delete "/users/log_out", UserSessionController, :delete
  end

  if Application.compile_env(:eco_habits, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EcoHabitsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
