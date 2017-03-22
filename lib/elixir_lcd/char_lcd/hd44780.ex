defmodule ElixirLCD.CharLCD.HD44780 do
  @moduledoc """
  The HD44780 module is an LCD driver module for CharLCD. There are no
  user callable functions in this module, it is controlled by the CharLCD
  API.

  ## Configuration

  While there are no callable functions you will still need to configure
  the module hardware in your config.exs file.

  Example:

  ```elixir
    config :hd44780, display: %{
      rs: 1,
      en: 2,
      d4: 3,
      d5: 4,
      d6: 5,
      d7: 6,
      rows: 2,
      cols: 20,
      font_5x10: false
    }
  ```
  A minumum of 6 GPIO pins must be defined:
  * ```rs:``` The RS (register select) pin
  * ```en:``` The EN (enable) pin
  * ```d4...d7: The D4 through D7 pins for a 4 bit interface

  In addition to may also define some optional pins:
  * ```rw:``` The RW (Read/Write) pin - connect to ground if not used
  * ```d0...d3``` The D0 through D3 dins for an 8 bit inteface

  If only d4...d7 are configured a 4 bit interface is assumed. The RW
  pin is not currently used by this driver. You must connect the RW pin
  to ground.

  In addition to pin configuration, properties of the display should also
  be set:
  * ```rows:``` The number of rows on the display (1 or 2)
  * ```cols:``` The numbers of columns on the display

  If your display has a 5x10 font you must set ```font_5x10:``` to true,
  a 5x8 font is the default and therefore this key is optional for 5x8
  font displays.

  Please refer to the CharLCD documentations for additional API information
  and configuration.
  """
  use Bitwise
  use ElixirLCD.CharLCD.Driver
  alias ElixirALE.GPIO

  @low    0
  @high   1

  # Function set flags
  @mode_4bit  0x10
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

  def start() do
    display = Application.get_env(:hd44780, :display)
    display = display
    |> Enum.into(@pins_4bit, &start_pin(display, &1, :output))
    |> Enum.into(%{bits: 4})

    display = case display[:d0] do
      nil ->  display
      _ ->  display
            |> Enum.into(@pins_8bit, &start_pin(display, &1, :output))
            |> Map.put(:bits, 8)
    end

    display
    |>  init()
  end

  def stop(display) do
    {:ok, display} = command(display, {:display, :off})
    [ :rs_pid, :en_pid,
      :d0_pid, :d1_pid, :d2_pid, :d3_pid,
      :d4_pid, :d5_pid, :d6_pid, :d7_pid ]
    |>  Enum.filter(fn x -> not is_nil(display[x]) end)
    |>  Enum.each(fn x -> GPIO.release(display[x]) end)
    :ok
  end

  def execute do
    &command/2
  end

  defp start_pin(display, pin, direction) do
    %{^pin => gpio_number} = display
    {:ok, pid} = GPIO.start_link(gpio_number, direction)
    %{String.to_atom("#{to_string(pin)}_pid") => pid}
  end

  # ------------------------------------------------------------------
  # Initialization
  #

  defp init(display) do
    lines = case display[:rows] do
      1 ->  @lines_1
      _ ->  @lines_2
    end

    font = case display[:font_5x10] do
      true  ->  @font_5x10
      _     ->  @font_5x8
    end

    bits = case display[:bits] do
      4 ->  @mode_4bit
      _ ->  @mode_8bit
    end

    starting_function_state = @cmd_functionset ||| bits ||| font ||| lines
    starting_display_state = @cmd_dispcontrol ||| @ctl_display
    display_state = %{
      function_set: starting_function_state,
      # Set display on at intialization
      display_control: starting_display_state,
      row_offsets: %{
        0 => 0x00,
        1 => 0x40,
        2 => 0x00 + display[:cols],
        3 => 0x40 + display[:cols]
      },
      entry_mode: @cmd_entrymodeset,
      shift_control: @cmd_cursorshift
    }

    # initialize controller and set starting state
    init(display, bits)
    |>  Map.merge(display_state)
    |>  set_feature(:function_set)
    |>  set_feature(:display_control)
    |>  clear
    |>  set_feature(:entry_mode)
    |>  set_feature(:shift_control)
  end

  # Power on initialization for 4bit operation
  defp init(display, @mode_4bit) do
    display
    |>  delay(100)
    |>  rs(@low)
    |>  en(@low)
    |>  write_4_bits(0x03)
    |>  delay(50)
    |>  write_4_bits(0x03)
    |>  delay(50)
    |>  write_4_bits(0x03)
    |>  delay(50)
    |>  write_4_bits(0x02)
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
    for char <- map_string(content) do
      {:ok, _} = write_a_byte(display, char, @high)
    end
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
  defp command(display, {:scroll, cols}) when cols < 0 do
    write_a_byte(display, @cmd_cursorshift ||| @shift_display ||| @shift_right)
    command(display, {:scroll, cols + 1})
  end
  defp command(display, {:scroll, cols}) when cols > 0 do
    write_a_byte(display, @cmd_cursorshift ||| @shift_display)
    command(display, {:scroll, cols - 1})
  end
  defp command(display, {:scroll, _cols}) do
    {:ok, display}
  end
  defp command(display, {:char, idx, bitmap}) when idx in 0..7 and byte_size(bitmap) === 8 do
    write_a_byte(display, @cmd_setcgramaddr)
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
        |>  write_4_bits(byte_to_write &&& 0x0F)
      _ -> display
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
    display
  end

  # Write 4 parallel bits to the device
  defp write_4_bits(display, bits) do
    GPIO.write(display.d4_pid, bits &&& 0x01)
    GPIO.write(display.d5_pid, bits >>> 1 &&& 0x01)
    GPIO.write(display.d6_pid, bits >>> 2 &&& 0x01)
    GPIO.write(display.d7_pid, bits >>> 3 &&& 0x01)
    display
  end

  defp rs(display, value) do
    GPIO.write(display[:rs_pid], value)
    display
  end

  defp en(display, value) do
    GPIO.write(display[:en_pid], value)
    display
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

if Mix.env == :test do
  defmodule ElixirALE.GPIO do

    require Logger

    def start_link(pin, pin_direction, opts \\ []) do
      Logger.info("MockALE: start_link(#{inspect pin}, #{inspect pin_direction}, #{inspect opts})")
      {:ok, pin}
    end

    def write(pin, value) do
      Logger.info("MockALE: Pin(#{pin}) -> write(#{inspect value})")
      :ok
    end

    def release(pin) do
      Logger.info("MockALE: Pin(#{pin}) -> release()")
      :ok
    end
  end
end
