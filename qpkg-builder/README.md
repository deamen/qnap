# qpkg-builder
Build qpkg-builder container for building qpkg.

# Usage:
Build the qpkg-builder:
```bash
DOCKER_BUILDKIT=1 docker build -t qpkg-builder .

```

Build the transmission-daemon qpkg:
```bash
DOCKER_BUILDKIT=1 docker run -it --rm -v ${PWD}/qpkgs/transmission-3:/SRC qpkg-builder

```
