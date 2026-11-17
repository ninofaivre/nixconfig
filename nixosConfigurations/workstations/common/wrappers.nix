{ wrappers, ... }: {
  imports = map (wrapper: wrapper.install) (with wrappers; [
    triad
  ]);

  wrappers = {
    triad.enable = true;
  };
}
