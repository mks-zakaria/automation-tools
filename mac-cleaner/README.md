# mac-cleaner

Frees disk space on macOS by removing caches and rebuildable developer files.
Never touches `/Applications`, `~/Pictures`, Documents, Desktop or source code.

```sh
./clean.sh       # asks before the bigger steps
./clean.sh -y    # cleans everything without asking
```

**Always cleaned:** npm / pip / uv / Puppeteer / pre-commit / Homebrew / pnpm caches,
`~/Library/Caches`, Xcode DerivedData and iOS DeviceSupport, unavailable simulators,
Gradle caches, logs, Trash.

**Asked first:** project build folders in `~/projects` (`node_modules`, `build`, `build-*`,
`Pods`, `.next`, venvs — `build` folders tracked by git are skipped), all iOS simulators
and runtimes, Android emulators, unused Docker images/containers/build cache (volumes kept).
