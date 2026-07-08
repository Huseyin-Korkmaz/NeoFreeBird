ARCHS = arm64
TARGET := iphone:clang:16.5:14.0
include $(THEOS)/makefiles/common.mk
DEBUG = 1

TWEAK_NAME = BHTwitter

BHTwitter_FILES = $(shell find src \( -name '*.x' -o -name '*.m' \) | sort) $(wildcard deps/Colours/*.m deps/JGProgressHUD/*.m deps/SAMKeychain/*.m)
BHTwitter_FRAMEWORKS = UIKit Foundation AVFoundation AVKit CoreMotion GameController VideoToolbox Accelerate CoreMedia CoreImage CoreGraphics ImageIO Photos CoreServices SystemConfiguration SafariServices Security QuartzCore WebKit SceneKit
BHTwitter_PRIVATE_FRAMEWORKS = Preferences
BHTwitter_EXTRA_FRAMEWORKS = Cephei CepheiPrefs CepheiUI
BHTwitter_OBJ_FILES = $(shell find deps/lib -name '*.a')
BHTwitter_LIBRARIES = sqlite3 bz2 c++ iconv z
BHTwitter_CFLAGS = -Isrc -Ideps -fobjc-arc -Wno-deprecated-declarations -Wno-nullability-completeness -Wno-unused-function -Wno-unused-property-ivar -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk

ifdef SIDELOADED
SUBPROJECTS += deps/libflex deps/zxPluginsInject
else
SUBPROJECTS += deps/libflex
endif

include $(THEOS_MAKE_PATH)/aggregate.mk
