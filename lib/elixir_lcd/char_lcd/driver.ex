defmodule ElixirLCD.CharLCD.Driver do
  @moduledoc """
  Define driver behaviour
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour ElixirLCD.CharLCD.Driver
      if Mix.env != :test do
        # require ElixirALE.TestHelper
      end
    end
  end

  @type display :: map

  @callback start :: display

  @callback stop(display) :: atom

  @callback execute :: function

end
