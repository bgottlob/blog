---
title: "Basic Use-Cases of the Nix Package Manager"
date: 2019-05-29T07:28:21-04:00
draft: false
---

Nix is a "purely functional" package manager aimed at creating reliable, reproducible build environments. 
It is an incredibly powerful tool, but it's difficult to understand the benefits of its academically pure approach and the wide range of problems it can solve without having some experience using it.
Its [user manual](https://nixos.org/nix/manual/) is comprehensive and well-written, but very dense.
I started using Nix a few months ago and only understand a small fraction of its functionality, but it turns out even that is enough to solve many common issues I face building development environments.

This post introduces some basic tools Nix provides and a few use-cases of those tools.
I assume no prior knowledge of Nix and hope to demonstrate the power of some of its most basic functionality.

# Up and Running with Nix
The simplest way to install Nix is using [the single-user installation instructions](https://nixos.org/nix/manual/#sect-single-user-installation) in the Nix manual.

## Basic Commands
To install a package, use `nix-env -iA nixpkgs.<package>`:

``` bash
$ nix-env -iA nixpkgs.ruby
installing 'ruby-2.5.5'
...
created 131 symlinks in user environment

$ which ruby
/home/bgottlob/.nix-profile/bin/ruby
```

To uninstall a package, use `nix-env -e <package>`:
``` bash
$ nix-env -e ruby
uninstalling 'ruby-2.5.5'
```

Search for packages using a regular expression with `nix-env -qaP <regex>`:
``` bash
$ nix-env -qaP 'ruby.*'
nixpkgs.ruby_2_3             ruby-2.3.8
nixpkgs.ruby_2_4             ruby-2.4.5
nixpkgs.ruby                 ruby-2.5.5
nixpkgs.ruby_2_6             ruby-2.6.3
nixpkgs.jetbrains.ruby-mine  ruby-mine-2019.1.1
nixpkgs.ruby-zoom            ruby-zoom-5.0.1
nixpkgs.rubyripper           rubyripper-0.6.2
```

## Nix Shell
The `nix-shell` command is used to build isolated development environments.
`nix-shell` can be passed package names, then an interactive shell is created with those packages installed and loaded.
``` bash
$ nix-shell -p ruby_2_3

[nix-shell:~]$ which ruby
/nix/store/qzz6hx1fhmi56656zwhwhph5mfnbp5rs-ruby-2.3.8/bin/ruby

[nix-shell:~]$ ruby --version
ruby 2.3.8p459 (2018-10-18) [x86_64-linux]

[nix-shell:~]$ exit
exit
$ nix-shell -p ruby_2_4

[nix-shell:~]$ which ruby
/nix/store/pjwbsybhj72khk4xsm8sk121xnn64y7l-ruby-2.4.5/bin/ruby

[nix-shell:~]$ ruby --version
ruby 2.4.5p335 (2018-10-18) [x86_64-linux]
```
Loading an environment with a specific minor version of Ruby, exiting, then entering one with a different version of Ruby is seamless.
The packages under `/nix/store` are named in the format `/<hash>-<package>-<version>`, where the hash is of the package and its configuration.
This allows different versions of the same package and different configurations for the same version of a package to exist in isolation.

### Nix Shell Files
`shell.nix` files are used to declaratively build a reproducible development environment.
In its simplest form, a `shell.nix` file will specify the set of packages to be loaded into the Nix shell and sometimes shell commands to run at startup.
Here is an example `shell.nix` file:
``` nix
let
  pkgs = import <nixpkgs> {};
in
  pkgs.stdenv.mkDerivation {
    name = "phoenix-env";
    src = null;
    buildInputs = [
      pkgs.elixir_1_7
      pkgs.postgresql_9_6
      pkgs.nodejs-8_x
    ];
    shellHook = ''
      echo "Welcome to your Phoenix Environment"
    ''
  };
```

This environment will contain installations of Elixir 1.7, PostgreSQL 9.6, and Node.js 8, the dependencies of the [Phoenix web framework](https://hexdocs.pm/phoenix/installation.html).

To load a shell from a file, run `nix-shell <filename>`:
``` bash
$ nix-shell shell.nix
```
Or, if your `shell.nix` is in the current directory:
``` bash
$ nix-shell
```
These files do not necessarily need to be named `shell.nix`, but this is the default name recognized by the `nix-shell` command.

The `--pure` flag clears the environment before starting the Nix shell.
This essentially means that other packages installed on your system but not specified in your `shell.nix` (or with the `-p` option) will not be available.
This provides a greater level of isolation and more reliable reproducibility.

``` bash
$ nix-shell --pure -p ruby_2_3

[nix-shell:~]$ which ruby
bash: which: command not found

[nix-shell:~]$ ruby --version
ruby 2.3.8p459 (2018-10-18) [x86_64-linux]

[nix-shell:~]$ exit
exit
$ nix-shell --pure -p ruby_2_3 -p which

[nix-shell:~]$ which ruby
/nix/store/qzz6hx1fhmi56656zwhwhph5mfnbp5rs-ruby-2.3.8/bin/ruby

[nix-shell:~]$ ruby --version
ruby 2.3.8p459 (2018-10-18) [x86_64-linux]

[nix-shell:~]$ which which
/nix/store/7zkl77776dhjbb3v50lqb2j137ribiyv-which-2.21/bin/which
```

### Per-Project Nix Shell Files
In projects I use Nix to manage, I commit the `shell.nix` file to the root directory of the project's git repository.

This allows me to manage dependencies on a per-project basis.
For example, if one of my projects runs on Elixir 1.8 and another runs on Elixir 1.6, each of those requirements are expressed and managed within the corresponding project's repository.
Once I enter each project's directory and run `nix-shell`, I don't need to think about which version of Elixir I am using, as the correct version will be specified in `shell.nix`.
I only need to think about dependency versions when I want to modify them.

When I need to upgrade dependencies to, for example, take advantage of a new language feature, I can make changes to the `shell.nix` and application code in the same commit.
Other branches of the application code without that change will still be configured to use the older dependencies, since there will not be much reason to upgrade them yet.

# Use-Cases
This small amount of Nix knowledge opens up much of its power and can be used to solve some common problems:

1. Replace language-specific version managers such as `nvm`, `rvm`, and `virtualenv`
2. Decouple development dependencies from user dependencies
3. Build a simple CI process

## Replace Language-Specific Version Managers
Many popular programming languages have some "version manager" that installs multiple versions of the language side by side.
After using `rvm` to manage Ruby versions and `nvm` for Node.js for a while, I ran into some problems with them and searched for alternatives.
I have found the previously discussed Nix shell functionality to provide a more isolated and maintainable solution over language-specific version managers.

Version managers often require modifications to your `.bash_profile` and `.bashrc` files.
The Nix installation script does modify `.bash_profile`, but this is compared to at least one change per version manager.
This can become unwieldy once you have more than one version manager installed.

Each version manager works differently and has a different interface, which often obscures its innards.
This isn't necessarily a bad thing, but as soon as something goes wrong, it's usually not worth my time to figure out how to fix it.
I often run into slightly different problems on different systems due to minor configuration differences that are difficult to identify.
Nix provides a single interface and approach for all programming languages.
Of course, you may run into language-specific issues, but such issues will be reproducible on other systems and in an isolated environment.
This makes debugging much simpler and increases the chances someone else can help you out.

Version managers are dependent on the versions they decide to support.
This usually is not a problem for older versions, but the latest are not always available.
You may need to manually install a specific version, a situation you likely wanted to avoid when you decided to use a version manager in the first place.
Nix provides tools for specifying a tarball of the version of your desired dependency to be fetched and built from source.
Even if Nixpkgs doesn't yet have the latest version, you can still fetch the source code and build it using Nix.

## Decouple Development Dependencies from User Dependencies
Different Linux distributions release software on different time frames.
Arch Linux is always on the latest stable software releases, whereas Ubuntu moves much slower, especially on LTS distributions.
For example, Arch Linux adopted Elixir 1.8, the current stable version, the day it was officially relased.
Ubuntu 18.04 is currently on Elixir 1.3.

If I was an Arch user working on a Phoenix application that requires Elixir version 1.7, a full system upgrade would force me to upgrade to Elixir 1.8.
I would either have to install Elixir 1.7 outside of `pacman`, hope that 1.7 is in my `pacman` cache and downgrade it after every subsequent full system upgrade, or wait to do a full system upgrade until I update my application to work on the latest version of Elixir.

Conversely, if I used Ubuntu 18.04, my only choice would be install and  manage Elixir 1.7 outside of `apt`.

Utilizing a `shell.nix` file in a git repo allows my application's needs to dictate the version of Elixir used, rather than the release cycle of my Linux distribution.
As an Arch user, the rest of my system's dependencies would not fall behind due to my application's required Elixir version.
As an Ubuntu 18.04 user, I would not need to wait for the package maintainers to upgrade Elixir to 1.7.

## Build a Simple Continuous Integration Process
The `nix-shell` command has a useful `--run` option, which runs a given command in a non-interactive Nix shell:
``` bash
$ nix-shell -p ruby_2_3 --run 'ruby --version'
ruby 2.3.8p459 (2018-10-18) [x86_64-linux]
$ nix-shell -p ruby_2_4 --run 'ruby --version'
ruby 2.4.5p335 (2018-10-18) [x86_64-linux]
```

I develop a few internal Ruby gems at work and need to maintain support for at least Ruby 2.3, 2.4, and 2.5.
I can run the following command locally and check whether my changes have broken compatibility across Ruby versions:
``` bash
$ nix-shell -p ruby_2_3 --run 'rake test' && \
    nix-shell -p ruby_2_4 --run 'rake test' && \
    nix-shell -p ruby_2_5 --run 'rake test'
```

This same process can run on a CI server, though I have set up my actual CI process in a more robust way to provide more useful output.

# Conclusion
There are many common pain points that can be mitigated with Nix.
Hopefully this introduction gives you some ideas on ways to integrate Nix into your daily workflow and solve your own dependency and development environment problems.

The Nix tools I have demonstrated here are just the tip of the iceberg.
Check out the following resources for more:

1. [Nix User Manual](https://nixos.org/nix/manual/)
1. [NixOS](https://nixos.org/): the Linux distribution based on the Nix package manager
1. [Bundix](https://github.com/manveru/bundix): a utility for installing Ruby gems managed by bundler using Nix
1. [Jean-Philippe Cugnet's blog post](https://medium.com/@ejpcmac/using-nix-in-elixir-projects-ff5300214e70) describing ways to use Nix for Elixir and Phoenix projects
