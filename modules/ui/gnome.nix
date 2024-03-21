{ pkgs, config, lib, ... }:

# UI and desktop-related options
let
	cfg = config.host.ui.gnome;
in
with lib;
{

	options = {
		host.ui.gnome.enable = mkEnableOption (mdDoc "Enables Gnome");
	};

	config = mkIf cfg.enable {
		host.ui = {
			audio.enable = true;
			flatpak.enable = true;
		};
		
		services = {
			# Configure the xserver
			xserver = {
				# Enable the X11 windowing system.
				enable = true;

				# Configure keymap in X11
				xkb = {
					layout = "us";
					variant = "";
				};

				# Enable Gnome
				desktopManager.gnome.enable = true;
				displayManager = {
					gdm.enable = true;
				};

				# Remove default packages that came with the install
				excludePackages = with pkgs; [
					xterm
				];
			};

			# Install Flatpaks
			flatpak.packages = [
				"com.mattjakeman.ExtensionManager"
				"dev.geopjr.Tuba"
				"org.bluesabre.MenuLibre"
				"org.gnome.baobab"
				"org.gnome.Calculator"
				"org.gnome.Characters"
				"org.gnome.Calendar"
				"org.gnome.Evince"
				"org.gnome.Evolution"
				"org.gnome.FileRoller"
				"org.gnome.Firmware"
				"org.gnome.gitg"
				"org.gnome.Loupe"	# Gnome's fancy new image viewer
				"org.gnome.Music"
				"org.gnome.seahorse.Application"
				"org.gnome.TextEditor"
				"org.gnome.World.Secrets"
				"org.gtk.Gtk3theme.Adwaita-dark"
			];

			# Disable CUPS - not needed
			printing.enable = false;
		};
		
		environment = {
			# Remove default Gnome packages that came with the install, then install the ones I actually use
			gnome.excludePackages = (with pkgs; [
				gnome-photos
				gnome-tour
				gnomeExtensions.extension-list
				gedit # text editor
			]) ++ (with pkgs.gnome; [
				cheese # webcam tool
				gnome-music
				gnome-calendar
				epiphany # web browser
				geary # email reader
				evince # document viewer
				gnome-characters
				totem # video player
				tali # poker game
				iagno # go game
				hitori # sudoku game
				atomix # puzzle game
			]);

			# Install additional Gnome packages
			systemPackages = with pkgs; [
				# Gnome tweak tools
				gnome.gnome-tweaks
				# Gnome extensions
				gnomeExtensions.appindicator
				gnomeExtensions.dash-to-panel
				gnomeExtensions.gsconnect
				gnomeExtensions.forge
				# Themeing
				gnome.gnome-themes-extra
				papirus-icon-theme
			];
		};

		# Manage fonts
		fonts = {
			# Install extra fonts
			packages = with pkgs; [
				noto-fonts
				noto-fonts-cjk
				noto-fonts-emoji
				liberation_ttf
				fira-code
				fira-code-symbols
				fira
				roboto-slab
			];

			# Enable font dir for use with Flatpak. See https://nixos.wiki/wiki/Fonts#Flatpak_applications_can.27t_find_system_fonts
			fontDir.enable = true;
		};

		# Gnome UI integration for KDE apps
		qt = {
			enable = true;
			platformTheme = "gnome";
			style = "adwaita-dark";
		};
	};
}
