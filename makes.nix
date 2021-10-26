{ inputs
, ...
}:
{
  inputs = {
    prod = true;

    pythonOnNixRef = "main";
    pythonOnNixRev = "393341352b695acd2b7da1b5dc0265f68ab6f4b0";
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
