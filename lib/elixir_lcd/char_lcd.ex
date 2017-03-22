defmodule ElixirLCD.CharLCD do
  @moduledoc """
  CharLCD implements a standard API for controlling and displaying text
  on character matrix LCD/LED display modules. CharLCD handles most modes
  and operations supported by common display modules.

  CharLCD controllers an assortment of displays by interacting with a
  driver module implementing the CharDisplay protocol. CharLCD has no
  support for directly controlling display hardware and instead relies on
  the CharDisplay implementing driver modules to execute standard
  character matrix operations on the actual device.

  ## Usage

  CharLCD is implemented as a GenServer which you should add to your
  application supervision tree on startup in your mix.exs file:

  ```elixir
    def application(_target) do
      [mod: {MyApp, []},
       extra_applications: [..., CharLCD, ...]]
    end
  ```

  ## Configuration

  To configure and use CharLCD, add a config setting in your config.exs
  file specifying the driver module you are using. Each driver module also
  requires configuration, see the documentation for the driver module you
  are using for details on how to correctly configure it. Here is an example
  of the configuration of CharLCD controlling an HD44780 display module
  with a common 4 bit parallel hardware interface.

  ```elixir
    config :char_lcd, driver: HD44780
    config :hd44780, interface: [
      rs: 21,
      en: 22,
      d0: 23,
      d1: 24,
      d2: 25,
      d3: 26
    ]
  ```

  """
  use GenServer
  require Logger
  alias ElixirLCD.CharLCD

  defmodule LCDState do
    defstruct driver: nil, display: nil, execute: nil
  end

  @doc """
    Start the GenServer, takes a display implementing ElixirLCD.CharLCD.Display
    protocol.
  """
  def start_link(driver_module) do
    state = %LCDState{driver: driver_module}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    state = %LCDState{state | display: apply(state.driver, :start, [])}
    state = %LCDState{state | execute: apply(state.driver, :execute, [])}
    {:ok, state}
  end

  # -------------------------------------------------------------------
  # Public API
  #

  def clear(), do: cast(:clear)
  def home(), do: cast(:home)
  def set_cursor(col, row), do: cast({:set_cursor, row, col})
  def write(content), do: cast({:write, content})
  def scroll_left(cols \\ 1), do: cast({:scroll, cols})
  def scroll_right(cols \\ 1), do: cast({:scroll, -cols})
  def create_char(idx, bits), do: cast({:char, idx, bits})
  def enable(:cursor), do: cast({:enable, :cursor})
  def enable(:blink), do: cast({:enable, :blink})
  def enable(:display), do: cast({:enable, :display})
  def enable(:autoscroll), do: cast({:enable, :autoscroll})
  def enable(:rtl_text), do: cast({:enable, :rtl_text})
  def enable(:ltr_text), do: cast({:enable, :ltr_text})
  def disable(:cursor), do: cast({:disable, :cursor})
  def disable(:blink), do: cast({:disable, :blink})
  def disable(:display), do: cast({:disable, :display})
  def disable(:autoscroll), do: cast({:disable, :autoscroll})
  def disable(:rtl_text), do: CharLCD.enable(:ltr_text)
  def disable(:ltr_text), do: CharLCD.enable(:rtl_text)
  def stop(), do: stop(:shutdown)

  # -------------------------------------------------------------------
  # GenServer Cast callbacks
  #

  def handle_cast(:clear, state), do: execute({:clear, []}, state)
  def handle_cast(:home, state), do: execute({:home, []}, state)
  def handle_cast({:set_cursor, row, col}, state) do
    execute({:set_cursor, row, col}, state)
  end
  def handle_cast({:write, content}, state) do
    execute({:write, content}, state)
  end
  def handle_cast({:scroll, cols}, state) do
    execute({:scroll, cols}, state)
  end
  def handle_cast({:char, idx, bitmap}, state) when idx in 0..7 and byte_size(bitmap) === 8 do
    execute({:char, idx, bitmap}, state)
  end
  def handle_cast({:enable, feature}, state) do
    execute({feature, :on}, state)
  end
  def handle_cast({:disable, feature}, state) do
    execute({feature, :off}, state)
  end

  defp execute(op, state) do
    {result, display} = state.execute.(state.display, op)
    log_command(result, op)
    {:noreply, updated_display_state(state, display)}
  end

  # -------------------------------------------------------------------
  # Private Utility Functions
  #

  defp cast(msg), do: GenServer.cast(__MODULE__, msg)

  defp stop(msg), do: GenServer.stop(__MODULE__, msg)

  defp updated_display_state(state, display) do
    %{state | display: display}
  end

  defp log_command(:ok, cmd) do
    Logger.debug("#{__MODULE__}: #{to_string(cmd)}: ok")
  end

  defp log_command(:unavailable, cmd) do
    Logger.warn("#{__MODULE__} #{to_string(cmd)}: unavailable")
  end

  defp log_command(:unsupported, cmd) do
    Logger.info("#{__MODULE__}: #{to_string(cmd)}: unsupported")
  end
end
