glpi-agent
==========

1. [Overview](#overview)
1. [Examples](#examples)
1. [Default variables](#default-variables)
     * [Packages and installation](#packages-and-installation)
     * [Fusioninventory Agent](#fusioninventory-agent)
     * [Configuration](#configuration)
1. [Debian dedicated variables](#debian-dedicated-variables)
1. [Development](#development)
1. [License](#license)
1. [Author Information](#author-information)


## Overview

This role will try to install and manage glpi-agent on Linux systems (Debian family only at the beginning).

It's heavily inspired from the previous role dedicated to [fusioninventory-agent](https://github.com/ipr-cnrs/fusioninventory).

## Examples

<details>
  <summary>Install glpi-agent from your own APT/Yum/… repository (<i>click to expand</i>)</summary>
  <!-- have to be followed by an empty line! -->

``` yml
- hosts: serverXYZ
  vars:
      glpi_agent__conf_raw: |
        # glpi-agent requires a server to start the service
        server = http://server.domain.com/front/inventory.php

  roles:
    - role: ipr-cnrs.glpi_agent
```
* **glpi-agent** package is not (yet) available in officials repositories (Debian, Ubuntu,…).
</details>

<details>
  <summary>Install glpi-agent prebuild package from GLPI Agent Github project (<i>click to expand</i>)</summary>
  <!-- have to be followed by an empty line! -->

``` yml
- hosts: serverXYZ
  vars:
      glpi_agent__install_from_url: true
      glpi_agent__conf_raw: |
        # glpi-agent requires a server to start the service
        server = http://server.domain.com/front/inventory.php

  roles:
    - role: ipr-cnrs.glpi_agent
```
* `glpi_agent__install_from_url` will first install dependencies and
  use prebuild glpi-agent package from GLPI Agent Github repository.
* All versions and officials prebuild packages can be found on
  [GLPI Agent Github repository][glpi agent project github].
</details>


## Default variables

### Packages and installation

#### glpi_agent__enabled
**Boolean**. Enable or disable glpi-agent's installation and configuration.

``` yml
glpi_agent__enabled: true
```

#### glpi_agent__install_from_url
**Boolean**. If GLPI Agent package should be installed from package build by
GLIP project.

``` yml
glpi_agent__install_from_url: false
```

#### glpi_agent__version
**String**. GLPI Agent version to install.

``` yml
glpi_agent__version: '1.4-1'
```

#### glpi_agent__major_version
**String**. Extract the major version in order to build
glpi_agent__package_url variable.
* eg. for the last version (1.4-1), it will become **1.4**.

``` yml
glpi_agent__major_version: '{{ glpi_agent__version.split("-")[0] }}'
```

#### glpi_agent__package_name
**List**. GLPI Agent package name to install.

``` yml
glpi_agent__package_name:
  - glpi-agent
```

#### glpi_agent__depends
**Boolean**. If GLPI Agent dependencies should be installed.
Required for installation from URL and because some might be
missing from dependencies list…
See the dependencies list in OS vars files
([Debian](#debian-glpi_agent__depends_packages)) below.

``` yml
glpi_agent__depends: '{{ True if ansible_os_family in ["Debian"]
                                   else False }}'
```

#### glpi_agent__recommends
**Boolean**. If GLPI Agent packages recommandations should be installed.
See the recommandations list in OS vars files
([Debian](#debian-glpi_agent__recommends_packages)) below.

``` yml
glpi_agent__recommends: false
```

#### glpi_agent__suggests
**Boolean**. If GLPI Agent packages suggestions should be installed.
See the suggestions list in OS vars files
([Debian](#debian-glpi_agent__suggests_packages)) below.

``` yml
glpi_agent__suggests: false
```

### Fusioninventory Agent

The [official documentation][glpi agent doc installation]
recommends to uninstall fusioninventory agent before installing GLPI Agent.
Packages and related configuration files won't be purge by this role.

#### glpi_agent__fusioninventory_agent_state
State of previous Fusioninventory agent.

``` yml
glpi_agent__fusioninventory_agent_state: 'absent'
```

#### glpi_agent__fusioninventory_agent_packages
List of Fusioninventory agent packages to remove.

``` yml
glpi_agent__fusioninventory_agent_packages:
  - fusioninventory-agent
```

### Configuration

See [official documentation][glpi agent doc configuration]
for all parameters syntax.

#### glpi_agent__conf_file_dest
**String**. Path to GLPI Agent configuration file on the host.

``` yml
glpi_agent__conf_file_dest: '/etc/glpi-agent/conf.d/00-ansible.cfg'
```

#### glpi_agent__conf_file_src
**String**. Template used to provide GLPI Agent configuration file.

``` yml
glpi_agent__conf_file_src: '{{ "../templates" + glpi_agent__conf_file_dest + ".j2" }}'
```

#### glpi_agent__conf_raw
**String**. Template used to provide GLPI Agent configuration file.

``` yml
glpi_agent__conf_raw: ''
```
Usage exemple:
``` yml
glpi_agent__conf_raw: |
  tag = my_new_tag
```


## Debian dedicated variables

These variables can't be overrided by the user.

### Packages and installation for Debian

#### Debian glpi_agent__package_url
The URL used to download .deb package for GLPI Agent.
eg for version 1.4 :
https://github.com/glpi-project/glpi-agent/releases/download/1.4/glpi-agent_1.4-1_all.deb

``` yml
glpi_agent__package_url: '{{ "https://github.com/glpi-project/glpi-agent/releases/download/"
                           + glpi_agent__major_version
                           + "/glpi-agent_"
                           + glpi_agent__version
                           + "_all.deb" }}'
```

#### Debian glpi_agent__depends_packages
**List**. Dependencies for GLPI Agent package.
* Based on `dpkg --info` output for .deb package version 1.4-1.
* To skip the installation of these packages,
  see [glpi_agent__depends](#glpi_agent__depends) above.

``` yml
glpi_agent__depends_packages:
  - perl
  - ucf
  - lsb-base
  - libnet-cups-perl
  - libnet-ip-perl
  - libnet-ssh2-perl
  - libwww-perl
  - libparse-edid-perl
  - libproc-daemon-perl
  - libuniversal-require-perl
  - libfile-which-perl
  - libxml-treepp-perl
  - libxml-xpath-perl
  - libyaml-perl
  - libtext-template-perl
  - libcpanel-json-xs-perl
  - libjson-pp-perl
  - pciutils
  - usbutils
  - libhttp-daemon-perl
  - libyaml-tiny-perl
  - libossp-uuid-perl
  - libdatetime-perl
  - libsocket-getaddrinfo-perl
  ## Removed from dependencies to support old distros (before Buster)
  - usb.ids
```

#### Debian glpi_agent__recommends_packages
**List**. Recommandations for GLPI Agent package.
* Based on `dpkg --info` output for .deb package version 1.4-1.
* To skip the installation of these packages,
  see [glpi_agent__recommends](#glpi_agent__recommends) above.

``` yml
glpi_agent__recommends_packages:
  - libio-socket-ssl-perl
  - dmidecode
  - hdparm
  - fdisk
  - net-tools
```

#### Debian glpi_agent__suggests_packages
**List**. Suggestions for GLPI Agent package.
* Based on `dpkg --info` output for .deb package version 1.4-1.
* To skip the installation of these packages,
  see [glpi_agent__suggests](#glpi_agent__suggests) above.

``` yml
glpi_agent__suggests_packages:
  - smartmontools
  - read-edid
```


## Development

All PRs are welcome :)

For `defaults/main.yml` and vars files :
  * Try to apply the syntax describe in the header. Copy/paste
    an existing block should do the work 👍.
  * For a new variable, prefixing it with **glpi_agent__** allows
    to easily manage it in Ansible's host_vars,…

Feel free to share any good practices (for Debian/CentOS) and requests.

## License

[WTFPL][wtfpl website]

## Author Information

Jérémy Gardais
* [IPR][ipr website] (Institut de Physique de Rennes)
* [CNRS][cnrs website] and [University of Rennes 1][university rennes1 website]


[cnrs website]: https://www.cnrs.fr/
[glpi agent doc configuration]: https://glpi-agent.readthedocs.io/en/latest/configuration.html
[glpi agent doc installation]: https://glpi-agent.readthedocs.io/en/latest/installation/#installation
[glpi agent project github]: https://github.com/glpi-project/glpi-agent/releases
[ipr-cnrs fusioninventory github]: https://github.com/ipr-cnrs/fusioninventory
[ipr website]: https://ipr.univ-rennes1.fr/
[university rennes1 website]: https://www.univ-rennes1.fr/
[wtfpl website]: http://www.wtfpl.net/about/
