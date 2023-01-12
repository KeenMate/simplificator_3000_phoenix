# Simplificator 3000 Phoenix

[![Hex pm](http://img.shields.io/hexpm/v/simplificator_3000.svg?style=flat)](https://hex.pm/packages/simplificator_3000_phoenix) [![Hexdocs](https://img.shields.io/badge/hex-docs-blue.svg?style=flat)](https://hexdocs.pm/simplificator_3000_phoenix/)

Simplificator 3000 is a package containing various helpers for easier work in Phoenix.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `simplificator_3000_phoenix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:simplificator_3000_phoenix, "~> 1.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/simplificator_3000_phoenix>.

## Macros

Package contains macros for standardizing communications in channels and api endpoints. In both channel and api handler you set required params/payload scheme (using tarams), check required permission, groups or roles.
You can configure everything either for whole app (in config) or just one method

### API Handler

Just import  ```Simplificator3000Phoenix.ApiHandler```
then you use
```api_handler(action_name,params_scheme,optional_options)```
to define action and then create handler for given action which needs to be named action + postfix ("_handler" by default). Handler will be called only after permissions are check and params validated and parsed.

Minimal usage

``` elixir
  api_handler(:minimal, %{})

  def minimal_handler(conn, _params) do
    ok("hello there")
  end
```

With params scheme (see Tarams for scheme definition)

``` elixir
  @number_scheme %{
    number: [type: :integer, number: [greater_than: 0], required: true]
  }
  api_handler(:minimal_parameters, @number_scheme, fallback_options: [full_error: true])

  def minimal_parameters_handler(conn, %{number: num}) do
    case num do
      1 -> ok(%{three_times_bigger: num * 3})
      2 -> ok(%{three_times_bigger: num * 3}, %{data: "no this is metadata"})
      3 -> error(reason: :who_not, msg: "message", response_code: 501)
      4 -> {:error, :some_error_stuff}
    end
  end
```

To return data use ok or error macro (variable named conn has to be defined to use them). You can also return just conn if you want to manually reply. If you return anything else than {conn,_} or conn it will be handeled by fallback handler. You can enable/disable fallback handler with ```:fallback_enabled```. You can also pass arguments to fallback handler with ```:fallback_options```.

Default fallback handler return 500 internal server error by default, if you set ```fallback_options: [full_error: true]``` it will return inspected error as detail

With nested scheme

``` elixir
  @nested_scheme %{
    name: :string,
    email: [type: :string, required: true],
    addresses: [
      type:
        {
          :array,
         %{
           street: :string,
           district: :string,
           city: :string,
           zip_code: [type: :integer, number: [min: 10_000, max: 99_999]]
          }
        }
    ]
  }
  api_handler(:nested, @nested_scheme)

  def nested_handler(conn, params) do
    ok(params)
  end
```

With permissions check

``` elixir
  @params_scheme %{
    permissions: [type: {:array, :string}],
    groups: [type: {:array, :string}],
    roles: [type: {:array, :string}]
  }
  api_handler(:action, @params_scheme,
    roles: {["role", "role1"], :and},
    groups: ["group"],
    permissions: ["permission"]
  )

  def action_handler(conn, params) do
    ok(params)
  end

```

when you require permission/groups/roles, you either pass list of required stuff, or {list,operator }. Handler method will be called with ```(conn/socket, {type,required_stuff} ||  {type,required_stuff,operator} )``` and you handler will return true/false

```:unauthorized_handler``` will be called if request is not authorized

#### Api handler Configuration

``` elixir
config :simplificator_3000_phoenix,
  api_handler: %{
    # configuration goes here
  },
```

| key                    | type                                | detail |
| ---------------------- | ----------------------------------- | ------ |
| handler_postfix        | string                              |
| response_handler       | func(conn,handler_return) -> (conn) |
| invalid_params_handler | func(conn,params_error) -> (conn)   |
| fallback_handler       | func(conn,error,options) -> (conn)  |
| fallback_enabled       | boolean                             |
| permission_handler     | func(conn,required) -> boolean      |
| auth_operator          | :or or :and                         |
| unauthorized_handler   | func(conn) -> conn                  |

### Channels

add ```use Simplificator3000Phoenix.Channel```

Now replace join funtion with this

```elixir
def join("topic", payload, socket) do
  if authorized?("topic", payload, socket) do
    #required permission are check, you can check more stuff here before acception join
    {:ok, socket}
  else
    unauthorized(socket)
  end
end
```

to check permissions when joining channel

```elixir
use Simplificator3000Phoenix.Channel, permissions: ["permissions"], roles: {["role1",:and]}
```

to add handler for message use
```message(event,params_scheme,options)```
it is simular to ```api_handler``` except it doesnt have fallback controller and handler method has same name as event  
return (success/error)_(reply/push) to respond or no_reply to dont
examples:

```elixir
  message(:test, %{})

  def test(socket, _payload) do
    success_reply(socket, "hello")
  end

  message(
    :number,
    %{number_with: [type: :integer, required: true]},
    permissions: {["group2", "group3"], :and}
  )

  def number(socket, payload) do
    success_reply(socket, inspect(payload))
  end

  message(
    :async,
    %{number_with: [type: :integer, required: true]},
    roles: ["group1"]
  )

  def async(socket, payload) do

    Task.start_link(fn ->
      success_reply(socket, inspect(payload))
    end)

    no_reply()
  end


```

to add pubsub handler use ```sub(event)```
and define handler ```event(socket,message)``` pubsub messages need to have following format {event,message}

example:

```elixir
  message(:send_after)

  def send_after(socket, _payload) do
    #simulate pubsub message
    Process.send_after(self(), {:hello, %{message: "hello future me"}}, 1000)

    no_reply()
  end

  sub(:hello)

  def hello(socket, message) do
    IO.puts("HELLo")
    success_push(socket, "reply", message.message)
  end

```

#### Channel Configuration

``` elixir
config :simplificator_3000_phoenix,
  channel: %{
    # configuration goes here
  },
```

| key                    | type                              | detail |
| ---------------------- | --------------------------------- | ------ |
| invalid_params_handler | func(conn,params_error) -> (conn) |
| unauthorized_handler   | func(conn) -> conn                |

## Configuration

Example configuration

Only thing you have to configure is permission_handler (only if you use permissions, groups or roles)

```elixir
config :simplificator_3000_phoenix,
  auth_operator: 
  permission_handler:
  api_handler: %{
    #api handler configuration
  },
  channel: %{
    #channel configuration
  }

```
