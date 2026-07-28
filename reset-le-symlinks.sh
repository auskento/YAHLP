#!/bin/bash

# Reset Let's Encrypt certificate symlinks
# Scans archive folder and creates proper symlinks in live folder

set -e

ARCHIVE_DIR="/etc/letsencrypt/archive"
LIVE_DIR="/etc/letsencrypt/live"

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "Error: Archive directory not found: $ARCHIVE_DIR"
    exit 1
fi

echo "Resetting Let's Encrypt certificate symlinks..."
echo ""

RESET_COUNT=0

# Scan all domain folders in archive
for domain_archive in "$ARCHIVE_DIR"/*; do
    if [ ! -d "$domain_archive" ]; then
        continue
    fi

    domain=$(basename "$domain_archive")
    domain_live="$LIVE_DIR/$domain"

    echo "Processing domain: $domain"

    # Find the highest numbered cert version
    latest_cert=$(ls "$domain_archive"/cert*.pem 2>/dev/null | sort -V | tail -1)
    latest_privkey=$(ls "$domain_archive"/privkey*.pem 2>/dev/null | sort -V | tail -1)
    latest_chain=$(ls "$domain_archive"/chain*.pem 2>/dev/null | sort -V | tail -1)
    latest_fullchain=$(ls "$domain_archive"/fullchain*.pem 2>/dev/null | sort -V | tail -1)

    if [ -z "$latest_cert" ]; then
        echo "  ⚠ No certificate files found for $domain"
        continue
    fi

    # Create live directory if it doesn't exist
    mkdir -p "$domain_live"

    # Extract version number from filename (e.g., cert1.pem -> 1)
    cert_version=$(basename "$latest_cert" | sed 's/cert\([0-9]*\)\.pem/\1/')
    privkey_version=$(basename "$latest_privkey" | sed 's/privkey\([0-9]*\)\.pem/\1/')
    chain_version=$(basename "$latest_chain" | sed 's/chain\([0-9]*\)\.pem/\1/')
    fullchain_version=$(basename "$latest_fullchain" | sed 's/fullchain\([0-9]*\)\.pem/\1/')

    # Remove existing real files in live directory
    for file in cert.pem privkey.pem chain.pem fullchain.pem; do
        live_file="$domain_live/$file"
        if [ -f "$live_file" ] && [ ! -L "$live_file" ]; then
            echo "  Removing real file: $file"
            rm -f "$live_file"
        fi
    done

    # Remove existing symlinks
    for file in cert.pem privkey.pem chain.pem fullchain.pem; do
        live_file="$domain_live/$file"
        if [ -L "$live_file" ]; then
            rm -f "$live_file"
        fi
    done

    # Create symlinks to latest versions
    ln -s "../archive/$domain/cert${cert_version}.pem" "$domain_live/cert.pem"
    ln -s "../archive/$domain/privkey${privkey_version}.pem" "$domain_live/privkey.pem"
    ln -s "../archive/$domain/chain${chain_version}.pem" "$domain_live/chain.pem"
    ln -s "../archive/$domain/fullchain${fullchain_version}.pem" "$domain_live/fullchain.pem"

    echo "  ✓ Created symlinks to version $cert_version"
    ((RESET_COUNT++))
done

echo ""
echo "✓ Reset $RESET_COUNT domain certificate symlink(s)"
echo ""
echo "Verifying symlinks..."
find "$LIVE_DIR" -type l -name "*.pem" | while read link; do
    target=$(readlink "$link")
    if [ -f "$(dirname "$link")/$target" ] || [ -f "$(dirname "$(dirname "$link")")/$target" ]; then
        echo "  ✓ $link → $target"
    else
        echo "  ✗ BROKEN: $link → $target"
    fi
done
