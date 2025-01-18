# Extra install, run as user

# Rust tool
echo -e "\nInstalling default rust toolchain..."
rustup default stable

# Aur helper
echo -e "\nInstalling paru..."
git clone https://aur.archlinux.org/paru.git
cd paru/ && makepkg -si
cd .. && rm -rf paru

# Extra packages
echo "Installing packages..."
paru -S --needed $(grep -v '^#' extra-packages.txt)
echo "Packages installed."

# Sddm
sudo cp -r ./catppuccin-mocha /usr/share/sddm/themes/
sudo cp ./sddm.conf /etc/sddm.conf

#systemctl enable sddm.service
#xdg-user-dirs-update

# Xorg config
sudo cp ./30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf

# Bluetooth config
sudo cp ./51-blueman.rules /etc/polkit-1/rules.d/51-blueman.rules

# Login shell
read -p "Enter your username: " username
chsh --shell /usr/bin/fish $username
