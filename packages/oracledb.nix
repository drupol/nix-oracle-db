{ lib
, stdenv
, fetchurl

, makeBinaryWrapper
, rpmextract
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "oracle";
  version = "23c";

  src = fetchurl {
    url = "https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm";
    hash = "sha256-Exm818twbLcnUBy9mKvz85gKT9q+thOhq//HVpJcc3Q=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    rpmextract
  ] ++ lib.optionals stdenv.isLinux [
  ] ++ lib.optionals stdenv.isDarwin [
  ];

  buildInputs = [ ];

  unpackCmd = ''
    mkdir ${finalAttrs.pname}-${finalAttrs.version} && pushd ${finalAttrs.pname}-${finalAttrs.version}
    rpmextract $curSrc
    popd
  '';

  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/bin
    cp -ar {etc,opt,usr} $out

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
