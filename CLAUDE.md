# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Craft CLI is a headless management tool for Minecraft Fabric servers running on macOS. It provides a command-line interface to create, configure, start, stop, and monitor Minecraft servers with automatic crash recovery and Discord notifications.

**Key Characteristics:**
- Pure Bash implementation with no external dependencies beyond standard macOS tools
- Uses macOS LaunchDaemons for server process management
- Interactive FZF-based selection menus (with fallback to bash `select`)
- Named pipes for server command communication
- Modular command structure with separate library files per command

## Architecture

### Entry Point
- `bin/craft` - Main executable that:
  - Sets up environment variables (`CRAFT_HOME_DIR`, `CRAFT_LIB`, `CRAFT_SERVER_DIR`)
  - Handles command-line argument alias mapping
  - Sources and executes command modules from `lib/`

### Command Modules (`lib/`)
Each command is a separate file without `.sh` extension (recent refactor removed extensions):
- Commands are sourced dynamically and execute `{command}_command "$@"`
- All commands use `getopts` for argument parsing
- Common pattern: interactive server selection via FZF if `-n` not provided

**Key Commands:**
- `create` - Downloads Fabric installer, creates server directory, configures initial settings
- `start` - Creates named pipe, generates LaunchDaemon plist, bootstraps daemon
- `stop` - Sends `save-all` and `stop` to named pipe, boots out daemon
- `config` - Interactive property file editor
- `mod` - Manages mods in server's mods directory
- `status` - Uses `lsof` to check port and named pipe
- `command` - Sends Minecraft commands to running server via named pipe

### Utility Library (`lib/utils/`)
Modular utility functions organized by functionality. All utilities are sourced via `lib/common` for backward compatibility.

**Structure:**
```
lib/utils/
├── core       # Foundation utilities (no dependencies)
├── output     # Display and formatting (depends on core)
├── errors     # Error handling (depends on core, output)
├── test       # Testing utilities (depends on core, output)
└── server     # Server operations (depends on core, output)
```

**lib/utils/core** - Foundation functions with no dependencies:
- `form()` - ANSI color/style formatter (colors: black, red, green, yellow, blue, magenta, cyan, white; styles: normal, bold, dim, italic, underline)
- `tty_escape()` - Terminal escape sequence helper
- `strip_ansi()` - Remove ANSI codes from text
- `shell_join()` - Join shell arguments with proper escaping
- `version_ge()` - Semantic version comparison
- `min_sec()` - Convert seconds to "Xm Ys" format
- `boolean()` - Boolean value normalization
- `replace_alias_args()` - Argument alias replacement
- `ring_bell()` - Terminal bell

**lib/utils/output** - Display and UI functions:
- `fwhip()` - Blue arrow prefix for info messages
- `warn()` - Red X prefix for errors
- `send()` - Yellow prefix for notifications
- `indent()` - Indented output with configurable spacing
- `rm_line()` - Remove previous line from terminal
- `use_fzf()` - Interactive selection with FZF or fallback to bash `select`
- `box()` - Draw text box with optional label and word wrapping

**lib/utils/errors** - Error handling and help:
- `abort()` - Print error and exit
- `execute()` - Execute command and abort on failure
- `command_help()` - Display command help text
- `missing_argument()` - Handle missing required arguments
- `invalid_command()` - Handle invalid commands
- `invalid_option()` - Handle invalid options
- `missing_required_option()` - Handle missing required options

**lib/utils/test** - Testing utilities:
- `test_form()` - Format and display test info from associative array
- `test_desc_form()` - Format test descriptions with color
- `check_output()` - Check if output contains expected string
- `number()` - Display test number
- `runtime()` - Display command runtime

**lib/utils/server** - Server-specific operations:
- `server_on()` / `server_off()` - Check server status via `lsof` on port AND named pipe
- `get_properties()` - Loads both `server.properties` and `fabric-server-launcher.properties` into environment
- `list_properties()` - Parse property file into environment variables
- `find_server()` - Validates server directory exists
- `check_java()` - Detects and switches Java versions based on Minecraft version (8/16/17/21)
- `players()` - Uses `mcstatus` CLI to query online players via JSON
- `discord_message()` - Sends embeds to Discord webhook for monitoring

**lib/common** - Compatibility wrapper that sources all utility modules in dependency order

### Process Management
- **Named Pipes**: Created at `${CRAFT_SERVER_DIR}/${SERVER_NAME}/command-pipe` for IPC
- **LaunchDaemons**: Generated at `/Library/LaunchDaemons/craft.{SERVER_NAME}.daemon.plist`
  - Configured with `plutil` commands
  - Bootstrapped/booted out via `launchctl`
  - Logs to `${SERVER_DIR}/logs/daemon.log`

### Configuration Files
- `config/help/*.txt` - Help text for each command
- `config/craft.servername.daemon.plist` - LaunchDaemon template
- `config/test_config.bats` - BATS test suite
- `config/logo.txt` - ASCII art displayed on startup

### Server Structure
Servers stored in `/opt/craft/servers/{SERVER_NAME}/`:
- `fabric-server-launch.jar` - Fabric server launcher
- `server.properties` - Minecraft server configuration
- `fabric-server-launcher.properties` - Custom launcher settings (memory, webhook)
- `command-pipe` - Named pipe for server commands
- `logs/monitor/` - Monthly log files for server events
- `mods/` - Fabric mods directory
- `versions/` - Minecraft version info

## Development Commands

### Testing
```bash
# Run BATS test suite
bats config/test_config.bats

# Test a specific command with -t flag (shows test info and runtime)
sudo craft create -n "test-server" -t
sudo craft start -n "test-server" -t
```

### Local Development
```bash
# Run commands directly from repo
sudo bin/craft <command> [options]

# Check shell syntax
shellcheck bin/craft lib/*

# View server logs
tail -f /opt/craft/servers/{SERVER_NAME}/logs/daemon.log
tail -f /opt/craft/servers/{SERVER_NAME}/logs/monitor/$(date '+%Y-%m').log
```

### Debugging
```bash
# Check daemon status
launchctl print system/craft.{SERVER_NAME}.daemon

# List loaded daemons
launchctl list | grep craft

# Check port usage
lsof -i :25565

# Monitor named pipe
cat /opt/craft/servers/{SERVER_NAME}/command-pipe
```

## Code Patterns

### Adding New Commands
1. Create `lib/{command}` (no extension)
2. Define `{command}_command()` function
3. Use `getopts` for argument parsing with standard options:
   - `-n` for server name (with FZF fallback if omitted)
   - `-h` for help
   - `-t` for test mode
4. Call `command_help "$COMMAND" 0` for help
5. Use error handlers: `missing_argument`, `invalid_option`, `missing_required_option`
6. Create `config/help/{command}_help.txt`

### Argument Alias Mapping
Arguments can have aliases defined in `bin/craft`:
```bash
alias_map=(
    ["--help"]="-h"
    ["--list"]="-ls"
    ["--version"]="-v"
)
```

### Test Mode
All commands support `-t` flag which:
- Displays test info via `test_form()`
- Shows runtime via `runtime()`
- Useful for debugging and automated tests

### Property Management
Server properties use underscored, uppercase environment variables:
- `server.properties`: `server-port` → `$SERVER_PORT`
- `fabric-server-launcher.properties`: `server_max_mem` → `$SERVER_MAX_MEM`
- Custom properties: `discord_webhook` → `$DISCORD_WEBHOOK`

## Important Notes

- **Requires sudo**: Server operations need root for port binding and daemon management
- **macOS only**: Uses macOS-specific tools (`launchctl`, `/usr/libexec/java_home`, `lsof`)
- **No .sh extensions**: Commands in `lib/` have no file extension (refactored in commit f1615b9)
- **Named pipe validation**: `server_on()` checks both port AND pipe existence for true running state
- **Java version switching**: Automatic via `check_java()` using `/usr/libexec/java_home`
- **Interactive by default**: Most commands use FZF for selection if server name not provided
- **Logging**: All server lifecycle events logged to `logs/monitor/{YYYY-MM}.log`

## External Dependencies

- **Java**: Required version depends on Minecraft version (8/16/17/21)
- **Git**: Used during installation process
- **curl**: API calls to Fabric Meta API and Discord webhooks
- **jq**: JSON parsing for Fabric versions and server status
- **mcstatus**: Python CLI tool for querying Minecraft server status (optional for player counts)
- **fzf**: Interactive selection (optional, falls back to bash `select`)

## Configuration

Server-specific settings in `fabric-server-launcher.properties`:
- `serverJar` - JAR file to launch
- `server_init_mem` - Initial memory (default: 512M)
- `server_max_mem` - Max memory (default: 2G)
- `discord_webhook` - Discord webhook URL for notifications

Discord webhook format sends embeds with server status, timestamps, and color-coded events.