defmodule Simplificator3000Phoenix.Config do
  @config_name :simplificator_3000_phoenix
  def get_from_config(key) do
    Application.get_env(@config_name, key)
  end

  @auth_handler :auth_handler

  def get_auth_handler(options) do
    with nil <- Keyword.get(options, @auth_handler, nil),
         nil <- get_from_config(@auth_handler) do
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
end
