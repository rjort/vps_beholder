# VPS Beholder

<p align="center">
  <img src="assets/app_icon.png" width="200" alt="VPS Beholder Logo">
</p>

A graphical GTK4 application written in Ruby to monitor and observe Docker containers running on your remote VPS over SSH.

## Features
- **GTK4 User Interface**: Hardware accelerated and natively integrated GUI.
- **SSH Authentication**: Connects securely to any remote server using SSH passwords and local `ed25519` keys.
- **Save Connections**: Quickly reconnect using the built-in host caching feature.
- **Container Listing**: Instantly fetches and lists your remote Docker containers.

## Requirements
- Ruby 3.2+
- GTK4 runtime libraries installed on your operating system (e.g., `libgtk-4-dev` for Ubuntu).
- Docker installed and accessible by the authenticating user on the remote VPS.

## Installation

### Method 1: Portable AppImage (Recommended)
You can build a portable `.AppImage` that embeds Ruby and all dependencies:
```bash
make appimage
```
This will generate `VPS_Beholder-x86_64.AppImage`.
You can run it directly:
```bash
./VPS_Beholder-x86_64.AppImage
```
To integrate it with your Linux system (add it to your Application Menu and terminal path):
```bash
./VPS_Beholder-x86_64.AppImage --install
```
To remove the system integration:
```bash
./VPS_Beholder-x86_64.AppImage --uninstall
```

### Method 2: System-wide Build
1. Clone the repository.
2. Install the gems via Bundler:
   ```bash
   bundle install
   ```
3. Run the installer to set up local desktop shortcuts:
   ```bash
   make install
   ```

## Usage

Start the application using:
```bash
bundle exec ruby main.rb
```
1. In the login dialog, enter your remote VPS target in the format `user@host` (e.g., `root@192.168.1.100`).
2. Provide your SSH password if necessary.
3. If successful, the application will display the live Docker containers running on your server!

## Testing
Run the RSpec test suite with:
```bash
bundle exec rspec
```
