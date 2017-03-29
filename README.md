# ExLCD

[![Hex.pm](https://img.shields.io/hexpm/v/ex_lcd.svg)](https://hex.pm/packages/ex_lcd)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_lcd.svg)](https://hex.pm/packages/ex_lcd)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_lcd.svg)](https://hex.pm/packages/ex_lcd)

**ExLCD** is a Hex package providing an API and support for character matrix LCD displays in your Elixir and nerves projects. It uses [elixir_ale](https://github.com/fhunleth/elixir_ale) for hardware IO.

The hardware interface and the user API are separate modules providing relative hardware independence. This provides you with the ability to change displays without significant changes your application code.

**Disclaimer:** This is still under heavy development and probably isn't suited for production use. Please consider testing and contributing to improving the project.

## Documentation

Project and API documentation is available online at [hexdocs.pm](https://hexdocs.pm/ex_lcd/)

## Examples

Example applications using ExLCD are available in the [cthree/ex_lcd_examples](https://github.com/cthree/ex_lcd_examples) Github repository.

## Contributing

If you wish to support a new type of display module, fix or report a bug, add a feature or otherwise contribute to the project please [open an issue](https://github.com/cthree/ex_lcd/issues) to discuss your issue or idea. I'm happy to accept suggestions, bug reports, pull requests and other help. Driver modules for unsupported displays is especially appreciated.

## Acknowledgements

Many thanks to [@tmecklem](https://github.com/tmecklem) for inspiration and encouragement. ExLCD started as his **elixir_lcd** package. While none of the original code remains, his guidance and advice is greatly appreciated.

## License

Licensed under the [Apache-2.0](https://choosealicense.com/licenses/apache-2.0/) license. Please see the [LICENSE file](https://github.com/cthree/ex_lcd/blob/master/LICENSE.txt) included in the repository if you are unfamiliar with the terms and conditions.

## Installation

**ExLCD** [is available in Hex](https://hex.pm/docs/publish), the package can be installed as a dependency of your project:

  1. Add **ex_lcd** and **elixir_ale** to your list of dependencies in `mix.exs`:
          def deps do
            [{:elixir_ale, "~> 0.6"},
             {:ex_lcd, "~> 0.3.2"}]
          end

  2. Ensure **ex_lcd** is started before your application:
          def application(_target) do
            [mod: {MyApplication.Application, []},
             extra_applications: [:ex_lcd]]
          end
