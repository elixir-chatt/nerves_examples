defmodule HelloGpio do
  use Application

  require Logger

  alias Circuits.GPIO

  @output_pin Application.get_env(:hello_gpio, :output_pin, 26)
  @input_pin Application.get_env(:hello_gpio, :input_pin, 20)

  def start(_type, _args) do
    Logger.info("Starting pin #{@output_pin} as output")
    {:ok, pin1} = GPIO.open(26, :output)
    {:ok, pin2} = GPIO.open(19, :output)
    spawn(fn -> toggle_pins_both_ways([pin1, pin2]) end)

    Logger.info("Starting pin #{@input_pin} as input")
    {:ok, input_gpio} = GPIO.open(@input_pin, :input)
    spawn(fn -> listen_forever(input_gpio) end)
    {:ok, self()}
  end
  
  defp toggle_pins_both_ways(pins) do
    Enum.map( (1..4), fn(_) -> toggle_pins_alternating(pins) end)
    Enum.map( (1..4), fn(_) -> toggle_pins_together(pins) end)

    toggle_pins_both_ways(pins)
  end

  defp toggle_pins_together(pins) do
    blink(pins)
  end

  defp toggle_pins_alternating(pins) do
    Enum.map( pins, &blink/1)
  end
  
  defp blink(pins) do
    toggle(pins, 1)
    toggle(pins, 0)
  end
  
  defp toggle(pins, value) when is_list(pins) do
    Enum.map pins, &GPIO.write(&1, value)
    Process.sleep(500)
  end
  defp toggle(pins, value), do: toggle([pins], value)

  defp listen_forever(input_gpio) do
    # Start listening for interrupts on rising and falling edges
    GPIO.set_interrupts(input_gpio, :both)
    listen_loop()
  end

  defp listen_loop() do
    # Infinite loop receiving interrupts from gpio
    receive do
      {:circuits_gpio, p, _timestamp, 1} ->
        Logger.debug("Received rising event on pin #{p}")

      {:circuits_gpio, p, _timestamp, 0} ->
        Logger.debug("Received falling event on pin #{p}")
    end

    listen_loop()
  end
end
