#!/bin/bash
set -e

echo "Building AppImage..."
APPDIR="AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$APPDIR/usr/src/vps_beholder"

# Copy icon and desktop file
cp assets/app_icon.png "$APPDIR/usr/share/icons/hicolor/512x512/apps/com.vps.beholder.png"
cp assets/app_icon.png "$APPDIR/com.vps.beholder.png" # AppImage requires icon in root
cp com.vps.beholder.desktop "$APPDIR/vps_beholder.desktop"

# Copy source code
rsync -av --exclude='.git' --exclude='AppDir' --exclude='*.AppImage' . "$APPDIR/usr/src/vps_beholder/"

# Find Ruby and copy it
RUBY_PATH=$(asdf where ruby 2>/dev/null || echo "")
if [ -z "$RUBY_PATH" ]; then
    # Fallback for environments without ASDF (e.g. GitHub Actions)
    RUBY_BIN=$(which ruby 2>/dev/null || echo "")
    if [ -n "$RUBY_BIN" ]; then
        RUBY_PATH=$(dirname "$(dirname "$RUBY_BIN")")
    fi
fi

if [ -z "$RUBY_PATH" ] || [ ! -d "$RUBY_PATH" ]; then
    echo "Could not find ruby installation. Currently required for building the AppImage."
    exit 1
fi

echo "Bundling Ruby from $RUBY_PATH..."
cp -r "$RUBY_PATH" "$APPDIR/usr/ruby"

# Bundle gems locally
echo "Bundling gems..."
cd "$APPDIR/usr/src/vps_beholder"
export GEM_HOME="../../ruby/lib/ruby/gems/3.3.0"
export GEM_PATH="../../ruby/lib/ruby/gems/3.3.0"
export PATH="../../ruby/bin:$PATH"
bundle config set --local path 'vendor/bundle'
bundle config set --local without 'development test'
bundle install
cd ../../../../

echo "Aggressively cleaning up AppDir to reduce AppImage size..."
# 1. Remove Ruby documentation and interactive help
rm -rf "$APPDIR/usr/ruby/share/doc"
rm -rf "$APPDIR/usr/ruby/share/ri"

# 2. Remove all global ASDF gems, caches, and specs, keeping only the default gems.
# The actual app dependencies are isolated in vendor/bundle now!
rm -rf "$APPDIR/usr/ruby/lib/ruby/gems/3.3.0/cache"
rm -rf "$APPDIR/usr/ruby/lib/ruby/gems/3.3.0/doc"
rm -rf "$APPDIR/usr/ruby/lib/ruby/gems/3.3.0/gems"/*
rm -f "$APPDIR/usr/ruby/lib/ruby/gems/3.3.0/specifications"/*.gemspec

# 3. Clean up build artifacts and test files inside vendor/bundle
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type d -name "cache" -exec rm -rf {} + 2>/dev/null || true
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type d -name "spec" -exec rm -rf {} + 2>/dev/null || true
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type d -name "test" -exec rm -rf {} + 2>/dev/null || true
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type f -name "*.c" -delete 2>/dev/null || true
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type f -name "*.h" -delete 2>/dev/null || true
find "$APPDIR/usr/src/vps_beholder/vendor/bundle" -type f -name "*.o" -delete 2>/dev/null || true

# 4. Strip debugging symbols from binaries and shared objects to save space
echo "Stripping debugging symbols..."
find "$APPDIR" -type f -exec file {} + | grep ELF | awk -F: '{print $1}' | xargs strip --strip-unneeded 2>/dev/null || true


# Create AppRun
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/bash
APPDIR="$(dirname "$(readlink -f "${0}")")"
APPIMAGE_PATH="${APPIMAGE:-$(readlink -f "${0}")}"

# Handle install/uninstall flags
if [ "$1" == "--install" ]; then
    echo "Installing VPS Beholder AppImage integration..."
    mkdir -p ~/.local/share/applications
    mkdir -p ~/.local/share/icons/hicolor/512x512/apps
    mkdir -p ~/.local/bin
    
    # Copy icon
    cp "$APPDIR/com.vps.beholder.png" ~/.local/share/icons/hicolor/512x512/apps/com.vps.beholder.png
    
    # Create desktop file pointing to this AppImage
    sed "s|Exec=vps_beholder|Exec=\"$APPIMAGE_PATH\"|g" "$APPDIR/vps_beholder.desktop" > ~/.local/share/applications/com.vps.beholder.desktop
    
    # Create wrapper in bin
    echo "#!/bin/bash" > ~/.local/bin/vps_beholder
    echo "exec \"$APPIMAGE_PATH\" \"\$@\"" >> ~/.local/bin/vps_beholder
    chmod +x ~/.local/bin/vps_beholder
    
    echo "VPS Beholder AppImage installed successfully!"
    echo "You can now search for it in your application menu or run 'vps_beholder' in the terminal."
    exit 0
elif [ "$1" == "--uninstall" ]; then
    echo "Uninstalling VPS Beholder AppImage integration..."
    rm -f ~/.local/share/applications/com.vps.beholder.desktop
    rm -f ~/.local/share/icons/hicolor/512x512/apps/com.vps.beholder.png
    rm -f ~/.local/bin/vps_beholder
    echo "VPS Beholder AppImage integration removed successfully!"
    exit 0
fi

# Fallback for dynamic libraries (e.g. GTK4 extensions)
export LD_LIBRARY_PATH="$APPDIR/usr/ruby/lib:$LD_LIBRARY_PATH"

export PATH="$APPDIR/usr/ruby/bin:$PATH"
export GEM_HOME="$APPDIR/usr/ruby/lib/ruby/gems/3.3.0"
export GEM_PATH="$APPDIR/usr/ruby/lib/ruby/gems/3.3.0"

cd "$APPDIR/usr/src/vps_beholder"
exec bundle exec ruby main.rb "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Download appimagetool if not present
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo "Downloading appimagetool..."
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

echo "Generating AppImage..."
ARCH=x86_64 ./appimagetool-x86_64.AppImage --appimage-extract-and-run "$APPDIR" "VPS_Beholder-x86_64.AppImage"

echo "Done! VPS_Beholder-x86_64.AppImage is ready."
