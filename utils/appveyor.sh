#!/bin/bash

# Stop at the first error and show all run commands
set -e
set -x

export BUILD_FOLDER=/Projects/$APPVEYOR_PROJECT_NAME
export ADALIB_DIR=$BUILD_FOLDER/adalib
export PATH=/c/Python38-x64:\
$ADALIB_DIR/bin:\
/c/GNAT/bin:\
/mingw64/bin:\
$PATH
export GPR_PROJECT_PATH=$ADALIB_DIR/share/gpr
export LIBRARY_TYPE=relocatable
export CPATH=/mingw64/include
export LIBRARY_PATH=/mingw64/lib

function do_install()
{
    cd $BUILD_FOLDER

    # Get Langkit, in particular the branch that corresponds to the Libadalang
    # commit being tested.
    if ! [ -d langkit ]
    then
        git clone https://github.com/AdaCore/langkit
    fi
    (
        cd langkit
        python $APPVEYOR_BUILD_FOLDER\\utils\\gh-langkit-branch.py \
            $APPVEYOR_REPO_NAME \
            $APPVEYOR_REPO_BRANCH \
            $APPVEYOR_PULL_REQUEST_HEAD_REPO_NAME \
            $APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH \



    )

    # Install libiconv and gmp
    pacman -S --noconfirm mingw-w64-x86_64-libiconv mingw-w64-x86_64-gmp

    # Get and build libgpr, gnatcoll-core and gnatcoll-bindings. Only build
    # relocatable variants, as we don't need the static and static-pic ones.
    git clone -q https://github.com/AdaCore/gprbuild
    (
        cd gprbuild
        make BUILD=production prefix="$ADALIB_DIR" libgpr.build.shared
        make BUILD=production prefix="$ADALIB_DIR" libgpr.install.shared
    )

    git clone -q https://github.com/AdaCore/gnatcoll-core
    make prefix=$ADALIB_DIR LIBRARY_TYPES=relocatable -C gnatcoll-core \
      build install

    git clone -q https://github.com/AdaCore/gnatcoll-bindings
    for component in iconv gmp ; do
      python gnatcoll-bindings/$component/setup.py build --reconfigure -j0 \
          --prefix="$ADALIB_DIR" --library-types=relocatable
      python gnatcoll-bindings/$component/setup.py install
    done

    # Install all Python dependencies for Langkit
    python -m pip install -r langkit/REQUIREMENTS.dev

    # Build and install Langkit_Support
    langkit/manage.py build-langkit-support
    langkit/manage.py install-langkit-support "$ADALIB_DIR"
}

function do_build()
{
    cd $BUILD_FOLDER
    export PYTHONPATH=$APPVEYOR_BUILD_FOLDER\\langkit

    # Generate Libadalang
    python ada/manage.py generate

    # Build the generated lexer alone first, as it takes a huge amount of
    # memory. Only then build the rest in parallel.
    gprbuild -Pbuild/libadalang.gpr \
        -XBUILD_MODE=dev -XLIBRARY_TYPE=relocatable -XLIBADALANG_WARNINGS=true \
        -p -c -u libadalang-lexer_state_machine.adb

    # Restrict parallelism to avoid OOM issues
    python ada/manage.py build -j12

    # Install Libadalang so we can create a binary distribution
    python ada/manage.py install "$ADALIB_DIR"
    cd "$ADALIB_DIR"
    7z a $BUILD_FOLDER/libadalang-${APPVEYOR_REPO_BRANCH}-windows.zip .
}

do_$1
