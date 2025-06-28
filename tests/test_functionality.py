#!/usr/bin/env python3
"""
Functionality tests for web-terminal project
Tests core features and integration points
"""

import os
import subprocess
import socket
import time
import json
import signal
from pathlib import Path

class FunctionalityTester:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.results = []
        
    def test_ttyd_startup(self):
        """Test if ttyd can start successfully"""
        print("[*] Testing ttyd startup...")
        
        # Check if ttyd is available
        try:
            result = subprocess.run(['which', 'ttyd'], 
                                  capture_output=True, 
                                  text=True)
            if result.returncode != 0:
                return False, "ttyd not installed"
                
            # Try to start ttyd with a test configuration
            test_port = 17681  # Use different port to avoid conflicts
            process = subprocess.Popen(
                ['ttyd', '-p', str(test_port), '-o', '--once', 'echo', 'test'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Give it time to start
            time.sleep(2)
            
            # Check if it's running
            if process.poll() is None:
                # Clean up
                process.terminate()
                process.wait()
                return True, f"ttyd can start on port {test_port}"
            else:
                stderr = process.stderr.read().decode()
                return False, f"ttyd failed to start: {stderr}"
                
        except Exception as e:
            return False, f"Error testing ttyd: {e}"
            
    def test_tmux_sessions(self):
        """Test tmux session management"""
        print("[*] Testing tmux session management...")
        
        try:
            # Check if tmux is available
            result = subprocess.run(['tmux', '-V'], 
                                  capture_output=True, 
                                  text=True)
            if result.returncode != 0:
                return False, "tmux not installed"
                
            # List current sessions
            result = subprocess.run(['tmux', 'list-sessions'], 
                                  capture_output=True, 
                                  text=True)
            
            # Create test session
            test_session = "web-terminal-test"
            subprocess.run(['tmux', 'new-session', '-d', '-s', test_session])
            
            # Verify it was created
            result = subprocess.run(['tmux', 'has-session', '-t', test_session])
            if result.returncode == 0:
                # Clean up
                subprocess.run(['tmux', 'kill-session', '-t', test_session])
                return True, "tmux session management works"
            else:
                return False, "Failed to create tmux session"
                
        except Exception as e:
            return False, f"Error testing tmux: {e}"
            
    def test_nginx_config_validity(self):
        """Test if nginx configurations are valid"""
        print("[*] Testing nginx configuration validity...")
        
        nginx_configs = list(self.project_root.glob('**/*nginx*.sh'))
        issues = []
        
        for config_file in nginx_configs:
            try:
                content = config_file.read_text()
                
                # Look for common nginx syntax errors
                if 'server {' in content:
                    # Check for matching braces
                    open_braces = content.count('{')
                    close_braces = content.count('}')
                    if open_braces != close_braces:
                        issues.append(f"{config_file.name}: Mismatched braces")
                        
                    # Check for semicolons
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        line = line.strip()
                        if line and not line.startswith('#') and not line.endswith(('{', '}', ';')):
                            if 'location' not in line and 'server' not in line and 'EOF' not in line:
                                issues.append(f"{config_file.name}:{i+1}: Missing semicolon")
                                
            except Exception as e:
                issues.append(f"{config_file.name}: Error reading file: {e}")
                
        if issues:
            return False, f"Nginx config issues: {', '.join(issues[:3])}"
        else:
            return True, "Nginx configurations appear valid"
            
    def test_port_availability(self):
        """Test if required ports are available or in use"""
        print("[*] Testing port availability...")
        
        ports_to_check = {
            7681: "ttyd default",
            2222: "SSH tunnel",
            7500: "Additional service 1",
            7501: "Additional service 2",
            7502: "Additional service 3"
        }
        
        results = []
        for port, description in ports_to_check.items():
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            try:
                result = sock.connect_ex(('localhost', port))
                if result == 0:
                    results.append(f"Port {port} ({description}): IN USE")
                else:
                    results.append(f"Port {port} ({description}): AVAILABLE")
            except Exception as e:
                results.append(f"Port {port} ({description}): ERROR - {e}")
            finally:
                sock.close()
                
        return True, "; ".join(results)
        
    def test_web_interface_files(self):
        """Test if web interface files are complete"""
        print("[*] Testing web interface files...")
        
        required_files = {
            'index.html': 'Main terminal interface',
            'terminal.js': 'Terminal client logic',
            'mobile-complete.html': 'Mobile interface'
        }
        
        missing = []
        for filename, description in required_files.items():
            file_path = self.project_root / filename
            if not file_path.exists():
                missing.append(f"{filename} ({description})")
                
        if missing:
            return False, f"Missing files: {', '.join(missing)}"
            
        # Check for required JavaScript libraries in HTML files
        html_files = list(self.project_root.glob('*.html'))
        missing_deps = []
        
        for html_file in html_files:
            content = html_file.read_text()
            if 'terminal' in html_file.name.lower() or html_file.name == 'index.html':
                if 'xterm' not in content.lower():
                    missing_deps.append(f"{html_file.name}: Missing xterm.js")
                    
        if missing_deps:
            return False, f"Missing dependencies: {', '.join(missing_deps)}"
            
        return True, "All web interface files present"
        
    def test_shell_script_syntax(self):
        """Test shell scripts for basic syntax errors"""
        print("[*] Testing shell script syntax...")
        
        shell_scripts = list(self.project_root.glob('*.sh'))
        errors = []
        
        for script in shell_scripts:
            try:
                # Use bash -n for syntax checking
                result = subprocess.run(['bash', '-n', str(script)], 
                                      capture_output=True, 
                                      text=True)
                if result.returncode != 0:
                    errors.append(f"{script.name}: {result.stderr.strip()}")
            except Exception as e:
                errors.append(f"{script.name}: {e}")
                
        if errors:
            return False, f"Syntax errors: {errors[0]}" 
        else:
            return True, f"All {len(shell_scripts)} shell scripts have valid syntax"
            
    def test_ssh_tunnel_setup(self):
        """Test SSH tunnel configuration"""
        print("[*] Testing SSH tunnel setup...")
        
        # Check for SSH keys
        ssh_keys = [
            Path.home() / '.ssh' / 'id_rsa',
            Path.home() / '.ssh' / 'id_ed25519'
        ]
        
        key_found = any(key.exists() for key in ssh_keys)
        if not key_found:
            return False, "No SSH keys found for tunnel setup"
            
        # Check for autossh
        try:
            result = subprocess.run(['which', 'autossh'], 
                                  capture_output=True, 
                                  text=True)
            if result.returncode != 0:
                return True, "SSH keys found but autossh not installed (optional)"
        except:
            pass
            
        return True, "SSH tunnel prerequisites met"
        
    def test_credential_management(self):
        """Test credential file setup"""
        print("[*] Testing credential management...")
        
        cred_file = self.project_root / 'credentials.sh'
        example_file = self.project_root / 'credentials.example.sh'
        
        if not example_file.exists():
            return False, "credentials.example.sh missing"
            
        if not cred_file.exists():
            return True, "credentials.sh not found (expected for new installation)"
            
        # Check if credentials.sh is properly gitignored
        gitignore = self.project_root / '.gitignore'
        if gitignore.exists():
            content = gitignore.read_text()
            if 'credentials.sh' not in content:
                return False, "credentials.sh not in .gitignore!"
                
        return True, "Credential files properly configured"
        
    def run_all_tests(self):
        """Run all functionality tests"""
        print("Running Web Terminal Functionality Tests...\n")
        
        tests = [
            ("ttyd startup", self.test_ttyd_startup),
            ("tmux sessions", self.test_tmux_sessions),
            ("nginx configs", self.test_nginx_config_validity),
            ("port availability", self.test_port_availability),
            ("web interface", self.test_web_interface_files),
            ("shell syntax", self.test_shell_script_syntax),
            ("SSH tunnel", self.test_ssh_tunnel_setup),
            ("credentials", self.test_credential_management)
        ]
        
        passed = 0
        for test_name, test_func in tests:
            try:
                success, message = test_func()
                if success:
                    print(f"✓ {test_name}: {message}")
                    passed += 1
                else:
                    print(f"✗ {test_name}: {message}")
            except Exception as e:
                print(f"✗ {test_name}: Exception - {e}")
                
        print(f"\nTest Summary: {passed}/{len(tests)} passed")
        
        # Write detailed report
        report_path = self.project_root / 'functionality_test_report.json'
        with open(report_path, 'w') as f:
            json.dump({
                'passed': passed,
                'total': len(tests),
                'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
            }, f, indent=2)
            
        return passed == len(tests)


if __name__ == "__main__":
    tester = FunctionalityTester()
    success = tester.run_all_tests()
    exit(0 if success else 1)