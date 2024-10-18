# Additional ZSH settings via Home Manager
{ ... }:
{
  programs = {
    # Set up Starship
    # https://starship.rs/
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.ignoreDups = true; # Do not enter command lines into the history list if they are duplicates of the previous event.
      initExtra = ''
        function set_win_title(){
        	echo -ne "\033]0; $(basename "$PWD") \007"
        }
        precmd_functions+=(set_win_title)

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
      '';
    };
  };
}
