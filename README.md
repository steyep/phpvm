## php-version-manager
A wrapper script for [homebrew](http://brew.sh/) that will allow for easy switching between php environments. 

### Installation:
1. Clone the repo
2. Run the install script: `sh ./install.sh`

### Usage:
```
Usage: phpvm <options>

The following commands are supported:
   list, ls                  : List installed PHP versions.
   use [version]             : Specify a version of PHP to use.
   add [version]             : Specify a version of PHP to install.
   remove, rm [version]      : Specify a version of PHP to remove.
   config <options>          : Configure variables

The following options are supported:
   --verbose, -v             : Verbose output.
   --help, -h                : Show this message.
```
### Options
* Configure php-version-manager by running `phpvm config [...]` and defining as many of the following variables as you'd like:
  * `PROFILE=path/to/.profile` – location of your `.bashrc`, `.zshrc`, etc.
  * `APACHE_CONFIG=path/to/httpd.conf` – location of the `httpd.conf` Apache is using 
  * `APACHE_ENABLED=[0|1]` – Ensure Apache has the correct `php_module` loaded for the specified version of PHP and run `apachectl restart` when the value is set to `1`. Default is `0`. Note: depending on your setup, this may require `sudo` privileges.
