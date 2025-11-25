#!/usr/bin/env python3
"""
Check Naming Conventions

Utility tool for SystemSpecGen workflow.
Validates that all IDs in system specs follow naming conventions.
Supports both single file and directory validation.

Usage:
    python check_naming_conventions.py <spec_file_or_dir>

Example (single file):
    python check_naming_conventions.py ./project/systems_spec.yml

Example (directory):
    python check_naming_conventions.py ./project/specs/

Naming Conventions:
    - System IDs: PascalCase ending with "System"
    - Entity names: PascalCase
    - Event IDs: SCREAMING_SNAKE_CASE
    - Query IDs: snake_case starting with get_/list_/has_/is_/can_
    - Command IDs: snake_case verbs
    - Field names: snake_case
    - Action IDs: ACTION_VERB_NOUN

Exit codes:
    0: All conventions followed
    1: Violations found
    4: File I/O error
"""

import sys
import os
import re
import yaml
from pathlib import Path
from glob import glob


def load_yaml(filepath: str) -> dict:
    """Load a YAML file and return its contents."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def is_pascal_case(s: str) -> bool:
    """Check if string is PascalCase."""
    return bool(re.match(r'^[A-Z][a-zA-Z0-9]*$', s))


def is_screaming_snake_case(s: str) -> bool:
    """Check if string is SCREAMING_SNAKE_CASE."""
    return bool(re.match(r'^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$', s))


def is_snake_case(s: str) -> bool:
    """Check if string is snake_case."""
    return bool(re.match(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$', s))


def to_pascal_case(s: str) -> str:
    """Convert string to PascalCase suggestion."""
    words = re.split(r'[_\s-]+', s)
    return ''.join(word.capitalize() for word in words)


def to_screaming_snake_case(s: str) -> str:
    """Convert string to SCREAMING_SNAKE_CASE suggestion."""
    # Insert underscore before uppercase letters
    result = re.sub(r'([a-z])([A-Z])', r'\1_\2', s)
    return result.upper().replace(' ', '_').replace('-', '_')


def to_snake_case(s: str) -> str:
    """Convert string to snake_case suggestion."""
    # Insert underscore before uppercase letters
    result = re.sub(r'([a-z])([A-Z])', r'\1_\2', s)
    return result.lower().replace(' ', '_').replace('-', '_')


def check_naming_conventions(spec_file: str) -> int:
    """
    Check naming conventions in a system spec file.
    Returns exit code.
    """
    # Load spec
    try:
        data = load_yaml(spec_file)
    except Exception as e:
        print(f"Error loading {spec_file}: {e}")
        return 4

    # Handle both unified file format and individual file format
    systems = []
    if 'systems_spec' in data:
        # Unified format (legacy)
        systems_spec = data.get('systems_spec', {})
        systems = systems_spec.get('systems', [])
    elif isinstance(data, list):
        # Individual file as list
        systems = data
    elif isinstance(data, dict) and 'id' in data:
        # Individual file as single system dict
        systems = [data]

    if not systems:
        print(f"Error: No systems found in {spec_file}")
        return 4

    print(f"Checking naming conventions for {len(systems)} system(s)")

    violations = []

    for system in systems:
        system_id = system.get('id', 'Unknown')
        prefix = f"[{system_id}]"

        # Check system ID: PascalCase ending with "System"
        if not is_pascal_case(system_id):
            suggestion = to_pascal_case(system_id)
            violations.append(f"{prefix} System ID should be PascalCase (suggested: {suggestion})")
        if not system_id.endswith('System'):
            violations.append(f"{prefix} System ID should end with 'System'")

        # Check entity names: PascalCase (handle both old and new format)
        data_section = system.get('data', {})
        entities = data_section.get('entities', []) if data_section else system.get('entities', [])

        for entity in entities:
            name = entity.get('name', '')
            if name and not is_pascal_case(name):
                suggestion = to_pascal_case(name)
                violations.append(f"{prefix} Entity '{name}' should be PascalCase (suggested: {suggestion})")

            # Check field names: snake_case
            for field_name in entity.get('fields', {}).keys():
                if not is_snake_case(field_name):
                    suggestion = to_snake_case(field_name)
                    violations.append(f"{prefix} Field '{name}.{field_name}' should be snake_case (suggested: {suggestion})")

        # Check event IDs: SCREAMING_SNAKE_CASE (handle both old and new format)
        events_section = system.get('events', {})
        events_emit = events_section.get('emits', []) if events_section else system.get('events_emit', [])

        for event in events_emit:
            event_id = event.get('id') if isinstance(event, dict) else event
            if event_id and not is_screaming_snake_case(event_id):
                suggestion = to_screaming_snake_case(event_id)
                violations.append(f"{prefix} Event '{event_id}' should be SCREAMING_SNAKE_CASE (suggested: {suggestion})")

        # Check query IDs: snake_case with proper prefix (handle both old and new format)
        interface_section = system.get('interface', {})
        queries = interface_section.get('queries', []) if interface_section else system.get('queries', [])

        valid_query_prefixes = ('GET_', 'LIST_', 'HAS_', 'IS_', 'CAN_', 'FIND_', 'COUNT_')
        for query in queries:
            query_id = query.get('id', '')
            if query_id:
                if not is_screaming_snake_case(query_id):
                    suggestion = to_screaming_snake_case(query_id)
                    violations.append(f"{prefix} Query '{query_id}' should be SCREAMING_SNAKE_CASE (suggested: {suggestion})")
                elif not query_id.startswith(valid_query_prefixes):
                    violations.append(f"{prefix} Query '{query_id}' should start with {valid_query_prefixes}")

        # Check command IDs: SCREAMING_SNAKE_CASE (handle both old and new format)
        commands = interface_section.get('commands', []) if interface_section else system.get('commands', [])

        for command in commands:
            cmd_id = command.get('id', '')
            if cmd_id and not is_screaming_snake_case(cmd_id):
                suggestion = to_screaming_snake_case(cmd_id)
                violations.append(f"{prefix} Command '{cmd_id}' should be SCREAMING_SNAKE_CASE (suggested: {suggestion})")

        # Check action IDs: ACTION_VERB_NOUN (handle both old and new format)
        player_actions = interface_section.get('player_actions', []) if interface_section else system.get('actions_player', [])

        for action in player_actions:
            action_id = action.get('id', '')
            if action_id:
                if not is_screaming_snake_case(action_id):
                    suggestion = to_screaming_snake_case(action_id)
                    violations.append(f"{prefix} Action '{action_id}' should be SCREAMING_SNAKE_CASE (suggested: {suggestion})")
                elif not action_id.startswith('ACTION_'):
                    violations.append(f"{prefix} Action '{action_id}' should start with 'ACTION_'")

        # Check UI facet IDs: PascalCase
        for facet in system.get('ui_facets', []):
            facet_id = facet.get('id', '')
            if facet_id and not is_pascal_case(facet_id):
                suggestion = to_pascal_case(facet_id)
                violations.append(f"{prefix} UI facet '{facet_id}' should be PascalCase (suggested: {suggestion})")

    # Report results
    if violations:
        print(f"\nNaming convention violations ({len(violations)}):")
        for violation in violations:
            print(f"  - {violation}")
        return 1
    else:
        print("\nAll naming conventions followed")
        return 0


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    spec_path = sys.argv[1]

    # Check if input is a directory or file
    if os.path.isdir(spec_path):
        # Check all .yml files in directory
        spec_pattern = os.path.join(spec_path, "*.yml")
        spec_files = glob(spec_pattern)

        if not spec_files:
            print(f"Error: No .yml files found in {spec_path}")
            sys.exit(4)

        print(f"Found {len(spec_files)} spec files to check\n")

        total_violations = 0
        failed_files = []

        for spec_file in spec_files:
            print(f"Checking {os.path.basename(spec_file)}...")
            exit_code = check_naming_conventions(spec_file)
            if exit_code != 0:
                total_violations += 1
                failed_files.append(os.path.basename(spec_file))
            print()

        # Summary
        print("=" * 60)
        print(f"Naming Convention Check Summary:")
        print(f"  Total files: {len(spec_files)}")
        print(f"  Passed: {len(spec_files) - total_violations}")
        print(f"  Failed: {total_violations}")

        if failed_files:
            print(f"\nFiles with violations:")
            for f in failed_files:
                print(f"  - {f}")
            sys.exit(1)
        else:
            print("\nAll files follow naming conventions")
            sys.exit(0)

    elif os.path.isfile(spec_path):
        # Check single file
        exit_code = check_naming_conventions(spec_path)
        sys.exit(exit_code)
    else:
        print(f"Error: Path not found: {spec_path}")
        sys.exit(4)


if __name__ == "__main__":
    main()
