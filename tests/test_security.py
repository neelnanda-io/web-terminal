#!/usr/bin/env python3
"""
Security tests for web-terminal project
Tests for vulnerabilities, exposed secrets, and security misconfigurations
"""

import os
import re
import subprocess
from pathlib import Path
import json

class SecurityTester:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.vulnerabilities = []
        self.warnings = []
        
    def test_hardcoded_credentials(self):
        """Scan for hardcoded passwords and API keys"""
        print("[*] Scanning for hardcoded credentials...")
        
        # Patterns that indicate possible secrets
        secret_patterns = [
            (r'password\s*=\s*["\']([^"\']+)["\']', 'Hardcoded password'),
            (r'api_key\s*=\s*["\']([^"\']+)["\']', 'Hardcoded API key'),
            (r'secret\s*=\s*["\']([^"\']+)["\']', 'Hardcoded secret'),
            (r'feet essential wherever principle', 'Known default password'),
            (r'htpasswd -[bc]+ \w+ "([^"]+)"', 'Password in command'),
            (r'143\.110\.172\.229', 'Hardcoded IP address')
        ]
        
        files_to_scan = list(self.project_root.glob('**/*.sh')) + \
                       list(self.project_root.glob('**/*.py')) + \
                       list(self.project_root.glob('**/*.js')) + \
                       list(self.project_root.glob('**/*.html'))
        
        for file_path in files_to_scan:
            if 'node_modules' in str(file_path) or '.git' in str(file_path):
                continue
                
            try:
                content = file_path.read_text()
                for pattern, desc in secret_patterns:
                    matches = re.finditer(pattern, content, re.IGNORECASE)
                    for match in matches:
                        self.vulnerabilities.append({
                            'type': 'hardcoded_secret',
                            'severity': 'HIGH',
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': content[:match.start()].count('\n') + 1,
                            'description': f'{desc}: {match.group(0)[:50]}...'
                        })
            except Exception as e:
                pass
                
    def test_command_injection(self):
        """Check for potential command injection vulnerabilities"""
        print("[*] Checking for command injection risks...")
        
        # Patterns that might indicate command injection
        injection_patterns = [
            (r'subprocess\.run\([^,]+shell=True', 'Shell=True in subprocess'),
            (r'os\.system\(', 'os.system usage'),
            (r'eval\(', 'eval() usage'),
            (r'exec\(', 'exec() usage'),
            (r'\$\([^)]+\)', 'Command substitution in shell'),
            (r'`[^`]+`', 'Backtick command execution')
        ]
        
        code_files = list(self.project_root.glob('**/*.py')) + \
                    list(self.project_root.glob('**/*.sh'))
        
        for file_path in code_files:
            try:
                content = file_path.read_text()
                for pattern, desc in injection_patterns:
                    matches = re.finditer(pattern, content)
                    for match in matches:
                        self.warnings.append({
                            'type': 'command_injection_risk',
                            'severity': 'MEDIUM',
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': content[:match.start()].count('\n') + 1,
                            'description': desc
                        })
            except Exception:
                pass
                
    def test_authentication_strength(self):
        """Check authentication configuration"""
        print("[*] Analyzing authentication configuration...")
        
        # Check nginx configs for auth settings
        nginx_configs = list(self.project_root.glob('**/*nginx*.sh'))
        
        for config_file in nginx_configs:
            try:
                content = config_file.read_text()
                
                # Check for basic auth only
                if 'auth_basic' in content and 'auth_basic_user_file' in content:
                    self.warnings.append({
                        'type': 'weak_authentication',
                        'severity': 'MEDIUM',
                        'file': str(config_file.relative_to(self.project_root)),
                        'description': 'Only HTTP Basic Authentication is used'
                    })
                    
                # Check for HTTP without HTTPS redirect
                if 'listen 80;' in content and 'listen 443' not in content:
                    self.vulnerabilities.append({
                        'type': 'unencrypted_transport',
                        'severity': 'HIGH',
                        'file': str(config_file.relative_to(self.project_root)),
                        'description': 'HTTP used without HTTPS'
                    })
            except Exception:
                pass
                
    def test_access_controls(self):
        """Check for proper access controls"""
        print("[*] Checking access controls...")
        
        # Look for ttyd command execution
        ttyd_scripts = list(self.project_root.glob('**/start-ttyd*.sh'))
        
        for script in ttyd_scripts:
            try:
                content = script.read_text()
                
                # Check if ttyd allows command execution
                if 'ttyd' in content and '-W' in content:
                    self.vulnerabilities.append({
                        'type': 'unrestricted_command_execution',
                        'severity': 'CRITICAL',
                        'file': str(script.relative_to(self.project_root)),
                        'description': 'ttyd allows full command execution with -W flag'
                    })
                    
                # Check for credential exposure in process list
                if '-c "$TTYD_CREDENTIAL"' in content or '-c "' in content:
                    self.warnings.append({
                        'type': 'credential_in_process_list',
                        'severity': 'MEDIUM',
                        'file': str(script.relative_to(self.project_root)),
                        'description': 'Credentials may be visible in process list'
                    })
            except Exception:
                pass
                
    def test_ssh_security(self):
        """Check SSH configuration security"""
        print("[*] Analyzing SSH security...")
        
        ssh_scripts = list(self.project_root.glob('**/*ssh*.sh'))
        
        for script in ssh_scripts:
            try:
                content = script.read_text()
                
                # Check for SSH key management issues
                if 'cat' in content and '.ssh/id_rsa' in content:
                    self.vulnerabilities.append({
                        'type': 'ssh_key_exposure',
                        'severity': 'CRITICAL',
                        'file': str(script.relative_to(self.project_root)),
                        'description': 'SSH private key being read/transmitted'
                    })
                    
                # Check for weak SSH options
                if 'StrictHostKeyChecking no' in content:
                    self.warnings.append({
                        'type': 'weak_ssh_config',
                        'severity': 'MEDIUM',
                        'file': str(script.relative_to(self.project_root)),
                        'description': 'SSH host key checking disabled'
                    })
            except Exception:
                pass
                
    def test_web_security_headers(self):
        """Check for security headers in web responses"""
        print("[*] Checking web security configuration...")
        
        # Look for missing security headers in nginx configs
        important_headers = [
            'X-Frame-Options',
            'X-Content-Type-Options',
            'Content-Security-Policy',
            'X-XSS-Protection'
        ]
        
        nginx_files = list(self.project_root.glob('**/*nginx*.sh'))
        
        for nginx_file in nginx_files:
            try:
                content = nginx_file.read_text()
                for header in important_headers:
                    if header not in content:
                        self.warnings.append({
                            'type': 'missing_security_header',
                            'severity': 'LOW',
                            'file': str(nginx_file.relative_to(self.project_root)),
                            'description': f'Missing security header: {header}'
                        })
            except Exception:
                pass
                
    def generate_report(self):
        """Generate security assessment report"""
        print("\n" + "="*60)
        print("SECURITY ASSESSMENT REPORT")
        print("="*60)
        
        # Critical vulnerabilities
        critical = [v for v in self.vulnerabilities if v['severity'] == 'CRITICAL']
        high = [v for v in self.vulnerabilities if v['severity'] == 'HIGH']
        medium_warnings = [w for w in self.warnings if w['severity'] == 'MEDIUM']
        low_warnings = [w for w in self.warnings if w['severity'] == 'LOW']
        
        print(f"\nSummary:")
        print(f"  Critical Issues: {len(critical)}")
        print(f"  High Issues: {len(high)}")
        print(f"  Medium Warnings: {len(medium_warnings)}")
        print(f"  Low Warnings: {len(low_warnings)}")
        
        if critical:
            print(f"\n[CRITICAL] Security Vulnerabilities:")
            for vuln in critical:
                print(f"  • {vuln['file']}:{vuln.get('line', '?')}")
                print(f"    {vuln['description']}")
                
        if high:
            print(f"\n[HIGH] Security Issues:")
            for vuln in high:
                print(f"  • {vuln['file']}:{vuln.get('line', '?')}")
                print(f"    {vuln['description']}")
                
        if medium_warnings:
            print(f"\n[MEDIUM] Security Warnings:")
            for warn in medium_warnings[:5]:  # Show first 5
                print(f"  • {warn['file']}:{warn.get('line', '?')}")
                print(f"    {warn['description']}")
            if len(medium_warnings) > 5:
                print(f"  ... and {len(medium_warnings) - 5} more")
                
        # Write detailed report
        report_path = self.project_root / 'security_assessment.json'
        report_data = {
            'vulnerabilities': self.vulnerabilities,
            'warnings': self.warnings,
            'summary': {
                'critical': len(critical),
                'high': len(high),
                'medium': len(medium_warnings),
                'low': len(low_warnings)
            }
        }
        
        with open(report_path, 'w') as f:
            json.dump(report_data, f, indent=2)
            
        print(f"\nDetailed report saved to: {report_path}")
        
        return len(critical) == 0  # Return True if no critical issues
        
    def run_all_tests(self):
        """Run all security tests"""
        self.test_hardcoded_credentials()
        self.test_command_injection()
        self.test_authentication_strength()
        self.test_access_controls()
        self.test_ssh_security()
        self.test_web_security_headers()
        
        return self.generate_report()


if __name__ == "__main__":
    tester = SecurityTester()
    success = tester.run_all_tests()
    exit(0 if success else 1)