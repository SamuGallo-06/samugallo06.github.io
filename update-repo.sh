#!/bin/bash
set -e
KEYID="D504C799A03C2B10B0CE90B628E74A863AE19A4C"
cd "$(dirname "$0")"

build_suite() {
  local DIST="$1"
  for ARCH in amd64 arm64; do
    DIR="dists/$DIST/main/binary-$ARCH"
    mkdir -p "$DIR"
    dpkg-scanpackages --arch "$ARCH" "pool/$DIST" /dev/null > "$DIR/Packages"
    dpkg-scanpackages --arch all   "pool/$DIST" /dev/null >> "$DIR/Packages"
    gzip -9 -k -f "$DIR/Packages"
  done

  # Per beta/dev: apt non li installa né aggiorna da solo se non richiesti
  local EXTRA=()
  if [ "$DIST" != "stable" ]; then
    EXTRA=(-o APT::FTPArchive::Release::NotAutomatic=yes
           -o APT::FTPArchive::Release::ButAutomaticUpgrades=yes)
  fi

  apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="Samuele" \
    -o APT::FTPArchive::Release::Label="Mio repo" \
    -o APT::FTPArchive::Release::Suite="$DIST" \
    -o APT::FTPArchive::Release::Codename="$DIST" \
    -o APT::FTPArchive::Release::Architectures="amd64 arm64" \
    -o APT::FTPArchive::Release::Components="main" \
    "${EXTRA[@]}" \
    release "dists/$DIST" > "dists/$DIST/Release"

  rm -f "dists/$DIST/Release.gpg" "dists/$DIST/InRelease"
  gpg --default-key "$KEYID" -abs -o "dists/$DIST/Release.gpg" "dists/$DIST/Release"
  gpg --default-key "$KEYID" --clearsign -o "dists/$DIST/InRelease" "dists/$DIST/Release"
}

for S in stable beta dev; do
  mkdir -p "pool/$S"
  build_suite "$S"
done
