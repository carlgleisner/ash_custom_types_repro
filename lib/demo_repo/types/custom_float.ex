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
