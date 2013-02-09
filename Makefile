ARCHS = armv7
TARGET = iphone:clang::4.0
include theos/makefiles/common.mk

TWEAK_NAME = CloakStatus
CloakStatus_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
