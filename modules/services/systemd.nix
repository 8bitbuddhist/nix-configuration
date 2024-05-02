# Configure systemD
_: {
	services = {
		# Allow systemd user services to keep running after the user has logged out
		logind.killUserProcesses = false;
	};

	# Reduce systemd logout time to 30s
	environment.etc = {		
		"systemd/system.conf.d/10-reduce-logout-wait-time.conf" = {
			text = ''
				[Manager]
				DefaultTimeoutStopSec=30s
			'';
		};
	};
}