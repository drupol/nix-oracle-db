{
  stdenvNoCC,
  dockerTools,
  podman,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "oracle-oci-oradata";
  version = "1.0.0";

  src = dockerTools.pullImage {
    imageName = "container-registry.oracle.com/database/free";
    imageDigest = "sha256:83edd0756fda0e5faecc0fdf047814f0177d4224d7bf037e4900123ee3e08718";
    finalImageName = "oracle-free";
    finalImageTag = "23.4.0.0";
    sha256 = "sha256-NBI6y2YNHrwgWkwpd2MJfcESUiL4NAU0gDMXZMhiaZg=";
    os = "linux";
    arch = "x86_64";
  };

  nativeBuildInputs = [ podman ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    podman load -i $(readlink -f ${finalAttrs.src})

    # podman rm --force --ignore oracledbtmp
    # podman create --name oracledbtmp container-registry.oracle.com/database/free:23.4.0.0
    # podman cp oracledbtmp:/opt/oracle/oradata/ $out/
    # podman rm --force --ignore oracledbtmp

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    # TODO
    mkdir -p $out
    runHook postInstall
  '';
})
