include theos/makefiles/common.mk

TWEAK_NAME = ScreenshotExtender
ScreenshotExtender_FILES = Tweak.xm
ScreenshotExtender_FRAMEWORKS = UIKit
SUBPROJECTS = screenshotextenderpref

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
