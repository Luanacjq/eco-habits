defmodule EcoHabitsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use EcoHabitsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar-glass sticky top-0 z-40 h-14">
      <div class="grid grid-cols-3 items-center w-full max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 h-full">

        <%!-- Coluna esquerda: logo --%>
        <div class="flex items-center">
          <.link navigate={~p"/habitos"} class="flex items-center gap-2 font-bold text-base-content hover:text-primary transition-colors group">
            <span class="text-xl group-hover:scale-110 transition-transform inline-block">🌱</span>
            <span class="text-base tracking-tight">EcoHabits</span>
          </.link>
        </div>

        <%!-- Coluna central: links de navegação, centralizados e sem caixa --%>
        <nav :if={@current_scope} class="hidden sm:flex items-center justify-center gap-6">
          <.link navigate={~p"/habitos"} class="text-sm font-medium text-base-content/60 hover:text-primary transition-colors relative group">
            Hábitos
            <span class="absolute -bottom-[18px] left-0 right-0 h-0.5 bg-primary rounded-full scale-x-0 group-hover:scale-x-100 transition-transform origin-center" />
          </.link>
          <.link navigate={~p"/perfil"} class="text-sm font-medium text-base-content/60 hover:text-primary transition-colors relative group">
            Perfil
            <span class="absolute -bottom-[18px] left-0 right-0 h-0.5 bg-primary rounded-full scale-x-0 group-hover:scale-x-100 transition-transform origin-center" />
          </.link>
        </nav>
        <div :if={is_nil(@current_scope)} class="hidden sm:block" />

        <%!-- Coluna direita: tema + avatar / botões de auth --%>
        <div class="flex items-center justify-end gap-2">
          <.theme_toggle />

          <div :if={@current_scope} class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="cursor-pointer flex items-center gap-1.5 pl-1 pr-2 py-1 rounded-xl hover:bg-base-200/60 transition-colors">
              <div class="w-7 h-7 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs font-bold shrink-0">
                {String.first(@current_scope.user.name) |> String.upcase()}
              </div>
              <span class="text-sm font-medium hidden sm:block max-w-[90px] truncate">
                {hd(String.split(@current_scope.user.name))}
              </span>
              <.icon name="hero-chevron-down-micro" class="size-3 text-base-content/40" />
            </div>
            <div tabindex="0" class="dropdown-content z-50 mt-2 w-56 anim-scale-in right-0">
              <div class="glass-card rounded-2xl shadow-xl overflow-hidden">
                <div class="px-4 py-3 border-b border-base-300/50">
                  <p class="text-sm font-semibold truncate">{@current_scope.user.name}</p>
                  <p class="text-xs text-base-content/50 truncate">{@current_scope.user.email}</p>
                </div>
                <ul class="menu menu-sm p-1.5 gap-0.5">
                  <li><.link navigate={~p"/perfil"} class="rounded-lg">👤 Meu perfil</.link></li>
                  <li><.link navigate={~p"/users/settings"} class="rounded-lg">⚙️ Configurações</.link></li>
                  <li>
                    <.link href={~p"/users/log_out"} method="delete" class="rounded-lg text-error hover:bg-error/10">
                      🚪 Sair
                    </.link>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <div :if={is_nil(@current_scope)} class="flex gap-2">
            <.link navigate={~p"/users/log_in"} class="btn btn-ghost btn-sm">Entrar</.link>
            <.link navigate={~p"/users/register"} class="btn btn-primary btn-sm">Criar conta</.link>
          </div>
        </div>

      </div>
    </header>

    <main class="px-4 pt-8 pb-16 sm:px-6 lg:px-8 relative z-10">
      <div class="mx-auto max-w-5xl anim-fade-up">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
