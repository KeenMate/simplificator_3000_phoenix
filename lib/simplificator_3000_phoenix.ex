defmodule Simplificator3000Phoenix do
  def controller do
    quote do
      def set_title(conn, title), do: Plug.Conn.assign(conn, :title, title)
    end
  end

  def view do
    quote do
      @before_compile {unquote(__MODULE__), :view_before_compile}
    end
  end

  def layout do
    quote do
      def title(conn, assigns) do
        {:ok, application} = :application.get_application()
        app_name = Application.get_env(application, :page_title)
        title_separator = Application.get_env(application, :title_separator)

        title =
          case view_module(conn).page_title(view_template(conn), assigns) do
            title when is_binary(title) -> title
            _ -> Map.get(assigns, :title)
          end

        case {title, title_separator} do
          {nil, _} -> app_name
          {title, nil} -> title
          {title, separator} -> title <> " " <> separator <> " " <> app_name
        end


      end
    end
  end

  defmacro view_before_compile(_env) do
    quote do
      def page_title(_, _), do: nil
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
