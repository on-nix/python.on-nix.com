{ inputs
, ...
}:
{
  inputs = {
    prod = true;

    pythonOnNixRef = "main";
    pythonOnNixRev = "a3d93d5221d36ec864c5fd86597064650ef7c70c";
    pythonOnNixUrl = "https://github.com/on-nix/python";
    pythonOnNix = import
      (builtins.fetchGit {
        ref = inputs.pythonOnNixRef;
        rev = inputs.pythonOnNixRev;
        url = inputs.pythonOnNixUrl;
      })
      { };
  };
}
