# ExLCD

[![Hex.pm](https://img.shields.io/hexpm/v/ex_lcd.svg)](https://hex.pm/packages/ex_lcd)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_lcd.svg)](https://hex.pm/packages/ex_lcd)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_lcd.svg)](https://hex.pm/packages/ex_lcd)

**ExLCD** is a Hex package providing an API and support for character
matrix LCD displays in your Elixir and nerves projects. It uses
[elixir_ale](https://github.com/fhunleth/elixir_ale) for hardware IO.

The hardware interface and the user API are separate modules providing
relative hardware independence. This provides you with the ability
to change displays without significant changes your application code.

**Disclaimer** This is still under heavy development and probably isn't suited
for production use. Please consider testing and contributing to improving the
project.

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
and encouragement. ExLCD started as his elixir_lcd package. While none of
the original code remains, his guidance and advice is greatly appreciated.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ex_lcd to your list of dependencies in `mix.exs`:

        def deps do
          [{:ex_lcd, "~> 0.3.0"}]
        end

  2. Ensure ex_lcd is started before your application:

        def application do
          [applications: [:ex_lcd]]
        end
