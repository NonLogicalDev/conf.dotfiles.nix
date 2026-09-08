{
  description = "Personal Nix-managed user and system profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      outputs = inputs.blueprint { inherit inputs; };
    in
    outputs
    // {
      homeModules = builtins.mapAttrs (
        _name: module:
        if builtins.isString module || builtins.isPath module then
          {
            _file = toString module;
            imports = [ module ];
          }
        else
          module
      ) outputs.homeModules;
    };
}
