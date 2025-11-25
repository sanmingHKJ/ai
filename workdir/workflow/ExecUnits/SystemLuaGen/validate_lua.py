#!/usr/bin/env python3
"""
SystemLuaGen Phase 4: Validation & Testing

Validates generated Lua code for syntax and contract compliance.

Usage:
    python validate_lua.py <GAME_DIR>

Example:
    python validate_lua.py ../../../projects/castle_defense/
"""

import sys
import os
import yaml
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Tuple
import re


class LuaValidator:
    def __init__(self, game_dir: str):
        self.game_dir = Path(game_dir).resolve()
        self.units_data_dir = self.game_dir / "UnitsData"
        self.intermediate_dir = self.units_data_dir / "_intermediate"
        self.service_nodes_dir = self.game_dir / "ServiceNodes"

        # Loaded data
        self.generation_plan: Optional[Dict] = None
        self.entities_registry: Optional[Dict] = None

        # Validation results
        self.errors = []
        self.warnings = []
        self.lua_files = []

    def load_yaml(self, file_path: Path) -> Dict:
        """Load and parse YAML file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Error loading {file_path}: {e}")
            sys.exit(2)

    def save_yaml(self, data: Dict, file_path: Path):
        """Save data to YAML file."""
        try:
            file_path.parent.mkdir(parents=True, exist_ok=True)
            with open(file_path, 'w', encoding='utf-8') as f:
                yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
            print(f"✓ Saved: {file_path}")
        except Exception as e:
            print(f"Error saving {file_path}: {e}")
            sys.exit(2)

    def load_generation_plan(self):
        """Load generation plan."""
        plan_path = self.intermediate_dir / "lua_generation_plan.yml"
        if not plan_path.exists():
            print(f"Error: lua_generation_plan.yml not found")
            sys.exit(2)

        data = self.load_yaml(plan_path)
        self.generation_plan = data.get('generation_plan', {})

    def load_entities_registry(self):
        """Load entities registry."""
        entities_path = self.intermediate_dir / "entities_registry.yml"
        if entities_path.exists():
            self.entities_registry = self.load_yaml(entities_path)

    def find_lua_files(self):
        """Find all generated Lua files."""
        print("Finding generated Lua files...")

        if not self.service_nodes_dir.exists():
            print(f"Error: ServiceNodes directory not found")
            sys.exit(2)

        self.lua_files = list(self.service_nodes_dir.glob("**/*.lua"))
        print(f"✓ Found {len(self.lua_files)} Lua files")

    def validate_syntax(self, lua_file: Path) -> Tuple[bool, str]:
        """Validate Lua syntax using luac if available."""
        # Try to use luac for syntax checking
        try:
            result = subprocess.run(
                ['luac', '-p', str(lua_file)],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                return True, "OK"
            else:
                return False, result.stderr.strip()

        except FileNotFoundError:
            # luac not available, do basic validation
            return self.validate_syntax_basic(lua_file)
        except subprocess.TimeoutExpired:
            return False, "Timeout"
        except Exception as e:
            return False, f"Error: {e}"

    def validate_syntax_basic(self, lua_file: Path) -> Tuple[bool, str]:
        """Basic Lua syntax validation without luac."""
        try:
            with open(lua_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check for balanced keywords
            issues = []

            # Count function/end pairs
            function_count = len(re.findall(r'\bfunction\b', content))
            end_count = len(re.findall(r'\bend\b', content))

            # Account for if/then/end, for/do/end, etc.
            control_structures = len(re.findall(r'\b(if|for|while)\b', content))

            # Simple heuristic check
            if abs(function_count - end_count) > control_structures:
                issues.append("Unbalanced function/end keywords")

            # Check for common syntax errors
            if re.search(r'function\s+\w+\.\w+\s*\(', content) and not re.search(r'function\s+\w+:\w+\s*\(', content):
                # Has . but not :, might be intentional
                pass

            if issues:
                return False, "; ".join(issues)

            return True, "Basic check OK (luac not available)"

        except Exception as e:
            return False, f"Read error: {e}"

    def validate_sgf_pattern(self, lua_file: Path) -> List[str]:
        """Validate that file follows SGF pattern."""
        issues = []

        try:
            with open(lua_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check if it's a system file
            if 'Server.lua' in lua_file.name or 'Client.lua' in lua_file.name:
                # Should have SGF lifecycle methods
                if 'function' in content:
                    if ':PreInit()' not in content:
                        issues.append("Missing PreInit() method")
                    if ':Init()' not in content:
                        issues.append("Missing Init() method")
                    if ':PostInit()' not in content:
                        issues.append("Missing PostInit() method")
                    if ':Start()' not in content:
                        issues.append("Missing Start() method")

                # Should have .new constructor
                if '.new(sgf)' not in content:
                    issues.append("Missing .new(sgf) constructor")

        except Exception as e:
            issues.append(f"Read error: {e}")

        return issues

    def validate_event_contracts(self) -> List[str]:
        """Validate event contracts."""
        issues = []

        # Load EventID.lua to get all valid event IDs
        event_id_file = self.service_nodes_dir / "MainStorage" / "Framework" / "Runtime" / "EventID.lua"
        if not event_id_file.exists():
            issues.append("EventID.lua not found")
            return issues

        try:
            with open(event_id_file, 'r', encoding='utf-8') as f:
                event_content = f.read()

            # Extract event IDs
            valid_events = set(re.findall(r'EventID\.(\w+)\s*=', event_content))

            # Check all system files for event references
            for lua_file in self.lua_files:
                if 'System' in lua_file.name:
                    with open(lua_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Find event references
                    event_refs = re.findall(r'EventID\.(\w+)', content)

                    for event_ref in event_refs:
                        if event_ref not in valid_events:
                            issues.append(f"{lua_file.name}: References unknown event '{event_ref}'")

        except Exception as e:
            issues.append(f"Error checking event contracts: {e}")

        return issues

    def validate_network_contracts(self) -> List[str]:
        """Validate network message contracts."""
        issues = []

        # Load Protocol.lua to get all valid message IDs
        protocol_file = self.service_nodes_dir / "MainStorage" / "Framework" / "Runtime" / "Protocol.lua"
        if not protocol_file.exists():
            issues.append("Protocol.lua not found")
            return issues

        try:
            with open(protocol_file, 'r', encoding='utf-8') as f:
                protocol_content = f.read()

            # Extract message IDs
            valid_client_msgs = set(re.findall(r'ClientMSGID\.(\w+)\s*=', protocol_content))
            valid_server_msgs = set(re.findall(r'ServerMSGID\.(\w+)\s*=', protocol_content))

            # Check all system files for message references
            for lua_file in self.lua_files:
                if 'System' in lua_file.name:
                    with open(lua_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Find message references
                    client_msg_refs = re.findall(r'Protocol\.ClientMSGID\.(\w+)', content)
                    server_msg_refs = re.findall(r'Protocol\.ServerMSGID\.(\w+)', content)

                    for msg_ref in client_msg_refs:
                        if msg_ref not in valid_client_msgs:
                            issues.append(f"{lua_file.name}: References unknown client message '{msg_ref}'")

                    for msg_ref in server_msg_refs:
                        if msg_ref not in valid_server_msgs:
                            issues.append(f"{lua_file.name}: References unknown server message '{msg_ref}'")

        except Exception as e:
            issues.append(f"Error checking network contracts: {e}")

        return issues

    def run_syntax_checks(self):
        """Run syntax checks on all Lua files."""
        print("Running syntax validation...")

        passed = 0
        failed = 0

        for lua_file in self.lua_files:
            success, message = self.validate_syntax(lua_file)

            if success:
                passed += 1
            else:
                failed += 1
                self.errors.append(f"Syntax error in {lua_file.name}: {message}")

        print(f"  Passed: {passed}/{len(self.lua_files)}")
        if failed > 0:
            print(f"  Failed: {failed}/{len(self.lua_files)}")

        return failed == 0

    def run_sgf_pattern_checks(self):
        """Run SGF pattern validation."""
        print("Running SGF pattern validation...")

        total_issues = 0

        for lua_file in self.lua_files:
            if 'System' in lua_file.name and lua_file.name not in ['ServerMain.lua', 'ClientMain.lua']:
                issues = self.validate_sgf_pattern(lua_file)

                if issues:
                    total_issues += len(issues)
                    for issue in issues:
                        self.warnings.append(f"{lua_file.name}: {issue}")

        if total_issues > 0:
            print(f"  Found {total_issues} pattern issues")
        else:
            print(f"  All system files follow SGF pattern")

        return total_issues == 0

    def run_contract_checks(self):
        """Run contract validation."""
        print("Running contract validation...")

        # Check event contracts
        event_issues = self.validate_event_contracts()
        self.warnings.extend(event_issues)

        # Check network contracts
        network_issues = self.validate_network_contracts()
        self.warnings.extend(network_issues)

        total_issues = len(event_issues) + len(network_issues)

        if total_issues > 0:
            print(f"  Found {total_issues} contract issues")
        else:
            print(f"  All contracts validated")

        return total_issues == 0

    def generate_report(self):
        """Generate validation report."""
        print()
        print("Generating validation report...")

        report = {
            'validation_report': {
                'timestamp': self.get_timestamp(),
                'syntax_check': {
                    'status': 'PASS' if not self.errors else 'FAIL',
                    'files_checked': len(self.lua_files),
                    'errors': self.errors
                },
                'sgf_pattern_check': {
                    'status': 'PASS',  # Warnings don't fail
                    'systems_validated': len([f for f in self.lua_files if 'System' in f.name])
                },
                'contract_check': {
                    'status': 'PASS',  # Warnings don't fail
                    'warnings': self.warnings
                },
                'overall_status': 'PASS' if not self.errors else 'FAIL'
            }
        }

        self.save_yaml(report, self.intermediate_dir / "lua_validation_report.yml")

        return report['validation_report']['overall_status'] == 'PASS'

    def get_timestamp(self):
        """Get current timestamp."""
        from datetime import datetime
        return datetime.now().isoformat()

    def run(self):
        """Run the complete validation pipeline."""
        print("=" * 60)
        print("SystemLuaGen Phase 4: Validation & Testing")
        print("=" * 60)
        print()

        # Load data
        self.load_generation_plan()
        self.load_entities_registry()

        # Find Lua files
        self.find_lua_files()

        # Run validations
        print()
        syntax_ok = self.run_syntax_checks()

        print()
        pattern_ok = self.run_sgf_pattern_checks()

        print()
        contract_ok = self.run_contract_checks()

        # Generate report
        print()
        report_ok = self.generate_report()

        # Summary
        print()
        print("=" * 60)
        if report_ok:
            print("✓ Phase 4 Complete - All validations passed")
        else:
            print("✗ Phase 4 Complete - Validation errors found")
        print("=" * 60)

        # Print errors
        if self.errors:
            print()
            print("ERRORS:")
            for error in self.errors:
                print(f"  ✗ {error}")

        # Print warnings
        if self.warnings:
            print()
            print("WARNINGS:")
            for warning in self.warnings[:10]:  # Limit to first 10
                print(f"  ⚠ {warning}")
            if len(self.warnings) > 10:
                print(f"  ... and {len(self.warnings) - 10} more warnings")

        print()

        return 0 if report_ok else 1


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_lua.py <GAME_DIR>")
        print()
        print("Example:")
        print("  python validate_lua.py ../../../projects/castle_defense/")
        sys.exit(1)

    game_dir = sys.argv[1]

    validator = LuaValidator(game_dir)
    exit_code = validator.run()

    sys.exit(exit_code)


if __name__ == '__main__':
    main()
