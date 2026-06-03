APP_NAME := SleepGuard
HELPER_NAME := SleepGuardOverlay
BUILD_DIR := .build/release
DIST_DIR := dist
APP_DIR := $(DIST_DIR)/$(APP_NAME).app
HELPER_APP_DIR := $(APP_DIR)/Contents/Library/LoginItems/$(HELPER_NAME).app

.PHONY: all build package clean

all: package

build:
	swift build -c release

assets/SleepGuard.icns: Scripts/generate_app_icon.swift
	swift Scripts/generate_app_icon.swift

package: build assets/SleepGuard.icns
	rm -rf $(DIST_DIR)
	mkdir -p $(APP_DIR)/Contents/MacOS
	mkdir -p $(APP_DIR)/Contents/Resources
	mkdir -p $(HELPER_APP_DIR)/Contents/MacOS
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_DIR)/Contents/MacOS/$(APP_NAME)
	cp $(BUILD_DIR)/$(HELPER_NAME) $(HELPER_APP_DIR)/Contents/MacOS/$(HELPER_NAME)
	cp assets/SleepGuard.icns $(APP_DIR)/Contents/Resources/SleepGuard.icns
	plutil -create xml1 $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleExecutable -string $(APP_NAME) $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleIdentifier -string com.faka.sleepguard $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleIconFile -string SleepGuard.icns $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleName -string $(APP_NAME) $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundlePackageType -string APPL $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleShortVersionString -string 0.1.0 $(APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleVersion -string 1 $(APP_DIR)/Contents/Info.plist
	plutil -insert LSMinimumSystemVersion -string 14.0 $(APP_DIR)/Contents/Info.plist
	plutil -create xml1 $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleExecutable -string $(HELPER_NAME) $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleIdentifier -string com.faka.sleepguard.overlay $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleName -string $(HELPER_NAME) $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert CFBundlePackageType -string APPL $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleShortVersionString -string 0.1.0 $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert CFBundleVersion -string 1 $(HELPER_APP_DIR)/Contents/Info.plist
	plutil -insert LSUIElement -bool true $(HELPER_APP_DIR)/Contents/Info.plist

clean:
	rm -rf .build $(DIST_DIR)
