.PHONY: run test lint check install uninstall appimage

run:
	bundle exec ruby main.rb

test:
	bundle exec rspec

lint:
	bundle exec rubocop

check: lint test

appimage:
	./build_appimage.sh

install:
	@echo "Installing VPS Beholder to ~/.local/share/vps_beholder..."
	mkdir -p ~/.local/share/vps_beholder
	rsync -av --exclude='.git' --exclude='.gemini' . ~/.local/share/vps_beholder/
	
	@echo "Setting up executable wrapper..."
	mkdir -p ~/.local/bin
	cp bin/vps_beholder ~/.local/bin/vps_beholder
	
	@echo "Setting up desktop entry and icon..."
	mkdir -p ~/.local/share/icons/hicolor/512x512/apps
	cp assets/app_icon.png ~/.local/share/icons/hicolor/512x512/apps/com.vps.beholder.png
	mkdir -p ~/.local/share/applications
	sed "s|Exec=vps_beholder|Exec=$(HOME)/.local/bin/vps_beholder|g" com.vps.beholder.desktop > ~/.local/share/applications/com.vps.beholder.desktop
	
	@echo "Installation complete! You can now run 'vps_beholder' from your terminal or application menu."

uninstall:
	@echo "Removing VPS Beholder..."
	rm -rf ~/.local/share/vps_beholder
	rm -f ~/.local/bin/vps_beholder
	rm -f ~/.local/share/icons/hicolor/512x512/apps/com.vps.beholder.png
	rm -f ~/.local/share/applications/com.vps.beholder.desktop
	@echo "Uninstallation complete."
