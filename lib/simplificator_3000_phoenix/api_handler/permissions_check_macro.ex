defmodule Simplificator3000Phoenix.ApiHandler.PermissionsCheck do
  alias Simplificator3000Phoenix.ApiHandler.Config

  @permissions :permissions
  @roles :roles
  @groups :groups

  def check_permissions(conn, options) do
    required_permissions = Keyword.get(options, @permissions, false)
    required_roles = Keyword.get(options, @roles, false)
    required_groups = Keyword.get(options, @groups, false)

    if(required_permissions || required_roles || required_groups) do
      permission_handler = Config.get_permission_handler(options)
      auth_operator = Config.get_auth_operator(options)

      check_results = [
        check(conn, permission_handler, @permissions, required_permissions),
        check(conn, permission_handler, @roles, required_roles),
        check(conn, permission_handler, @groups, required_groups)
      ]

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

  defp check(_conn, _handler, _type, required) when required == false do
    true
  end

  defp check(conn, handler, type, required) do
    handler_params =
      case required do
        {requirements, operator} -> {type, requirements, operator}
        requirements -> {type, requirements}
      end

    handler.(conn, handler_params)
  end
end
