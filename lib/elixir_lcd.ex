use Bitwise

defmodule ElixirLcd do
  # commands
  @lcd_cleardisplay 0x01
  @lcd_returnhome 0x02
  @lcd_entrymodeset 0x04
  @lcd_displaycontrol 0x08
  @lcd_cursorshift 0x10
  @lcd_functionset 0x20
  @lcd_setcgramaddr 0x40
  @lcd_setddramaddr 0x80
  
  # flags for display entry mode
  @lcd_entryright 0x00
  @lcd_entryleft 0x02
  @lcd_entryshiftincrement 0x01
  @lcd_entryshiftdecrement 0x00
  
  # flags for display on/off control
  @lcd_displayon 0x04
  @lcd_displayoff 0x00
  @lcd_cursoron 0x02
  @lcd_cursoroff 0x00
  @lcd_blinkon 0x01
  @lcd_blinkoff 0x00
  
  # flags for display/cursor shift
  @lcd_displaymove 0x08
  @lcd_cursormove 0x00
  @lcd_moveright 0x04
  @lcd_moveleft 0x00
  
  # flags for function set
  @lcd_8bitmode 0x10
  @lcd_4bitmode 0x00
  @lcd_2line 0x08
  @lcd_1line 0x00
  @lcd_5x10dots 0x04
  @lcd_5x8dots 0x00
  
  # flags for backlight control
  @lcd_backlight 0x08
  @lcd_nobacklight 0x00
  
  @en 0b00000100  # Enable bit
  @rw 0b00000010  # Read/Write bit
  @rs 0b00000001  # Register select bit

  def connect do
    {:ok, pid} = I2c.start_link("i2c-0", 0x3f)

    # reset
    write_4_bits(pid, 0x00, 0x00)
    :timer.sleep 1000
   
    write_4_bits(pid, 0x03, 0x00)
    :timer.sleep 5 
    write_4_bits(pid, 0x03, 0x00)
    :timer.sleep 5 
    write_4_bits(pid, 0x03, 0x00)
    :timer.sleep 1 
    IO.puts "Entering 4-bit mode"
    write_4_bits(pid, 0x02, 0x00)

    IO.puts "Setting function set to 2 lines and 5x8 dots"
    display_function = @lcd_4bitmode ||| @lcd_2line ||| @lcd_5x8dots
    lcd_send(pid, @lcd_functionset ||| display_function)

    IO.puts "Turning on display and cursor"
    display_control = @lcd_displayon ||| @lcd_cursoron
    lcd_send(pid, @lcd_displaycontrol ||| display_control)

    IO.puts "Clearing display"
    lcd_send(pid, @lcd_cleardisplay)

    IO.puts "Setting entry left"
    display_mode = @lcd_entryleft
    lcd_send(pid, @lcd_entrymodeset ||| display_mode)
 
    IO.puts "Returning cursor to home"
    lcd_send(pid, @lcd_returnhome)

    IO.puts "Printing 'Ready'"
    :timer.sleep 200
    write_chars(pid, 'Ready', 1)
  end

  def write_chars(pid, char_list, line) do
    line_command = case line do
      1 -> 0x80
      2 -> 0xC0
      3 -> 0x94
      4 -> 0xD4
    end
    lcd_send(pid, line_command)
    _write_chars(pid, char_list)
  end

  defp _write_chars(_, []), do: nil
  defp _write_chars(pid, [head | tail]) do
    lcd_send(pid, head, @rs)
    _write_chars(pid, tail)
  end

  defp lcd_send(pid, data, mode \\ 0) do
    high = data &&& 0xf0 ||| mode
    low = (data <<< 4) &&& 0xf0 ||| mode
    # :io.format("sending ~8.2.0B ~8.2.0B (0x~2.16.0B~2.16.0B)~n", [high, low, high, low])
    write_4_bits(pid, high) 
    write_4_bits(pid, low) 
  end

  defp write_4_bits(pid, data, include_backlight \\ @lcd_backlight) do
    data = data ||| include_backlight
    :io.format("sending ~8.2.0B (0x~2.16.0B)~n", [data, data])
    i2c_expander_write(pid, data)
    pulse_enable(pid, data)
  end

  defp pulse_enable(pid, data) do
    i2c_expander_write(pid, data ||| @en)
    :timer.sleep 1
    i2c_expander_write(pid, data &&& ~~~@en)
    :timer.sleep 1
  end

  defp i2c_expander_write(pid, data) do
    I2c.write(pid, <<data>>)
    :timer.sleep 1
  end
end
