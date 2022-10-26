{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.clasp = nixpkgs.legacyPackages.x86_64-linux.callPackage ./clasp.nix {};

    packages.x86_64-linux.default = self.packages.x86_64-linux.clasp;

  };
}
