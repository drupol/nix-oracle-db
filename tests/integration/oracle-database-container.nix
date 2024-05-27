{
  name = "Oracle Database";

  nodes = {
    machine1 =
      { pkgs, ... }:
      {
        imports = [ ../../modules/oracle-database-container.nix ];
        services.oracle-database-container = {
          enable = true;
          openFirewall = true;
          passwordFile = ./password.txt;
        };
      };
  };

  testScript = ''
    start_all()
    machine1.wait_for_unit("oracle-database-container.target")
  '';
}
