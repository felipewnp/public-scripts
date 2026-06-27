# serve_files 🚀

A lightweight, zero-dependency global CLI tool to securely serve, download, and upload files across isolated, routed private networks without relying on internet connectivity.

This project was built as an offline-first alternative to tools like **croc** or **e2ecp**, eliminating the need for public relay signaling/discovery servers while adding native TLS encryption and basic authentication over standard HTTP routing layers.

---

## Key Features

- **Instant Installation**: Deploy globally using a single bash pipe command.
- **Smart Dynamic Binding**: Automatically discovers the network interface routing traffic to your target subnets.
- **Native P2P Uploads**: Enables bidirectional file sharing (`/upload` endpoint) without extra server software.
- **On-the-Fly TLS Encryption**: Generates sandboxed temporary self-signed SSL certificates automatically to stop credential sniffing.
- **Basic Authentication**: Built-in credential locking protecting both the viewing directory and the upload endpoint.

---

## Installation

Deploy `serve_files` as a global system binary by running the remote installer script:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/yourrepo/main/install.sh | bash
```

> **Note**: Replace the URL above with the actual raw URL to your installer script.

---

## Usage Guide

The binary can be invoked from any folder on your filesystem. It will only host files inside the current working directory.

### 1. Basic Server (Zero Configuration)
Starts an unencrypted server on the auto-detected network IP at port `8888`:
```bash
serve_files
```

### 2. High-Security Deployment (TLS + Authentication + Custom Port)
Locks down the connection with end-to-end encryption, credentials, and custom port configuration:
```bash
serve_files --secure --port=9999 --user=admin --pass=secret123
```

### 3. Explicit IP Binding
Force the server to bind to a specific loopback or interface address:
```bash
serve_files --ip=127.0.0.1 --port=8080
```

---

## Command Line Arguments

| Argument | Description | Default |
| :--- | :--- | :--- |
| `--secure` | Enables HTTPS/TLS using a secure self-signed certificate. | Disabled (HTTP) |
| `--port` | The port the web server will listen on. | `8888` |
| `--ip` | Explicitly overrides interface auto-detection. | Auto-Detected IP |
| `--user` | Username required to access the server endpoints. | None |
| `--password` | Password matching the defined username. | None |

> **Note**: Both `--user` and `--password` must be provided together to enable authentication.

---

## Interaction from Remote Clients

Once your server is up and running (e.g., at `https://172.31.136.26:9999`), devices on the other routed subnet can interact with it instantly using standard networking tools.

### Via Web Browser

Open your browser and navigate to:
- **To Browse/Download**: `https://172.31.136.26:9999`
- **To Upload Files**: `https://172.31.136.26:9999/upload`

*Note: Since the server utilizes an internal self-signed TLS certificate, browsers will display a privacy warning. Click **Advanced** and select **Proceed** to access the interface.*

### Via Command Line (`curl`)

#### Download a file securely:
```bash
curl -k -u "admin:secret123" -O https://172.31.136.26:9999/target_file.zip
```

#### Upload a file securely:
```bash
curl -k -u "admin:secret123" -X POST https://172.31.136.26:9999/upload -F "files=@my_local_document.pdf"
```

*(The `-k` or `--insecure` flag instructs curl to trust the self-signed certificate connection).*

### Via Another Terminal (Local Testing)

To test the server locally from the same machine:

```bash
# Browse files
curl http://127.0.0.1:8888

# Upload a file
curl -X POST http://127.0.0.1:8888/upload -F "files=@test.txt"
```

---

## Architecture Details

- **Security Isolation**: Temporary TLS certificates (`.serve_files_cert.pem`) are generated out-of-root inside the `/tmp` system directory. This prevents unauthorized clients from downloading your server's private key.
- **Graceful Shutdown**: Pressing `Ctrl+C` triggers an explicit signal handler that gracefully closes the sockets and deletes transient environment artifacts.
- **Zero Dependencies**: The installer only requires `python3` and `openssl` (optional for TLS). All other functionality is built into Python's standard library.
- **Authentication Storage**: When authentication is enabled, credentials are passed directly to the uploadserver module without being written to disk, minimizing security risks.

---

## Troubleshooting

### Common Issues

#### "python3 is required but not installed"
Install Python 3 on your system:
```bash
# Ubuntu/Debian
sudo apt install python3 python3-pip

# macOS
brew install python3

# Windows (WSL or native)
# Download from python.org
```

#### "openssl not found"
The `--secure` flag requires OpenSSL. Install it via:
```bash
# Ubuntu/Debian
sudo apt install openssl

# macOS
brew install openssl

# Windows
# Download from slproweb.com/products/Win32OpenSSL.html
```

#### Permission Denied
If you see `Permission denied` when running `serve_files`, ensure the binary is executable:
```bash
sudo chmod +x /usr/local/bin/serve_files
```

#### Port Already in Use
Specify a different port:
```bash
serve_files --port=9000
```

---

## Security Considerations

- **Self-Signed Certificates**: The generated certificates are self-signed and not trusted by browsers by default. This is acceptable for internal/offline networks but should not be used in production internet-facing environments.
- **Credential Transmission**: When using `--secure`, credentials are transmitted over an encrypted TLS tunnel, protecting them from network sniffing.
- **Temporary Artifacts**: All generated certificates are stored in `/tmp` and are automatically cleaned up on system reboot or server shutdown.
- **Network Exposure**: By default, the server binds to your network interface IP, making it accessible to anyone on your local network. Use `--ip=127.0.0.1` to restrict access to localhost only.

---

## Uninstallation

To remove the `serve_files` binary:

```bash
sudo rm /usr/local/bin/serve_files
```

To remove any leftover temporary certificates:

```bash
rm -f /tmp/.serve_files_cert.pem
```

---

## Contributing

Contributions are welcome! Please submit issues and pull requests on the [GitHub repository](https://github.com/yourusername/yourrepo).

### Development Setup

1. Fork the repository
2. Make your changes to the installer script
3. Test locally using:
   ```bash
   ./install.sh
   serve_files --help
   ```
4. Submit a pull request with a clear description of your changes

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Built on top of the excellent [uploadserver](https://github.com/DogukanGundogdu/uploadserver) Python package
- Inspired by the need for offline-first file sharing in air-gapped environments
- Special thanks to all contributors and users who provided feedback

---

## Support

For questions, issues, or feature requests:
- Open an issue on [GitHub Issues](https://github.com/yourusername/yourrepo/issues)
- Contact the maintainers via [email](mailto:maintainer@example.com)

---

**Happy file sharing! 📁✨**
