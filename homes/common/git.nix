{ namespace, osConfig, ... }:
{
  programs.git = {
    enable = true;
    userName = osConfig.${namespace}.secrets.users.aires.firstName;
    userEmail = osConfig.${namespace}.secrets.users.aires.email;
    extraConfig = {
      core.editor = osConfig.${namespace}.editor;
      merge.conflictStyle = "zdiff3";
      pull.ff = "only";
      push.autoSetupRemote = "true";
      safe.directory = "${osConfig.${namespace}.secrets.nixConfigFolder}/.git";
      submodule.recurse = true;
      credential.helper = "/run/current-system/sw/bin/git-credential-libsecret";
    };
  };
}
