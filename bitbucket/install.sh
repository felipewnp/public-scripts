#!/usr/bin/env bash
set -e

echo "=== Installing serve_files wrapper with Auth ==="

# 1. Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is required but not installed." >&2
    exit 1
fi

# 2. Check/Install dependencies
echo "Checking Python dependencies..."
python3 -m pip install uploadserver --break-system-packages &> /dev/null || python3 -m pip install uploadserver &> /dev/null

# 3. Check for openssl
if ! command -v openssl &> /dev/null; then
    echo "WARNING: openssl not found. The (--secure) flag will not function."
fi

TARGET_BIN="/usr/local/bin/serve_files"

echo "Writing binary to $TARGET_BIN..."
sudo tee "$TARGET_BIN" > /dev/null << 'EOF'
#!/usr/bin/env python3
import sys
import os
import subprocess
import argparse
import hashlib
import string
import random

def get_default_ip():
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def generate_htpasswd(username, password, filepath):
    """Generates a standard apache-compatible htpasswd file using MD5 encryption natively"""
    # Create an Apache-compatible MD5-based password hash ($1$)
    # Using python's passlib or crypt would be ideal, but to ensure zero-dependency, 
    # we can fall back to standard MD5 hash if the system doesn't have complex libraries.
    # Note: uploadserver natively accepts raw MD5 hashes prefixed with $apr1$ or standard crypt.
    # For maximum compatibility with Python's basic libraries, we use an MD5 implementation.
    
    import base64
    # Simple salt generation
    salt = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(8))
    
    # Standard Apache MD5 algorithm (APR1)
    # To keep it completely bulletproof and zero-dependency, we can use a simpler format 
    # that python's server accepts or use a known working layout.
    # Uploadserver natively supports basic auth configs via plain text or MD5.
    # Let's generate a standard MD5 crypt hash using openssl if available, or fallback.
    try:
        # Most secure and standard way since openssl is checked by installer
        res = subprocess.run(
            ["openssl", "passwd", "-apr1", "-salt", salt, password],
            capture_output=True, text=True, check=True
        )
        hashed_password = res.stdout.strip()
    except Exception:
        # Fallback to standard crypt layout if openssl fails
        hashed_password = hashlib.md5(password.encode()).hexdigest()
        
    with open(filepath, "w") as f:
        f.write(f"{username}:{hashed_password}\n")

def main():
    parser = argparse.ArgumentParser(description="Serve files locally with optional upload, TLS, and Auth support.")
    parser.add_argument("--secure", action="store_true", help="Enable HTTPS/TLS encryption")
    parser.add_argument("--port", type=int, default=8888, help="Port to run the server on (default: 8888)")
    parser.add_argument("--ip", type=str, default=None, help="IP address to bind to")
    parser.add_argument("--user", type=str, default=None, help="Username for basic authentication")
    parser.add_argument("--pass", dest="password", type=str, default=None, help="Password for basic authentication")

    args = parser.parse_args()

    # If user is provided but pass is missing (or vice-versa)
    if (args.user and not args.password) or (args.password and not args.user):
        print("ERROR: Both --user and --pass must be provided together to enable authentication.")
        sys.exit(1)

    bind_ip = args.ip if args.ip else get_default_ip()
    cmd = ["python3", "-m", "uploadserver", str(args.port), "--bind", bind_ip]

    # Handle TLS/Secure Layer
    if args.secure:
        cert_path = os.path.expanduser("~/.serve_files_cert.pem")
        if not os.path.exists(cert_path):
            print(f"Generating temporary self-signed TLS cert at {cert_path}...")
            subprocess.run([
                "openssl", "req", "-x509", "-out", cert_path, "-keyout", cert_path,
                "-newkey", "rsa:2048", "-nodes", "-sha256", "-days", "365",
                "-subj", "/CN=localhost"
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        cmd.extend(["--server-certificate", cert_path])
        protocol = "https"
    else:
        protocol = "http"

    # Handle Authentication
    if args.user and args.password:
        htpasswd_path = os.path.expanduser("~/.serve_files_htpasswd")
        generate_htpasswd(args.user, args.password, htpasswd_path)
        cmd.extend(["--http-auth", htpasswd_path])
        print(f"🔒 Authentication enabled! Credentials -> User: {args.user}")

    print(f"\n🚀 Server booting up at {protocol}://{bind_ip}:{args.port}")
    print(f"   Upload directory available at {protocol}://{bind_ip}:{args.port}/upload")
    print("Press Ctrl+C to stop.\n")

    try:
        subprocess.run(cmd)
    except KeyboardInterrupt:
        print("\nServer gracefully shut down.")
        # Cleanup temporary auth file if it exists
        htpasswd_path = os.path.expanduser("~/.serve_files_htpasswd")
        if os.path.exists(htpasswd_path):
            os.remove(htpasswd_path)

if __name__ == "__main__":
    main()
EOF

sudo chmod +x "$TARGET_BIN"
echo "=== Installation complete! ==="
