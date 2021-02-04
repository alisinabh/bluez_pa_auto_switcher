# bluez_pa_auto_switcher

Automatically switches A2DP/HSP/HFP when a microphone is needed in Linux and pulseaudio. Just run the installation script and you are ready to go!

## Installation

You can use the provided `install.sh` in all distros with systemd and pulseaudio on them. If you don't have systemd then just running `bluez_pa_auto_switcher.rb'
after boot/login should work.

To install it simply run the following command:

```bash
curl https://raw.githubusercontent.com/alisinabh/bluez_pa_auto_switcher/main/install.sh | bash
```

## Configuration

You can edit the `~/.config/bluez_pa_auto_switcher/config.yaml` file to change the configuration. After changing the config remember to restart the service using
`systemctl --user restart bluez_pa_auto_switcher` command.

 - `validClients`: A list of application names to support auto switching for.

## The problem

TL; DR: Automatically switching to **Headset Head Unit (HSP/HFP)** Mode in Linux, Pulseaudio.

One of the most annoying things happened to me as a Linux user was setting up my bluetooth headphones. For audio playback it mostly works fine though.
The problems start to happen when you try to use the microphone. To use them you need to change the card profile to **Headset Head Unit (HSP/HFP)** and that should happen manually.
(For example using `pavucotrol` GUI or `pactl set-card-profile` in terminal) But like MacOS and Android I wanted it to happen automatically in Linux too.

I found this tool [bt_pa_auto_switcher](https://github.com/jikamens/bt_pa_auto_switcher) but I wasn't able to get it to work :(

But after reading the source I decided to re-write it since it looked pretty simple.

The project is heavily inspired by [bt_pa_auto_switcher](https://github.com/jikamens/bt_pa_auto_switcher)

