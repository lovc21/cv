{
  description = "Build your resume with Markdown and custom CSS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            permittedInsecurePackages = [ "openssl-1.1.1w" ];
          };
        };

        buildInputs = with pkgs; [
          pandoc
          wkhtmltopdf-bin
          fontconfig    # Font management
          freetype      # Font rendering
        ];

        buildPhase = ''
          # Ensure Fontconfig can find its configuration
          export FONTCONFIG_PATH=${pkgs.fontconfig}/etc/fonts

          # Convert Markdown to HTML with embedded resources
          pandoc resume.md \
            -t html -f markdown \
            -c style.css --embed-resources --standalone \
            -o resume.html

          # Convert HTML to PDF
          wkhtmltopdf --enable-local-file-access \
            resume.html \
            resume.pdf
        '';

      in with pkgs; {
        packages = {
          default = stdenvNoCC.mkDerivation {
            inherit buildInputs buildPhase;
            name = "resume_md";
            src = ./.;
            installPhase = ''
              mkdir -p $out/resume
              cp resume.* $out/resume/
            '';
          };
        };

        checks = {
          default = stdenvNoCC.mkDerivation {
            inherit buildInputs buildPhase;
            name = "resume-md checks";
            src = ./.;
            installPhase = ''
              mkdir -p $out
            '';
          };
        };

        devShell = mkShell {
          inherit buildInputs;
        };
      });
}
