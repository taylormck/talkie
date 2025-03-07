run: ensure-bin-exists
    odin run src -out:bin/talkie

build-release: ensure-bin-exists
    odin build src -o:speed -out:bin/talkie

test:
    odin test src

ensure-bin-exists:
    #!/usr/bin/env sh
    if [ ! -d "bin" ]; then
        mkdir bin
    fi

