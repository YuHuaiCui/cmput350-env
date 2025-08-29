# CMPUT 350 Development Environment Setup

This repository contains the setup script and configuration files for the CMPUT 350 development environment.

## Quick Start

Run this command in your terminal to set up the development environment:

```bash
curl -L https://raw.githubusercontent.com/YuHuaiCui/cmput350-env/main/setup.sh | bash
```

Or, clone the repository and run the script locally:

```bash
git clone https://github.com/YuHuaiCui/cmput350-env.git
cd cmput350-env
chmod +x setup.sh
./setup.sh
```

## What the Script Does

The setup script will:

1. **System Detection** - Identifies OS (Linux/WSL/macOS) and package manager
2. **Check Existing Tools** - Detects what's already installed (Zsh, Nix, direnv)
3. **Install Missing Components** - Only installs what's needed:
   - **Zsh** - Shell (if not present, script works with Bash too)
   - **Nix** - Package manager for reproducible environments
   - **direnv** - Automatic environment switching
4. **Enable Nix Flakes** - Configures experimental features for modern Nix usage
5. **Create Project Directory** - Interactive selection of where to place `cmput350-f25`
6. **Download flake.nix** - Gets the course-specific development environment
7. **Configure Shell Hooks** - Sets up both Zsh and Bash for compatibility
8. **Activate & Test** - Verifies the development environment works

## Supported Platforms

- **Linux/WSL** - Ubuntu, Debian, Arch
- **Windows WSL** - Ubuntu 24.04 LTS recommended
- **macOS** - Intel and Apple Silicon

The script automatically detects your OS and package manager, handling both fresh installs and systems with partial setups (some students may already have Zsh, Nix, or direnv installed).

## Manual Setup (Alternative)

If you prefer to set up manually or the script fails:

### 1. Install Nix

```bash
# Multi-user installation (recommended)
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

### 2. Enable Flakes

Add to `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

### 3. Install direnv

```bash
# Using Nix
nix-env -iA nixpkgs.direnv

# Or on macOS with Homebrew
brew install direnv
```

### 4. Configure Shell

Add to `~/.zshrc`:
```bash
eval "$(direnv hook zsh)"
```

### 5. Create Project

```bash
mkdir ~/cmput350-f25
cd ~/cmput350-f25
curl -O https://raw.githubusercontent.com/YuHuaiCui/cmput350-env/main/flake.nix
echo "use flake" > .envrc
direnv allow
```

## Using the Environment

Once setup is complete:

1. **Enter the project directory:**
   ```bash
   cd ~/cmput350-f25
   ```
   The environment will activate automatically.

2. **Manual activation:**
   ```bash
   nix develop
   ```

3. **Check the environment:**
   You should see the CMPUT 350 welcome message with tool versions.

## Available Tools

The development environment includes:

- **C++ Development**: gcc, g++, gdb, cmake, ninja
- **Graphics**: SFML libraries and dependencies
- **Analysis Tools**: valgrind, cppcheck
- **OpenGL Support**: Mesa, GL libraries

## Troubleshooting

### Nix commands not found
- Restart your terminal
- Source the Nix profile:
  ```bash
  # Multi-user install
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  
  # Single-user install
  source ~/.nix-profile/etc/profile.d/nix.sh
  ```

### direnv not activating
- Ensure you've restarted your terminal after setup
- Manually allow direnv in the project:
  ```bash
  cd ~/cmput350-f25
  direnv allow
  ```

### WSL Graphics Issues
- Ensure WSLg is enabled or an X server is running
- Try setting display:
  ```bash
  export DISPLAY=:0
  ```
- For software rendering:
  ```bash
  export LIBGL_ALWAYS_SOFTWARE=1
  ```

### Build Errors
- Check OpenGL support:
  ```bash
  glxinfo | head -10
  ```
- Test with simple graphics:
  ```bash
  glxgears
  xeyes
  ```

## Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Ensure your system is up to date
3. Try running the setup script again
4. Contact the course instructor or TA

## Repository Structure

```
.
├── README.md          # This file
├── setup.sh           # Automated setup script
└── flake.nix         # Nix flake configuration for the development environment
```