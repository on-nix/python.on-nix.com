{ inputs
, ...
}:
{
  inputs = {
    prod = true;

    pythonOnNixRef = "main";
    pythonOnNixRev = "ac7ad126d259829393f328a89b162fd0ea30fdf9";
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
