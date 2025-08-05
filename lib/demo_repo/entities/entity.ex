defmodule DemoRepo.Entities.Entity do
  use Ash.Resource,
    otp_app: :demo_repo,
    domain: DemoRepo.Entities,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "entities"
    repo DemoRepo.Repo
  end

  actions do
    defaults [
      :read,
      :destroy,
      create: [:name, :size, :balance],
      update: [:name, :size, :balance]
    ]

    create :instrumented_create do
      accept [:name, :size, :balance]

      change fn changeset, _context -> changeset |> dbg() end
    end

    update :instrumented_update do
      require_atomic? false

      accept [:name, :size, :balance]

      change fn changeset, _context -> changeset |> dbg() end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :size, :custom_float do
      allow_nil? true
    end

    attribute :balance, :money do
      allow_nil? true
    end
  end
end
