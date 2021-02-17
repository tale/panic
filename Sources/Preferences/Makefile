include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PanicPreferences
PanicPreferences_FILES = $(wildcard Classes/**/*.m) $(wildcard Classes/*.m)
PanicPreferences_CFLAGS = -fobjc-arc
PanicPreferences_INSTALL_PATH = /Library/PreferenceBundles
PanicPreferences_FRAMEWORKS = UIKit
PanicPreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk
