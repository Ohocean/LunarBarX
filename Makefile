TARGET := iphone:clang:16.5:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LunarBarX
LunarBarX_FILES = Tweak.x
LunarBarX_CFLAGS = -fobjc-arc -Wno-unused-variable
LunarBarX_FRAMEWORKS = Foundation UIKit
LunarBarX_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
