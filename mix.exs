defmodule IamRole.Mixfile do
  use Mix.Project

  def project do
    [app: :iam_role,
     version: "1.0.0",
     description: "Application for automatically fetching AWS IAM " <>
       "role security credentials.",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger, :inets, :jsone],
     mod: {IamRole, []}]
  end

  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.10", only: :dev},
      {:jsone, "~> 1.2"}
    ]
  end

  defp package do
    [
      maintainers: ["Teemu Harju"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tsharju/iam_role"}
    ]
  end
  
end
