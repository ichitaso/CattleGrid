DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:16.2:15.0
else
TARGET = iphone:14.5:13.0
endif

THEOS_DEVICE_IP = 0.0.0.0 -p 2222

XCODEPROJ_NAME = CattleGrid

$(XCODEPROJ_NAME)_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' IPHONEOS_DEPLOYMENT_TARGET=13 OTHER_SWIFT_FLAGS="-D JAILBREAK"
#$(XCODEPROJ_NAME)_CFLAGS += -DJAILBREAK=1
$(XCODEPROJ_NAME)_CODESIGN_FLAGS = -Sent.plist

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/xcodeproj.mk

after-stage::
	@echo "Copying IPA..."
	mkdir -p $(THEOS_OUTPUT_DIR)/Payload
	cp -r $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app $(THEOS_OUTPUT_DIR)/Payload
	cd $(THEOS_OUTPUT_DIR) && zip -r $(XCODEPROJ_NAME).tipa Payload

clean::
	@echo "Cleaning IPA..."
	rm -rf $(THEOS_OUTPUT_DIR)/$(XCODEPROJ_NAME).tipa

after-install::
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	install.exec 'uicache --path /var/jb/Applications/CattleGrid.app/'
else
	install.exec 'uicache --path /Applications/CattleGrid.app/'
endif
