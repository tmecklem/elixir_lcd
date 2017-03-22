# defmodule ElixirALE.TestHelper do
#   @moduledoc """
#   Mock ElixirALE API for testing
#   """
#   defmodule ElixirALE.GPIO do
#
#     require Logger
#
#     def start_link(pin, pin_direction, opts \\ []) do
#       Logger.info("MockALE: start_link(#{inspect pin}, #{inspect pin_direction}, #{inspect opts})")
#       {:ok, pin}
#     end
#
#     def write(pin, value) do
#       Logger.info("MockALE: Pin(#{pin}) -> write(#{inspect value})")
#       :ok
#     end
#
#     def release(pin) do
#       Logger.info("MockALE: Pin(#{pin}) -> release()")
#       :ok
#     end
#   end
#
#   defmodule ElixirALE.SPI do
#
#   end
#
#   defmodule ElixirALE.I2C do
#
#   end
# end
