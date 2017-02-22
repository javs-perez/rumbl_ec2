defmodule RumblEc2.Video do
  use RumblEc2.Web, :model

  schema "videos" do
    field :url, :string
    field :title, :string
    field :description, :string
    belongs_to :user, RumblEc2.User
    belongs_to :category, RumblEc2.Category

    timestamps()
  end

  @doc """
  Builds a changeset based on the `model` and `params`.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:url, :title, :description])
    |> assoc_constraint(:category)
  end
end
