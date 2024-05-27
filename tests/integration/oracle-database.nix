{
  name = "Oracle Database";

  nodes = {
    machine1 =
      { pkgs, ... }:
      {
        imports = [ ../../modules/oracle-database.nix ];
        services.oracle-database.enable = true;
      };
  };

  testScript = ''
    start_all()
    machine1.wait_for_unit("oracle-database.target")
  '';
}
