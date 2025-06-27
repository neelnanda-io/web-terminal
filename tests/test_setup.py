#!/usr/bin/env python3
"""
Test suite for web-terminal setup verification
"""

import os
import sys
import subprocess
import socket
import time
import requests
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class TestWebTerminal:
    """Test cases for web terminal setup"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.results = []
        
    def run_test(self, test_name, test_func):
        """Run a single test and record result"""
        try:
            result = test_func()
            self.results.append((test_name, "PASS", result))
            print(f"✓ {test_name}")
            return True
        except Exception as e:
            self.results.append((test_name, "FAIL", str(e)))
            print(f"✗ {test_name}: {e}")
            return False
    
    def test_required_files_exist(self):
        """Check that all required files exist"""
        required_files = [
            "start-ttyd.sh",
            "credentials.example.sh",
            ".gitignore",
            "SECURITY.md",
            "project_memory.md"
        ]
        
        for file in required_files:
            file_path = self.project_root / file
            if not file_path.exists():
                raise FileNotFoundError(f"Required file missing: {file}")
        
        return "All required files present"
    
    def test_credentials_not_exposed(self):
        """Ensure no hardcoded credentials in tracked files"""
        # Files that should not contain credentials
        files_to_check = [
            "start-ttyd.sh",
            "setup-ssh-access.sh",
            "vps-nginx-setup.sh"
        ]
        
        sensitive_patterns = [
            "feet essential wherever principle",  # Old hardcoded password
            "password=",
            "TTYD_CREDENTIAL=\"admin:"
        ]
        
        for file in files_to_check:
            file_path = self.project_root / file
            if file_path.exists():
                content = file_path.read_text()
                for pattern in sensitive_patterns:
                    if pattern in content:
                        raise ValueError(f"Sensitive data found in {file}: {pattern}")
        
        return "No hardcoded credentials found"
    
    def test_gitignore_complete(self):
        """Verify .gitignore contains necessary entries"""
        gitignore_path = self.project_root / ".gitignore"
        content = gitignore_path.read_text()
        
        required_entries = [
            "credentials.sh",
            ".env",
            "*.key",
            "*.log",
            "*password*",
            "*secret*"
        ]
        
        for entry in required_entries:
            if entry not in content:
                raise ValueError(f".gitignore missing entry: {entry}")
        
        return ".gitignore properly configured"
    
    def test_executable_permissions(self):
        """Check that shell scripts have executable permissions"""
        shell_scripts = list(self.project_root.glob("*.sh"))
        
        non_executable = []
        for script in shell_scripts:
            if not os.access(script, os.X_OK):
                non_executable.append(script.name)
        
        if non_executable:
            raise PermissionError(f"Scripts not executable: {', '.join(non_executable)}")
        
        return f"All {len(shell_scripts)} shell scripts are executable"
    
    def test_port_availability(self):
        """Check if ttyd port is available"""
        port = 7681
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            result = sock.connect_ex(('localhost', port))
            sock.close()
            
            if result == 0:
                # Port is in use - this might be ttyd already running
                return f"Port {port} is in use (ttyd may be running)"
            else:
                return f"Port {port} is available"
        except Exception as e:
            raise Exception(f"Could not check port: {e}")
    
    def test_tmux_availability(self):
        """Check if tmux is installed and accessible"""
        try:
            result = subprocess.run(['tmux', '-V'], 
                                  capture_output=True, 
                                  text=True,
                                  check=True)
            version = result.stdout.strip()
            return f"tmux available: {version}"
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise Exception("tmux not found or not working")
    
    def test_ttyd_availability(self):
        """Check if ttyd is installed and accessible"""
        try:
            result = subprocess.run(['ttyd', '--version'], 
                                  capture_output=True, 
                                  text=True,
                                  check=True)
            version = result.stdout.strip()
            return f"ttyd available: {version}"
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise Exception("ttyd not found - install with: brew install ttyd")
    
    def test_ssh_key_exists(self):
        """Check if SSH key exists for VPS connection"""
        ssh_key_paths = [
            Path.home() / ".ssh" / "id_rsa",
            Path.home() / ".ssh" / "id_ed25519"
        ]
        
        for key_path in ssh_key_paths:
            if key_path.exists():
                return f"SSH key found: {key_path}"
        
        raise FileNotFoundError("No SSH key found for VPS connection")
    
    def run_all_tests(self):
        """Run all tests and print summary"""
        print("Running Web Terminal Setup Tests...\n")
        
        tests = [
            ("Required files exist", self.test_required_files_exist),
            ("No exposed credentials", self.test_credentials_not_exposed),
            ("Gitignore complete", self.test_gitignore_complete),
            ("Scripts executable", self.test_executable_permissions),
            ("Port availability", self.test_port_availability),
            ("Tmux installed", self.test_tmux_availability),
            ("ttyd installed", self.test_ttyd_availability),
            ("SSH key exists", self.test_ssh_key_exists)
        ]
        
        for test_name, test_func in tests:
            self.run_test(test_name, test_func)
        
        # Print summary
        print("\n" + "="*50)
        passed = sum(1 for _, status, _ in self.results if status == "PASS")
        total = len(self.results)
        
        print(f"Test Summary: {passed}/{total} passed")
        
        if passed < total:
            print("\nFailed tests:")
            for name, status, message in self.results:
                if status == "FAIL":
                    print(f"  - {name}: {message}")
            return False
        else:
            print("\nAll tests passed! ✓")
            return True


if __name__ == "__main__":
    tester = TestWebTerminal()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)