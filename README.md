Packer template for minimalistic and flexible VMs
=================================================

(currently only Ubuntu 16.04.1 Xenial supported)
The template can generate virtualbox, vmware and qemu/kvm images or vagrant boxes.

The options of the template can configured via packer variables.

example:
    `packer build -only virtualbox -var vm_name=testvm -var disk_size=40000 1604.json`

The most relevant variables (defaults in brackets) are:

*   `mirror` (auto):
    The mirror URL. `auto` detects the fastest nearby-mirror.
*   language settings:
    - `country` (US)
    - `keyboard` (us)
    - `language` (en)
    - `locale` (en_US.UTF-8)
*   VM settings:
    - `disk_size` (4096): size in KB
    - `cpu_cores` (1)
    - `memory` (512): RAM size in MB
    - `build_cpu_cores` (2): cores during VM build
    - `build_memory` (1024): memory during VM build
    - `partitioning` (onlyroot): 
        onlyroot creates only a single root parition, `atomic` creates root and swap.
*   `headless` (true)
    headless installation, i.e. does not open am VM window. (see caveats)
*   `vm_name` (mini1604)
*   proxy settings:
    `http_proxy`, `https_proxy`, `ftp_proxy` and `no_proxy` are copied from enviroment.
*   `with_kupgrade` (false):
    whether to keep kernel generic packages, kernel and VM guest sources for for automatic kernel upgrades.
*   `with_x11` (false): whether to install the core X11 server with VM guest support.
*   `with_i386` (false): whether to keep i386 packages
*   `with_ppas` (): PPAs to add
*   `with_pkgs` (): additional packages to install
*   `without_pkgs` (): packages to purge after installation
*   provisioners:
    - `with_ansible` (false): install ansible
    - `with_salt` (false): install salt stack
    - `with_chef` (false): install chef
    - `with_puppet` (false): install puppet
    - `with_docker` (false): install docker

The template uses a required `aptcache` folder for downloaded deb packages for faster or offline installations.
After installation the apt cache is downloaded to a file `aptcache.tar`, which you may extract to the cache folder
for the next installation. It will be empty, if you create a file `aptcache/nodownload.

Caveats:

*   due to a packer bug you have to remove the section `vboxmanage_post` in 1604.json if you set headless=false.
*   On Windows Virtualbox the hostonly-Interfaces are called "VirtualBox Host-Only Ethernet Adapter",
    "VirtualBox Host-Only Ethernet Adapter #2"... instead of "vboxnet0". Rename them or change the line
    `["modifyvm", "{{.Name}}", "--hostonlyadapter2", "vboxnet0"]` in 1604.json
    http://www.fidian.com/problems-only-tyler-has/renaming-windows-network-adapter
    https://www.virtualbox.org/ticket/7067
