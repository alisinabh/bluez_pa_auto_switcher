# bluez_pa_auto_switcher

Automatically switches A2DP/HSP/HFP when a microphone is needed in Linux and pulseaudio. Just run the installation script and you are ready to go!

## Requirements

 - `pactl`: The pactl executable should be available.
 - `ruby`: `>= 2.0.0` should work. Tested with `2.7.2`
 - `pipewire-pulse`: **Optional** if you are using pipewire.
 - `zenity`: To ask before switching.

## Installation

You can use the provided `install.sh` in all distros with systemd and pulseaudio on them. If you don't have systemd then just running `bluez_pa_auto_switcher.rb'
after boot/login should work.

To install it simply run the following command:

```bash
bash -c "$(curl -sSL https://raw.githubusercontent.com/alisinabh/bluez_pa_auto_switcher/main/install.sh)"
```

Or you can just clone and run the `bluez_pa_auto_switcher.rb` file manually.

## Configuration

You can edit the `~/.config/bluez_pa_auto_switcher/config.yaml` file to change the configuration. For example you can unblock an app which you have blocked by removing it from the config file.

 - `invalidClients`: A list of application names to disable the auto switching prompt for. Apps will be added to this list when you choose `Never For APP` from the prompt automatically.

After changing configuration you will need to restart the service using systemd.

```bash
systemctl --user restart bluez_pa_auto_switcher.service
```

## The problem and How?

TL; DR: Automatically switching to **Headset Head Unit (HSP/HFP)** Mode in Linux, Pulseaudio.

One of the most annoying things happened to me as a Linux user was setting up my bluetooth headphones. For audio playback it mostly works fine though.
The problems start to happen when you try to use the microphone. To use them you need to change the card profile to **Headset Head Unit (HSP/HFP)** and that should happen manually.
(For example using `pavucotrol` GUI or `pactl set-card-profile` in terminal) But like MacOS and Android I wanted it to happen automatically in Linux too.

I found this tool [bt_pa_auto_switcher](https://github.com/jikamens/bt_pa_auto_switcher) but I wasn't able to get it to work :(

But after reading the source I decided to re-write it since it looked pretty simple. Just watch for pulseaudio events with `pactl subscribe` and change the card profile whenever a valid client asks for input sinks.

The project is heavily inspired by [bt_pa_auto_switcher](https://github.com/jikamens/bt_pa_auto_switcher)

## License

MIT
