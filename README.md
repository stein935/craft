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

Craft CLI is a headless management tool for Fabric servers running on MacOS. Use Craft CLI to create and configure new servers. Run and monitor servers. Auto restart servers when they crash.

## Features

- Create - Name your server. Choose your Minecraft and Fabric loader versions.
- Delete - Permanently delete a server and all its files.
- Configure - Configure the server properties and launch parameters interactively.
- Mod - Add or remove Fabric mods from your server (supports local files and URLs).
- Start - Run a server using macOS LaunchDaemons for automatic process management.
- Stop - Safely stop a server with proper save and cleanup.
- Restart - Safely stop then restart a server.
- Status - Check if a server is running and view player counts.
- Command - Send Minecraft commands to a running server.
- Test - Run automated test suite using BATS.

## Environment Requirements

1. macOS (uses macOS-specific LaunchDaemons)
2. Java (version 8/16/17/21 depending on Minecraft version - automatically detected)
3. Git 2.7.0+
4. Optional: fzf (for enhanced interactive menus, falls back to bash select)
5. Optional: mcstatus (Python CLI tool for player count display)
6. Optional: jq (for JSON parsing in version selection)

## Usage

```
  Command: craft

  Usage:
    craft <command> [options]     Usage details: Run '$ craft <command> -h'

  Commands
    -h                              Display help message
    -ls                             List all existing servers
    -v                              Display version information
    command                         Send a command to a running server
    config                          Configure a server
    create                          Creates a new Minecraft server
    delete                          Delete an existing server
    mod                             Add or remove mods from an existing server
    restart                         If running, stop then restart an existing server
    start                           Start an existing server
    status                          Get status of an existing server
    stop                            Stop an existing server
    test                            Run BATS test suite
```

## Commands

### -h

`craft -h` _Craft cli help_

### -ls

`craft -ls` _List all existing servers_

### -v

`craft -v` _Display version information_

### Test

`craft test` _Run the BATS test suite to validate Craft CLI functionality_

### Command

_Send a Minecraft command to a running server_

`craft command -n <server_name> -c <minecraft_server_command>`

```
  Command: command

  Usage:
   craft command -n <server_name> -c <command [options]>   Usage details: Run '$ craft command -h'

  Required:
   -n <server_name>                Name of server to command
   -c <command [options]>        Minecraft server command

  Description:
   Sends commands through the named pipe to a running server and captures the response.

  Minecraft commands:
  See https://minecraft.fandom.com/wiki/Commands for more info
```

### Config

_Configure an existing server. This includes the server properties and launcher properties_

`craft config -n <new _server_name>`

```
  Command: config

  Usage:
   craft config -n <server_name>           Usage details: Run '$ craft config -h'

  Required:
   -n <server_name>                        Name of server to configure

  Server properties:
  See https://minecraft.fandom.com/wiki/Server.properties for more info

   -allow-flight                           Default: false
   -allow-nether                           Default: true
   -broadcast-console-to-ops               Default: true
   -broadcast-rcon-to-ops                  Default: true
   -difficulty                             Default: easy
   -enable-command-block                   Default: false
   -enable-jmx-monitoring                  Default: false
   -enable-query                           Default: false
   -enable-rcon                            Default: false
   -enable-status                          Default: true
   -enforce-secure-profile                 Default: true
   -enforce-whitelist                      Default: false
   -entity-broadcast-range-percentage      Default: 100
   -force-gamemode                         Default: false
   -function-permission-level              Default: 2
   -gamemode                               Default: survival
   -generate-structures                    Default: true
   -generator-settings                     Default: {}
   -hardcore                               Default: false
   -hide-online-players                    Default: false
   -level-name                             Default: world
   -level-seed
   -level-type                             Default: minecraft:normal
   -max-chained-neighbor-updates           Default: 1000000
   -max-players                            Default: 20
   -max-tick-time                          Default: 60000
   -max-world-size                         Default: 29999984
   -motd                                   Default: AMinecraftServer
   -network-compression-threshold          Default: 256
   -online-mode                            Default: true
   -op-permission-level                    Default: 4
   -player-idle-timeout                    Default: 0
   -prevent-proxy-connections              Default: false
   -previews-chat                          Default: false
   -pvp                                    Default: true
   -query.port                             Default: 25565
   -rate-limit                             Default: 0
   -rcon.password
   -rcon.port                              Default: 25575
   -require-resource-pack                  Default: false
   -resource-pack
   -resource-pack-prompt
   -resource-pack-sha1
   -server-ip
   -server-port                            Default: 25565
   -simulation-distance                    Default: 10
   -spawn-animals                          Default: true
   -spawn-monsters                         Default: true
   -spawn-npcs                             Default: true
   -spawn-protection                       Default: 16
   -sync-chunk-writes                      Default: true
   -text-filtering-config
   -use-native-transport                   Default: true
   -view-distance                          Default: 10
   -white-list                             Default: false
   -help | -h                              usage

  Launcher properties:
   -serverJar                              Jar file in server dir to use when launching
   -server_init_mem                        Memory limit when starting the server. Default: 512M
   -server_max_mem                         Memory limit when running the server. Default: 8G
```

### Create

_Create a new Minecraft server. Specify name, versions, configure server options and accept EULA_

`craft create -n <new_server_name>`

```
  Command: create

  Usage:
   craft create -n <server_name> [options]       Usage details: Run '$ craft create -h'

  Required:
   -n <server_name>                        Sets name of new server

  Options:
   -g <minecraft_version>                  Sets Minecraft game version
   -l <fabric_loader_version>              Sets Fabric loader version
   -s                                      Enables snapshot Minecraft versions

  Description:
   Downloads Fabric installer, creates server directory, initializes server files,
   and prompts for EULA acceptance. Automatically detects required Java version.
```

### Delete

_Permanently delete an existing server. This removes all files and LaunchDaemons_

`craft delete -n <server_name>`

```
  Command: delete

  Usage:
   craft delete -n <server_name>      Usage details: Run '$ craft delete -h'

  Required:
   -n <server_name>                   Name of server to delete

  Description:
   Stops the server if running, then permanently deletes the server directory
   and associated LaunchDaemon plist. Prompts for confirmation before deletion.
```

### Mod

_Add, remove or list mods for an existing server_

`craft mod -n <server_name> [options]`

```
  Command: mod

  Usage:
   craft mod -n <server_name> [options]     Usage details: Run '$ craft mod -h'

  Required:
   -n <server_name>     Name of server

  Options (one required):
   -l                   List mods in mods directory
   -p <path>            Local path to mod file you would like to install
   -u <url>             URL to download mod file from
   -r <file_name>       Name of mod file you would like to remove
                        Use -l to find exact file name

  Description:
   Manages Fabric mods in the server's mods directory. Supports adding mods
   from local files or direct download from URLs.
```

### Restart

_Safely stop (if running) then restart a server_

`craft restart -n <server_name>`

```
  Command: restart

  Usage:
   craft restart -n <server_name>     Usage details: Run '$ craft restart -h'

  Required:
   -n <server_name>                   Name of server to restart

  Description:
   Stops the server if running, then starts it again. Logs the restart event
   to the server's monitor log.
```

### Start

_Start an existing server using macOS LaunchDaemons_

`craft start -n <server_name>`

```
  Command: start

  Usage:
   craft start -n <server_name>     Usage details: Run '$ craft start -h'

  Required:
   -n <server_name>     Name of server to start

  Description:
   Starts the Minecraft server using macOS LaunchDaemons for process management.
   Creates a named pipe for command communication and monitors the startup process.
   The LaunchDaemon provides automatic crash recovery.
```

### Status

_Check the status of an existing server_

`craft status [options]`

```
  Command: status

  Usage:
   craft status [options]             Usage details: Run '$ craft status -h'

  Options:
   -n <server_name>         Check status of specific server
   -N                       Interactive server selection menu

  Description:
   Checks if a Minecraft server is running by verifying the port is in use and
   the named pipe exists. If no options provided, displays status of all servers.
   Shows server name, port, PID, and online players (if mcstatus is installed).
```

### Stop

_Safely stop a running server_

`craft stop -n <server_name>`

```
  Command: stop

  Usage:
   craft stop -n <server_name>     Usage details: Run '$ craft stop -h'

  Required:
   -n <server_name>                Name of server to stop

  Description:
   Safely stops a running Minecraft server by sending save-all and stop commands
   through the named pipe. Cleans up the LaunchDaemon and removes the command pipe.
```
