defmodule RumblEc2.Repo do
  @moduledoc """
  In memory repository.
  """

  def all(RumblEc2.User) do
    [%RumblEc2.User{id: "1",name: "Jose",username: "josevalim",password: "elixir"},
     %RumblEc2.User{id: "2",name: "Bruce",username: "redrapids",password: "7langs"},
     %RumblEc2.User{id: "3",name: "Chris",username: "chrismccord",password: "phx"}]
  end
  def all(_module), do: []

  def get(module, id) do
    Enum.find all(module), fn map -> map.id == id end
  end

  def get_by(module, params) do
    Enum.find all(module), fn map ->
      Enum.all?(params, fn {key, val} -> Map.get(map, key) == val end)
    end
  end
end
