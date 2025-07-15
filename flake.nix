{
  description = "hugo bin versions";

  outputs =
    { ... }:
    {
      overlays.default = ./overlay.nix;
    };
}
