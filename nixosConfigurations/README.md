# Example deployment after nixos install for workstation-desktop

## populate secret key (encrypted secrets are in the repo)
- `mkdir -p /tmp/mnt/usbstick && mount /dev/sda2 /tmp/mnt/usbstick`
- `cp /tmp/mnt/usbstick/sops-age-key_workstation-desktop.txt /root`

## pull config from github
- `cd /etc/nixos`
- `git init`
- `git remote add github https://github.com/ninofaivre/nixconfig` *replace remote after first build which will import ssh keys*
- `git pull github master`

## clean / merge of generated config with repo
- `rm ./configuration.nix`
- `mv ./hardware-configuration.nix ./nixosConfigurations/workstations/desktop` *if hardware changed, else rm it*

## first build
- `nixos-rebuild switch --accept-flake-config --flake /etc/nixos#workstations-desktop`

## end
- `rebuild switch` *is how to build now*
