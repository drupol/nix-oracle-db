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
    environment.etc."oratab".text = ''
      free:/var/lib/oracle-database/oradata/free:N
    '';

    environment.etc."sysconfig/oracle-free-23c.conf".text = ''
      # LISTENER PORT used Database listener, Leave empty for automatic port assignment
      LISTENER_PORT=1521

      # Character set of the database
      CHARSET=AL32UTF8

      # Database file directory
      # If not specified, database files are stored under Oracle base/oradata
      DBFILE_DEST=/var/lib/oracle-database/oradata

      # DB Domain name
      DB_DOMAIN=

      # SKIP Validations, memory, space
      SKIP_VALIDATIONS=false
    '';

    systemd.services.oracle-database = {
      description = "Oracle Database";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        mkdir -p $STATE_DIRECTORY/oradata
        cat /etc/oratab
        cat /etc/sysconfig/oracle-free-23c.conf
      '';
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/dbstart /var/lib/oracle-database/oradata";
        StateDirectory = "oracle-database";
        DynamicUser = true;
        PrivateTmp = "yes";
        Restart = "on-failure";
        Environment = [];
      };
    };
  };
}
