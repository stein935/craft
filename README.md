# Craft CLI - Minecraft Server Manager

## Install

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/stein935/craft_install/main/install.sh)"
```

## Uninstall

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/stein935/craft_install/main/uninstall.sh)"
```

## Introduction

Craft CLI is a headless management tool for Fabric servers running on MacOS and Linux. Use Craft CLI to create and configure new servers, run and monitor servers, and auto-restart servers when they crash.

## Features

- Create - Name you server. Choose your Minecraft and Fabric loader versions.
- Delete - Delete a server.
- Configure - Configure the server properties and launch parameters.
- Mod - Add fabric mods to your server.
- Start - Run a server.
- Stop - Safely stop a server.
- Restart - Safely stop then restart a server.
- Status - Check to see if a serer is running.

## Environment Requirements

### MacOS

1. MacOS
2. [Java 17+](https://www.oracle.com/java/technologies/downloads/)
3. [Git 2.7.0+ ](https://git-scm.com/download/mac)

### Linux

1. Linux (Debian/Ubuntu, Fedora, Arch, etc.)
2. Java 17+ (`sudo apt install openjdk-17-jre` or equivalent)
3. Git 2.7.0+ (`sudo apt install git`)
4. curl, jq, bats (`sudo apt install curl jq bats`)
5. systemd (for daemon/service management)

## Usage

```
  Command: craft

  Usage:
    craft <command> [ options ]     Usage details: Run '$ craft <command> -h'

## Linux Service Management

Craft CLI supports systemd for running servers as background services on Linux. When starting a server with the `-d` (daemon) flag, a systemd service will be created and managed automatically.

Example:
```

craft start -n <server_name> -d

```

This will create and start a systemd service named `craft.<server_name>.service`.

  Commands
    -h                              Print usage message
    -ls                             List all existing servers
    -v                              Print version
    command                         Send a command to a running server
    config                          Configure a server
    create                          Creates a new Minecraft server
    delete                          Delete an existing server
    mod                             Add mods to an existing server
    restart                         If running, stop then restart an existing server
    start                           Start an existing server
    status                          Get status of an existing server
    stop                            Stop an existing server
```
