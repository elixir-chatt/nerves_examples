# Notes 

## Configure ssh key

Add key to config/config.exs
```
  Path.join([System.user_home!(), ".ssh", "yourkey_rsa.pub"]),
```

Configure wireless

```
config :nerves_network, :default,
  wlan0: [
    ssid: System.get_env("NERVES_NETWORK_SSID") || "Cragus",
    psk: System.get_env("NERVES_NETWORK_PSK") || "sassybluerooster",
    key_mgmt: String.to_atom(key_mgmt)
  ]
```

## Connect to wifi

```
export NERVES_NETWORK_SSID=your-wifi-network
export NERVES_NETWORK_PSK=your-wifi-password
export MIX_TARGET=rpi3
```

mix firmware
mix firmware.burn

put in sd card and start device 

Ping it

```
ping hello_gpio.local
```

## Remote shell

The cookie is in "rel/vm.args"

```
...
## Distributed Erlang Options
##  The cookie needs to be configured prior to vm boot for
##  for read only filesystem.

# -name hello_gpiok@0.0.0.0
-setcookie chocolatechip
...
```

Note this for later. 

```
iex --name host@0.0.0.0 \
    --cookie chocolatechip \
    --remsh hello_gpio@hello_gpio.local
```  
Push changes with 

```
mix firmware.push hello_gpio.local
```

