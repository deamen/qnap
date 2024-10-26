# qpkg-builder
Build qpkg for using the qpkg-builder container image.

Build the transmission-daemon qpkg:
```bash
DOCKER_BUILDKIT=1 docker run -it --rm -v ${PWD}/qpkgs/transmission-3:/SRC qpkg-builder

```

Build the rclone qpkg:
```bash
podman run -it --rm -v ${PWD}/qpkgs/rclone:/SRC:z quay.io/deamen/qpkg-builder
```