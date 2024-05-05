{ lib, pkgs, osConfig, ... }: {
	# Additional Gnome configurations via home-manager.
	dconf.settings = lib.mkIf osConfig.host.ui.gnome.enable {
		"org/gnome/mutter" = {
			edge-tiling = true;
			workspaces-only-on-primary = false;
			experimental-features = [
				"scale-monitor-framebuffer"	# Fractional scaling
				"variable-refresh-rate"
			];
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

			# Set icon theme
			icon-theme = "Papirus-Dark";

			# Set legacy application theme
			gtk-theme = "Adwaita-dark";
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

		/*
			FIXME: Still needs work
		"org/gnome/shell/extensions/dash-to-panel" = {
			animate-appicon-hover = false;
			animate-appicon-hover-animation-extent = {
				RIPPLE = 4;
				PLANK = 4;
				SIMPLE = 1;
			};
			appicon-margin = 8;
			appicon-padding = 8;
			available-monitors= [0];
			dot-position = "BOTTOM";
			hotkeys-overlay-combo= "TEMPORARILY";
			leftbox-padding = -1;
			panel-anchors = {"0" = "MIDDLE"; };
			panel-element-positions={
				"0" = [{
					"element" = "dateMenu";
					"visible" = true;
					"position" = "stackedTL";
				}
				{
					"element" = "activitiesButton";
					"visible" = true;
					"position" = "stackedTL";
				}
				{
					"element" = "showAppsButton";
					"visible" = true;
					"position" = "centerMonitor";
				}
				{
					"element" = "leftBox";
					"visible" = false;
					"position" = "stackedTL";
				}
				{
					"element" = "taskbar";
					"visible" = true;
					"position" = "centerMonitor";
				}
				{
					"element" = "centerBox";
					"visible" = false;
					"position" = "stackedBR";
				}
				{
					"element" = "rightBox";
					"visible" = false;
					"position" = "stackedBR";
				}
				{
					"element" = "systemMenu";
					"visible" = true;
					"position"= "stackedBR";
				}
				{
					"element" = "desktopButton";
					"visible" = false;
					"position" = "stackedBR";
				}];
			};
			panel-lengths = { "0" = 100; };
			panel-positions = { "0" = "TOP"; };
			panel-sizes = { "0" = 64; };
			primary-monitor = 0;
			status-icon-padding = -1;
			tray-padding = -1;
			window-preview-title-position = "TOP";
		};
		*/
	};
}
