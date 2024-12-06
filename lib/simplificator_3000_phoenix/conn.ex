defmodule Simplificator3000Phoenix.Conn do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  import Simplificator3000.MapHelpers, only: [camel_cased_map_keys: 1, snake_cased_map_keys: 1]

  def success(data \\ nil, metadata \\ nil) do
    %{data: data, metadata: metadata}
  end

  def success_response(conn, data \\ nil, metadata \\ nil) do
    response = success(data, metadata) |> map_response()

    conn
    |> put_status(200)
    |> json(response)
  end

  def error(opts \\ []) do
    %{
      error: %{
        code: Keyword.get(opts, :reason),
        msg: Keyword.get(opts, :msg),
        detail: Keyword.get(opts, :detail)
      },
      metadata: Keyword.get(opts, :metadata)
    }
  end

  def error_response(conn, opts \\ []) do
    response = error(opts) |> map_response()

    conn
    |> put_status(Keyword.get(opts, :response_code, 500))
    |> json(response)
  end

  # * Mapping and Parsing

  def map_response(list) when is_list(list) do
    Enum.map(list, &map_response/1)
  end

  def map_response(tuple) when is_tuple(tuple) do
    Tuple.to_list(tuple)
  end

  def map_response(%Decimal{} = dec) do
    Decimal.to_float(dec)
  end

  def map_response(%DateTime{} = val), do: val

  def map_response(%Time{} = val), do: val

  def map_response(%Date{} = val), do: val

  def map_response(%{} = struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> map_response()
  end

  def map_response(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn {key, val}, acc ->
      Map.put(acc, key, map_response(val))
    end)
    |> camel_cased_map_keys()
  end

  def map_response(val), do: val

  def parse_payload(list) when is_list(list) do
    Enum.map(list, &parse_payload/1)
  end

  def parse_payload(%Decimal{} = dec), do: dec

  def parse_payload(%{} = struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> parse_payload()
  end

  def parse_payload(map) when is_map(map) do
    snake_cased_map_keys(map)
  end

  def parse_payload(val), do: val
end
