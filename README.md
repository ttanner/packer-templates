Packer template for minimalistic and flexible VMs
=================================================

(currently only Ubuntu 16.04.2 Xenial is supported)
The template can generate virtualbox, vmware and qemu/kvm images or vagrant boxes.
Requires Packer 0.11 or higher.

The options of the template can configured via packer variables.

example:
    `packer build -only virtualbox -var vm_name=testvm -var disk_size=40000 1604.json`

The most relevant variables (defaults in brackets) are:

*   `mirror` (auto):
    The mirror URL. `best` detects the fastest nearby-mirror, `auto` uses the Ubunutu dynamic mirror lookup,
      and `default` use the country dependent mirror.
*   language settings:
    - `country` (US)
    - `keyboard` (us)
    - `language` (en)
    - `locale` (en_US.UTF-8)
*   VM settings:
    - `disk_size` (4096): disk size in MB
    - `partitioning` (onlyroot): 
        `onlyroot` creates only a single root parition, `atomic` creates root and swap.
    - `cpu_cores` (1)
    - `memory` (512): RAM size in MB
    - `build_cpu_cores` (2): cores during VM build
    - `build_memory` (1024): memory during VM build
    - `headless` (true): headless installation, i.e. does not open am VM window. (see caveats)
    - `vga` (773): screen resolution:
        771=800×600, 773=1024×768, 353=1152×864, 775=1280×1024, 864=1440×900, 832=1400x1050, 796=1600×1200
    - `vbox_hostif` (vboxnet0): the name of the host-only interface. Use "VirtualBox Host-Only Ethernet Adapter" on Windows.
*   `vm_name` (mini1604)
*   proxy settings:
    `http_proxy`, `https_proxy`, `ftp_proxy` and `no_proxy` are copied from enviroment.
*   `offline` (false): pure offline installation - should not rely on downloads but only on cache
*   `with_kupgrade` (false):
    whether to keep generic kernel packages, headers, and VM guest sources for for automatic kernel upgrades.
*   `with_hwe' (true): whether to use the HWE stack for kernel and X11
*   `with_x11` (false): whether to install the core X11 server with VM guest support. conflicts with `offline`.
*   `with_i386` (false): whether to keep i386 packages
*   `with_qt` (false): whether to install Qt 5.7.1 PPA
*   `with_llvm` (false): whether to install LLVM 4.0 PPA
*   `with_salt` (false): whether to install salt stack PPA
*   `with_ppas` (""): PPAs to add (separated by spaces)
*   `with_pkgs` (""): additional packages to install
*   `without_pkgs` (""): packages to purge after installation

The template uses a required `aptcache` folder for downloaded deb packages for faster or offline installations.
After installation the apt cache is downloaded to a file `aptcache.tar`, which you may extract to the cache folder
for the next installation. It will be empty, if you create a file `aptcache/nodownload`.

The disk is called /dev/sda, the first network interface eth0, on Virtualbox the host-only interface eth1.

Current disk usage and compressed image size (Ubuntu 16.04.2):
minimal (HWE): 472MB/173MB
with kupgrade,x11,plymouth: 803MB/272MB
with kupgrade,x11,plymouth,mate: 1.6GB/594MB

Zesty
minimal: 701MB/180MB

If want to use TRIM on Virtualbox, you need to re-enable it after importing the OVF:
in "Manager for virtual media" copy the .vmdk image of your VM to a dynamic .vdi, replace it in the VM settings as the disk
and execute 'VBoxManage storageattach $vmname --storagectl "SATA Controller" --port 0 --device 0 --discard on --nonrotational on'.

Caveats:

*   On Windows Virtualbox the hostonly interfaces are called ["VirtualBox Host-Only Ethernet Adapter"]([https://www.virtualbox.org/ticket/7067]), "VirtualBox Host-Only Ethernet Adapter #2"... instead of "vboxnet0".
    [Rename them](http://www.fidian.com/problems-only-tyler-has/renaming-windows-network-adapter) or set the variable `vbox_hostif` accordingly.
