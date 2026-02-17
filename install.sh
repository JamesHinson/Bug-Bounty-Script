#!/usr/bin/env bash


set -e

echo "======================================="
echo " Recon / Pentest Tools Auto Installer"
echo " Ubuntu System-Wide Setup"
echo "======================================="

# Must run as root
if [[ $EUID -ne 0 ]]; then
	echo "Run as root: sudo $0"
	exit 1
fi

echo "[*] Updating system..."
apt update -y
apt upgrade -y

echo "[*] Installing core dependencies..."
apt install -y \
	git curl wget unzip build-essential \
	python3 python3-pip python3-venv \
	ruby-full \
	golang \
	libcurl4-openssl-dev \
	libssl-dev \
	jq

# Ensure Go binaries go into system PATH
export GOPATH=/root/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin


########################################
# APT INSTALLABLE TOOLS
########################################

echo "[*] Installing APT-based tools..."

apt install -y \
	nmap \
	dirb \
	dnsenum \
	whois \
	nikto \
	whatweb


########################################
# RUBY TOOL (Wappalyzer CLI alternative)
########################################

echo "[*] Installing Wappalyzer CLI..."

gem install wappalyzer


########################################
# PYTHON TOOLS
########################################

echo "[*] Installing Python-base tools..."

pip3 install --break-system-packages \
	sublist3r \
	sqlmap


########################################
# XSSER (Not on PyPI — install from source)
########################################

echo "[*] Installing Xsser from GitHub..."

if [ ! -d "/opt/xsser" ]; then
    git clone https://github.com/epsylon/xsser.git /opt/xsser
    cd /opt/xsser
    python3 setup.py install
    ln -sf /opt/xsser/xsser /usr/local/bin/xsser
else
    echo "[*] Xsser already installed"
fi


########################################
# GO TOOLS
########################################

echo "[*] Installing Go-based tools..."

# Install latest Go if not present (Ubuntu repo often outdated)
if ! command -v go &> /dev/null; then
	echo "[*] Installing latest Go..."
	GO_VER="1.22.0"
	wget https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
	rm -rf /usr/local/go
	tar -C /usr/local -xzf go${GO_VER}.linux-amd64.tar.gz
	rm go${GO_VER}.linux-amd64.tar.gz
	export PATH=$PATH:/usr/local/go/bin
fi

# Install Go tools
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/owasp-amass/amass/v4/cmd/amass@latest

echo "[*] Updating Nuclei templates..."
/root/go/bin/nuclei -update-templates || true


########################################
# VERIFY INSTALL
########################################

echo
echo "======================================="
echo " Verifying tool installation..."
echo "======================================="

tools=(
	nmap dirb dnnsenum whois whatweb nikto
	wappalyzer sublist3r xsser sqlmap
	nuclei amass
)


for tool in "${tools[@]}"; do
	if command -v "$tool" &> /dev/null; then
		echo "[OK] $tool installed"
	else
		echo "[FAIL] $tool missing"
	fi
done

echo "[*] Cleaning up unnecessary packages and dependencies"
apt autoremove -y

echo
echo "======================================="
echo " Installation Complete"
echo " Tools available globally via PATH"
echo "======================================="
