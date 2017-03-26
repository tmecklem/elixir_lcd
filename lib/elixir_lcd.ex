defmodule ElixirLCD do
  @moduledoc """
  **ElixirLCD** is an LCD Display Framework which provides a standard and
  consistent API for using simple LCD display modules in your
  enbedded projects running on BEAM. It uses elixir_ale for hardware
  IO.

  The hardware interface and the user API are separate modules providing
  relative hardware independence. This provides you with the ability
  to change display modules without changing your application code.
  Simply change the driver module or write one if it's not available.

  ## Examples and Howto

  Example projects using ElixirLCD are available in the
  [elixir_lcd_examples](https://github.com/cthree/elixir_lcd_examples)
  repository.

  ## Contributing

  If you want to develop a new driver to support an unsupported display
  module for use with ElixirLCD, fix or report a bug, add a feature
  or otherwise contribute to the project please fork the
  [github repository](https://github.con/cthree/elixir_lcd) and read
  the README.md file for details. I welcome your input and contribution!

  ## Acknowledgements

  Many thanks to @tmecklem for starting this project and allowing me to
  run with it and make it my own.

  ## License

  Copyright 2017 Erik Petersen

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  """
end
