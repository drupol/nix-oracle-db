{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.oracle-database;
in
{
  options = {
    services.oracle-database = {
      enable = lib.mkEnableOption (lib.mdDoc "Oracle Database");
      package = lib.mkPackageOptionMD pkgs "oracle-database" { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.oracle-database = {
      description = "Oracle Database";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "";
      };
    };
  };
}
