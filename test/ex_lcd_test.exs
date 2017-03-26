defmodule ExLCDTest do
  use ExUnit.Case
  
  test "start_link starts a genserver and initializes its state" do
      assert {:ok, pid} = ExLCD.start_link({TestDriver, %{}})
      assert Process.alive?(pid)
  end

  describe "cast operations" do
    setup do
      # A state for testing
      state = %ExLCD.LCDState{display: %{}, callback: &TestDriver.command/2}
      [state: state]
    end

    test "clear clears display", state do
      assert {:noreply, state} = ExLCD.handle_cast(:clear, state[:state])
      assert {:clear, []} = state.display
    end

    test "home homes the cursor", state do
      assert {:noreply, state} = ExLCD.handle_cast(:home, state[:state])
      assert {:home, []} = state.display
    end

    test "set_cursor positions the cursor", state do
      assert {:noreply, state} = ExLCD.handle_cast({:set_cursor, 1, 2}, state[:state])
      assert {:set_cursor, 1, 2} = state.display
    end

    test "write outputs some text", state do
      assert {:noreply, state} = ExLCD.handle_cast({:write, "hello"}, state[:state])
      assert {:write, "hello"} = state.display
    end

    test "scroll scrolls the display", state do
      assert {:noreply, state} = ExLCD.handle_cast({:scroll, 1}, state[:state])
      assert {:scroll, 1} = state.display
    end

    test "move left moves the cursor left", state do
      assert {:noreply, state} = ExLCD.handle_cast({:left, 1}, state[:state])
      assert {:left, 1} = state.display
    end

    test "move right moves the cursor right", state do
      assert {:noreply, state} = ExLCD.handle_cast({:right, 1}, state[:state])
      assert {:right, 1} = state.display
    end

    test "enable enables a feature", state do
      assert {:noreply, state} = ExLCD.handle_cast({:enable, :foo}, state[:state])
      assert {:foo, :on} = state.display
    end

    test "disable disables a feature", state do
      assert {:noreply, state} = ExLCD.handle_cast({:disable, :foo}, state[:state])
      assert {:foo, :off} = state.display
    end

    test "char creates a custom glyph", state do
      char = <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>
      assert {:noreply, state} = ExLCD.handle_cast({:char, 6, char}, state[:state])
      assert {:char, 6, ^char} = state.display
    end
  end
end

defmodule TestDriver do
  use ExLCD.Driver

  def start(config), do: {:ok, config}
  def stop(_), do: :ok
  def execute(), do: &command/2
  def command(_state, op), do: {:ok, op}
end
