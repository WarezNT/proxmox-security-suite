# Proxmox Security Suite

**Prima și singura suită completă de securitate automată pentru Proxmox VE** - De la zero la securizat în 15 minute, fără expertiză de securitate necesară.

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-8.x-orange)](https://www.proxmox.com/)
[![Automation](https://img.shields.io/badge/automation-100%25-blue)](README.md)

---

## 🌟 De Ce Acest Proiect?

Spre deosebire de ghidurile manuale de hardening sau scripturile parțiale de securitate, aceasta este **singura suită completă de automatizare a securității** pentru Proxmox:

| Caracteristică | Proxmox Security Suite | Alternative |
|----------------|------------------------|-------------|
| **Automatizare Completă** | ✅ Instalare cu o comandă | ❌ Manual sau minimal |
| **Monitoring în Timp Real** | ✅ Serviciu systemd + alerte | ❌ Nu există |
| **Fail2Ban Integration** | ✅ Setup automat + filtre Proxmox | ❌ Nu inclus |
| **Firewall Container** | ✅ Reguli automate per-LXC | ❌ Doar manual |
| **Actualizări Automate** | ✅ Management securitate | ❌ Nu inclus |
| **Testare Securitate** | ✅ Teste basic + avansate | ❌ Doar audit |
| **Integrare Tailscale** | ✅ Model VPN built-in | ❌ Nu acoperit |
| **Integrare NPM** | ✅ Securitate reverse proxy | ❌ Nu acoperit |
| **Management Unificat** | ✅ Comandă `proxmox-security` | ❌ Pași multipli manuali |

**Poziționare:** Suita de securitate turnkey care hardizează, monitorizează, actualizează și testează infrastructura Proxmox cu o singură comandă.

---

## 📋 Cuprins

- [Prezentare Generală](#prezentare-generală)
- [Arhitectura de Securitate](#arhitectura-de-securitate)
- [Instalare Rapidă](#instalare-rapidă)
- [Scripturi Incluse](#scripturi-incluse)
- [Configurare Detaliată](#configurare-detaliată)
- [Utilizare](#utilizare)
- [Testare Securitate](#testare-securitate)
- [Monitorizare și Alerting](#monitorizare-și-alerting)
- [Troubleshooting](#troubleshooting)
- [Resurse Externe](#resurse-externe)

## 🎯 Prezentare Generală

Acest set de scripturi oferă o soluție completă pentru securizarea unei infrastructuri Proxmox VE care include:

- **Proxmox VE**: Platforma de virtualizare principală
- **Nginx Proxy Manager (NPM)**: Reverse proxy pentru servicii publice
- **Tailscale VPN**: Acces securizat pentru management
- **Cloudflare**: DNS și SSL/TLS management

### 🏗️ Arhitectura de Securitate

```
Internet → Cloudflare → Proxmox (YOUR_PUBLIC_IP) → NPM (10.10.0.2) → Services
                                ↓
                          Tailscale VPN (YOUR_TAILSCALE_IP) → Management Access
```

**Principii de securitate implementate:**
- ✅ Separarea traficului public de cel de management
- ✅ Acces la management doar prin Tailscale VPN
- ✅ Firewall pe multiple nivele (Proxmox + Container + iptables)
- ✅ Monitorizare în timp real și alerting
- ✅ Actualizări automate de securitate
- ✅ Backup-uri automate de configurații

## 🚀 Instalare Rapidă

### Pas 1: Descărcarea Scripturilor

```bash
# Pe serverul Proxmox
cd /tmp
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/setup.sh
chmod +x setup.sh
```

### Pas 2: Instalarea Completă

```bash
sudo ./setup.sh
```

Acest script va instala și configura automat:
- Fail2Ban pentru protecție împotriva atacurilor brute-force
- Unattended-upgrades pentru actualizări automate de securitate
- Logwatch pentru monitorizarea log-urilor
- Scripturi de monitoring și alerting
- Configurări SSH hardening
- Serviciu de monitorizare în timp real

### Pas 3: Configurarea Email-urilor

După instalare, actualizați adresele de email în:

```bash
# Fail2Ban
sudo nano /etc/fail2ban/jail.local

# Logwatch  
sudo nano /etc/logwatch/conf/logwatch.conf

# Unattended Upgrades
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

### Pas 4: Pornirea Serviciilor

```bash
# Pornirea monitoring-ului de securitate
sudo systemctl start proxmox-security-monitor

# Verificarea status-ului
proxmox-security status
```

## 📦 Scripturi Incluse

### 1. `setup.sh`
**Scriptul principal de instalare**

- Descarcă toate scripturile din folderul `scripts/`
- Instalează toate dependențele necesare
- Configurează serviciile de securitate
- Creează scripturile de management
- Configurează monitoring-ul automat

```bash
sudo ./setup.sh
```

### 2. `scripts/security-hardening.sh`
**Script interactiv pentru hardening-ul sistemului**

Oferă opțiuni pentru:
- Configurarea Fail2Ban
- Firewall la nivel de container
- Monitoring rețea
- Securizarea backup-urilor
- Hardening SSH
- Monitoring log-uri

```bash
sudo proxmox-security-hardening
# sau
sudo ./security-hardening.sh
```

### 3. `scripts/security-monitor.sh`
**Monitoring în timp real și alerting**

Funcționalități:
- Monitorizarea conexiunilor suspecte
- Detectarea încercărilor de autentificare eșuate
- Verificarea integrității sistemului
- Alerting prin email și syslog
- Generarea de rapoarte de securitate

```bash
# Pornire monitoring
sudo proxmox-security monitor start

# Status monitoring
sudo proxmox-security monitor status

# Generare raport
sudo proxmox-security monitor report
```

### 4. `scripts/security-updates.sh`
**Management automat al actualizărilor de securitate**

Opțiuni:
- Verificarea actualizărilor disponibile
- Aplicarea selectivă a update-urilor (security/proxmox/all)
- Actualizarea container-elor
- Backup automat înainte de update
- Rollback la configurații anterioare

```bash
# Verificare actualizări
sudo proxmox-security update check

# Aplicare actualizări de securitate
sudo proxmox-security update security

# Actualizare container-e
sudo proxmox-security update containers
```

### 5. `scripts/security-test.sh`
**Testare de securitate de bază**

Testează:
- Accesibilitatea porturilor de management
- Funcționalitatea serviciilor web
- Configurația SSL/TLS
- Izolarea Tailscale

```bash
# Test de la un server extern
./scripts/security-test.sh YOUR_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP
```

### 5. `scripts/advanced-security-test.sh`
**Testare avansată de penetrare**

Include:
- Scanare porturi cu nmap
- Testare vulnerabilități web cu nikto
- Analiză SSL/TLS detaliată
- Verificare headers de securitate HTTP
- Detectarea rate limiting-ului

```bash
# Test de la server extern
./scripts/advanced-security-test.sh YOUR_PUBLIC_IP yourdomain.com
```

## ⚙️ Configurare Detaliată

### Configurarea Proxmox Firewall

> 📖 **Documentație Detaliată**: [Proxmox Firewall Guide](https://pve.proxmox.com/wiki/Firewall) - Configurare firewall multi-nivel, security groups, și IP sets

```bash
# /etc/pve/firewall/cluster.fw
[IPSET management]
192.168.1.100 # Example admin IP 1
192.168.1.101 # Example admin IP 2
# Add your trusted IPs here

[RULES]
# Servicii publice
IN ACCEPT -source 0.0.0.0/0 -dport 80 -proto tcp
IN ACCEPT -source 0.0.0.0/0 -dport 443 -proto tcp

# Management doar din Tailscale
IN ACCEPT -source +management -dport 22,8006 -proto tcp
IN DROP -dport 22,8006 -proto tcp -log warning
```

**Resurse Utile**:
- [Firewall Configuration Examples](https://pve.proxmox.com/wiki/Firewall#_examples) - Exemple practice
- [Security Groups](https://pve.proxmox.com/wiki/Firewall#pve_firewall_security_groups) - Grupare reguli reutilizabile


### Configurarea NPM Container Firewall

> 📖 **Documentație LXC**: [Linux Container Security](https://pve.proxmox.com/wiki/Linux_Container#_security_considerations) - Best practices pentru containere

```bash
# /etc/pve/firewall/NPM_CONTAINER_ID.fw (replace NPM_CONTAINER_ID with your container ID)
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
# HTTP/HTTPS din rețeaua privată
IN ACCEPT -source 10.10.0.0/24 -dport 80,443
# NPM admin doar din Tailscale
IN ACCEPT -source 100.64.0.0/10 -dport 81
# ICMP pentru monitoring
IN ACCEPT -p icmp
# Drop și log restul
IN DROP -log warning
```

**Referințe**:
- [Container Firewall](https://pve.proxmox.com/wiki/Firewall#pve_firewall_vm_container_configuration) - Firewall la nivel de container
- [Unprivileged Containers](https://pve.proxmox.com/wiki/Unprivileged_LXC_containers) - Securitate îmbunătățită

### Configurarea Rețelei

> 📖 **Network Setup**: [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration) - Ghid complet pentru bridges, bonds, și VLANs

```bash
# /etc/network/interfaces
auto vmbr1
iface vmbr1 inet static
    address 10.10.0.1/24
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    
    # NAT pentru acces internet din containere
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o eth0 -j MASQUERADE
    
    # Port forwarding pentru servicii publice
    post-up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.10.0.2:80
    post-up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 10.10.0.2:443
    
    # NPM admin doar prin Tailscale
    post-up iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 81 -j DNAT --to-destination 10.10.0.2:81
```

## 🎮 Utilizare

### Managementul Zilnic

```bash
# Verificarea status-ului de securitate
proxmox-security status

# Verificarea log-urilor de securitate
proxmox-security logs

# Generarea unui raport de securitate
proxmox-security report
```

### Managementul Actualizărilor

```bash
# Verificarea actualizărilor disponibile
proxmox-security update check

# Aplicarea doar a actualizărilor de securitate
proxmox-security update security

# Backup manual înainte de modificări majore
proxmox-security-updates backup
```

### Monitoring și Alerting

```bash
# Status monitoring în timp real
proxmox-security monitor status

# Pornirea/oprirea monitoring-ului
proxmox-security monitor start
proxmox-security monitor stop

# Test manual de securitate
proxmox-security monitor check
```

## 🧪 Testare Securitate

### Testare de Bază (Internă)

```bash
# Test complet de securitate
proxmox-security test basic

# Test doar a unui aspect specific
./security-test.sh localhost yourdomain.com
```

### Testare Avansată (Externă)

⚠️ **IMPORTANT**: Testarea externă trebuie făcută de pe un server care NU este conectat la același Tailscale network!

```bash
# De pe un VPS extern
./advanced-security-test.sh YOUR_PUBLIC_IP yourdomain.com

# Exemplu rezultat așteptat:
# ✓ Port 22 (SSH): FILTERED (securizat)
# ✓ Port 8006 (Proxmox): FILTERED (securizat)  
# ✓ Port 80 (HTTP): OPEN (corect)
# ✓ Port 443 (HTTPS): OPEN (corect)
# ✗ Port 81 (NPM Admin): OPEN (PERICOL!)
```

### Interpretarea Rezultatelor

**Status-uri normale pentru porturile de management:**
- `FILTERED` sau `CLOSED` = ✅ Securizat corect
- `OPEN` = ❌ PERICOL! Port expus public

**Status-uri normale pentru serviciile publice:**
- Port 80/443 `OPEN` = ✅ Corect pentru servicii web
- Port 81 `FILTERED` = ✅ NPM admin securizat

## 📊 Monitorizare și Alerting

### Tipuri de Alerte

**Alerte Critice (CRITICAL):**
- Servicii critice oprite (pvedaemon, pveproxy, pve-firewall)
- Firewall-ul Proxmox dezactivat
- Spațiu pe disc sub 10%

**Alerte Importante (HIGH):**
- Multiple încercări de autentificare eșuate
- Porturile de management expuse public
- Procese suspecte detectate

**Alerte Medii (MEDIUM):**
- Containere oprite neașteptat
- Număr mare de conexiuni web
- Fișiere de log mari

### Configurarea Email-urilor

> 📖 **Setup Notificări**: [Proxmox Email Configuration](https://pve.proxmox.com/wiki/Email_Notification_Configuration) - Configurare SMTP și test emailuri

```bash
# Pentru Fail2Ban
sudo nano /etc/fail2ban/jail.local
# Modificați: destemail = admin@yourdomain.com

# Pentru Logwatch
sudo nano /etc/logwatch/conf/logwatch.conf  
# Modificați: MailTo = admin@yourdomain.com

# Pentru actualizări automate
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
# Modificați: Unattended-Upgrade::Mail "admin@yourdomain.com";
```

### Interpretarea Log-urilor

```bash
# Log-uri de securitate
tail -f /var/log/proxmox-security/security.log

# Log-uri Fail2Ban
tail -f /var/log/fail2ban.log

# Log-uri autentificare
tail -f /var/log/auth.log | grep "authentication failure"
```

## 🔧 Troubleshooting

### Probleme Comune

#### 1. NPM nu este accesibil din exterior

```bash
# Verificați status container (replace NPM_CONTAINER_ID with your container ID)
pct status NPM_CONTAINER_ID

# Verificați configurația rețelei
pct config NPM_CONTAINER_ID | grep net0

# Verificați iptables NAT
iptables -t nat -L PREROUTING -n -v --line-numbers
```

#### 2. Management inaccesibil prin Tailscale

```bash
# Verificați status Tailscale
tailscale status

# Verificați IP Tailscale
ip addr show tailscale0

# Testați conectivitatea
ping YOUR_TAILSCALE_IP
```

> 📖 **Tailscale Troubleshooting**: [Tailscale Network Problems](https://tailscale.com/kb/1023/troubleshooting/) - Diagnosticare probleme VPN

#### 3. Fail2Ban nu blochează atacurile

> 📖 **Fail2Ban Guide**: [Fail2Ban Manual](https://fail2ban.readthedocs.io/) - Configurare avansată filtre și jail-uri

```bash
# Verificați status Fail2Ban
fail2ban-client status

# Verificați jail-urile active
fail2ban-client status sshd
fail2ban-client status proxmox

# Verificați log-urile
tail -f /var/log/fail2ban.log
```

**Referințe Utile**:
- [Fail2Ban Configuration](https://github.com/fail2ban/fail2ban/wiki/Proper-fail2ban-configuration) - Best practices
- [Custom Filters](https://fail2ban.readthedocs.io/en/latest/filters.html) - Crearea de filtre personalizate

#### 4. Alertele email nu funcționează

> 📖 **Email Setup**: [Proxmox Email Configuration](https://pve.proxmox.com/wiki/Email_Notification_Configuration) - Setup complet SMTP relay

```bash
# Testați configurația Postfix
echo "Test email" | mail -s "Test" admin@yourdomain.com

# Verificați status Postfix
systemctl status postfix

# Verificați log-urile mail
tail -f /var/log/mail.log
```

### Comenzi de Diagnostic

```bash
# Status complet de securitate
proxmox-security status

# Test conectivitate rețea
curl -I http://localhost:81  # NPM admin local
curl -I http://10.10.0.2:80  # NPM service

# Verificare firewall
pve-firewall status
iptables -L -n -v

# Test DNS și SSL
dig yourdomain.com
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

### Recovery în Caz de Urgență

#### Dezactivarea Temporară a Firewall-ului

```bash
# ATENȚIE: Folosiți doar în urgențe!
pve-firewall stop

# Nu uitați să-l reactivați:
pve-firewall start
```

#### Restaurarea unei Configurații Anterioare

```bash
# Listarea backup-urilor disponibile
ls -la /var/backups/proxmox-configs/

# Restaurarea unei configurații
proxmox-security-updates rollback
```

#### Accesul de Urgență prin SSH

Dacă Tailscale nu funcționează și aveți acces fizic la server:

```bash
# Dezactivați temporar restricțiile SSH
sudo nano /etc/ssh/sshd_config
# Comentați: AllowUsers root
sudo systemctl restart sshd

# Nu uitați să reactivați restricțiile după rezolvarea problemei!
```

## 📝 Loguri și Fișiere Importante

### Locații Log-uri

```bash
/var/log/proxmox-security/security.log    # Log-uri monitoring securitate
/var/log/proxmox-security/monitor.log     # Log-uri serviciu monitoring
/var/log/fail2ban.log                     # Log-uri Fail2Ban
/var/log/auth.log                         # Log-uri autentificare
/var/log/daemon.log                       # Log-uri Proxmox (include pvedaemon)
/var/log/mail.log                         # Log-uri email/alerting
```

### Fișiere de Configurație

```bash
/etc/pve/firewall/cluster.fw             # Reguli firewall Proxmox
/etc/pve/firewall/NPM_CONTAINER_ID.fw    # Reguli firewall container NPM (replace with your ID)
/etc/network/interfaces                  # Configurația rețelei
/etc/fail2ban/jail.local                 # Configurația Fail2Ban
/etc/ssh/sshd_config                     # Configurația SSH
```

### Backup-uri Automate

```bash
/var/backups/proxmox-configs/            # Backup-uri configurații sistem
/var/lib/vz/dump/                        # Backup-uri containere/VM-uri Proxmox
```

## 🎯 Best Practices

### Securitate

1. **Folosiți Tailscale pentru management**: Nu expuneți niciodată porturile 22, 8006, 81 public
2. **Actualizări regulate**: Rulați `proxmox-security update check` săptămânal
3. **Monitorizare activă**: Verificați `proxmox-security status` zilnic
4. **Backup-uri regulate**: Folosiți `proxmox-security-updates backup` înainte de modificări importante
5. **Testare periodică**: Rulați testele de securitate lunar de pe un server extern

### Monitoring

1. **Configurați alertele email**: Esențial pentru notificări în timp real
2. **Verificați log-urile regulat**: `proxmox-security logs`
3. **Generați rapoarte lunare**: `proxmox-security report`
4. **Monitorizați performanțele**: Urmăriți utilizarea CPU/RAM/Disk

### Maintenance

1. **Curățarea log-urilor**: Log-urile sunt rotite automat, dar verificați dimensiunile
2. **Actualizarea scripturilor**: Verificați pentru noi versiuni ale suite-ului
3. **Review securitate**: Analizați monthly rapoartele de securitate
4. **Testarea backup-urilor**: Testați procedura de rollback periodic

## � Resurse Externe

Pentru informații detaliate despre configurări specifice, consultați [EXTERNAL_RESOURCES.md](EXTERNAL_RESOURCES.md) care include:

### Documentație Oficială
- **[Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)** - Documentație completă Proxmox
- **[Proxmox Firewall Guide](https://pve.proxmox.com/wiki/Firewall)** - Configurare firewall și security groups
- **[Email Notifications Setup](https://pve.proxmox.com/wiki/Email_Notification_Configuration)** - Configurarea alertelor email în Proxmox

### Componente Integrate
- **[Fail2Ban Documentation](https://fail2ban.readthedocs.io/)** - Configurare avansată Fail2Ban
- **[Tailscale on Proxmox](https://tailscale.com/kb/1133/proxmox/)** - Setup complet Tailscale VPN
- **[Nginx Proxy Manager](https://nginxproxymanager.com/)** - Ghid complet NPM
- **[Cloudflare SSL/TLS](https://developers.cloudflare.com/ssl/)** - Configurare SSL și security

### Tutoriale Comunitate
- **[Proxmox Forum](https://forum.proxmox.com/)** - Comunitate oficială și suport
- **[Proxmox Helper Scripts](https://tteck.github.io/Proxmox/)** - Scripturi comunitate pentru Proxmox
- **[CIS Debian Benchmark](https://www.cisecurity.org/benchmark/debian_linux)** - Standard de securitate industrie

**Tip**: Vezi [EXTERNAL_RESOURCES.md](EXTERNAL_RESOURCES.md) pentru lista completă de resurse, tutoriale video, și documente tehnice detaliate.

## 📞 Suport și Documentație

### Documentație Proiect
- **[README.md](README.md)** - Acest fișier - prezentare generală
- **[QUICKSTART.md](QUICKSTART.md)** - Ghid rapid pas-cu-pas pentru începători
- **[EXTERNAL_RESOURCES.md](EXTERNAL_RESOURCES.md)** - Link-uri către documentație oficială
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Ghid pentru contribuitori
- **[COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md)** - Analiza competitivă și diferențiatori

### Obținerea Ajutorului
Când întâmpini probleme, urmează această ordine:
1. Verifică documentația acestui proiect (README, QUICKSTART)
2. Consultă [Proxmox Wiki](https://pve.proxmox.com/wiki/Main_Page) pentru probleme specifice Proxmox
3. Caută în [Proxmox Forum](https://forum.proxmox.com/) pentru soluții comunitate
4. Deschide un Issue pe GitHub cu detalii complete

### Contribuții

Pentru îmbunătățiri sau bug reports:
1. Deschideți un issue cu detalii complete
2. Includeți log-urile relevante
3. Specificați versiunea Proxmox și OS-ul folosit
4. Consultați [CONTRIBUTING.md](CONTRIBUTING.md) pentru guidelines

### Licență

Acest proiect este open-source și disponibil sub licența MIT. Vezi [LICENSE](LICENSE) pentru detalii.

---

**⚠️ Notă Importantă**: Acest suite de securitate este un instrument puternic, dar nu înlocuiește bune practici de securitate și administrare responsabilă. Testați toate configurațiile într-un mediu de dezvoltare înainte de aplicarea în producție.