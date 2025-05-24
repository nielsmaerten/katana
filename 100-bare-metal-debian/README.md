# Bare-Metal Debian Automated Installation

Perform an automated, bare-metal installation of Debian using a preseed configuration.

## Steps

1. **Download Debian Netinst ISO**  
   Get the latest image from: https://www.debian.org/distrib/netinst

2. **Create a Bootable USB Stick**  
   Use a tool like Rufus or `dd` to write the ISO to a USB drive.

3. **Prepare the Target System**  
   Disconnect all drives except the one you want to install Debian on.
   The entire drive will be used by default.

4. **Boot and Start Automated Install**  
   - Boot from the USB stick.
   - At the boot menu, select **Automated installation**.
   - When prompted, enter the URL to the preseed file:  
     [https://go.niels.me/preseed](https://go.niels.me/preseed)

5. **Confirm Partition Layout**  
   Review and confirm the proposed partitioning.

6. **Wait for Installation to Complete**  
   Once finished, SSH access will be available using your GitHub SSH keys.

