defmodule MockHD44780 do
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
