defmodule ExLCD.HD44780Test do
  use ExUnit.Case
  use Bitwise
  alias ExLCD.HD44780

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
