defmodule Simplificator3000Phoenix.PermissionsCheck do
  alias Simplificator3000Phoenix.Config

  @permissions :permissions
  @roles :roles
  @groups :groups

  def check_permissions(conn_or_socket, options) do
    required_permissions = Keyword.get(options, @permissions)
    required_roles = Keyword.get(options, @roles)
    required_groups = Keyword.get(options, @groups)

    if(required_permissions || required_roles || required_groups) do
      permission_handler = Config.get_permission_handler(options)
      auth_operator = Config.get_auth_operator(options)

      check_results =
        [
          check(conn_or_socket, permission_handler, @permissions, required_permissions),
          check(conn_or_socket, permission_handler, @roles, required_roles),
          check(conn_or_socket, permission_handler, @groups, required_groups)
        ]
        |> Enum.filter(&(&1 != :no_check))

      case auth_operator do
        :or ->
          Enum.any?(check_results)

        :and ->
          Enum.all?(check_results)
      end
    else
      true
    end
  end

  defp check(_conn_or_socket, _handler, _type, nil) do
    # so we can filter results we didnt check
    :no_check
  end

  defp check(conn_or_socket, handler, type, required) do
    handler_params =
      case required do
        {requirements, operator} -> {type, requirements, operator}
        requirements -> {type, requirements}
      end

    handler.(conn_or_socket, handler_params)
  end
end
