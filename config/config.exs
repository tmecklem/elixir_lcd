# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Sample HD44780 configuration for a 2x20 display connected to
# a Raspberry Pi. The 4 bit interface requires 6 GPIO pins
# which are managed by the driver. Example connected as:
#
#
config :elixir_lcd, hd447090: %{
  rs: 25,
  en: 24,
  d4: 23,
  d5: 22,
  d6: 18,
  d7: 17,
  rows: 2,
  cols: 20,
  font_5x10: false
}

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :elixir_lcd, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:elixir_lcd, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
