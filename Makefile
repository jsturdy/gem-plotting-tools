#
# Makefile for gemplotting package
#

BUILD_HOME := $(shell dirname `pwd`)

Project      := gem-plotting-tools
ShortProject := gemplotting
Namespace    := gempython
Package      := gemplotting
ShortPackage := gemplotting
LongPackage  := gemplotting
PackageName  := $(Namespace)_$(ShortPackage)
PackageDir   := pkg/$(Namespace)/$(ShortPackage)
ScriptDir    := pkg/$(Namespace)/scripts
ManDir       := pkg/man
INSTALL_PATH=/opt/$(Namespace)

ProjectPath:=$(BUILD_HOME)/$(Project)
ConfigDir:=$(ProjectPath)/config

include $(ConfigDir)/mfCommonDefs.mk
include $(ConfigDir)/mfPythonDefs.mk

# Explicitly define the modules that are being exported (for PEP420 compliance)
PythonModules = ["$(Namespace).$(ShortPackage)", \
                 "$(Namespace).$(ShortPackage).utils", \
                 "$(Namespace).$(ShortPackage).fitting", \
                 "$(Namespace).$(ShortPackage).macros", \
                 "$(Namespace).$(ShortPackage).mapping" \
]
$(info PythonModules=${PythonModules})

GEMPLOTTING_VER_MAJOR:=$(shell $(ConfigDir)/tag2rel.sh | awk '{split($$0,a," "); print a[1];}' | awk '{split($$0,b,":"); print b[2];}')
GEMPLOTTING_VER_MINOR:=$(shell $(ConfigDir)/tag2rel.sh | awk '{split($$0,a," "); print a[2];}' | awk '{split($$0,b,":"); print b[2];}')
GEMPLOTTING_VER_PATCH:=$(shell $(ConfigDir)/tag2rel.sh | awk '{split($$0,a," "); print a[3];}' | awk '{split($$0,b,":"); print b[2];}')

include $(ConfigDir)/mfSphinx.mk
include $(ConfigDir)/mfPythonRPM.mk

PythonSources=$(wildcard ana*.py)
PythonSources+=$(wildcard utils/*.py)
PythonSources+=$(wildcard fitting/*.py)
PythonSources+=$(wildcard macros/*.py)
PythonSources+=$(wildcard mapping/*.py)

default:
	$(MakeDir) $(PackageDir)
	@cp -rf macros fitting mapping utils $(PackageDir)
	@echo "__path__ = __import__('pkgutil').extend_path(__path__, __name__)" > pkg/$(Namespace)/__init__.py
	@cp -rf __init__.py $(PackageDir)

# Override, as this package uses pkg/setup.py as the template file
$(PackageSetupFile): pkg/setup.py
$(PackagePrepFile): $(PythonSources) Makefile | default man
	@if ! [ -e pkg/installrpm.sh ]; then \
	    cp -rf config/scriptlets/installrpm.sh pkg/; \
	    perl -pi -e "s|__PYTHON_SCRIPT_PATH__|$(INSTALL_PATH)/bin/$(ShortPackage)|g" pkg/installrpm.sh; \
	fi
	$(MakeDir) $(ScriptDir)
	@cp -rf anaUltra*.py $(ScriptDir)
	@cp -rf anaSBit*.py $(ScriptDir)
	@cp -rf anaXDAQ*.py $(ScriptDir)
	@cp -rf ana_scans.py $(ScriptDir)
	@cp -rf anaDACScan.py $(ScriptDir)
	@cp -rf anaXDAQLatency.py $(ScriptDir)
	@cp -rf packageFiles4Docker.py $(ScriptDir)
	-rm -rf $(ManDir)
	$(MakeDir) $(ManDir)
	@cp -rf doc/_build/man/* $(ManDir)
	gzip $(ManDir)/*
	-cp -rf README.md LICENSE CHANGELOG.md MANIFEST.in requirements.txt $(PackageDir)
	-cp -rf README.md LICENSE CHANGELOG.md MANIFEST.in requirements.txt pkg
	touch $@

clean:
	-rm -rf $(ScriptDir)
	-rm -rf $(PackageDir)
	-rm -rf $(ManDir)
	-rm -f  pkg/$(Namespace)/__init__.py
	-rm -f  pkg/README.md
	-rm -f  pkg/LICENSE
	-rm -f  pkg/MANIFEST.in
	-rm -f  pkg/CHANGELOG.md
	-rm -f  pkg/requirements.txt

print-env:
	@echo BUILD_HOME     $(BUILD_HOME)
	@echo GIT_VERSION    $(GIT_VERSION)
	@echo PYTHON_VERSION $(PYTHON_VERSION)
	@echo GEMDEVELOPER   $(GEMDEVELOPER)
