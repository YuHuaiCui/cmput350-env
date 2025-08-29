#!/bin/bash

# CMPUT 350 Development Environment Setup Script
# Supports: Linux, WSL, and macOS

set -e  # Exit on error

# Check if we have sudo access (will be used for various installations)
check_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        echo "This script requires sudo access for some operations."
        echo "Please enter your password when prompted."
        if sudo true; then
            return 0
        else
            return 1
        fi
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

echo "========================================"
echo "  CMPUT 350 Development Environment"
echo "  Setup Script"
echo "========================================"
echo ""
print_success "Detected OS: $OS"

# Check for sudo access early if on Linux/WSL
if [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
    print_step "Checking sudo access..."
    echo ""
    echo "This script may need sudo access for:"
    echo "  • Installing Zsh (if not present)"
    echo "  • Installing system packages (curl, xz-utils)"
    echo "  • Installing direnv via package manager"
    echo "  • Configuring system-wide Nix settings"
    echo ""
    if check_sudo; then
        print_success "Sudo access confirmed"
    else
        print_warning "No sudo access. Some features may require manual installation."
        print_warning "The script will use fallback methods where possible:"
        print_warning "  • Nix will be installed in single-user mode"
        print_warning "  • direnv will be installed via Nix"
        print_warning "  • You can continue with Bash instead of Zsh"
    fi
fi

# Detect package manager for Linux systems
if [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        print_success "Package manager: apt (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        print_success "Package manager: dnf (Fedora)"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        print_success "Package manager: yum (RHEL/CentOS)"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        print_success "Package manager: pacman (Arch)"
    else
        PKG_MANAGER="unknown"
        print_warning "No standard package manager detected"
    fi
fi

# Check what's already installed
echo ""
print_step "Checking existing installations..."
echo ""
command -v zsh &> /dev/null && print_success "✓ Zsh: $(zsh --version 2>&1 | head -1)" || print_warning "✗ Zsh: Not installed"
command -v nix &> /dev/null && print_success "✓ Nix: $(nix --version)" || print_warning "✗ Nix: Not installed"
command -v direnv &> /dev/null && print_success "✓ direnv: $(direnv version)" || print_warning "✗ direnv: Not installed"
echo ""

# Step 1: Check/Install Zsh
print_step "Step 1: Checking Zsh installation..."

if command -v zsh &> /dev/null; then
    print_success "Zsh is already installed ($(zsh --version))"
else
    if [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
        print_warning "Zsh not found. Installing..."
        
        if sudo -n true 2>/dev/null; then
            case "$PKG_MANAGER" in
                apt)
                    sudo apt update
                    sudo apt install -y zsh
                    ;;
                dnf)
                    sudo dnf install -y zsh
                    ;;
                yum)
                    sudo yum install -y zsh
                    ;;
                pacman)
                    sudo pacman -S --noconfirm zsh
                    ;;
                *)
                    print_error "Cannot install Zsh automatically. Please install it manually."
                    print_warning "You can continue with Bash, but Zsh is recommended."
                    ;;
            esac
        else
            print_warning "No sudo access. Cannot install Zsh automatically."
            print_warning "You can continue with Bash, or install Zsh manually later."
        fi
        
        if command -v zsh &> /dev/null; then
            print_success "Zsh installed successfully"
        fi
    elif [[ "$OS" == "macos" ]]; then
        print_success "Zsh should be pre-installed on macOS"
    fi
fi

# Offer to set Zsh as default shell (optional)
if command -v zsh &> /dev/null; then
    CURRENT_SHELL=$(basename "$SHELL")
    if [[ "$CURRENT_SHELL" != "zsh" ]]; then
        echo ""
        print_warning "Your current default shell is: $CURRENT_SHELL"
        read -p "Would you like to set Zsh as your default shell? (y/n): " set_zsh_default < /dev/tty
        if [[ "$set_zsh_default" == "y" ]]; then
            if command -v chsh &> /dev/null; then
                ZSH_PATH=$(which zsh)
                # Check if zsh is in /etc/shells
                if grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null; then
                    chsh -s "$ZSH_PATH"
                    print_success "Default shell changed to Zsh. This will take effect on your next login."
                else
                    # Try to add zsh to /etc/shells if we have sudo
                    if sudo -n true 2>/dev/null; then
                        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
                        chsh -s "$ZSH_PATH"
                        print_success "Default shell changed to Zsh. This will take effect on your next login."
                    else
                        print_warning "Cannot change default shell. Zsh path not in /etc/shells and no sudo access."
                        print_warning "You can manually change it later with: chsh -s $(which zsh)"
                    fi
                fi
            else
                print_warning "chsh command not found. Cannot change default shell automatically."
                print_warning "You can manually change it later if needed."
            fi
        else
            print_success "Keeping $CURRENT_SHELL as default shell"
        fi
    else
        print_success "Zsh is already your default shell"
    fi
fi

# Step 2: Install Nix
print_step "Step 2: Checking Nix installation..."

if command -v nix &> /dev/null; then
    print_success "Nix is already installed ($(nix --version))"
    
    # Ensure Nix is properly sourced even if already installed
    if [[ "$OS" == "macos" ]]; then
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    else
        if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        elif [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    fi
else
    print_warning "Nix not found. Installing..."
    
    # Install dependencies for WSL/Linux
    if [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
        print_step "Installing required dependencies..."
        
        if sudo -n true 2>/dev/null; then
            case "$PKG_MANAGER" in
                apt)
                    sudo apt update
                    sudo apt install -y curl xz-utils
                    ;;
                dnf|yum)
                    sudo $PKG_MANAGER install -y curl xz
                    ;;
                pacman)
                    sudo pacman -S --noconfirm curl xz
                    ;;
                *)
                    print_warning "Please ensure curl and xz are installed"
                    ;;
            esac
        else
            print_warning "No sudo access. Please ensure curl and xz are installed."
            if ! command -v curl &> /dev/null || ! command -v xz &> /dev/null; then
                print_error "curl and/or xz not found. These are required for Nix installation."
                print_error "Please install them manually and run this script again."
                exit 1
            fi
        fi
    fi
    
    # Download and run Nix installer
    print_step "Downloading and installing Nix..."
    
    # Check if we can use daemon mode (requires sudo)
    if sudo -n true 2>/dev/null; then
        curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    else
        print_warning "Installing Nix in single-user mode (no sudo access for daemon mode)"
        curl -L https://nixos.org/nix/install | sh
    fi
    
    # Source Nix
    if [[ "$OS" == "macos" ]]; then
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    else
        if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        elif [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    fi
    
    print_success "Nix installed successfully"
    print_warning "You may need to restart your terminal or run: source ~/.zshrc"
fi

# Step 3: Enable Flakes
print_step "Step 3: Enabling Nix Flakes..."

# Create Nix config directory if it doesn't exist
mkdir -p ~/.config/nix

# Check if flakes are already enabled
if grep -q "experimental-features.*flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    print_success "Flakes are already enabled"
else
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
    print_success "Flakes enabled in ~/.config/nix/nix.conf"
fi

# Also add to /etc/nix/nix.conf for system-wide configuration (requires sudo)
if [[ "$OS" == "macos" ]] || [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
    if [ -f /etc/nix/nix.conf ]; then
        if ! grep -q "experimental-features.*flakes" /etc/nix/nix.conf 2>/dev/null; then
            if sudo -n true 2>/dev/null; then
                print_warning "Adding flakes to system-wide Nix configuration..."
                echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null
                print_success "Flakes enabled system-wide"
            else
                print_warning "No sudo access to modify /etc/nix/nix.conf"
                print_warning "Flakes enabled in user config only (~/.config/nix/nix.conf)"
            fi
        fi
    fi
fi

# Step 4: Install direnv
print_step "Step 4: Installing direnv..."

if command -v direnv &> /dev/null; then
    print_success "direnv is already installed ($(direnv version))"
else
    print_warning "direnv not found. Installing..."
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            brew install direnv
        else
            print_warning "Homebrew not found. Installing direnv with Nix..."
            nix-env -iA nixpkgs.direnv
        fi
    elif [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
        # Try to install with package manager first (faster if available)
        installed=false
        
        if sudo -n true 2>/dev/null; then
            case "$PKG_MANAGER" in
                apt)
                    print_step "Attempting to install direnv with apt..."
                    if sudo apt install -y direnv 2>/dev/null; then
                        print_success "direnv installed with apt"
                        installed=true
                    fi
                    ;;
                dnf)
                    print_step "Attempting to install direnv with dnf..."
                    if sudo dnf install -y direnv 2>/dev/null; then
                        print_success "direnv installed with dnf"
                        installed=true
                    fi
                    ;;
                pacman)
                    print_step "Attempting to install direnv with pacman..."
                    if sudo pacman -S --noconfirm direnv 2>/dev/null; then
                        print_success "direnv installed with pacman"
                        installed=true
                    fi
                    ;;
            esac
        else
            print_warning "No sudo access. Will install direnv with Nix."
        fi
        
        if [ "$installed" = false ]; then
            print_warning "Package manager install failed, installing with Nix..."
            nix-env -iA nixpkgs.direnv
        fi
    else
        nix-env -iA nixpkgs.direnv
    fi
    
    print_success "direnv installed successfully"
fi

# Configure shell hooks for direnv
print_step "Configuring direnv shell hooks..."

# Detect current shell
CURRENT_SHELL=$(basename "$SHELL")
print_step "Detected shell: $CURRENT_SHELL"

# For Zsh
if command -v zsh &> /dev/null; then
    if [ -f ~/.zshrc ]; then
        if ! grep -q 'eval "$(direnv hook zsh)"' ~/.zshrc; then
            echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
            print_success "Added direnv hook to ~/.zshrc"
        else
            print_success "direnv hook already configured in ~/.zshrc"
        fi
    else
        echo 'eval "$(direnv hook zsh)"' > ~/.zshrc
        print_success "Created ~/.zshrc with direnv hook"
    fi
fi

# For Bash (always configure as fallback)
if [ -f ~/.bashrc ]; then
    if ! grep -q 'eval "$(direnv hook bash)"' ~/.bashrc; then
        echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
        print_success "Added direnv hook to ~/.bashrc"
    else
        print_success "direnv hook already configured in ~/.bashrc"
    fi
else
    echo 'eval "$(direnv hook bash)"' > ~/.bashrc
    print_success "Created ~/.bashrc with direnv hook"
fi

# Step 5: Create project directory
print_step "Step 5: Setting up CMPUT 350 project directory..."

echo ""
print_warning "Where would you like to create the 'cmput350-f25' folder?"
echo "Options:"
echo "  1) Home directory (~)"
echo "  2) Documents folder (~/Documents)"
echo "  3) Desktop (~/Desktop)"
echo "  4) Custom location"
echo ""
# Read from terminal, not from pipe
read -p "Enter your choice (1-4): " choice < /dev/tty

case $choice in
    1)
        PROJECT_DIR="$HOME/cmput350-f25"
        ;;
    2)
        mkdir -p ~/Documents
        PROJECT_DIR="$HOME/Documents/cmput350-f25"
        ;;
    3)
        mkdir -p ~/Desktop
        PROJECT_DIR="$HOME/Desktop/cmput350-f25"
        ;;
    4)
        read -p "Enter the full path where you want to create the folder: " custom_path < /dev/tty
        # Expand tilde if present
        custom_path="${custom_path/#\~/$HOME}"
        PROJECT_DIR="$custom_path/cmput350-f25"
        ;;
    *)
        print_error "Invalid choice. Using home directory."
        PROJECT_DIR="$HOME/cmput350-f25"
        ;;
esac

# Create the project directory
if [ -d "$PROJECT_DIR" ]; then
    print_warning "Directory $PROJECT_DIR already exists."
    read -p "Do you want to use this existing directory? (y/n): " use_existing < /dev/tty
    if [[ "$use_existing" != "y" ]]; then
        print_error "Setup cancelled. Please remove or rename the existing directory and run again."
        exit 1
    fi
else
    mkdir -p "$PROJECT_DIR"
    print_success "Created directory: $PROJECT_DIR"
fi

# Step 6: Download flake.nix from GitHub
print_step "Step 6: Downloading flake.nix..."

cd "$PROJECT_DIR"

# Check if flake.nix already exists
if [ -f flake.nix ]; then
    print_warning "flake.nix already exists in $PROJECT_DIR"
    read -p "Do you want to overwrite it? (y/n): " overwrite < /dev/tty
    if [[ "$overwrite" != "y" ]]; then
        print_success "Keeping existing flake.nix"
    else
        # Download flake.nix from the repo
        curl -L -o flake.nix https://raw.githubusercontent.com/YuHuaiCui/cmput350-env/main/flake.nix
        print_success "Downloaded flake.nix"
    fi
else
    # Download flake.nix from the repo
    curl -L -o flake.nix https://raw.githubusercontent.com/YuHuaiCui/cmput350-env/main/flake.nix
    print_success "Downloaded flake.nix"
fi

# Step 7: Create .envrc
print_step "Step 7: Creating .envrc for direnv..."

cat > .envrc << 'EOF'
use flake

# Optional: Add any project-specific environment variables here
# export MY_VAR="value"

# Optional: Load additional scripts
# source_env_if_exists .envrc.local
EOF

print_success "Created .envrc file"

# Step 8: Allow direnv
print_step "Step 8: Activating direnv for this project..."

# Source direnv hook for current session if not already loaded
if ! command -v _direnv_hook &> /dev/null; then
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        eval "$(direnv hook zsh)"
    else
        eval "$(direnv hook bash)"
    fi
fi

direnv allow .
print_success "direnv activated for $PROJECT_DIR"

# Step 9: Test the environment
print_step "Step 9: Testing the development environment..."

echo ""
print_warning "Entering Nix development shell for the first time..."
print_warning "This may take a while as Nix downloads all dependencies..."
echo ""

# Try to enter the dev shell
if nix develop --command echo "Development environment is working!"; then
    print_success "Successfully entered Nix development shell!"
else
    print_error "Failed to enter development shell. Please check the error messages above."
fi

# Final instructions
echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
print_success "Your CMPUT 350 development environment is ready!"
echo ""
echo -e "Project location: ${BLUE}$PROJECT_DIR${NC}"
echo ""
echo -e "${YELLOW}Important next steps:${NC}"
echo ""
echo -e "1. ${BLUE}Restart your terminal${NC} or run:"
# Show the correct source command based on current shell
CURRENT_SHELL_NOW=$(basename $SHELL)
if [[ "$CURRENT_SHELL_NOW" == "zsh" ]]; then
    echo "   source ~/.zshrc"
elif [[ "$CURRENT_SHELL_NOW" == "bash" ]]; then
    echo "   source ~/.bashrc"
    # Check if user changed default shell to zsh earlier
    if [[ "${set_zsh_default:-}" == "y" ]]; then
        echo ""
        echo -e "   ${YELLOW}Note:${NC} You changed your default shell to zsh."
        echo -e "   To switch to zsh now, run: ${BLUE}zsh${NC}"
        echo "   Or restart your terminal for the change to take effect."
    fi
else
    echo "   source ~/.bashrc  (for bash)"
    echo "   source ~/.zshrc   (for zsh)"
fi
echo ""
echo -e "2. ${BLUE}Navigate to your project:${NC}"
echo "   cd $PROJECT_DIR"
echo ""
echo -e "3. ${BLUE}The environment will activate automatically${NC} when you enter the directory."
echo "   You should see the CMPUT 350 welcome message."
echo ""
echo -e "4. ${BLUE}To manually enter the development shell:${NC}"
echo "   nix develop"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo ""
echo "• If direnv doesn't activate automatically:"
echo "  - Make sure you've restarted your terminal"
echo "  - Run: direnv allow"
echo ""
echo "• If Nix commands aren't found:"
echo "  - Restart your terminal"
echo "  - For multi-user install: source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
echo "  - For single-user install: source ~/.nix-profile/etc/profile.d/nix.sh"
echo ""
echo "• For WSL users with graphics issues:"
echo "  - Make sure you have an X server running (like VcXsrv or WSLg)"
echo "  - Try: export DISPLAY=:0"
echo ""
echo -e "${GREEN}Happy coding!${NC}"