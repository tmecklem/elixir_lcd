defmodule ExLCD.Driver do
  @moduledoc """
  ExLCD.Driver defines the behaviour expected of display driver
  modules. Each display driver module must use this module and implement the
  expected callback functions.

    ```elixir
    defmodule MyDisplayDriver do
      use ExLCD.Driver
      ...
    end
    ```
  """
  @doc false
  defmacro __using__(_) do
    quote do
      import Kernel, except: [defp: 2]
      import unquote(__MODULE__), only: [defp: 2, target: 0]
      @behaviour ExLCD.Driver
    end
  end

  # Redefine defp when testing to expose private functions
  @doc false
  defmacro defp(definition, do: body) do
    case Mix.env do
      :test -> quote do
        Kernel.def(unquote(definition)) do
          unquote(body)
        end
      end
      _ -> quote do
        Kernel.defp(unquote(definition)) do
          unquote(body)
        end
      end
    end
  end

  @doc false
  # Return the nerves build target or "host" if there isn't one
  def target() do
    System.get_env("MIX_TARGET") || "host"
  end

  @typedoc """
  Opaque driver module state data
  """
  @type display :: map

  @doc """
  start/1 is called during initialization of ExLCD which passes
  a map of configuration parameters for the driver. The driver is_
  expected to initialize the display to a ready state and return
  state data held by and passed into the driver on each call. ExLCD
  manages your driver's state. After this callback returns it is expected
  that the display is ready to process commands from ExLCD.
  """
  @callback start(map) :: {:ok | :error, display}

  @doc """
    stop/1 may be called on request by the application to free the hardware
    resources held by the display driver.
  """
  @callback stop(display) :: :ok

  @doc """
  execute/0 is called by ExLCD to learn the function it should call
  to send commands to your driver. The typespec of the function returned
  must be:
    function(display, operation) :: display
  The returned function will be called upon to do all of the heavy lifting.
  """
  @callback execute :: function
end
