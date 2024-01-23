{ lib
, stdenv
, fetchurl
, buildFHSEnv

, makeBinaryWrapper
, rpmextract
, libaio
, alsa-lib
}:
let
  oracle-database-base = stdenv.mkDerivation (finalAttrs: {
    pname = "oracle-database-base";
    version = "23c";

    src = fetchurl {
      url = "https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm";
      hash = "sha256-Exm818twbLcnUBy9mKvz85gKT9q+thOhq//HVpJcc3Q=";
    };

    nativeBuildInputs = [
      makeBinaryWrapper
      rpmextract
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      libaio
      alsa-lib
    ];

    unpackCmd = ''
      mkdir ${finalAttrs.pname}-${finalAttrs.version} && pushd ${finalAttrs.pname}-${finalAttrs.version}
      rpmextract $curSrc
      popd
    '';

    dontPatchShebangs = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out $out/bin $lib/lib $bin/bin
      cp -ar {etc,opt,usr} $out
      cp -ar opt/oracle/product/23c/dbhomeFree/lib/* $lib/lib/
      cp -ar opt/oracle/product/23c/dbhomeFree/bin/* $bin/bin/

      runHook postInstall
    '';

    outputs = [ "bin" "out" "dev" "lib" ];
  });

  oracle-database-fhs = buildFHSEnv {
    name = "oracle-database-fhs";

    targetPkgs = pkgs: [
      oracle-database-base
      libaio
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "oracle-database";
  version = "23c";

  dontUnpack = true;
  dontBuild = true;

  buildInputs = [
    oracle-database-fhs
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${oracle-database-fhs}/bin/sqlplus $out/bin/sqlplus

    runHook postInstall
  '';

  meta = {
    description = "Oracle database";
    homepage = "http://www.oracle.com";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ drupol ];
  };
})
