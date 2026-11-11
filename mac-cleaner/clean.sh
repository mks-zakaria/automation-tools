#!/bin/zsh
# clean.sh — free disk space on this Mac.
# Never touches /Applications, ~/Pictures, Documents, Desktop or source code.
# Usage:  ~/Desktop/clean.sh        (asks before the bigger steps)
#         ~/Desktop/clean.sh -y     (does everything without asking)

YES=0; [[ "$1" == "-y" ]] && YES=1
free() { df -h /System/Volumes/Data | awk 'NR==2{print $4}'; }
ask()  { (( YES )) && return 0; read -q "?$1 [y/N] "; local r=$?; echo; return $r; }
step() { print -P "\n%F{cyan}==> $1%f"; }

BEFORE=$(free)
print -P "%F{yellow}Free space before: $BEFORE%f"

step "Caches (npm, yarn, pip, uv, brew, browsers, ~/Library/Caches)"
rm -rf ~/.npm/_cacache ~/Library/Caches/* ~/.cache/uv ~/.cache/puppeteer \
       ~/.cache/pre-commit ~/.cache/pip 2>/dev/null
command -v brew >/dev/null && brew cleanup -s --prune=all >/dev/null 2>&1
command -v pnpm >/dev/null && pnpm store prune >/dev/null 2>&1

step "Xcode build data (DerivedData, DeviceSupport, old archives kept)"
rm -rf ~/Library/Developer/Xcode/DerivedData \
       ~/Library/Developer/Xcode/"iOS DeviceSupport" 2>/dev/null
xcrun simctl delete unavailable 2>/dev/null

step "Gradle cache"
rm -rf ~/.gradle/caches ~/.gradle/daemon 2>/dev/null

step "Logs and trash"
rm -rf ~/Library/Logs/* ~/.Trash/* 2>/dev/null

if ask "Delete project build folders in ~/projects (node_modules, build, Pods, .next, venv...)?"; then
  step "Project build folders"
  find ~/projects -xdev -type d \( -name node_modules -o -name .next -o -name Pods \
       -o -name .gradle -o -name DerivedData -o -name .venv -o -name venv \
       -o -name build -o -name 'build-*' \) -prune -print 2>/dev/null |
  while read -r d; do
    case "$(basename "$d")" in build|build-*)
      # skip build folders that contain files tracked by git
      if [[ -n "$(git -C "$(dirname "$d")" ls-files -- "$(basename "$d")" 2>/dev/null | head -1)" ]]; then
        echo "  skip (tracked in git): $d"; continue
      fi;;
    esac
    rm -rf "$d"
  done
fi

if ask "Delete ALL iOS simulators and simulator runtimes?"; then
  step "iOS simulators"
  xcrun simctl shutdown all 2>/dev/null
  xcrun simctl delete all 2>/dev/null
  xcrun simctl runtime delete all 2>/dev/null
fi

if ask "Delete Android emulators (~/.android/avd)?"; then
  step "Android emulators"
  rm -rf ~/.android/avd/* 2>/dev/null
fi

if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  if ask "Prune unused Docker images, containers and build cache (volumes kept)?"; then
    step "Docker"
    docker system prune -a -f
    docker builder prune -a -f
  fi
else
  echo "\n(Docker not running — skipped. Start Docker and rerun to clean it.)"
fi

print -P "\n%F{green}Done. Free space: $BEFORE -> $(free)%f"
echo "Tip: restart the Mac to also clear system temp files."
