defmodule ElixirLCD.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_lcd,
     name: "elixir_lcd",
     description: description(),
     version: "0.1.0",
     elixir: "~> 1.4",
     package: package(),
     source_url: "https://github.com/cthree/elixir_lcd",
     make_clean: ["clean"],
     docs: [extras: ["README.md"]],
     aliases: ["docs": ["docs", &copy_images/1]],
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp elixirc_paths([:test, :dev]), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:elixir_ale, "~> 0.5.0", only: [:prod]},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp description do
    """
    Elixir API to control and write to character matrix LCD displays.
    """
  end

  defp package do
    %{files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Erik Petersen"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/cthree/elixir_lcd"}}
  end

  # Copy the images referenced by docs, since ex_doc doesn't do this.
  defp copy_images(_) do
    File.cp_r "assets", "doc/assets"
  end
end
