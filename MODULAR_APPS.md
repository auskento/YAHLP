# Adding Modular Apps

This directory contains dynamically loaded app configurations.

## Structure
- apache-conf/apps/*.conf - Apache proxy configurations
- html/apps-icons/*.png - App icons

## Example: Adding Tdarr (code: tda)

1. Create apache-conf/apps/tda.conf with proxy configuration
2. Create html/apps-icons/tda.png with app icon (64x64)
3. Add tda to CUSTOM_APPS array in generate-html-menu.sh
4. Restart container

## Future: Dynamic Status Panels

When implemented, place metadata in apache-conf/apps/tda.json to enable status checking.
