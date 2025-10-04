# Contributing to Proxmox Security Suite

Thank you for your interest in contributing to the Proxmox Security Suite! This document provides guidelines for contributing to the project.

## 🎯 Project Goals

This security suite aims to provide a comprehensive, easy-to-use security hardening solution for Proxmox VE infrastructure that:
- Is fully generic and works with any Proxmox configuration
- Provides automated security monitoring and alerting
- Follows security best practices
- Is well-documented and user-friendly

## 📋 Development Guidelines

### Code Standards

1. **Shell Scripts:**
   - Use `#!/bin/bash` shebang
   - Include descriptive comments
   - Use meaningful variable names
   - Add error handling with proper exit codes
   - Follow consistent formatting

2. **Documentation:**
   - Keep README.md comprehensive but concise
   - QUICKSTART.md should be step-by-step for beginners
   - Use clear, non-technical language when possible
   - Include examples for all configurations

3. **Security:**
   - Never hardcode IPs, domains, or credentials
   - Use placeholders (e.g., `YOUR_PUBLIC_IP`, `NPM_CONTAINER_ID`)
   - Validate user input in scripts
   - Log security-relevant actions

### Anonymization Requirements

**CRITICAL:** All contributions must maintain anonymization:

✅ **Use Generic Placeholders:**
- `YOUR_PUBLIC_IP` for public IP addresses
- `YOUR_TAILSCALE_IP` for Tailscale VPN IPs
- `NPM_CONTAINER_ID` for container IDs
- `yourdomain.com` for domain names
- `your-email@domain.com` for email addresses

❌ **Never Include:**
- Real IP addresses (except RFC 5737 documentation ranges)
- Real domain names
- Personal hardware identifiers
- Email addresses (except generic examples)
- Specific container IDs (except as examples)

### Testing Requirements

Before submitting a pull request:

1. **Syntax Validation:**
   ```bash
   # Check all shell scripts
   shellcheck *.sh
   ```

2. **Security Testing:**
   ```bash
   # Test from external server (not on Tailscale)
   ./security-test.sh YOUR_SERVER_IP
   ./advanced-security-test.sh YOUR_SERVER_IP
   ```

3. **Documentation Check:**
   ```bash
   # Verify no personal data
   grep -r "152.53.67" .  # Should return nothing
   grep -r "gamili" .      # Should return nothing
   ```

## 🔧 How to Contribute

### Reporting Bugs

1. **Check existing issues** to avoid duplicates
2. **Provide details:**
   - Proxmox VE version
   - Operating system
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs (anonymize IPs/domains!)

### Suggesting Features

1. **Open an issue** with the `enhancement` label
2. **Describe the use case** and benefits
3. **Consider security implications**
4. **Provide examples** if applicable

### Submitting Pull Requests

1. **Fork the repository**

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes:**
   - Follow coding standards
   - Update documentation
   - Add tests if applicable

4. **Test thoroughly:**
   - Test on a clean Proxmox installation
   - Verify all scripts work
   - Check documentation accuracy

5. **Commit with clear messages:**
   ```bash
   git commit -m "Add: Description of what you added"
   git commit -m "Fix: Description of what you fixed"
   git commit -m "Docs: Description of documentation changes"
   ```

6. **Push and create PR:**
   ```bash
   git push origin feature/your-feature-name
   ```
   - Describe your changes clearly
   - Reference related issues
   - Explain testing performed

## 📝 Documentation Guidelines

### README.md
- Comprehensive overview
- Installation instructions
- Usage examples
- Troubleshooting section

### QUICKSTART.md
- Step-by-step guide for beginners
- Clear prerequisites
- Expected results at each step
- Links to detailed documentation

### Script Comments
```bash
# Function: brief description
# Parameters: list parameters
# Returns: return value/exit code
# Example: usage example
function_name() {
    # Implementation
}
```

## 🔐 Security Considerations

### When Adding Features

1. **Least Privilege:** Scripts should request minimum permissions needed
2. **Input Validation:** Always validate user input
3. **Secure Defaults:** Default configurations should be secure
4. **Logging:** Log security-relevant actions
5. **Reversibility:** Provide rollback/restore options

### When Modifying Scripts

1. **Backup First:** Scripts should backup configurations before changes
2. **Error Handling:** Gracefully handle failures
3. **User Confirmation:** Prompt before destructive actions
4. **Clear Warnings:** Mark dangerous operations clearly

## 🧪 Testing Infrastructure

### Test Environment

Recommended test setup:
- Fresh Proxmox VE installation
- At least one LXC container for NPM
- Separate external server for security testing (not on Tailscale)

### Test Scenarios

1. **Fresh Installation:**
   - Run `install-security-suite.sh`
   - Verify all services start
   - Check firewall rules

2. **Existing Installation:**
   - Test upgrade path
   - Verify no conflicts with existing configs

3. **Security Validation:**
   - Run external security tests
   - Verify management ports are closed
   - Confirm public services work

## 📦 Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR:** Breaking changes
- **MINOR:** New features (backward compatible)
- **PATCH:** Bug fixes

### Before Release

1. Update `CHANGELOG.md` with all changes
2. Update version numbers in scripts
3. Test complete installation from scratch
4. Run security tests from external server
5. Update documentation for new features
6. Create GitHub release with release notes

## 🙏 Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes
- README acknowledgments section

## 📞 Getting Help

- **Questions:** Open a GitHub issue with the `question` label
- **Discussions:** Use GitHub Discussions for general topics
- **Security Issues:** Email directly (do not open public issue)

## 📜 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and improve
- Keep discussions professional

## 🎓 Learning Resources

### Proxmox VE
- [Official Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE API](https://pve.proxmox.com/pve-docs/api-viewer/)

### Security Best Practices
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Shell Scripting
- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/) for script validation

## 📊 Project Structure

```
proxmox-security/
├── .github/
│   └── copilot-instructions.md    # AI assistant instructions
├── .gitignore                      # Git ignore rules
├── CHANGELOG.md                    # Version history
├── CONTRIBUTING.md                 # This file
├── LICENSE                         # Project license
├── QUICKSTART.md                   # Quick start guide
├── README.md                       # Main documentation
├── setup.sh                        # Initial setup script
├── install-security-suite.sh       # Main installer
├── security-hardening.sh           # Interactive hardening
├── security-monitor.sh             # Real-time monitoring
├── security-updates.sh             # Update management
├── security-test.sh                # Basic security tests
└── advanced-security-test.sh       # Advanced penetration testing
```

Thank you for contributing to making Proxmox infrastructure more secure! 🔐