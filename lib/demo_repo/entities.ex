defmodule DemoRepo.Entities do
  use Ash.Domain,
    otp_app: :demo_repo,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource DemoRepo.Entities.Entity
  end
end
