{ inputs
, ...
}:
{
  inputs = {
    prod = true;

    pythonOnNixRef = "main";
    pythonOnNixRev = "5ed7469cb2721b2d680c377569e7d69b6b803e35";
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
