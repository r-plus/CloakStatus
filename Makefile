ARCHS = armv7
TARGET = iphone:clang::4.0
include theos/makefiles/common.mk

TWEAK_NAME = CloakStatus
CloakStatus_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = CloakStatusSettings
CloakStatusSettings_FILES = Preference.m
CloakStatusSettings_INSTALL_PATH = /Library/PreferenceBundles
# CloakStatusSettings_FRAMEWORKS = UIKit 
CloakStatusSettings_PRIVATE_FRAMEWORKS = Preferences
CloakStatusSettings_LIBRARIES = prefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CloakStatus.plist$(ECHO_END)
