# ExLCD

[![CircleCI](https://circleci.com/gh/cthree/ex_lcd/tree/master.svg?style=svg&circle-token=f8105a10e6a487d7bddbefdd2886c2a2231609d9)](https://circleci.com/gh/cthree/ex_lcd/tree/master)

**ExLCD** is a Hex package providing an API and support for character
matrix LCD displays in your Elixir and nerves projects. It uses
[elixir_ale](https://github.com/fhunleth/elixir_ale) for hardware IO.

The hardware interface and the user API are separate modules providing
relative hardware independence. This provides you with the ability
to change displays without significant changes your application code.

## Examples

Example projects using ExLCD are available in the
[ex_lcd_examples](https://github.com/cthree/ex_lcd_examples)
Github repository.

## Contributing

If you wish to develop a new driver to support an unsupported display
module, fix or report a bug, add a feature or otherwise contribute to
the project please open an issue to discuss your issue or idea. I'm
happy to accept suggestions, bug reports, pull requests and other
help! Driver modules for unsupported displays is especially appreciated.

## Acknowledgements

Many thanks to [@tmecklem](https://github.com/tmecklem) for inspiration
and encouragement. ExLCD started as his elixir_lcd package but none of
the original code remains but the guidance was appreciated.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ex_lcd to your list of dependencies in `mix.exs`:

        def deps do
          [{:ex_lcd, "~> 0.2.0"}]
        end

  2. Ensure ex_lcd is started before your application:

        def application do
          [applications: [:ex_lcd]]
        end
