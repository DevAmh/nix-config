{inputs, ...}:
{
  modules ? [],
  specialArgs ? {},
  ...
}:
let
  slam = import inputs.slam {

  };
in
slam.evalModules
