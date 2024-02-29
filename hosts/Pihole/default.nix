{ pkgs, lib, ... }:

# Settings specific to Raspberry Pi 4b

{
	imports = [ 
		./hardware-configuration.nix
		../common
	];

	system.stateVersion = "24.05";

	host = {
		role = "server";
		users.aires.enable = true;
		boot.enable = false;
	};

	networking.hostName = "Pihole";
	time.timeZone = "America/New_York";

	environment.systemPackages = with pkgs; [
		libraspberrypi
		raspberrypifw
		raspberrypi-eeprom
		linuxKernel.kernels.linux_rpi4
	];

	# Connect to the network automagically
	networking.networkmanager.enable = lib.mkForce false;

	# Enable SSH
	services.openssh = {
		enable = true;
		ports = [ 33105 ];

		settings = {
			PasswordAuthentication = true;
			AllowUsers = ["aires"];
			PermitRootLogin = "no";
		};
	};
}
