{ lib
, stdenvNoCC
, fetchurl
, buildFHSEnv
, writeScript
, rpmextract
, libaio
, alsa-lib
, makeBinaryWrapper
, openssl
, iproute2
, su
, gawk
, gnugrep
, hostname
, coreutils
}:
let
  oracle-database-unwrapped = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "oracle-database-unwrapped";
    version = "23c";

    src = fetchurl {
      url = "https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm";
      hash = "sha256-Exm818twbLcnUBy9mKvz85gKT9q+thOhq//HVpJcc3Q=";
    };

    nativeBuildInputs = [
      rpmextract
    ];

    unpackCmd = ''
      mkdir ${finalAttrs.pname}-${finalAttrs.version} && pushd ${finalAttrs.pname}-${finalAttrs.version}
      rpmextract $curSrc
      popd
    '';

    postPatch = ''
      # Making very subtle changes so that Nix can update the SheBang automatically.
      substituteInPlace opt/oracle/product/${finalAttrs.version}/dbhomeFree/OPatch/opatch.pl \
        --replace "#!/usr/bin/env PERL5OPT=-T perl" "#!/usr/bin/env -S PERL5OPT=-T perl"
      substituteInPlace opt/oracle/product/${finalAttrs.version}/dbhomeFree/OPatch/emdpatch.pl \
        --replace "#!/usr/bin/env PERL5OPT=-T perl" "#!/usr/bin/env -S PERL5OPT=-T perl"
      # This script can only be run by root. This changes prevent that. Not sure at all about this yet.
      substituteInPlace etc/init.d/oracle-free-23c \
        --replace "/opt/oracle/product/23c/dbhomeFree" ${placeholder "out"}/opt/oracle \
        --replace 'if [ $(id -u) != "0" ]' 'if false' \
        --replace 'SS=/usr/sbin/ss' 'SS=${iproute2}/bin/ss' \
        --replace 'SS="/sbin/ss"' 'SS="${iproute2}/bin/ss"' \
        --replace 'SU=/bin/su' 'SU=${su}/bin/su' \
        --replace 'AWK=/bin/awk' 'AWK=${gawk}/bin/awk' \
        --replace 'DF=/bin/df' 'DF=${coreutils}/bin/df' \
        --replace 'GREP=/usr/bin/grep' 'GREP=${gnugrep}/bin/grep' \
        --replace 'TAIL=/usr/bin/tail' 'TAIL=${coreutils}/bin/tail' \
        --replace 'TAIL=/bin/tail' 'TAIL=${coreutils}/bin/tail' \
        --replace 'HOSTNAME_CMD="/bin/hostname"' 'HOSTNAME_CMD="${hostname}/bin/hostname"' \
        --replace 'MKDIR_CMD="/bin/mkdir"' 'MKDIR_CMD="${coreutils}/bin/mkdir"'
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/oracle
      cp -ar {etc,usr} $out/
      cp -ar opt/oracle/product/${finalAttrs.version}/dbhomeFree/* $out/opt/oracle
      ln -s $out/opt/oracle/bin $out/bin
      ln -s $out/opt/oracle/lib $out/lib

      # to be confirmed: Remove these files as they are not needed.
      rm -rf $out/opt/oracle/lib/pkgconfig
      rm -rf $out/opt/oracle/lib/cmake

      runHook postInstall
    '';
  });

  fhs = buildFHSEnv {
    name = "oracle-database";

    targetPkgs = pkgs: [
      oracle-database-unwrapped
      alsa-lib
      libaio
      openssl
    ];

    runScript = writeScript "oracle-database-fhs-wrapper" ''
      exec "$@"
    '';

    meta.mainProgram = "oracle-database";
  };
in
stdenvNoCC.mkDerivation {
  pname = "oracle-database";
  inherit (oracle-database-unwrapped) version;

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    find ${oracle-database-unwrapped}/opt/oracle/bin -type f -executable -print0 | while read -d $'\0' executable
    do
      makeWrapper ${lib.getExe fhs} $out/bin/$(basename $executable) \
        --set-default ORACLE_HOME ${oracle-database-unwrapped}/opt/oracle \
        --add-flags $executable
    done

    find ${oracle-database-unwrapped}/etc/init.d -type f -executable -print0 | while read -d $'\0' executable
    do
      exe=$(cut -d"/" -f5- <<< $executable)
      makeWrapper ${lib.getExe fhs} $out/$exe \
        --set-default ORACLE_HOME ${oracle-database-unwrapped}/opt/oracle \
        --add-flags $executable
    done

    runHook postInstall
  '';

  meta = {
    description = "Oracle Database";
    homepage = "http://www.oracle.com";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ drupol ];
  };
}
