#############
# Variables #
#############

GODOT_VERSION := $(shell cat .godot_version)
RELEASE_NAME = stable
SUBDIR =
GODOT_PLATFORM = x11.64
GODOT_FILENAME = Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}
GODOT_TEMPLATE = Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz

GAME_NAME = RootedShadow
GAME_VERSION := $(shell cat .version)

#############
# Commands  #
#############

mkflower:
	mkdir -p .mkflower
	mkdir -p .mkflower/build
	mkdir -p .mkflower/bin
	mkdir -p .mkflower/cache

	touch .mkflower/.gitignore
	echo '*' >> .mkflower/.gitignore

	touch .mkflower/.gdignore

install_godot: mkflower
	# curl -X GET "https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/SHA512-SUMS.txt" --output .mkflower/cache/SHA512-SUMS.txt
	# if [ ! -f ".mkflower/cache/${GODOT_FILENAME}" ] || [ "$(cat .mkflower/cache/SHA512-SUMS.txt | grep ${GODOT_FILENAME} | awk -F'[[:space:]]+' '{print $1}')" != "$(sha256sum .mkflower/cache/${GODOT_FILENAME})" ]; then \
	curl -X GET "https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/${GODOT_FILENAME}.zip" --output .mkflower/cache/${GODOT_FILENAME}.zip; \
	unzip .mkflower/cache/${GODOT_FILENAME}.zip -d .mkflower/cache/; \
	cp .mkflower/cache/${GODOT_FILENAME} .mkflower/bin/${GODOT_FILENAME};
	# fi

install_templates: mkflower
	curl -X GET "https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/${GODOT_TEMPLATE}" --output .mkflower/cache/${GODOT_TEMPLATE}; \
	unzip .mkflower/cache/${GODOT_TEMPLATE} -d .mkflower/cache/; \
	mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}; \
	cp .mkflower/cache/templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME};

export_release_linux:
	mkdir -p .mkflower/build/linux
	.mkflower/bin/${GODOT_FILENAME} --export "Linux/X11" .mkflower/build/linux/${GAME_NAME}.x86_64
	(cd .mkflower/build/linux && zip ${GAME_NAME}-linux-v${GAME_VERSION}.zip -r .)
	mv .mkflower/build/linux/${GAME_NAME}-linux-v${GAME_VERSION}.zip .mkflower/build/${GAME_NAME}-linux-v${GAME_VERSION}.zip

export_release_windows:
	mkdir -p .mkflower/build/windows
	.mkflower/bin/${GODOT_FILENAME} --export "Windows Desktop" .mkflower/build/windows/${GAME_NAME}.exe
	(cd .mkflower/build/windows && zip ${GAME_NAME}-windows-v${GAME_VERSION}.zip -r .)
	mv .mkflower/build/windows/${GAME_NAME}-windows-v${GAME_VERSION}.zip .mkflower/build/${GAME_NAME}-windows-v${GAME_VERSION}.zip

export_release_mac:
	.mkflower/bin/${GODOT_FILENAME} --export "Mac OSX" .mkflower/build/${GAME_NAME}-mac-v${GAME_VERSION}.zip

editor:
	.mkflower/bin/${GODOT_FILENAME} --editor

godot:
	.mkflower/bin/${GODOT_FILENAME} $(ARGS)

run_release:
	.mkflower/build/linux/${GAME_NAME}.x86_64

clean_mkflower:
	rm -rf .mkflower

clean_godot:
	rm -rf .godot

#############
# Playbook  #
#############

clean: clean_mkflower clean_godot
build: clean_godot export_release_linux
run: build run_release

export_release_all: export_release_linux export_release_mac export_release_windows
ci_build: clean install_godot install_templates export_release_all
