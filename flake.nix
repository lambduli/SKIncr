{
  description = "SKIncr development shell";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/22.11"; };

  outputs = { self, nixpkgs, ... }:
    let
	  pkgs = nixpkgs.legacyPackages."x86_64-linux";
	in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "SKIncr";
        buildInputs = with pkgs; [
          clang_10
        ];
      };
    };
}

