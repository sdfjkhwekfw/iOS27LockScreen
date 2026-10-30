DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

TARGET = iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

TWEAK_NAME = iOS27LockScreen
iOS27LockScreen_FILES = iOS27LockScreen.xm
iOS27LockScreen_CFLAGS = -fobjc-arc
iOS27LockScreen_FRAMEWORKS = UIKit Foundation CoreFoundation
iOS27LockScreen_LIBRARIES = substrate

SUBPROJECTS += LockScreenClockCustomPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
