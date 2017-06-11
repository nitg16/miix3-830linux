#!/bin/bash

echo ""
echo "DISCLAIMER: This script comes without any guarantees."
echo "I am not responsible if it renders your device unusable."
echo "Use it your own risk."
sleep 5
echo ""
echo "This script will configure your Ubuntu 17.04 installation on a baytrail device."
echo "It has been tested to work on Lenovo miix 8-830."
echo "It **should** work on other baytrail devices with little to no tweaks."
sleep 5

ask() {
    # https://djm.me/ask
    local prompt default REPLY

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

rotation_setup () {

rotate_desktop.sh $1
sleep 5

echo "[Desktop Entry]
Name=Rotate
Type=Application
Exec=rotate_desktop.sh $1
Terminal=false" > ~/.config/autostart/rotate.desktop

echo "[SeatDefaults]
display-setup-script=rotate_desktop.sh $1" | sudo tee /etc/lightdm/lightdm.conf

}

echo ""
if ask "Do you want to continue the script?"; then
    :
else
    exit
fi

echo ""
echo "Removing thermald, fixes random system lockups." 
echo ""
sleep 2

sudo pkill thermald 
sudo apt remove thermald

echo ""
echo "Installing all deb packages in the folder, including latest mainline kernel."
echo "Mainline kernels are not supported by Canonical."
echo ""
sleep 3

sudo dpkg -i *.deb

echo ""
echo "Enabling bluetooth."
echo ""
sleep 2

sudo systemctl enable start_bt

echo ""
echo "Applying fix for Alsa."
echo ""
sleep 2

cd UCM-master
sudo cp -R * /usr/share/alsa/ucm/
cd ..
sudo rm /var/lib/alsa/asound.state

echo ""
echo "Applying fix for pulseaudio."
echo ""
sleep 2

sudo cp daemon.conf ~/.config/pulse/daemon.conf

echo ""
echo "Creating touchegg config files and adding it to autostart."
echo "Touchegg can enable two finger tap right click and also other gestures." 
echo "Touchegg only works on synaptics driver and not on libinput."
echo "Run 'sudo apt install touchegg' on next boot to enable it."
echo ""
sleep 3

mkdir -p ~/.config/touchegg
sudo cp touchegg.conf ~/.config/touchegg
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Name=Touchegg
Type=Application
Exec=touchegg
Terminal=false" > ~/.config/autostart/autostart_touchegg.desktop

echo ""
echo "Adding a system wide rotate_desktop.sh command."
echo "It will fix click/touch issues on different display orientations."
echo "You should use this instead of your default distro specific tool to rotate screen."
echo ""
sleep 4

sudo cp rotate_desktop.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/rotate_desktop.sh

echo ""
PS3='Please select default display orientation for desktop 
and login screen (lightdm login manager only, does not work with gdm3 and sddm): '
options=("normal" "inverted" "left" "right")
select opt in "${options[@]}"
do
    case $opt in
        "normal")
            rotation_setup normal
            break
            ;;
        "inverted")
            rotation_setup inverted
            break
            ;;
        "left")
            rotation_setup left
            break
            ;;
        "right")
            rotation_setup right 
            break
            ;;
        *) echo invalid option;;
    esac
done

echo ""
echo "Enabling tear free display graphics"
echo "This will not work if you remove xserver-xorg-vido-intel package."
echo ""
sleep 3

sudo mkdir -p /etc/X11/xorg.conf.d

echo "Section \"Device\"
   Identifier \"Intel Graphics\"
   Driver      \"intel\"
   Option      \"TearFree\"    \"true\"
EndSection" | sudo tee /etc/X11/xorg.conf.d/20-intel.conf

echo ""
echo "Disabling apport (crash report popups)"
echo ""
sleep 2

sudo service apport stop ; sudo sed -ibak -e s/^enabled\=1$/enabled\=0/ /etc/default/apport ; sudo mv /etc/default/apportbak ~

echo ""
echo "Installing right click panel applet."
echo "It should work on any panel that supports gtk3 applets."
echo "Xdotool required, run 'sudo apt install xdotool on next boot."
echo ""
sleep 3

sudo cp rclick.py /usr/local/bin/
sudo chmod +x /usr/local/bin/rclick.py
echo "[Desktop Entry]
Name=rclick
Type=Application
Exec=rclick.py
Terminal=false" > ~/.config/autostart/rclick.desktop

echo ""
echo "Few tweaks are in manualconfig.txt (important)" 
echo ""
sleep 5

# restart system

echo ""
echo "Rebooting after 20 seconds (required), press ctrl+c to abort"
sleep 20
reboot