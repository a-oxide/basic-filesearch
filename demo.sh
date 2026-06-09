#!/bin/bash
# demo.sh - one-command launcher for the filesearch project
#
# usage:
#   ./demo.sh            interactive menu
#   ./demo.sh test       run test suite then exit
#   ./demo.sh shell      drop into bash
#   ./demo.sh clean      remove the podman image

set -e

IMAGE="pi-filesearch"
BUILD_DIR="/tmp/opencode/docker_build"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

build_image() {
    echo ""
    echo "==> building podman image..."
    mkdir -p "$BUILD_DIR"
    cp "$SCRIPT_DIR"/main.cpp "$SCRIPT_DIR"/Makefile \
        "$SCRIPT_DIR"/Dockerfile "$SCRIPT_DIR"/*.sh \
        "$BUILD_DIR/" 2>/dev/null
    podman build --no-cache -t "$IMAGE" "$BUILD_DIR"
    echo ""
    echo "==> build complete"
    echo ""
}

case "${1:-menu}" in
    test)
        build_image
        echo "==> starting podman container..."
        echo "==> creating 50000 symbolic test files..."
        echo ""
        podman run --rm "$IMAGE" /bin/bash -c '
            bash setup_test_files.sh
            echo ""
            echo "==> running automated test suite..."
            echo ""
            bash test_search.sh
        '
        echo ""
        echo "==> test suite complete"
        ;;
    shell)
        build_image
        echo ""
        echo "==> starting podman container..."
        echo ""
        echo "inside the container:"
        echo "  bash setup_test_files.sh    # create ~50k test files"
        echo "  ./filesearch                # run the search tool"
        echo "  type 'quit' to exit"
        echo ""
        podman run -it --rm --name pi-demo "$IMAGE"
        ;;
    clean)
        echo ""
        echo "==> removing image and build cache..."
        podman rmi -f "$IMAGE" 2>/dev/null || true
        rm -rf "$BUILD_DIR"
        echo "==> cleaned up"
        echo ""
        ;;
    menu)
        build_image
        echo ""
        echo "  filesearch demo"
        echo ""
        echo "  1) run automated tests"
        echo "  2) interactive shell"
        echo "  3) quit"
        echo ""
        read -rp "choose [1-3]: " choice
        case "$choice" in
            1)
                echo ""
                echo "==> starting podman container..."
                echo "==> creating 50000 symbolic test files..."
                echo ""
                podman run --rm "$IMAGE" /bin/bash -c '
                    bash setup_test_files.sh
                    echo ""
                    echo "==> running automated test suite..."
                    echo ""
                    bash test_search.sh
                '
                echo ""
                echo "==> test suite complete"
                ;;
            2)
                echo ""
                echo "==> starting podman container..."
                echo ""
                echo "inside the container:"
                echo "  bash setup_test_files.sh"
                echo "  ./filesearch"
                echo ""
                podman run -it --rm --name pi-demo "$IMAGE"
                ;;
            3)
                exit 0
                ;;
        esac
        ;;
esac
