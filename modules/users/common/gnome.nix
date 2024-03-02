{ lib, pkgs, osConfig, ... }: {
	# Additional Gnome configurations via home-manager. Imported by default by aires and gremlin.
	dconf.settings = lib.mkIf osConfig.host.ui.gnome.enable {
		"org/gnome/mutter" = {
			edge-tiling = true;
			workspaces-only-on-primary = false;
		};

		"org/gnome/desktop/interface" = {
			# Configure fonts
			font-name = "Fira Sans Semi-Light 11";
			document-font-name = "Roboto Slab 11";
			monospace-font-name = "Liberation Mono 11";
			titlebar-font = "Fira Sans Semi-Bold 11";

			# Configure hinting
			font-hinting = "slight";
			font-antialiasing = "rgba";

			# Configure workspace
			enable-hot-corners = true;
		};

		# Configure touchpad scroll & tap behavior
		"org/gnome/desktop/peripherals/touchpad" = {
			disable-while-typing = true;
			click-method = "fingers";
			tap-to-click = true;
			natural-scroll = true;
			two-finger-scrolling-enabled = true;
		};

		# Tweak window management
		"org/gnome/desktop/wm/preferences" = {
			button-layout = "appmenu:minimize,maximize,close";
			resize-with-right-button = true;
			focus-mode = "click";
		};

		# Make alt-tab switch windows, not applications
		"org/gnome/desktop/wm/keybindings" = {
			switch-tab = [];
			switch-windows = [ "<Alt>Tab" ];
			switch-windows-backward = [ "<Shift><Alt>Tab" ];
		};

		"org/gnome/shell" = {
			disable-user-extensions = false;
		};
	};
}
