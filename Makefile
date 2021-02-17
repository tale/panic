INSTALL_TARGET_PROCESSES = SpringBoard
SUBPROJECTS = Sources/Tweak Sources/Preferences

include $(THEOS)/makefiles/common.mk

export ARCHS = arm64 arm64e
export TARGET = iphone:clang:14.0:11.0
export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/aggregate.mk
