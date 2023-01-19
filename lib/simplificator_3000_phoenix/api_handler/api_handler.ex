defmodule Simplificator3000Phoenix.ApiHandler do
  alias Simplificator3000Phoenix.ApiHandler.ApiHandlerConfig, as: Config
  @fallback_options_key :fallback_options

  defmacro api_handler(method_name, params_template, options \\ []) do
    if(!is_atom(method_name)) do
      raise "method_name must be atom"
    end

    handler_method_postfix = Config.get_handler_method_postfix(options)
    # to existing should prevent misspelling of method names
    handler_method_name =
      String.to_existing_atom(Atom.to_string(method_name) <> handler_method_postfix)

    invalid_params_handler = Config.get_invalid_params_handler(options)

    unauthorized_handler = Config.get_unauthorized_handler(options)

    quote do
      def unquote(method_name)(conn, params) do
        if(
          Simplificator3000Phoenix.PermissionsCheck.check_permissions(
            conn,
            unquote(options)
          )
        ) do
          snake_cased_params = Simplificator3000.MapHelpers.snake_cased_map_keys(params)

          with {:ok, better_params} <- Tarams.cast(snake_cased_params, unquote(params_template)) do
            unquote(call_handler_method(handler_method_name, options))
          else
            {:error, errors} ->
              unquote(invalid_params_handler).(conn, errors)
          end
        else
          unquote(unauthorized_handler).(conn, unquote(options))
        end
      end
    end
  end

  defp call_handler_method(handler_method_name, options) do
    response_handler = Config.get_response_handler(options)

    quote do
      case(apply(__MODULE__, unquote(handler_method_name), [conn, better_params])) do
        # Got valid response call response handler
        {%Plug.Conn{} = conn, result} ->
          unquote(response_handler).(conn, result)

        # Allow to manually responde
        %Plug.Conn{} = conn ->
          conn

        err ->
          unquote(handle_fallback(options))
      end
    end
  end

  defp handle_fallback(options) do
    fallback_handler = Config.get_fallback_handler(options)
    fallback_options = Keyword.get(options, @fallback_options_key)
    fallback_enabled = Config.get_fallback_enabled(options)

    if fallback_enabled do
      quote do
        unquote(fallback_handler).(conn, err, unquote(fallback_options))
      end
    else
      quote do
        err
      end
    end
  end

  defmacro ok(data) do
    quote do
      {var!(conn), {:ok, unquote(data)}}
    end
  end

  defmacro ok(data, metadata) do
    quote do
      {var!(conn), {:ok, unquote(data), unquote(metadata)}}
    end
  end

  defmacro error(options) do
    quote do
      {var!(conn), {:error, unquote(options)}}
    end
  end
end
