## v1.1.2
### Fix
* Move glpi_agent__package_url to `defaults` (fix #1).

## v1.1.1
### Enhancements
* Add cronjob only if `cron` package is installed.
* Molecule: Test both systemd service and cronjob.

## v1.1.0
### Enhancements
* Update to version [1.5-1](https://github.com/glpi-project/glpi-agent/releases/tag/1.5).
* Drop support of Debian 10 Buster.
* Add support of Debian 12 Bookworm.
* Manage service state and enabled.
* Allow running the agent with a cron job instead of the service (thanks to @yodabzh).

### Fixes
* Molecule: Fix access to temp dir.
* Molecule: Ensure to install molecule-plugins to have docker driver.

## v1.0.1

### Fixes
* Load vars file and remove fusioninventory only if `glpi_agent__enabled` is set.
* Manage `glpi-agent` systemd service only if `glpi_agent__enabled` is set to
  avoid "Could not find the requested service glpi-agent: host" error.

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
