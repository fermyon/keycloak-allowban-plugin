{ maven, lib }:
maven.buildMavenPackage {
  pname = "keycloak-lists-plugin";
  version = "1.0";

  src = ./plugin;

  mvnHash = "sha256-hzl3ypSAwfS1AiQ5Bg1drIyNIUHHx9eRTbVkEuBi2Hw=";

  buildPhase = ''
    mvn --offline package;
  '';

  installPhase = ''
    mkdir -p $out
    install -Dm644 target/*.jar $out
  '';
}
