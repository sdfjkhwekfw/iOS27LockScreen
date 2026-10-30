TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += LockScreenClockCustomPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
