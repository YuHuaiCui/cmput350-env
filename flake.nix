{
  description = "CMPUT 350 Development Environment";
 
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
 
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # C++ compiler and build tools
            gcc
            gdb             
            cmake
            ninja
            pkg-config
           
            # SFML and dependencies
            sfml
            freetype
           
            # Development tools
            valgrind
            cppcheck         # Static analysis tool for C++
           
            # Graphics libraries (SFML dependencies)
            xorg.libX11
            xorg.libXrandr
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXext
            xorg.libXxf86vm
            mesa
            libGL
            libGLU
           
            # Graphics and X11 utilities for debugging
            mesa-demos      # glxinfo, glxgears
            xorg.xeyes      # xeyes
            xorg.xclock     # xclock
            pciutils        # lspci
          ];
         
          shellHook = ''
            echo "CMPUT 350 Development Environment"
            echo "SFML version: $(pkg-config --modversion sfml-all)"
            echo "Compiler: $(gcc --version | head -1)"
           
            # Set GCC as the default compiler
            export CC=gcc
            export CXX=g++
           
            # GCC-specific flags (using libstdc++)
            export CXXFLAGS="-std=c++17 -Wall -Wextra"
           
            # Set up graphics environment
            export LD_LIBRARY_PATH="${pkgs.mesa}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH"
            export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
           
            # Try different OpenGL versions if needed
            # export MESA_GL_VERSION_OVERRIDE=3.3
            # export MESA_GLSL_VERSION_OVERRIDE=330
           
            echo ""
            echo "Graphics debugging commands:"
            echo "  glxinfo | head -10    # Check OpenGL info"
            echo "  xeyes                 # Test basic X11"
            echo "  glxgears              # Test OpenGL"
            echo ""
            echo "If SFML fails, try:"
            echo "  export LIBGL_ALWAYS_SOFTWARE=1"
            echo "  export MESA_GL_VERSION_OVERRIDE=2.1"
            echo ""
            echo "GCC-specific commands:"
            echo "  g++ -std=c++17 -Wall -Wextra -o myapp main.cpp \`pkg-config --cflags --libs sfml-all\`"
            echo "  gdb ./myapp          # Debug with GDB"
            echo "  cppcheck *.cpp       # Static analysis"
          '';
        };
      });
}