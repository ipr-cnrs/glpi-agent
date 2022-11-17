## v1.0.0

### Features
* Support:
  * Debian 11 Bullseye
  * Debian 10 Buster
  * Ubuntu 22.04 Jammy Jellyfish
* Install `glpi-agent` package from your own repository.
* **or** install `glpi-agent` package from GLPI Agent Github project.
* Remove `fusioninventory-agent` package (not configuration file).
* Install missing dependencies (eg. `usb.ids`).
* Generate configuration file with some "raw" content".
* Ensure to (re)start and enable glpi-agent.service.
* Molecule tests for supported versions.
