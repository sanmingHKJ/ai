#!/usr/bin/env python3
"""
Validate YAML Against Schema

Utility tool for SystemSpecGen workflow.
Validates YAML files against schema definitions.
Supports both single file and directory validation.

Usage:
    python validate_spec_schema.py <yaml_file_or_dir> <schema_file>

Example (single file):
    python validate_spec_schema.py ./project/systems_spec.yml ./schemas/systems_spec_schema.yml

Example (directory):
    python validate_spec_schema.py ./project/specs/ ./schemas/systems_spec_schema.yml

Exit codes:
    0: Valid
    1: Schema violations found
    4: File I/O error
"""

import sys
import os
import yaml
import re
from pathlib import Path
from typing import Any
from glob import glob


def load_yaml(filepath: str) -> dict:
    """Load a YAML file and return its contents."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def validate_type(value: Any, expected_type: str) -> bool:
    """Validate that a value matches the expected type string."""
    if expected_type == 'string':
        return isinstance(value, str)
    elif expected_type == 'int':
        return isinstance(value, int) and not isinstance(value, bool)
    elif expected_type == 'float':
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    elif expected_type == 'bool':
        return isinstance(value, bool)
    elif expected_type == 'any':
        return True
    elif expected_type.startswith('list'):
        return isinstance(value, list)
    elif expected_type.startswith('dict') or expected_type.startswith('map'):
        return isinstance(value, dict)
    else:
        # Unknown type, assume valid
        return True


def validate_structure(data: Any, schema: Any, path: str = "") -> list:
    """
    Recursively validate data against schema structure.
    Returns list of error messages.
    """
    errors = []

    if schema is None:
        return errors

    # Handle schema type annotations (e.g., "string", "int")
    if isinstance(schema, str):
        if not validate_type(data, schema):
            errors.append(f"{path}: expected {schema}, got {type(data).__name__}")
        return errors

    # Handle dict schemas
    if isinstance(schema, dict):
        if not isinstance(data, dict):
            errors.append(f"{path}: expected dict, got {type(data).__name__}")
            return errors

        # Check required fields
        for key, value_schema in schema.items():
            if key.endswith('?'):
                # Optional field
                actual_key = key[:-1]
                if actual_key in data:
                    sub_path = f"{path}.{actual_key}" if path else actual_key
                    errors.extend(validate_structure(data[actual_key], value_schema, sub_path))
            else:
                # Required field
                if key not in data:
                    errors.append(f"{path}: missing required field '{key}'")
                else:
                    sub_path = f"{path}.{key}" if path else key
                    errors.extend(validate_structure(data[key], value_schema, sub_path))

        return errors

    # Handle list schemas
    if isinstance(schema, list):
        if not isinstance(data, list):
            errors.append(f"{path}: expected list, got {type(data).__name__}")
            return errors

        if len(schema) > 0:
            item_schema = schema[0]
            for i, item in enumerate(data):
                sub_path = f"{path}[{i}]"
                errors.extend(validate_structure(item, item_schema, sub_path))

        return errors

    return errors


def validate_systems_spec(data: dict) -> list:
    """
    Validate systems_spec.yml structure.
    Returns list of error messages.
    """
    errors = []

    # Check root structure
    if 'systems_spec' not in data:
        errors.append("Missing root 'systems_spec' key")
        return errors

    spec = data['systems_spec']

    # Check metadata
    if 'metadata' not in spec:
        errors.append("systems_spec: missing 'metadata'")
    else:
        metadata = spec['metadata']
        if 'version' not in metadata:
            errors.append("systems_spec.metadata: missing 'version'")

    # Check systems
    if 'systems' not in spec:
        errors.append("systems_spec: missing 'systems'")
        return errors

    systems = spec['systems']
    if not isinstance(systems, list):
        errors.append("systems_spec.systems: expected list")
        return errors

    # Validate each system
    required_fields = ['id', 'name', 'origin', 'category', 'authority', 'description']

    for i, system in enumerate(systems):
        system_id = system.get('id', f'system[{i}]')
        prefix = f"systems_spec.systems[{system_id}]"

        # Check required fields
        for field in required_fields:
            if field not in system:
                errors.append(f"{prefix}: missing required field '{field}'")

        # Validate entities
        for j, entity in enumerate(system.get('entities', [])):
            entity_name = entity.get('name', f'entity[{j}]')
            entity_prefix = f"{prefix}.entities[{entity_name}]"

            if 'name' not in entity:
                errors.append(f"{entity_prefix}: missing 'name'")
            if 'id_strategy' not in entity:
                errors.append(f"{entity_prefix}: missing 'id_strategy'")

        # Validate events_emit
        for j, event in enumerate(system.get('events_emit', [])):
            if isinstance(event, dict):
                event_id = event.get('id', f'event[{j}]')
                event_prefix = f"{prefix}.events_emit[{event_id}]"

                if 'id' not in event:
                    errors.append(f"{event_prefix}: missing 'id'")

        # Validate queries
        for j, query in enumerate(system.get('queries', [])):
            query_id = query.get('id', f'query[{j}]')
            query_prefix = f"{prefix}.queries[{query_id}]"

            if 'id' not in query:
                errors.append(f"{query_prefix}: missing 'id'")
            if 'returns' not in query:
                errors.append(f"{query_prefix}: missing 'returns'")

        # Validate commands
        for j, cmd in enumerate(system.get('commands', [])):
            cmd_id = cmd.get('id', f'command[{j}]')
            cmd_prefix = f"{prefix}.commands[{cmd_id}]"

            if 'id' not in cmd:
                errors.append(f"{cmd_prefix}: missing 'id'")

    return errors


def validate_systems_plan(data: dict) -> list:
    """
    Validate systems_plan.yml structure.
    Returns list of error messages.
    """
    errors = []

    # Check root structure
    if 'systems_plan' not in data:
        errors.append("Missing root 'systems_plan' key")
        return errors

    plan = data['systems_plan']

    # Check systems
    if 'systems' not in plan:
        errors.append("systems_plan: missing 'systems'")
        return errors

    systems = plan['systems']
    if not isinstance(systems, list):
        errors.append("systems_plan.systems: expected list")
        return errors

    # Validate each system
    required_fields = ['id', 'name', 'role', 'domain', 'description']

    for i, system in enumerate(systems):
        system_id = system.get('id', f'system[{i}]')
        prefix = f"systems_plan.systems[{system_id}]"

        for field in required_fields:
            if field not in system:
                errors.append(f"{prefix}: missing required field '{field}'")

        # Validate role
        if 'role' in system:
            valid_roles = ['core', 'support', 'meta', 'infrastructure']
            if system['role'] not in valid_roles:
                errors.append(f"{prefix}.role: invalid value '{system['role']}', expected one of {valid_roles}")

    return errors


def validate_spec_schema(yaml_file: str, schema_file: str) -> int:
    """
    Validate a YAML file against its schema.
    Returns exit code.
    """
    # Load files
    try:
        data = load_yaml(yaml_file)
    except Exception as e:
        print(f"Error loading {yaml_file}: {e}")
        return 4

    # Determine which validator to use based on file name
    yaml_name = os.path.basename(yaml_file).lower()
    schema_name = os.path.basename(schema_file).lower()

    errors = []

    if 'systems_spec' in yaml_name or 'systems_spec' in schema_name:
        print(f"Validating {yaml_file} as systems_spec")
        errors = validate_systems_spec(data)
    elif 'systems_plan' in yaml_name or 'systems_plan' in schema_name:
        print(f"Validating {yaml_file} as systems_plan")
        errors = validate_systems_plan(data)
    else:
        print(f"Warning: Unknown schema type, performing basic validation")
        # Basic validation only
        if not data:
            errors.append("File is empty or invalid YAML")

    # Report results
    if errors:
        print(f"\nValidation errors ({len(errors)}):")
        for error in errors:
            print(f"  - {error}")
        return 1
    else:
        print("\nValidation passed: no errors found")
        return 0


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    yaml_path = sys.argv[1]
    schema_file = sys.argv[2]

    # Check if input is a directory or file
    if os.path.isdir(yaml_path):
        # Validate all .yml files in directory
        spec_pattern = os.path.join(yaml_path, "*.yml")
        spec_files = glob(spec_pattern)

        if not spec_files:
            print(f"Error: No .yml files found in {yaml_path}")
            sys.exit(4)

        print(f"Found {len(spec_files)} spec files to validate\n")

        total_errors = 0
        failed_files = []

        for spec_file in spec_files:
            print(f"Validating {os.path.basename(spec_file)}...")
            exit_code = validate_spec_schema(spec_file, schema_file)
            if exit_code != 0:
                total_errors += 1
                failed_files.append(os.path.basename(spec_file))
            print()

        # Summary
        print("=" * 60)
        print(f"Validation Summary:")
        print(f"  Total files: {len(spec_files)}")
        print(f"  Passed: {len(spec_files) - total_errors}")
        print(f"  Failed: {total_errors}")

        if failed_files:
            print(f"\nFailed files:")
            for f in failed_files:
                print(f"  - {f}")
            sys.exit(1)
        else:
            print("\nAll files passed validation")
            sys.exit(0)

    elif os.path.isfile(yaml_path):
        # Validate single file
        exit_code = validate_spec_schema(yaml_path, schema_file)
        sys.exit(exit_code)
    else:
        print(f"Error: Path not found: {yaml_path}")
        sys.exit(4)


if __name__ == "__main__":
    main()
