defmodule HelloGpio do
  use Application

  require Logger

  alias Circuits.GPIO

  @output_pins Application.get_env(:hello_gpio, :output_pins, [26, 19])
  @input_pin Application.get_env(:hello_gpio, :input_pin, 20)
  require Logger

  alias Nerves.Network
  @interface Application.get_env(:hello_gpio, :interface, :eth0)



  def hello(), do: :world
    
  def start(_type, _args) do
    Logger.info("Starting network")
    GenServer.start_link(__MODULE__, to_string(@interface), name: __MODULE__)
    
    pins = open_pins(@output_pins)
    # spawn(fn -> toggle_pins_both_ways(pins) end)

    Logger.info("Starting pin #{@input_pin} as input")
    {:ok, input_gpio} = GPIO.open(@input_pin, :input)
    spawn(fn -> listen_forever(input_gpio) end)
    {:ok, self()}
  end
  
  def open_pins(pins) do
    Enum.map(pins, fn(pin_number) -> 
      {:ok, pin} = GPIO.open(pin_number, :output)
      pin
    end)
  end
  
  def init(interface) do
    Network.setup(interface)

    SystemRegistry.register()
    {:ok, %{interface: interface, ip_address: nil, connected: false}}
  end
  
  def toggle_pins_both_ways_forever(pins) do
    toggle_pins_both_ways(pins)
    toggle_pins_both_ways_forever(pins)
  end
  
  def toggle_pins_both_ways(pins, times\\4) do
    Enum.map( (1..times), fn(_) -> toggle_pins_alternating(pins) end)
    Enum.map( (1..times), fn(_) -> toggle_pins_together(pins) end)
  end

  def toggle_pins_together(pins) do
    blink(pins)
  end

  def toggle_pins_alternating(pins) do
    Enum.map( pins, &blink/1)
  end
  
  # named for the minot lighthouse near Boston
  def i_love_you(pins) do
    pins 
    |> Enum.zip([1, 4, 3])
    |> Enum.map(&blink_single_pin/1)
  end
  
  def blink_single_pin({pin, times}) do
    Enum.map((1..times), fn(_) -> blink(pin) end)
  end
  
  def blink(pins) do
    toggle(pins, 1)
    toggle(pins, 0)
  end
  
  def toggle(pins, value) when is_list(pins) do
    Enum.map pins, &GPIO.write(&1, value)
    Process.sleep(500)
  end
  def toggle(pins, value), do: toggle([pins], value)

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
