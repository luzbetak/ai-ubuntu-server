#!/bin/bash
# ============================================================================
# fix-nvidia-driver.sh
# Roll back broken NVIDIA driver 550 to 535 and pin kernel 6.14.0-37-generic
# RTX 3060 | Ubuntu 24.04
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SAFE_KERNEL="6.14.0-37-generic"
DRIVER_VERSION="535"

# --- Must run as root ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Run this script as root (sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}  NVIDIA Driver Rollback: 550 → 535        ${NC}"
echo -e "${YELLOW}  Safe Kernel: ${SAFE_KERNEL}              ${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""

# --- Step 1: Remove broken nvidia-driver-550 ---
echo -e "${GREEN}[1/5] Removing broken NVIDIA 550 driver...${NC}"
apt remove --purge -y \
    nvidia-driver-550 \
    nvidia-dkms-550 \
    nvidia-kernel-source-550 \
    nvidia-kernel-common-550 \
    nvidia-firmware-550-550.163.01 \
    nvidia-utils-550 \
    nvidia-compute-utils-550 \
    libnvidia-cfg1-550 \
    libnvidia-common-550 \
    libnvidia-compute-550 \
    libnvidia-decode-550 \
    libnvidia-encode-550 \
    libnvidia-extra-550 \
    libnvidia-fbc1-550 \
    libnvidia-gl-550 \
    xserver-xorg-video-nvidia-550 2>/dev/null || true

echo -e "${GREEN}[2/5] Cleaning up residual packages...${NC}"
apt autoremove --purge -y 2>/dev/null || true
apt --fix-broken install -y 2>/dev/null || true

# --- Step 2: Reinstall nvidia-driver-535 ---
echo -e "${GREEN}[3/5] Installing NVIDIA driver ${DRIVER_VERSION}...${NC}"
apt install -y nvidia-driver-${DRIVER_VERSION}

# --- Step 3: Pin boot kernel to 6.14.0-37-generic ---
echo -e "${GREEN}[4/5] Setting default boot kernel to ${SAFE_KERNEL}...${NC}"

GRUB_ENTRY="Advanced options for Ubuntu>Ubuntu, with Linux ${SAFE_KERNEL}"

cp /etc/default/grub /etc/default/grub.bak.$(date +%Y%m%d%H%M%S)
sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"${GRUB_ENTRY}\"|" /etc/default/grub
update-grub

# --- Step 4: Hold kernel 6.17 to prevent auto-upgrade issues ---
echo -e "${GREEN}[5/5] Holding kernel 6.17 packages to prevent future conflicts...${NC}"
apt-mark hold \
    linux-image-6.17.0-14-generic \
    linux-modules-6.17.0-14-generic \
    linux-modules-extra-6.17.0-14-generic \
    linux-headers-6.17.0-14-generic \
    linux-hwe-6.17-headers-6.17.0-14 2>/dev/null || true

# --- Summary ---
echo ""
echo -e "${YELLOW}============================================${NC}"
echo -e "${GREEN}  Done! Summary:${NC}"
echo -e "${GREEN}  • Removed NVIDIA 550 (broken on 6.17)${NC}"
echo -e "${GREEN}  • Installed NVIDIA ${DRIVER_VERSION}${NC}"
echo -e "${GREEN}  • Default boot kernel: ${SAFE_KERNEL}${NC}"
echo -e "${GREEN}  • Kernel 6.17 packages held${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""
echo -e "${YELLOW}  Reboot now to apply changes:${NC}"
echo -e "${YELLOW}    sudo reboot${NC}"
echo ""
echo -e "${NC}After reboot, verify with: nvidia-smi"
