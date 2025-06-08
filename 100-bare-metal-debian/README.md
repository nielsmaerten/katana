# Debian: Bare metal install

1. **Download Debian Netinst ISO:**  
   https://www.debian.org/distrib/netinst

1. **Create a Bootable USB Stick**  
   Use a tool like Rufus or `dd`.

1. **Boot and Start Automated Install**  
   - Boot from the USB stick.
   - At the boot menu, select **Automated installation**.
   - When prompted, enter the URL to the preseed file:  
      - Raw-file url to [./preseed.cfg](./preseed.cfg)
      - Or this short url: [https://go.niels.me/preseed](https://go.niels.me/preseed)

1. **Confirm Static IP**  
   Review and confirm the proposed IP configuration.

1. **Confirm Installation Target**  
   Review and confirm the proposed partition layout.

1. **Wait for Installation to Complete**  
   Once finished, connect via SSH. Keys will be imported from https://github.com/nielsmaerten.keys

