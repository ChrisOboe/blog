{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        gems = pkgs.bundlerEnv {
          name = "gems";
          ruby = pkgs.ruby;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
        };
      in
        with pkgs; {
          devShells = {
            bootstrap = mkShell {
              buildInputs = [ruby bundler bundix];
              env.BUNDLE_FORCE_RUBY_PLATFORM = true;
            };

            default = mkShell {
              buildInputs = [ruby gems];
              env.BUNDLE_FORCE_RUBY_PLATFORM = true;
            };
          };

          packages = {
            default = stdenv.mkDerivation {
              name = "blog";
              src = self;
              buildInputs = [ruby gems];
              env.BUNDLE_FORCE_RUBY_PLATFORM = true;
              buildPhase = ''
                ${gems}/bin/jekyll build
              '';
              installPhase = ''
                mkdir -p $out
                cp -r _site $out/_site
              '';
            };
            update = pkgs.writeShellApplication {
              name = "update";
              runtimeInputs = [bundler bundix coreutils];
              text = ''
                export BUNDLE_FORCE_RUBY_PLATFORM=true
                bundler update
                bundler lock
                bundler package --no-install --path ./vendor
                bundix
                rm -rf ./vendor
              '';
            };
          };
        }
    );
}
