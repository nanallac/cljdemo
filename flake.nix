{
  description = "A clj-nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    clj-nix.url = "github:jlesquembre/clj-nix";
  };

  outputs = {
    self,
    nixpkgs,
    devshell,
    clj-nix
  }: let
    pname = "cljdemo";
    version = builtins.substring 0 8 self.lastModifiedDate;
    
    supportedSystems = [ "x86_64-linux" ];
    
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    
    nixPkgsFor = forAllSystems (system: import nixpkgs {
      inherit system;
      overlays = [
        devshell.overlays.default
        clj-nix.overlays.default
      ];
    });
  in {
    packages = forAllSystems (system:
      let
        pkgs = nixPkgsFor.${system};
      in
      {
        cljdemo = pkgs.mkCljBin {
          projectSrc = ./.;
	  name = "ac.nanall/cljdemo";
	  inherit version;
	  main-ns = "hello.core";
        };

        default = self.packages.${system}.cljdemo;
      });

    apps = forAllSystems (system:
      let
        pkgs = nixPkgsFor.${system};
      in
      {
        cljdemo = {
	  type = "app";
	  program = "${self.packages.${system}.cljdemo}/bin/cljdemo";
	};
      });

    nixosModules.default = forAllSystems (system:
      let
        pkgs = nixPkgsFor.${system};
      in
      { config
      , lib
      , pkgs
      }:
        with lib; let
	  cfg = config.services.cljdemo;
	in {
        options.services.cljdemo = {
	  enable = mkEnableOption "enable the cljdemo service";
	  
	  # package = mkOption {
	  #   type = types.package;
	  #   default = self.packages.${system}.cljdemo;
	  #   description = "cljdemo package to use";
	  # };
	  
	  # port = mkOption {
	  #   type = types.port;
	  #   default = 3000;
	  #   description = "port to serve cljdemo on";
	  # };
	};

        config = mkIf cfg.enable {
	  systemd.services.cljdemo = {
	    description = "cljdemo";
	    wantedBy = [ "multi-user.target" ];

            serviceConfig = {
	      ExecStart = "${cfg.package}/bin/cljdemo";
	      ProtectHome = "read-only";
	      Restart = "on-failure";
	      Type = "exec";
	      DynamicUser = true;
	    };
	  };
	};
      });

    devShells = forAllSystems (system:
      let
        pkgs = nixPkgsFor.${system};
      in
      {
        default = pkgs.devshell.mkShell {
	  packages = [
	    pkgs.clojure
	    pkgs.jdk21
	  ];
	  commands = [
	    {
	      name = "update-deps";
	      help = "Update deps-lock.json";
	      command = '' nix run github:jlesquembre/clj-nix#deps-lock '';
	    }
	  ];
	};
      });
  };
}
