use Bitwise

defmodule ElixirLcd.I2cExpander do
  @lcd_backlight 0b00001000
  @en            0b00000100  # Enable bit
  @rw            0b00000010  # Read/Write bit
  @rs            0b00000001  # Register select bit

  def connect(device, i2c_address) do
    I2c.start_link(device, i2c_address)
  end

  def execute([], _), do: nil
  def execute([head | tail], pid) do
    execute(head, pid)
    execute(tail, pid)
  end

  def execute(%{data: <<data::8>>}, pid) do
    high = (data &&& 0xf0) ||| @rs
    low = ((data <<< 4) &&& 0xf0) ||| @rs
    write_4_bits(high, pid)
    write_4_bits(low, pid)
  end

  def execute(%{instruction: <<data::8>>}, pid) do
    high = (data &&& 0xf0)
    low = ((data <<< 4) &&& 0xf0)
    write_4_bits(high, pid)
    write_4_bits(low, pid)
  end

  def execute(%{instruction: <<data::4>>}, pid) do
    low = ((data <<< 4) &&& 0xf0)
    write_4_bits(low, pid)
  end

  defp write_4_bits(data, pid) do
    i2c_expander_write(data, pid)
    pulse_enable(data, pid)
  end

  defp pulse_enable(data, pid) do
    i2c_expander_write(data ||| @en, pid)
    :timer.sleep 1
    i2c_expander_write(data &&& ~~~@en, pid)
    :timer.sleep 1
  end

  defp i2c_expander_write(data, pid) do
    data_with_backlight = data ||| @lcd_backlight
    I2c.write(pid, <<data_with_backlight>>)
    :timer.sleep 1
  end
end
