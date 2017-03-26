defmodule ElixirLCD.CharLCD.HD44780 do
  @moduledoc """
  **ElixirLCD.CharLCD.HD44780** is the display driver module for Hitachi
  HD44780 type parallel LCD display controller managed display modules.

  ## Hitachi HD44780 Controller

  The HD44780 is the most ubiquitous character matrix display controller
  but not the only one. It supports a number of standard operations like
  moving the cursor, displaying characters and scrolling. It is an 8-bit
  parallel interface which can operate in 4-bit mode by sending 2 4-bit
  nibbles to make one 8-bit byte.

  It supports 208 characters which are compatible with UNICODE single byte
  latin characters. The controller character ROM includes a number of non-
  standard character glyphs which this driver maps to their multi-byte
  UNICODE equivilents automatically. See the character map in this file for
  details. There are also 8 user definable character bitmaps mapped to
  characters byte codes 0-7.

  ## Configuration

  The start/1 function expects to receive a map of configuration settings
  for the display and it's hardware interface. The configuration map is
  passed by your application to CharLCD.start_link/1 and then on to this
  driver module. Please see CharLCD for details. The following keys are
  used by this driver to operate the display:

  * *Key*     -> **Type(O|R)**  -> *Description*
  * rs        -> integer(R) -> The GPIO pin ID for the RS signal
  * en        -> integer(R) -> The GPIO pin ID for the EN signal
  * d0        -> integer(O) -> The GPIO pin ID for the d0 signal
  * d1        -> integer(O) -> The GPIO pin ID for the d1 signal
  * d2        -> integer(O) -> The GPIO pin ID for the d2 signal
  * d3        -> integer(O) -> The GPIO pin ID for the d3 signal
  * d4        -> integer(R) -> The GPIO pin ID for the d4 signal
  * d5        -> integer(R) -> The GPIO pin ID for the d5 signal
  * d6        -> integer(R) -> The GPIO pin ID for the d6 signal
  * d7        -> integer(R) -> The GPIO pin ID for the d7 signal
  * rows      -> integer(R) -> The number of display rows or lines
  * cols      -> integer(R) -> The number of display columns
  * font_5x10 -> boolean(O) -> Font: true: 5x10, false: 5x8 (default)

  O - optional
  R - required

  Example:

  ```elixir
    config :MyApp, hd44780: %{
      rs: 1,
      en: 2,
      d4: 3,
      d5: 4,
      d6: 5,
      d7: 6,
      rows: 2,
      cols: 20
    }
  ```

  ## More Information

  For more information about your display and its capabilities here are
  a few resources to help you get the most of it:

  * Hitachi HD44780 Datasheet
  * Wikipedia Entry for HD44780
  * ElixirLCD.CharLCD
  * Raspberry Pi Example Application with nerves
  """

  use Bitwise
  use ElixirLCD.CharLCD.Driver
  alias ElixirALE.GPIO

  @low    0
  @high   1

  # Function set flags
  @mode_4bit  0x01
  @mode_8bit  0x00
  @font_5x8   0x00
  @font_5x10  0x04
  @lines_1    0x00
  @lines_2    0x08

  # Command flags
  @cmd_clear        0x01
  @cmd_home         0x02
  @cmd_entrymodeset 0x04
  @cmd_dispcontrol  0x08
  @cmd_cursorshift  0x10
  @cmd_functionset  0x20
  @cmd_setcgramaddr 0x40
  @cmd_setddramaddr 0x80

  # Entry mode flags
  @entry_left       0x02
  @entry_increment  0x01

  # Display control flags
  @ctl_display      0x04
  @ctl_cursor       0x02
  @ctl_blink        0x01

  # Shift flags
  @shift_display    0x08
  @shift_right      0x04

  @pins_4bit [:rs, :en, :d4, :d5, :d6, :d7]
  @pins_8bit [:d0, :d1, :d2, :d3]

  # -------------------------------------------------------------------
  # CharDisplay.Driver Behaviour
  #
  @doc false
  def start(config) do
    init(config)
  end

  @doc false
  def stop(display) do
    {:ok, display} = command(display, {:display, :off})
    [ :rs_pid, :en_pid,
      :d0_pid, :d1_pid, :d2_pid, :d3_pid,
      :d4_pid, :d5_pid, :d6_pid, :d7_pid ]
    |>  Enum.filter(fn x -> not is_nil(display[x]) end)
    |>  Enum.each(fn x -> GPIO.release(display[x]) end)
    :ok
  end

  @doc false
  def execute do
    &command/2
  end

  # ------------------------------------------------------------------
  # Initialization
  #

  defp init(config) do
    # validate and unpack the config
    config |> validate_config!()

    bits = case config[:d0] do
      nil  ->  @mode_4bit
      _    ->  @mode_8bit
    end

    lines = case config.rows do
      1 ->  @lines_1
      _ ->  @lines_2
    end

    cols = config.cols

    font = case config[:font_5x10] do
      true  ->  @font_5x10
      _     ->  @font_5x8
    end

    pins = case bits do
      @mode_8bit  ->  @pins_4bit ++ @pins_8bit
      _           ->  @pins_4bit
    end

    starting_function_state = @cmd_functionset ||| bits ||| font ||| lines
    starting_display_state = @cmd_dispcontrol ||| @ctl_display

    Map.merge(config, %{
      function_set: starting_function_state,
      display_control: starting_display_state,
      row_offsets: row_offsets(cols),
      entry_mode: @cmd_entrymodeset,
      shift_control: @cmd_cursorshift
    })
    |>  reserve_gpio_pins(pins)
    |>  delay(50)
    |>  rs(@low)
    |>  en(@low)
    |>  poi(bits)
    |>  set_feature(:function_set)
    |>  set_feature(:display_control)
    |>  clear
    |>  set_feature(:entry_mode)
    |>  set_feature(:shift_control)
  end

  defp row_offsets(cols) do
    %{ 0 => 0x00, 1 => 0x40, 2 => 0x00 + cols, 3 => 0x40 + cols }
  end

  # setup GPIO output pins, add the pids to the config and return
  defp reserve_gpio_pins(config, pins) do
    config
    |>  Map.take(pins)
    |>  Enum.map(fn {k, v} -> {String.to_atom("#{k}_pid"), start_pin(v, :output)} end)
    |>  Map.new()
    |>  Map.merge(config)
  end

  # start ElixirALE.GPIO GenServer to manage a GPIO pin and return the pid
  defp start_pin(pin, direction) do
    with {:ok, pid} <- GPIO.start_link(pin, direction)
    do
      pid
    end
  end

  # Software Power On Init (POI) for 4bit operation of HD44780 controller.
  # Since the display is initialized more than 50mS after > 4.7V on due to
  # OS/BEAM/App boot time this isn't strictly necessary but let's be
  # safe and do it anyway.
  defp poi(state, @mode_4bit) do
    state
    |>  write_4_bits(0x03)
    |>  delay(5)
    |>  write_4_bits(0x03)
    |>  delay(5)
    |>  write_4_bits(0x03)
    |>  delay(5)
    |>  write_4_bits(0x02)
  end

  # POI for 8 bit mode
  defp poi(state, @mode_8bit) do
    state
    |>  set_feature(:function_set)
    |>  delay(5)
    |>  set_feature(:function_set)
    |>  delay(5)
    |>  set_feature(:function_set)
  end

  defp validate_config!(config) do
    config
  end

  # -------------------------------------------------------------------
  # CharLCD API callback
  #

  defp command(display, {:clear, _params}) do
    clear(display)
    {:ok, display}
  end

  defp command(display, {:home, _params}) do
    home(display)
    {:ok, display}
  end

  defp command(display, {:write, content}) do
    map_string(content)
    |>  Enum.each(fn(x) -> write_a_byte(display, x, @high) end)
    {:ok, display}
  end

  defp command(display, {:set_cursor, {row, col}}) do
    {:ok, set_cursor(display, {row, col})}
  end
  defp command(display, {:cursor, :off}) do
    {:ok, disable_feature_flag(display, :display_control, @ctl_cursor)}
  end
  defp command(display, {:cursor, :on}) do
    {:ok, enable_feature_flag(display, :display_control, @ctl_cursor)}
  end
  defp command(display, {:blink, :off}) do
    {:ok, disable_feature_flag(display, :display_control, @ctl_blink)}
  end
  defp command(display, {:blink, :on}) do
    {:ok, enable_feature_flag(display, :display_control, @ctl_blink)}
  end
  defp command(display, {:display, :off}) do
    {:ok, disable_feature_flag(display, :display_control, @ctl_display)}
  end
  defp command(display, {:display, :on}) do
    {:ok, enable_feature_flag(display, :display_control, @ctl_display)}
  end
  defp command(display, {:autoscroll, :off}) do
    {:ok, disable_feature_flag(display, :entry_mode, @entry_increment)}
  end
  defp command(display, {:autoscroll, :on}) do
    {:ok, enable_feature_flag(display, :entry_mode, @entry_increment)}
  end
  defp command(display, {:rtl_text, :on}) do
    {:ok, disable_feature_flag(display, :entry_mode, @entry_left)}
  end
  defp command(display, {:ltr_text, :on}) do
    {:ok, enable_feature_flag(display, :entry_mode, @entry_left)}
  end

  # Scroll the entire display left (-) or right (+)
  defp command(display, {:scroll, 0}), do: {:ok, display}
  defp command(display, {:scroll, cols}) when cols < 0 do
    write_a_byte(display, @cmd_cursorshift ||| @shift_display)
    command(display, {:scroll, cols + 1})
  end
  defp command(display, {:scroll, cols}) do
    write_a_byte(display, @cmd_cursorshift ||| @shift_display ||| @shift_right)
    command(display, {:scroll, cols - 1})
  end

  # Scroll(move) cursor right
  defp command(display, {:right, 0}), do: {:ok, display}
  defp command(display, {:right, cols}) do
    write_a_byte(display, @cmd_cursorshift ||| @shift_right)
    command(display, {:right, cols - 1})
  end

  # Scroll(move) cursor left
  defp command(display, {:left, 0}), do: {:ok, display}
  defp command(display, {:left, cols}) do
    write_a_byte(display, @cmd_cursorshift)
    command(display, {:left, cols - 1})
  end

  # Program custom character to CGRAM
  defp command(display, {:char, idx, bitmap}) when idx in 0..7 and length(bitmap) === 8 do
    write_a_byte(display, @cmd_setcgramaddr ||| idx)
    for line <- bitmap do
      write_a_byte(display, line, @high)
    end
    {:ok, display}
  end

  # All other commands are unsupported
  defp command(display, _), do: {:unsupported, display}

  # -------------------------------------------------------------------
  # Low-level device and utility functions
  #

  defp clear(display) do
    display
    |>  write_a_byte(@cmd_clear)
    |>  delay(20)
  end

  defp home(display) do
    display
    |>  write_a_byte(@cmd_home)
    |>  delay(20)
  end

  defp set_cursor(display, {row, col}) do
    col = min(col, display[:cols] - 1)
    row = min(row, display[:rows] - 1)
    %{^row => offset} = display[:row_offsets]
    write_a_byte(display, @cmd_setddramaddr ||| col + offset)
  end

  # Switch a register flag bit OFF(0). Return the updated state.
  defp disable_feature_flag(state, feature, flag) do
    %{state | feature => (state[feature] &&& ~~~flag)}
    |>  set_feature(feature)
  end

  # Switch a register flag bit ON(1). Return the updated state.
  defp enable_feature_flag(state, feature, flag) do
    %{state | feature => (state[feature] ||| flag)}
    |>  set_feature(feature)
  end

  # Write a feature register to the controller and return the state.
  defp set_feature(display, feature) do
    display |> write_a_byte(display[feature])
  end

  # Write a byte to the device
  defp write_a_byte(display, byte_to_write, rs_value \\ @low) do
    display |> rs(rs_value)

    case display[:d0] do
      nil -> display
             |>  write_4_bits(byte_to_write >>> 4)
             |>  write_4_bits(byte_to_write)
      _   -> display
             |>  write_8_bits(byte_to_write)
    end
  end

  # Write 8 parallel bits to the device
  defp write_8_bits(display, bits) do
    GPIO.write(display.d0_pid, bits &&& 0x01)
    GPIO.write(display.d1_pid, bits >>> 1 &&& 0x01)
    GPIO.write(display.d2_pid, bits >>> 2 &&& 0x01)
    GPIO.write(display.d3_pid, bits >>> 3 &&& 0x01)
    GPIO.write(display.d4_pid, bits >>> 4 &&& 0x01)
    GPIO.write(display.d5_pid, bits >>> 5 &&& 0x01)
    GPIO.write(display.d6_pid, bits >>> 6 &&& 0x01)
    GPIO.write(display.d7_pid, bits >>> 7 &&& 0x01)
    pulse_en(display)
  end

  # Write 4 parallel bits to the device
  defp write_4_bits(display, bits) do
    GPIO.write(display.d4_pid, bits &&& 0x01)
    GPIO.write(display.d5_pid, bits >>> 1 &&& 0x01)
    GPIO.write(display.d6_pid, bits >>> 2 &&& 0x01)
    GPIO.write(display.d7_pid, bits >>> 3 &&& 0x01)
    pulse_en(display)
  end

  defp rs(display, value) do
    GPIO.write(display[:rs_pid], value)
    display
  end

  defp en(display, value) do
    GPIO.write(display[:en_pid], value)
    display
  end

  defp pulse_en(display) do
    display
    |>  en(@low)
    |>  delay(1)
    |>  en(@high)
    |>  delay(1)
    |>  en(@low)
    |>  delay(1)
  end

  defp delay(display, ms) do
    Process.sleep(ms)
    display
  end

  defp character_table do
    %{
      # Low ASCII, arrows mainly
      0x10 => "▶︎", 0x11 => "◀︎", 0x12 => "“", 0x13 => "”",
      0x14 => "↟", 0x15 => "↡", 0x16 => "●", 0x17 => "↵",
      0x18 => "↑", 0x19 => "↓", 0x1A => "→", 0x1B => "←",
      0x1C => "≤", 0x1D => "≥", 0x1E => "▲", 0x1F => "▼",
      # A house instead on nbsp for some reason...
      0x7F => "⌂",
      # Cyrillicish
      0x80 => "Б", 0x81 => "Д", 0x82 => "Ж", 0x83 => "З",
      0x84 => "И", 0x85 => "Й", 0x86 => "Л", 0x87 => "П",
      0x88 => "У", 0x89 => "Ц", 0x8A => "Ч", 0x8B => "Ш",
      0x8C => "Щ", 0x8D => "Ъ", 0x8E => "Ы", 0x8F => "Э",
      # Greekish
      0x90 => "α", 0x91 => "♪", 0x92 => "Γ", 0x93 => "π",
      0x94 => "Σ", 0x95 => "σ", 0x96 => "♫", 0x97 => "τ",
      0x98 => "🔔", 0x99 => "θ", 0x9A => "Ω", 0x9B => "δ",
      0x9C => "∞", 0x9D => "❤️", 0x9E => "ℇ", 0x9F => "∩"
    }
  end

  defp map_string(string) do
    string
    |>  String.graphemes()
    |>  Enum.map(fn x -> map_char(x) end)
  end

  defp map_char(grapheme) when byte_size(grapheme) > 1 do
    {code, _} = character_table()
    |>  Enum.find({0x3F, grapheme}, fn {_k, v} -> v === grapheme end)
    code
  end

  defp map_char(grapheme) do
    [ code | _ ] = String.to_charlist(grapheme)
    code
  end
end

if Mix.env != :prod do
  if Mix.env != :test do
    defmodule HD44780Test.MockHD44780 do
      @moduledoc false
      def write(_, _), do: :ok
    end
  end

  defmodule ElixirALE.GPIO do
    @moduledoc false
    require Logger

    def start_link(pin, _pin_direction \\ :foo, _opts \\ []) do
      {:ok, pin}
    end

    def write(pin, value) do
      HD44780Test.MockHD44780.write(pin, value)
      :ok
    end

    def release(_pin), do: :ok
  end
end
