# Craft CLI - Minecraft Server Manager 

## Install

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/stein935/craft_install/main/install.sh)"
```

## Uninstall

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/stein935/craft_install/main/uninstall.sh)"
```

## Environment Requirements 

1. MacOS 
2. [Java 17+](https://www.oracle.com/java/technologies/downloads/)
3. [Git 2.7.0+ ](https://git-scm.com/download/mac)

## Usage 

```
  Command: craft

  Usage: 
    craft <command> [ options ]     Usage details: Run '$ craft <command> -h'

  Commands
    -ls                             List all existing servers
    command                         Send a command to a running server
    config                          Configure a server
    create                          Creates a new Minecraft server
    delete                          Delete an existing server 
    mod                             Add mods to an existing server
    restart                         If running, stop then restart an existing server
    server                          Enter shell for a server that is running
    start                           Start an existing server
    status                          Get status of an existing server
    stop                            Stop an existing server
```


## Commands 

### -h

`craft -h` *Craft cli help*

### -ls 

`craft -ls` *List all existing servers*

### Command 

*Send a server command to a running server*

`craft command -n <server_name> -c <minectaft_server_command`

```
  Command: command

  Usage: 
   craft command -n <server_name> -c <command [ options ]>   Usage details: Run '$ craft command -h'

  Required:
   -n <server_name>                Name of server to command      
   -c <command [ options ]>        Minecraft server command 

  Minecraft commands:
  See https://minecraft.fandom.com/wiki/Commands for more info
```

### Config

*Configure an existing server. This includes the server properties and launcher properties*

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

*Create a new minecraft server. Specify name, versions, configure server options and accept terms*

`craft create -n <new _server_name>`

```
  Command: create

  Usage: 
   craft create -n <server_name> [ options ]       Usage details: Run '$ craft create -h'

  Required:
   -n <server_name>                        Sets name of new server 

  Install options:
   -mcversion <minecraft_version>          Sets Minecraft game version
   -loader <fabric_loader_version>         Sets Fabric loader version       
   -snapshot                               Enables snapshot Minecraft versions

  Server options:
   -initmem <sever_init_mem>               Sets Minecraft server mem cap 
   -maxmem <sever_max_mem>                 Sets Minecraft server mem cap 
                                           Defaults to 8192M (8G)
  Server properties:
  See https://minecraft.fandom.com/wiki/Server.properties for more info
```

### Delete 

*Perminantly delete an existing server. This removes all files*

`craft delete -n <server_name>`

```
  Command: delete

  Usage: 
   craft delete -n <server_name>      Usage details: Run '$ craft delete -h' 

  Required:
   -n <server_name>                   Name of server to delete
```

### Mod

*Add, remove or list mods for an existing server*

`craft mod -n <server_name> -p <local_path_to_new_mod>`

```
  Command: mod

  Usage: 
   craft mod -n <server_name> [ options ]     Usage details: Run '$ craft mod -h'

  Required:
   -n <server_name>     Name of server to start       

  Options*
   -l                   List mods in mods directory
   -p                   Local path to mod file you would like to instal
   -r                   Name of mod file you would like to remove
                        Use -l to find exact file name
```

### Restart

*Safely stop (if running) then restart a server*

`craft restart -n <server_name>`

```
  Command: restart

  Usage: 
   craft restart -n <server_name>     Usage details: Run '$ craft restart -h'

  Required:
   -n <server_name>                   Name of server to restart
```

### Server

*View window where a server is running* 

`craft server -n <server_name>`

```
  Command: server

  Usage: 
   craft server -n <server_name>       Usage details: Run '$ craft server -h'

  Required:
   -n <server_name>                    Name of server to view
```

### Start

*Start an existing server. Option -m is used to periodically monitor server status and restart if down.*

`craft start -n <server_name>`

```
  Command: start

  Usage: 
   craft start -n <server_name> [ options ]     Usage details: Run '$ craft start -h'

  Required:
   -n <server_name>     Name of server to start       

  Options*
   -m                   Automatically restart server when it fails
   -v                   Verbose mode (see the java server starting in current vindow)
```

### Status

*Chech the status of an existing server*

`craft status -n <server_name>`

```
  Command: status

  Usage: 
   craft status -n <server_name>     Usage details: Run '$ craft status -h' 

  Required:
   -n <server_name>                  Name of server
```

### Stop

*Safely stop a running server*

`craft stop -n <server_name>`
  
```
  Command: stop

  Usage: 
   craft stop -n <server_name>     Usage details: Run '$ craft stop -h'

  Required:
   -n <server_name>                Name of server to stop
