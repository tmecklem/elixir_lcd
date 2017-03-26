defmodule ElixirLCD.CharLCD do
  @moduledoc """
  **ElixirLCD.CharLCD** implements a standard API for controlling and
  displaying text on character matrix LCD display modules. CharLCD
  handles most modes and operations supported by common display modules.

  CharLCD controls an assortment of displays by interacting with a
  driver module implementing the ElixirLCD.CharLCD.Driver behaviour.
  CharLCD has no direct support for controlling hardware and instead
  delegates low-level functions driver modules for the actual device.

  ## Usage

  ElixirLCD.CharLCD is implemented as a GenServer. Start it by calling
  ElixirLCD.CharLCD.start_link/1 and passing a tuple containing the
  name of the driver module in the first element and a map of
  configuration parameters in second element. See the driver module
  documentation for what configuration parameters it accepts.

  Example:
  ```elixir
    alias ElixirLCD.CharLCD
    CharLCD.start_link({CharLCD.HD44780, %{...}})
  ```
  """
  use GenServer
  require Logger
  alias ElixirLCD.CharLCD

  @type feature :: :display | :cursor | :blink | :autoscroll |
                   :rtl_text | :ltr_text
  @type feature_state :: :on | :off
  @type bitmap :: list

  defmodule LCDState do
    defstruct driver: nil, config: nil, display: nil, callback: nil
  end

  @doc """
  Start the CharLCD GenServer to manage the display.

  Pass a tuple containing the name of the driver module in the first element
  and a map of configuration parameters in second element. See the driver
  module documentation for what configuration parameters it accepts.

  Example:
  ```elixir
    alias ElixirLCD.CharLCD
    CharLCD.start_link({CharLCD.HD44780, %{...}})
  ```
  """
  @spec start_link({term, map}) :: {:ok, pid}
  def start_link({driver_module, config}) do
    state = %LCDState{driver: driver_module, config: config}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc false
  @spec init(term) :: {:ok, term}
  def init(state) do
    state = %LCDState{state | display: apply(state.driver, :start, [state.config])}
    state = %LCDState{state | callback: apply(state.driver, :execute, [])}
    {:ok, state}
  end

  # -------------------------------------------------------------------
  # Public API
  #

  @doc """
  Clear the display.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.clear
      :ok
    ```
  """
  @spec clear() :: :ok
  def clear(), do: cast(:clear)

  @doc """
  Home the cursor position to row 0, col 0

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.home
      :ok
    ```
  """
  @spec home() :: :ok
  def home(), do: cast(:home)

  @doc """
  Position the cursor at a specified row and colum

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.set_cursor(2, 12)
      :ok
    ```
  """
  @spec set_cursor(row::integer, col::integer) :: :ok
  def set_cursor(row, col), do: cast({:set_cursor, row, col})

  @doc """
  Write a string to the display at the current cursor position.

  Example:
  ```elixir
    iex> ElixirLCD.CharLCD.write("ElixirLCD!")
    :ok
  ```
  """
  @spec write(binary) :: :ok
  def write(content), do: cast({:write, content})

  @doc """
  Scroll the display contents left by 1 or some number of columns.

  Example:
  ```elixir
    iex> ElixirLCD.CharLCD.scroll_right(6)
    :ok
  ```
  """
  @spec scroll_left(integer) :: :ok
  def scroll_left(cols \\ 1), do: cast({:scroll, cols})

  @doc """
  Scroll the display contents right by 1 or some number of columns.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.scroll_right(6)
      :ok
    ```
  """
  @spec scroll_right(integer) :: :ok
  def scroll_right(cols \\ 1), do: cast({:scroll, -cols})

  @doc """
  Move the cursor 1 or some number of columns to the left of its current
  position.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.move_left(4)
      :ok
    ```
  """
  @spec move_left(integer) :: :ok
  def move_left(cols \\ 1), do: cast({:left, cols})

  @doc """
  Move the cursor 1 or some number of columns to the right of its current
  position.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.move_right(1)
      :ok
    ```
  """
  @spec move_right(integer) :: :ok
  def move_right(cols \\ 1), do: cast({:right, cols})

  @doc """
  Program a custom character glyph.

  Custom glyphs may not be supported by all displays. Check the driver
  to see if it is on yours. Pass a custome character index or slot
  number and a list of integers representing the glyph bitmap data. Format
  of the bitmap data and the numbering of the character slots is highly
  dependent on the display controller. Refer to the driver module for
  details.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.create_char(0, [0x7F, 0x7F, 0x7F, 0x7F,
      ...>                                   0x7F, 0x7F, 0x7F, 0x7F])
      :ok
    ```
  """
  @spec create_char(integer, bitmap) :: :ok
  def create_char(idx, bits), do: cast({:char, idx, bits})

  @doc """
  Enable a display feature.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.enable(:display)
      :ok
    ```
  """
  @spec enable(feature) :: :ok
  def enable(:cursor), do: cast({:enable, :cursor})
  def enable(:blink), do: cast({:enable, :blink})
  def enable(:display), do: cast({:enable, :display})
  def enable(:autoscroll), do: cast({:enable, :autoscroll})
  def enable(:rtl_text), do: cast({:enable, :rtl_text})
  def enable(:ltr_text), do: cast({:enable, :ltr_text})

  @doc """
  Disable a display feature.

    Example:
    ```elixir
      iex> ElixirLCD.CharLCD.disable(:blink)
      :ok
    ```
  """
  @spec disable(feature) :: :ok
  def disable(:cursor), do: cast({:disable, :cursor})
  def disable(:blink), do: cast({:disable, :blink})
  def disable(:display), do: cast({:disable, :display})
  def disable(:autoscroll), do: cast({:disable, :autoscroll})
  def disable(:rtl_text), do: CharLCD.enable(:ltr_text)
  def disable(:ltr_text), do: CharLCD.enable(:rtl_text)

  @doc """
  Stop the driver and release hardware resources.

  Example:
  ```elixir
    iex> ElixirLCD.CharLCD.stop
    :ok
  ```
  """
  @spec stop() :: :ok
  def stop(), do: stop(:shutdown)

  # -------------------------------------------------------------------
  # GenServer Cast callbacks
  #
  @doc false
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
  def handle_cast({:right, cols}, state) do
    execute({:right, cols}, state)
  end
  def handle_cast({:left, cols}, state) do
    execute({:left, cols}, state)
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
    {_result, display} = state.callback.(state.display, op)
    {:noreply, updated_display_state(state, display)}
  end

  # -------------------------------------------------------------------
  # Private Utility Functions
  #

  defp cast(msg), do: GenServer.cast(__MODULE__, msg)

  defp stop(msg), do: GenServer.stop(__MODULE__, msg)

  defp updated_display_state(state, display) do
    %LCDState{state | display: display}
  end
end
