#!/bin/bash

which ruby >> /dev/null

if [ $? != 0 ]; then
  echo ""
  echo -e "\033[0;31mRuby not found!\033[0m Install it then run the script again."
  echo "https://www.ruby-lang.org/en/documentation/installation/#package-management-systems"
  exit 1
fi

which zenity >> /dev/null

if [ $? != 0 ]; then
  echo ""
  echo -e "\033[0;31mZenity not found!\033[0m Please install zenity for your distro."
  echo "For example: sudo apt-get install -y zenity"
  exit 1
fi

if [ "$USER" == "root" ]; then
  echo ""
  echo -e "\033[0;31mRunning as root detected!\033[0m If you are not logged-in with root user this will NOT work."
  echo "Please run this as your regular user (Without sudo)"
  echo ""
fi

# set -e so from here on error causes halt to entire script
set -e

if test -f "/home/$USER/.bluez_pa_auto_switcher/bluez_pa_auto_switcher.rb"; then
  echo "It looks like bluez_pa_auto_switcher is already installed for this user. Are you sure you want to reinstall it (y/n)?"
  read answer

  case ${answer:0:1} in
    y|Y )
      rm -Rf ~/.bluez_pa_auto_switcher
      rm ~/.config/systemd/user/bluez_pa_auto_switcher.service
    ;;
    * )
      echo -e "\033[0;31mCancelled\033[0m You answered: $answer"
      exit 1
    ;;
  esac
fi

if test -f "./bluez_pa_auto_switcher.rb"; then
  echo "SKIPPING DOWNLOAD bluez_pa_auto_switcher.rb found! Using current directory for the files."
  mkdir -p ~/.bluez_pa_auto_switcher
  cp -r ./* ~/.bluez_pa_auto_switcher
else
  echo "Downloading project using git..."
  git clone https://github.com/alisinabh/bluez_pa_auto_switcher ~/.bluez_pa_auto_switcher
fi

if test -d "$HOME/.config/bluez_pa_auto_switcher"; then
  echo "Configuration folder already exists! Skipping..."
else
  mkdir -p $HOME/.config/bluez_pa_auto_switcher
  cp ./config.yaml $HOME/.config/bluez_pa_auto_switcher
fi

cd ~/.bluez_pa_auto_switcher

echo "Files installed successfully in ~/.bluez_pa_auto_switcher"
echo ""

echo "Installing the service for current user... => $USER"
echo ""

mkdir -p ~/.config/systemd/user
ln -s ~/.bluez_pa_auto_switcher/bluez_pa_auto_switcher.service ~/.config/systemd/user/bluez_pa_auto_switcher.service
chmod 644 ~/.config/systemd/user/bluez_pa_auto_switcher.service

echo "Reloading systemd daemon for user mode..."
echo ""

systemctl --user daemon-reload
systemctl --user --now enable bluez_pa_auto_switcher

echo ""
echo -e "\033[0;32mSuccess\033[0m Service installed and enabled to run after login for user $USER"
echo "To stop it run 'systemctl --user stop bluez_pa_auto_switcher'"
