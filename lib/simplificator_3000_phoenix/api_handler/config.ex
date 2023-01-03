defmodule Simplificator3000Phoenix.ApiHandler.Config do
  alias Simplificator3000Phoenix.ApiHandler

  @config_name :simplificator_3000_phoenix
  def get_from_config(key) do
    Application.get_env(@config_name, key)
  end

  @handler_method_postfix :handler_postfix
  def get_handler_method_postfix(options) do
    with nil <- Keyword.get(options, @handler_method_postfix, nil),
         nil <- get_from_config(@handler_method_postfix) do
      "_handler"
    end
  end

  @response_handler_key :response_handler
  def get_response_handler(options) do
    with nil <- Keyword.get(options, @response_handler_key, nil),
         nil <- get_from_config(@response_handler_key) do
      &ApiHandler.DefaultHandlers.default_response_handler/2
    end
  end

  @invalid_params_handler_key :invalid_params_handler
  def get_invalid_params_handler(options) do
    with nil <- Keyword.get(options, @invalid_params_handler_key, nil),
         nil <- get_from_config(@invalid_params_handler_key) do
      &ApiHandler.DefaultHandlers.default_invalid_params_handler/2
    end
  end

  @fallback_handler_key :fallback_handler

  def get_fallback_handler(options) do
    with nil <- Keyword.get(options, @fallback_handler_key, nil),
         nil <- get_from_config(@fallback_handler_key) do
      &ApiHandler.DefaultHandlers.default_fallback_controller/3
    end
  end

  @fallback_enabled_key :fallback_enabled

  def get_fallback_enabled(options) do
    with nil <- Keyword.get(options, @fallback_enabled_key, nil),
         nil <- get_from_config(@fallback_enabled_key) do
      true
    end
  end

  @permission_handler :permission_handler

  def get_permission_handler(options) do
    with nil <- Keyword.get(options, @permission_handler, nil),
         nil <- get_from_config(@permission_handler) do
      raise "permission handler not defined"
    end
  end

  @auth_operator_key :auth_operator
  def get_auth_operator(options) do
    with nil <- Keyword.get(options, @auth_operator_key, nil),
         nil <- get_from_config(@auth_operator_key) do
      :or
    end
  end

  @unauthorized_handler_key :unauthorized_handler
  def get_unauthorized_handler(options) do
    with nil <- Keyword.get(options, @unauthorized_handler_key, nil),
         nil <- get_from_config(@unauthorized_handler_key) do
      &ApiHandler.DefaultHandlers.default_unauthorized_handler/1
    end
  end
end
