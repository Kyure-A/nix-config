{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      battery = {
        full_symbol = "🔋 ";
        charging_symbol = "⚡️ ";
        discharging_symbol = "💀 ";
      };
      cmd_duration = {
        disabled = false;
        min_time = 4000;
      };
      directory = {
        disabled = false;
        truncation_length = 100;
        truncate_to_repo = false;
      };
      username = {
        style_user = "white bold";
        style_root = "yellow bold";
        format = "[$user]($style)";
        disabled = false;
        show_always = true;
      };
      hostname = {
        format = ''
          @[$hostname](white) 
        '';
        ssh_only = false;
        disabled = false;
      };
      time = {
        disabled = false;
        use_12hr = false;
        format = "($style) ";
        time_format = "%T";
      };
    };
  };
}
