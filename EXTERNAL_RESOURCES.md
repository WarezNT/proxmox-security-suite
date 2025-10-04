# External Resources & Official Documentation

This document provides links to official Proxmox documentation, community resources, and related tools for deeper understanding and advanced configuration.

## 📚 Official Proxmox Documentation

### Proxmox VE Core Documentation
- **[Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)** - Main documentation hub
- **[Proxmox VE Admin Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html)** - Comprehensive administration guide
- **[Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)** - REST API reference

### Firewall & Network Security
- **[Proxmox Firewall](https://pve.proxmox.com/wiki/Firewall)** - Firewall configuration and management
  - Datacenter-level firewall rules
  - Node-level firewall rules
  - VM/Container-level firewall rules
  - Security groups and IP sets
- **[Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)** - Network setup and bridging
- **[Linux Bridge](https://pve.proxmox.com/wiki/Network_Configuration#sysadmin_network_configuration)** - Bridge configuration for VMs/LXCs
- **[VLANs](https://pve.proxmox.com/wiki/Network_Configuration#_vlan_802_1q)** - VLAN-aware bridges

### LXC Containers
- **[Linux Container](https://pve.proxmox.com/wiki/Linux_Container)** - LXC fundamentals
- **[Proxmox Container Toolkit](https://pve.proxmox.com/wiki/Proxmox_Container_Toolkit)** - pct command reference
- **[Unprivileged LXC](https://pve.proxmox.com/wiki/Unprivileged_LXC_containers)** - Security best practices for containers

### Security & Authentication
- **[User Management](https://pve.proxmox.com/wiki/User_Management)** - Users, groups, and permissions
- **[Two-Factor Authentication](https://pve.proxmox.com/wiki/Two-Factor_Authentication)** - 2FA setup (TOTP, U2F)
- **[Certificate Management](https://pve.proxmox.com/wiki/Certificate_Management)** - SSL/TLS certificates
- **[SSH Key Authentication](https://pve.proxmox.com/wiki/SSH_Public_Key_Authentication)** - SSH security

### Backup & Recovery
- **[Backup and Restore](https://pve.proxmox.com/wiki/Backup_and_Restore)** - Backup strategies
- **[Proxmox Backup Server](https://pbs.proxmox.com/docs/)** - PBS documentation
- **[vzdump](https://pve.proxmox.com/wiki/VZDump)** - Backup tool reference

### Monitoring & Notifications
- **[Email Notification Configuration](https://pve.proxmox.com/wiki/Email_Notification_Configuration)** - Setup email alerts
  - SMTP relay configuration
  - Test notification emails
  - Alert templates
- **[Monitoring](https://pve.proxmox.com/wiki/Monitoring)** - Built-in monitoring tools
- **[Performance Monitoring](https://pve.proxmox.com/wiki/Performance_Monitoring)** - Performance analysis

---

## 🔐 Security Tools Documentation

### Fail2Ban
- **[Fail2Ban Official Wiki](https://github.com/fail2ban/fail2ban/wiki)** - Complete Fail2Ban documentation
- **[Fail2Ban Manual](https://fail2ban.readthedocs.io/)** - Configuration and filters
- **[Custom Filters Guide](https://www.fail2ban.org/wiki/index.php/HOWTO_fail2ban_with_OpenVZ)** - Creating custom filters
- **[Proxmox with Fail2Ban](https://forum.proxmox.com/threads/fail2ban-with-proxmox.19272/)** - Community discussion

### iptables & Firewall
- **[iptables Tutorial](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)** - Complete iptables guide
- **[Netfilter Documentation](https://www.netfilter.org/documentation/)** - Linux firewall framework
- **[NAT Configuration](https://www.karlrupp.net/en/computer/nat_tutorial)** - Network Address Translation guide

### SSH Hardening
- **[Mozilla OpenSSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)** - SSH security best practices
- **[ssh-audit](https://github.com/jtesta/ssh-audit)** - SSH configuration auditing
- **[SSHD Config Guide](https://www.ssh.com/academy/ssh/sshd_config)** - sshd_config reference

---

## 🌐 Networking Components

### Tailscale VPN
- **[Tailscale Documentation](https://tailscale.com/kb/)** - Official knowledge base
- **[Tailscale on Proxmox](https://tailscale.com/kb/1133/proxmox/)** - Proxmox-specific setup
- **[Access Control Lists](https://tailscale.com/kb/1018/acls/)** - Tailscale ACL configuration
- **[Exit Nodes](https://tailscale.com/kb/1103/exit-nodes/)** - Using Proxmox as exit node
- **[Subnet Routers](https://tailscale.com/kb/1019/subnets/)** - Expose internal networks

### Nginx Proxy Manager
- **[NPM Official Docs](https://nginxproxymanager.com/)** - Main documentation
- **[NPM Setup Guide](https://nginxproxymanager.com/setup/)** - Installation instructions
- **[Proxy Hosts](https://nginxproxymanager.com/guide/#proxy-hosts)** - Configuring reverse proxy
- **[SSL Certificates](https://nginxproxymanager.com/guide/#ssl-certificates)** - Let's Encrypt integration
- **[Advanced Configuration](https://nginxproxymanager.com/advanced-config/)** - Custom Nginx configs

### Cloudflare
- **[Cloudflare DNS Docs](https://developers.cloudflare.com/dns/)** - DNS configuration
- **[Cloudflare SSL/TLS](https://developers.cloudflare.com/ssl/)** - SSL/TLS modes and setup
- **[Origin CA Certificates](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/)** - Free SSL for origin
- **[Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)** - Alternative to port forwarding
- **[Security Settings](https://developers.cloudflare.com/fundamentals/get-started/concepts/security/)** - DDoS, WAF, firewall

---

## 🛡️ Security Standards & Benchmarks

### CIS Benchmarks
- **[CIS Debian 12 Benchmark](https://www.cisecurity.org/benchmark/debian_linux)** - Industry security standard
- **[CIS Controls](https://www.cisecurity.org/controls)** - Implementation guide
- **[Lynis Security Scanner](https://cisofy.com/lynis/)** - Automated CIS compliance checking

### Security Hardening Guides
- **[Debian Security Manual](https://www.debian.org/doc/manuals/securing-debian-manual/)** - Debian security guide
- **[Linux Kernel Hardening](https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project)** - Kernel security
- **[systemd Hardening](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing)** - Service sandboxing

---

## 📊 Monitoring & Logging

### Log Management
- **[rsyslog Documentation](https://www.rsyslog.com/doc/)** - Centralized logging
- **[Logwatch Manual](https://sourceforge.net/projects/logwatch/)** - Log analysis tool
- **[journalctl Guide](https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs)** - systemd logs

### Monitoring Solutions
- **[Prometheus](https://prometheus.io/docs/introduction/overview/)** - Metrics collection
- **[Grafana](https://grafana.com/docs/)** - Visualization and dashboards
- **[Netdata](https://learn.netdata.cloud/)** - Real-time monitoring
- **[Zabbix](https://www.zabbix.com/documentation/current/en/manual)** - Enterprise monitoring

### Proxmox Monitoring
- **[PVE Monitoring via SNMP](https://pve.proxmox.com/wiki/SNMP)** - SNMP configuration
- **[Proxmox Exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)** - Prometheus integration
- **[pvesh](https://pve.proxmox.com/wiki/Proxmox_VE_API#Using_the_shell_.28pvesh.29)** - CLI API tool for monitoring

---

## 🔧 System Administration Tools

### Package Management
- **[APT User's Guide](https://www.debian.org/doc/manuals/apt-guide/)** - Debian package management
- **[Unattended Upgrades](https://wiki.debian.org/UnattendedUpgrades)** - Automatic security updates
- **[apt-listchanges](https://packages.debian.org/stable/apt-listchanges)** - Package change notifications

### Backup Tools
- **[Borg Backup](https://borgbackup.readthedocs.io/)** - Deduplicating backup
- **[Restic](https://restic.readthedocs.io/)** - Modern backup program
- **[Duplicity](http://duplicity.nongnu.org/)** - Encrypted backup to cloud

### Performance Analysis
- **[htop](https://htop.dev/)** - Interactive process viewer
- **[iotop](https://guichaz.free.fr/iotop/)** - I/O monitoring
- **[nethogs](https://github.com/raboof/nethogs)** - Network bandwidth per process
- **[ncdu](https://dev.yorhel.nl/ncdu)** - Disk usage analyzer

---

## 📖 Community Resources

### Forums & Communities
- **[Proxmox Forum](https://forum.proxmox.com/)** - Official community forum
- **[r/Proxmox](https://www.reddit.com/r/Proxmox/)** - Reddit community
- **[r/homelab](https://www.reddit.com/r/homelab/)** - Homelab enthusiasts
- **[ServeTheHome Forums](https://forums.servethehome.com/)** - Server hardware & software

### Tutorials & Guides
- **[Proxmox Helper Scripts](https://tteck.github.io/Proxmox/)** - Community scripts by tteck
- **[TechnoTim Proxmox Guides](https://docs.technotim.live/posts/proxmox-cloud-init/)** - Popular homelab guides
- **[Learn Linux TV Proxmox Series](https://www.learnlinux.tv/tag/proxmox/)** - Video tutorials
- **[DB Tech Proxmox Playlist](https://www.youtube.com/c/DBTechYT)** - YouTube tutorials

### Security Resources
- **[OWASP](https://owasp.org/)** - Web application security
- **[SANS Reading Room](https://www.sans.org/reading-room/)** - Security papers
- **[CVE Database](https://cve.mitre.org/)** - Common vulnerabilities
- **[Debian Security Tracker](https://security-tracker.debian.org/)** - Debian security advisories

---

## 🛠️ Testing & Validation

### Security Testing Tools
- **[Nmap](https://nmap.org/book/man.html)** - Network scanning
- **[OpenVAS](https://www.openvas.org/)** - Vulnerability scanner
- **[Nikto](https://cirt.net/Nikto2)** - Web server scanner
- **[Lynis](https://cisofy.com/lynis/)** - Security auditing
- **[testssl.sh](https://testssl.sh/)** - SSL/TLS testing

### Network Testing
- **[iperf3](https://iperf.fr/)** - Network performance testing
- **[mtr](https://www.bitwizard.nl/mtr/)** - Network diagnostic
- **[tcpdump](https://www.tcpdump.org/)** - Packet analyzer
- **[Wireshark](https://www.wireshark.org/)** - Network protocol analyzer

---

## 📝 Configuration Examples

### Sample Configurations Repository
Our project includes working examples of:
- Proxmox firewall rules
- iptables NAT configurations
- Fail2Ban filters for Proxmox
- systemd service units
- Monitoring scripts

**Location**: All scripts in this repository are production-ready examples with inline comments explaining each configuration option.

### Related Projects
- **[HomeSecExplorer/Proxmox-Hardening-Guide](https://github.com/HomeSecExplorer/Proxmox-Hardening-Guide)** - CIS Benchmark-based manual hardening guide
- **[tteck/Proxmox](https://github.com/tteck/Proxmox)** - Helper scripts for Proxmox VE

---

## 🎓 Learning Resources

### Linux Fundamentals
- **[Linux Journey](https://linuxjourney.com/)** - Interactive Linux learning
- **[The Linux Documentation Project](https://tldp.org/)** - Comprehensive guides
- **[Bash Guide](https://mywiki.wooledge.org/BashGuide)** - Shell scripting

### Networking Basics
- **[Computer Networking: A Top-Down Approach](https://gaia.cs.umass.edu/kurose_ross/index.php)** - Networking fundamentals
- **[Practical Networking](https://www.practicalnetworking.net/)** - Visual networking guides
- **[Subnet Calculator](https://www.subnet-calculator.com/)** - IP addressing tool

### Virtualization Concepts
- **[KVM Documentation](https://www.linux-kvm.org/page/Documents)** - KVM hypervisor
- **[LXC Documentation](https://linuxcontainers.org/lxc/documentation/)** - Linux containers
- **[QEMU Documentation](https://www.qemu.org/documentation/)** - Machine emulator

---

## 📞 Getting Help

### Documentation Order
When troubleshooting, follow this order:
1. **This repository's documentation** - Check README, QUICKSTART, and inline script comments
2. **Proxmox Wiki** - Official documentation for Proxmox-specific issues
3. **Component documentation** - Check docs for specific tools (Fail2Ban, Tailscale, etc.)
4. **Community forums** - Search existing threads or ask new questions
5. **GitHub Issues** - Report bugs or request features in this repository

### Reporting Issues
When seeking help, include:
- ✅ Proxmox VE version (`pveversion -v`)
- ✅ Relevant error messages from logs
- ✅ Steps to reproduce the issue
- ✅ What you've already tried
- ✅ Output of diagnostic commands

### Contributing
Found a broken link or want to add a resource? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

**Last Updated**: October 2025  
**Maintained by**: Proxmox Security Suite contributors
