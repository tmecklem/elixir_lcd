defmodule ElixirLCD.CharLCD.HD44780Test do
  use ExUnit.Case
  use Bitwise
  alias ElixirLCD.CharLCD.HD44780
  alias HD44780Test.MockHD44780

  setup do
    # Device config for testing
    config = %{
      rs: 1, en: 2, d4: 4, d5: 5, d6: 6, d7: 7,
      rows: 2, cols: 20
    }

    # Mock the Hardware so we can inspect what happened
    with state = HD44780.start(config),
         {:ok, _} = MockHD44780.start_link(state)
    do
      %{state: state}
    end
  end

  describe "Command test:" do
    test "clear clears the display", %{state: state} do
      assert {:ok, _} = HD44780.command(state, {:clear, []})
      assert 0x01 = stack_value()
    end

    test "home homes the cursor", %{state: state} do
      assert {:ok, _} = HD44780.command(state, {:home, []})
      assert 0x02 = stack_value()
    end

    test "display turns on and off", %{state: state} do
      # 0b00001*CB
      assert {:ok, _} = HD44780.command(state, {:display, :on})
      assert 0x0C = (stack_value() &&& 0x0C)
      assert {:ok, _} = HD44780.command(state, {:display, :off})
      assert 0x08 = (stack_value() &&& 0x08)
    end

    test "cursor turns on and off", %{state: state} do
      # 0b00001D*B
      assert {:ok, _} = HD44780.command(state, {:cursor, :on})
      assert 0x0A = (stack_value() &&& 0x0A)
      assert {:ok, _} = HD44780.command(state, {:cursor, :off})
      assert 0x08 = (stack_value() &&& 0x08)
    end

    test "blink turns on and off", %{state: state} do
      # 0b00001DC*
      assert {:ok, _} = HD44780.command(state, {:blink, :on})
      assert 0x09 = (stack_value() &&& 0x09)
      assert {:ok, _} = HD44780.command(state, {:blink, :off})
      assert 0x08 = (stack_value() &&& 0x08)
    end

    test "autoscroll turns on and off", %{state: state} do
      # 0b00001DC*
      assert {:ok, _} = HD44780.command(state, {:autoscroll, :on})
      assert 0x05 = (stack_value() &&& 0x05)
      assert {:ok, _} = HD44780.command(state, {:autoscroll, :off})
      assert 0x04 = (stack_value() &&& 0x04)
    end

    test "rtl_text turns on", %{state: state} do
      # 0b00001DC*
      assert {:ok, _} = HD44780.command(state, {:rtl_text, :on})
      assert 0x04 == stack_value()
    end

    test "ltr_text turns on", %{state: state} do
      # 0b00001DC*
      assert {:ok, _} = HD44780.command(state, {:ltr_text, :on})
      assert 0x06 == stack_value()
    end

    test "shift screen left by one column", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:scroll, -1})
      assert 0x18 = (stack_value() &&& 0x18)
    end

    test "shift screen left by three columns", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:scroll, -3})
      %{stack: stack} = MockHD44780.status()
      assert [0x18, 0x18, 0x18] = stack
    end

    test "shift screen right by one column", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:scroll, 1})
      assert 0x1C = (stack_value() &&& 0x1C)
    end

    test "shift screen right by three columns", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:scroll, 3})
      %{stack: stack} = MockHD44780.status()
      assert [0x1C, 0x1C, 0x1C] = stack
    end

    test "move cursor left by one column", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:left, 1})
      assert 0x10 = (stack_value() &&& 0x10)
    end

    test "move cursor left by three columns", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:left, 3})
      %{stack: stack} = MockHD44780.status()
      assert [0x10, 0x10, 0x10] = stack
    end

    test "move cursor right by one column", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:right, 1})
      assert 0x14 = (stack_value() &&& 0x14)
    end

    test "move cursor right by three columns", %{state: state} do
      # 0b0001CD0
      assert {:ok, _} = HD44780.command(state, {:right, 3})
      %{stack: stack} = MockHD44780.status()
      assert [0x14, 0x14, 0x14] = stack
    end

    test "move cursor to row 1, column 14 moves the cursor", %{state: state} do
      # 0b1aaaaaa - 0x40 + 0x0E , row 1 starts at 0x40, col 14 is offset 0xE from there
      assert {:ok, _} = HD44780.command(state, {:set_cursor, {1, 14}})
      assert 0xCE = (stack_value() &&& 0xCE)
    end

    test "write hello world writes hello world", %{state: state} do
      assert {:ok, _} = HD44780.command(state, {:write, "hello world"})
      %{stack: stack} = MockHD44780.status()
      written = stack
      |> Enum.map(fn(x) -> x &&& 0xFF end)
      assert 'hello world' = written
    end

    test "write unicode symbols write mapped codes 0x10, 0x81 and 0x9D", %{state: state} do
      assert {:ok, _} = HD44780.command(state, {:write, "▶︎Д❤️"})
      %{stack: stack} = MockHD44780.status()
      written = stack
      |> Enum.map(fn(x) -> x &&& 0xFF end)
      assert [0x10, 0x81, 0x9D] = written
    end

    test "creating a custom character creates a custom character", %{state: state} do
      char = [ 0b00001010,
               0b00010101,
               0b00001010,
               0b00010101,
               0b00001010,
               0b00010101,
               0b00001010,
               0b00010101]
      assert {:ok, _} = HD44780.command(state, {:char, 3, char})
      %{stack: stack} = MockHD44780.status()
      written = Enum.map(stack, fn(x) -> x &&& 0xFF end)
      assert [0x43] ++ char == written
    end
  end

  defp stack_value() do
    with %{stack: stack} = MockHD44780.status()
    do
      List.first(stack)
    end
  end
end

defmodule HD44780Test.MockHD44780 do
  use GenServer
  use Bitwise

  @noisy false

  def start_link(display_state) do
    state = %{display_state: display_state, stack: [], register_state: 0x0000}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def status() do
    GenServer.call(__MODULE__, :status)
  end

  def write(pin, value) do
    GenServer.cast(__MODULE__, {pin, value})
  end

  def handle_call(:status, _, state) do
    {:reply, state, state}
  end

  def handle_cast({pin, value}, state) do
    {key, _} = state.display_state
    |>  Map.take([:rs, :en, :d0, :d1, :d2, :d3, :d4, :d5, :d6, :d7])
    |>  Enum.find(fn({_k, v}) -> v == pin end)
    {:noreply, write_bit(state, key, value)}
  end

  def write_bit(state, pin, value) do
    xform = case value do
      1   -> fn(x,y) -> x ||| y end
      0   -> fn(x,y) -> x &&& (~~~y) end
    end
    noise "Pin(#{pin}) #{value} [#{hex(state.register_state)}]"
    set_bit(state, pin, value, xform)
  end

  @pin_map [d4: 0x10, d5: 0x20, d6: 0x40, d7: 0x80,
            d0: 0x01, d1: 0x02, d2: 0x04, d3: 0x08]

  # Toggling EN high latches the register. Push it to the stack and reset
  defp set_bit(state, :en, 0, _),  do: state
  defp set_bit(state = %{register_state: register_state}, :en, 1, _) do
    noise "Register " <> hex(register_state, 4)
    # is the done flag set?
    {stack, register_state} = case register_state &&& 0x0200 do
      0x200 ->
        # push register to the stack and reset register
        {state.stack ++ [(register_state &&& 0x1FF)], 0}
      _ ->
        # Set finish flag to complete register write on next EN high
        {state.stack, (register_state &&& 0x01FF) ||| 0x0200}
    end

    %{state | stack: stack, register_state: register_state}
  end

  defp set_bit(state, :rs, _, xform) do
    new_register_state = xform.(state.register_state, 0x0100)
    %{state | register_state: new_register_state}
  end

  # If the 10th bit is set then d7 was written to so we either need an EN high
  # to latch the data or the next write to d4-d7 will be the low order bits
  # in a 4 bit interface.

  defp set_bit(state, :d7, _, xform) do
    shifted_value = case state.register_state >>> 9 do
      0 -> @pin_map[:d7]
      1 -> @pin_map[:d7] >>> 4
    end
    new_register_state = xform.(state.register_state, shifted_value)
    %{state | register_state: new_register_state}
  end

  defp set_bit(state, pin, _, xform) when pin in [:d4, :d5, :d6] do
    shifted_value = case state.register_state >>> 9 do
      0 -> @pin_map[pin]
      1 -> @pin_map[pin] >>> 4
    end
    new_register_state = xform.(state.register_state, shifted_value)
    %{state | register_state: new_register_state}
  end

  # Writing to d0-d3 forces finish on next EN high (8-bit mode)

  defp set_bit(state, pin, _, xform) do
    new_register_state = xform.(state.register_state, @pin_map[pin]) ||| 0x0200
    %{state | register_state: new_register_state}
  end

  defp noise(str) do
    if @noisy do
      IO.puts str
    end
  end

  defp hex(value, width \\ 2) do
    padded = Integer.to_string(value, 16)
    |>  String.pad_leading(width, "0")
    "0x" <> padded
  end
end
