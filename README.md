# Reproduction for custom `Ash.Type` question

## Running the reproduction

```sh
mix setup && iex -S mix phx.server
```

http://localhost:4000/admin?domain=Entities&resource=Entity&table=&action_type=read&action=read

## Description

This is a reproduction of an issue I've had with custom types.

In short, using the example implementation for float from the documentation resets the attribute upon validation when changing other attributes in the changeset (AshAdmin).

This app has a domain `Entities` with one resource `Entity` having the attributes:

- `:name` of the built-in type `:string`,
- `:size` of the custom type `:custom_float` defined in this codebase and
- `:balance` of the custom type `:money` from AshMoney (as installed by Igniter).

The body of the function that implements the custom type `:custom_float` is lifted verbatim from [the example in the documentation](https://hexdocs.pm/ash/Ash.Type.html#module-defining-custom-types):

```elixir
defmodule DemoRepo.Types.CustomFloat do
  use Ash.Type

  @impl Ash.Type
  def storage_type(_), do: :float

  @impl Ash.Type
  def cast_input(nil, _), do: {:ok, nil}

  def cast_input(value, _) do
    Ecto.Type.cast(:float, value)
  end

  @impl Ash.Type
  def cast_stored(nil, _), do: {:ok, nil}

  def cast_stored(value, _) do
    Ecto.Type.load(:float, value)
  end

  @impl Ash.Type
  def dump_to_native(nil, _), do: {:ok, nil}

  def dump_to_native(value, _) do
    Ecto.Type.dump(:float, value)
  end
end
```

The type `:custom_float` is, as far as I understand it, duly configured in `config/config.exs` like so:

```elixir
config :ash,
  # yada yada yada
  custom_types: [
    money: AshMoney.Types.Money,
    custom_float: DemoRepo.Types.CustomFloat
  ]
```

When creating an Entity in AshAdmin using a default `:create` action that accepts `:name`, `:size` and `:balance`:

```elixir
defaults [
  :read,
  :destroy,
  create: [:name, :size, :balance], # <- This bad boy right here
  update: [:name, :size, :balance]
]
```

it is possible to enter a value for `:size` in the form and have it passed to the changeset for persistence. However, touching any other field - thus triggering a validation - while `:size` has a value will set `:size` to `nil`. The same goes for the `:balance` attribute.

Creating an Entity using a create action `:instrumented_create`:

```elixir
create :instrumented_create do
  accept [:name, :size]

  change fn changeset, _context -> changeset |> dbg() end
end
```

yields the same result.

Looking at the output after having put first `name: "A"` and then `size: 1` in the form:

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :create,
  action: :instrumented_create,
  attributes: %{name: "A", size: 1.0},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: nil,
    name: nil,
    size: nil,
    balance: nil,
    __meta__: #Ecto.Schema.Metadata<:built, "entities">
  },
  valid?: true
>
```

and then looking after again editing the `:name` field in the form one gets:

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :create,
  action: :instrumented_create,
  attributes: %{name: "Ab", size: 1.0},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: nil,
    name: nil,
    size: nil,
    balance: nil,
    __meta__: #Ecto.Schema.Metadata<:built, "entities">
  },
  valid?: true
>
```

where `size: 1.0` actually shows up in the in the changeset, but has disappeard in the form.

Touching `:name` again, quite reasonably, results in the following since `:size` was not left in the form and therefore didn't make it to the params:

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :create,
  action: :instrumented_create,
  attributes: %{name: "Abc", size: nil},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: nil,
    name: nil,
    size: nil,
    balance: nil,
    __meta__: #Ecto.Schema.Metadata<:built, "entities">
  },
  valid?: true
>
```

As for doing the same but with `:balance` (that is a "known quantity"):

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :create,
  action: :instrumented_create,
  attributes: %{name: "A", balance: Money.new(:SEK, "1")},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: nil,
    name: nil,
    size: nil,
    balance: nil,
    __meta__: #Ecto.Schema.Metadata<:built, "entities">
  },
  valid?: true
>
```

touching `:name` again whereby the `:balance` field in the form is reset:

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :create,
  action: :instrumented_create,
  attributes: %{name: "Ab", balance: Money.new(:SEK, "1")},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: nil,
    name: nil,
    size: nil,
    balance: nil,
    __meta__: #Ecto.Schema.Metadata<:built, "entities">
  },
  valid?: true
>
```

and then one more time touching `:name`:

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :create,
  action: :instrumented_create,
  attributes: %{name: "Abc", balance: nil},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: nil,
    name: nil,
    size: nil,
    balance: nil,
    __meta__: #Ecto.Schema.Metadata<:built, "entities">
  },
  valid?: true
>
```

Finally, opening a record for updating with `:instrumented_update` puts out:

```elixir
changeset #=> #Ash.Changeset<
  domain: DemoRepo.Entities,
  action_type: :update,
  action: :instrumented_update,
  attributes: %{},
  relationships: %{},
  errors: [],
  data: %DemoRepo.Entities.Entity{
    id: "fef55f7d-7eaf-418f-80e9-6425be8c7b66",
    name: "Joe",
    size: nil,
    balance: Money.new(:SEK, "3"),
    __meta__: #Ecto.Schema.Metadata<:loaded, "entities">
  },
  valid?: true
>
```

leaving the field `:balance` with the value `nil` in the form. Since one cannot save both `:balance` and `:size`, `:size` was already `nil` when opening the `:instrumented_update` form. The same thing happens with the default `:update` form.

## Environment

- `macOS 15.6`
- `erlang 27.3.4`
- `elixir 1.18.4-otp-27`
- `ash 3.5.36`
- `ash_admin 0.13.17` <- Only tested in AshAdmin
- `ash_money 0.2.3`
- `ash_phoenix 2.3.14`
- `ash_postgres 2.6.16`
- `ash_sql 0.2.90`
- `phoenix_live_view 1.1.8` <- ?⚠️

### Generation

The application was generated with the following commands:

```sh
mix archive.install hex igniter_new --force
mix archive.install hex phx_new 1.8.0-rc.4 --force

mix igniter.new demo_repo --with phx.new --install ash,ash_phoenix \
  --install ash_postgres,ash_admin --install ash_money --yes

cd demo_repo && mix ash.setup
```

---

Written by a human being 🦦
