#!/bin/bash

# Generate index.html based on STYLE setting to redirect to the appropriate dashboard

OUTPUT_FILE="/var/www/html/index.html"
CONFIG_FILE="/etc/apache2/env.conf"

# Default to classic
STYLE="classic"

# Read STYLE from config file
if [ -f "$CONFIG_FILE" ]; then
    STYLE=$(grep "^STYLE=" "$CONFIG_FILE" | sed 's/STYLE="//' | sed 's/"//' | head -1)
    if [ -z "$STYLE" ]; then
        STYLE="classic"
    fi
fi

# Determine target dashboard
case "$STYLE" in
    modern)
        TARGET="/dashboard.html"
        ;;
    classic|*)
        TARGET="/index.html.original"
        ;;
esac

# Generate index.html with redirect
cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=REDIRECT_TARGET">
    <title>Redirecting...</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #08090c;
            color: #e9ecf2;
            font-family: system-ui, -apple-system, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
        }
        .container {
            text-align: center;
        }
        .spinner {
            border: 3px solid rgba(255,255,255,.1);
            border-top: 3px solid #3aa3e0;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="spinner"></div>
        <p>Loading dashboard...</p>
        <script>
            // Fallback redirect in case meta refresh doesn't work
            window.location.href = 'REDIRECT_TARGET';
        </script>
    </div>
</body>
</html>
EOF

# Replace the redirect target placeholder
sed -i "s|REDIRECT_TARGET|${TARGET}|g" "$OUTPUT_FILE"

echo "✓ Style redirect generated: $STYLE → $TARGET"
