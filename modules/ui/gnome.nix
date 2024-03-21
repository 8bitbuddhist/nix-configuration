{ pkgs, config, lib, ... }:

# UI and desktop-related options
let
	cfg = config.host.ui.gnome;

	# Override Qogir icon theme to keep it more up-to-date
	qogir-icon-theme_new = pkgs.qogir-icon-theme.overrideAttrs (old: {
		version = "git";
		src = builtins.fetchGit {
			url = "https://github.com/vinceliuice/Qogir-icon-theme.git";
			ref = "master";
			rev = "37f41bfc4b09b2e3fe2185e3173f98a42272c05b";
		};
	});
in
with lib;
{

	options = {
		host.ui.gnome.enable = mkEnableOption (mdDoc "Enables Gnome");
	};

	config = mkIf cfg.enable {
		host.ui.audio.enable = true;
		host.ui.flatpak.enable = true;
		
		# Configure the xserver
		services.xserver = {
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
		};
		
		# Remove default packages that came with the install
		services.xserver.excludePackages = with pkgs; [
			xterm
		];
		environment.gnome.excludePackages = (with pkgs; [
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
		environment.systemPackages = with pkgs; [
			# Gnome tweak tools
			gnome.gnome-tweaks
			# Gnome extensions
			gnomeExtensions.appindicator
			gnomeExtensions.dash-to-panel
			gnomeExtensions.gsconnect
			gnomeExtensions.forge
			# Themeing
			gnome.gnome-themes-extra
			qogir-icon-theme_new
		];

		# Install Flatpaks
		services.flatpak.packages = [
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
		services.printing.enable = false;

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
