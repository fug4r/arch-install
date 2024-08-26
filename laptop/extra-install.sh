echo "Installing packages..."
pacman -S --needed $(grep -v '^#' extra-packages.txt)
echo "Packages installed."


systemctl enable sddm.service
#xdg-user-dirs-update

#git clone https://aur.archlinux.org/paru.git
rustup default stable
