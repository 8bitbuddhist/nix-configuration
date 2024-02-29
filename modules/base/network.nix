{ ... }: {
	networking = {
		# Enable networking via NetworkManager
		networkmanager.enable = true;

		# Enable firewall
		nftables.enable = true;
		firewall = {
				enable = true;
		};
	};
}