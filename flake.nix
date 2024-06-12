{
  description = "auto updating seaweedfs overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    seaweedfs = {
      url = "github:seaweedfs/seaweedfs";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    ...
  }: let
    overlay = final: prev: {
      seaweedfs = prev.buildGo122Module rec {
          pname = "seaweedfs";
          version = inputs.seaweedfs.shortRev;
          src = inputs.seaweedfs;

          vendorHash = "sha256-Y2IAcr3tcgeJRHEEVcl/lbZqf6J1lQcHkqkranaaFRA=";

          subPackages = ["weed"];

          ldflags = [
            "-w"
            "-s"
            "-X github.com/seaweedfs/seaweedfs/weed/util.COMMIT=${version}"
          ];

          tags = [
            "elastic"
            "gocdk"
            "sqlite"
            "ydb"
            "tikv"
          ];

          preBuild = ''
            export GODEBUG=http2client=0
          '';

          preCheck = ''
            # Test all targets.
            unset subPackages

            # Remove unmaintained tests ahd those that require additional services.
            rm -rf unmaintained test/s3
          '';
        };
    };
  in
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [overlay];
        };
      in {
        packages.default = pkgs.seaweedfs;
        packages.seaweedfs = pkgs.seaweedfs;
      }
    )
    // {
      overlays.default = overlay;
    };
}
