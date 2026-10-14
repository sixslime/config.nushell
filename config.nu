# config.nu
#
# Installed by:
# version = "0.108.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# remove welcome message:
$env.config.show_banner = false;

# path:
$env.path ++= [
    ~/Desktop/user_PATH,
];

# zoxide (h):
source ~/.zoxide.nu;

def --env --wrapped h [...args] {
    if ($args | length) > 0 {
      __zoxide_z ...$args;
    };
    clear;
    print $"(ansi white)[ (pwd) ](ansi reset)";
    ls -a | reject modified size
}
alias hh = h ~;
alias hi = h ..;

# alaises:
alias reboot = sudo reboot;

# config:
$env.config.hooks.display_output = 'do { let cols = (term size).columns; let value = $in; if $cols >= 100 { $value | table -e } else if $cols >= 80 { $value | table -e -d 1 } else { $value | table }}';

# modules:
use gg;
use gg [wp, w];

# end command:
h
