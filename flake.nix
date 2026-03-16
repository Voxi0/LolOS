{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
		systems.url = "github:nix-systems/default";
	};
	outputs = inputs: let
		forEachSystem = inputs.nixpkgs.lib.genAttrs (import inputs.systems);
		pkgs = forEachSystem(system: inputs.nixpkgs.legacyPackages.${system});
	in {
		devShells = forEachSystem(system: {
			default = pkgs.${system}.mkShellNoCC {
				nativeBuildInputs = with pkgs.${system}; [
					# Toolchain
					gcc
					nasm

					# Emulator
					qemu
				];
			};
		});
	};
}
