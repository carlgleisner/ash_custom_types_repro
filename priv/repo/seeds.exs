# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DemoRepo.Repo.insert!(%DemoRepo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

DemoRepo.Entities.Entity
|> Ash.Changeset.for_create(
  :create,
  %{
    name: "Joe",
    size: 0.314,
    balance: "42 USD"
  }
)
|> Ash.create!()
