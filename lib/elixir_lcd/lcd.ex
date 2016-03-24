use Bitwise

defmodule ElixirLcd.Lcd do
  @instruction_clear_display 0x01
  @instruction_return_home 0x02

  @instruction_entry_mode_set 0x04
  @ems_increment 0x02 # move cursor to right
  @ems_shift_display 0x01 #scroll screen instead of move cursor

  @instruction_display_control 0x08
  @dc_display_on 0x04
  @dc_cursor_on 0x02
  @dc_blink_on 0x01

  @instruction_cursor_shift 0x10
  @cs_displaymove 0x08
  @cs_moveright 0x04

  @instruction_function_set 0x20
  @fs_4_bit_mode 0x00
  @fs_8_bit_mode 0x10
  @fs_2_line 0x08
  @fs_5x10_dots 0x04

  @instruction_setcgramaddr 0x40
  @instruction_setddramaddr 0x80

  def display_chars(chars) do
    Enum.map(chars, fn char -> %{data: <<char>>} end)
  end

  def move(row, column) do
    line_command = case row do
      1 -> 0x80
      2 -> 0xC0
      3 -> 0x94
      4 -> 0xD4
    end
    %{instruction: <<line_command ||| (column - 1)>>}
  end

  def reset_4_bits do
    eight_bit_function = <<0x3::4>>
    four_bit_function  = <<0x2::4>>
    [
      %{instruction: eight_bit_function}, # reset LCD driver
      %{instruction: eight_bit_function}, # do it again, per datasheet
      %{instruction: eight_bit_function}, # do it again, per datasheet
      %{instruction: four_bit_function},  # go 4 bit mode
      %{instruction: <<@instruction_function_set ||| @fs_4_bit_mode ||| @fs_2_line>>},
      %{instruction: <<@instruction_display_control ||| @dc_display_on>>},
      %{instruction: <<@instruction_clear_display>>},
      %{instruction: <<@instruction_entry_mode_set ||| @ems_increment>>}
    ]
  end
end
