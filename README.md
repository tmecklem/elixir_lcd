# ElixirLCD

**ElixirLCD** is an LCD Display Framework which provides a standard and
consistent API for using simple LCD display modules in your
embedded projects running on BEAM. It uses [elixir_ale](https://github.com/fhunleth/elixir_ale) for hardware
IO.

The hardware interface and the user API are separate modules providing
relative hardware independence. This provides you with the ability
to change display modules without changing your application code.
Simply change the driver module or write one if it's not available.

## Examples

Example projects using ElixirLCD are available in the
[elixir_lcd_examples](https://github.com/cthree/elixir_lcd_examples)
Github repository.

## Contributing

If you want to develop a new driver to support an unsupported display
module for use with ElixirLCD, fix or report a bug, add a feature
or otherwise contribute to the project please open an issue to discuss
your issue or ideas. I'm happy to accept fixes, suggestions, requests
and help! Hardware support drivers are particularly welcome!!

## Acknowledgements

Many thanks to [@tmecklem](https://github.com/tmecklem) for starting this
project and allowing me to run with it and make it my own.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add elixir_lcd to your list of dependencies in `mix.exs`:

        def deps do
          [{:elixir_lcd, "~> 0.1.0"}]
        end

  2. Ensure elixir_lcd is started before your application:

        def application do
          [applications: [:elixir_lcd]]
        end
