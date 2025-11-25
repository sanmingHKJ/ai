#!/usr/bin/env python3
"""
Build Global Registry from Skeleton Files

Phase 2B of SystemSpecGen workflow.
Reads all *_skeleton.yml files and builds global_registry.yml with all
event/query/command IDs for cross-system reference validation.

Usage:
    python build_global_registry.py <intermediate_dir>

Example:
    python build_global_registry.py ./project/_intermediate/

Exit codes:
    0: Success
    1: Validation errors found (parse error messages for details)
    2: File I/O error (missing files, YAML parse errors)
"""

import sys
import os
import re
import yaml
from glob import glob
from pathlib import Path
from typing import Any


def load_yaml(filepath: str) -> dict:
    """Load a YAML file and return its contents."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def save_yaml(filepath: str, data: dict) -> None:
    """Save data to a YAML file."""
    with open(filepath, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def is_screaming_snake_case(s: str) -> bool:
    """Check if string is SCREAMING_SNAKE_CASE."""
    return bool(re.match(r'^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$', s))


def build_signature(args: dict, returns: dict) -> str:
    """Build a signature string from args and returns."""
    param_strs = []
    # args is a dict with field_name: type_string format
    for name, ptype in (args or {}).items():
        param_strs.append(f"{name}: {ptype}")

    params_str = ', '.join(param_strs)
    return_type = returns if isinstance(returns, str) else (returns.get('type', 'void') if returns else 'void')

    return f"({params_str}) -> {return_type}"


def build_global_registry(intermediate_dir: str) -> int:
    """
    Build global registry from skeleton files.

    Returns exit code.
    """
    intermediate_path = Path(intermediate_dir)

    # Find all skeleton files
    skeleton_pattern = str(intermediate_path / "*_skeleton.yml")
    skeleton_files = glob(skeleton_pattern)

    if not skeleton_files:
        print(f"Error: No skeleton files found matching {skeleton_pattern}")
        return 2  # File I/O error

    print(f"Found {len(skeleton_files)} skeleton files")

    # Collect data from all skeletons
    events = []
    queries = []
    commands = []
    subscriptions = []  # For validation
    system_ids = set()  # Track all system IDs

    errors = []
    warnings = []

    for skeleton_file in skeleton_files:
        print(f"  Processing: {os.path.basename(skeleton_file)}")

        try:
            data = load_yaml(skeleton_file)
        except Exception as e:
            print(f"    Error loading {skeleton_file}: {e}")
            return 2  # File I/O error

        # Handle both list format and single system format
        # Extract system_spec if present (schema format)
        if isinstance(data, list):
            system = data[0] if data else {}
        elif 'system_spec' in data:
            system = data['system_spec']
        else:
            system = data

        system_id = system.get('id', 'Unknown')
        system_ids.add(system_id)

        # Collect events.emits
        events_data = system.get('events', {})
        for event in events_data.get('emits', []):
            event_id = event.get('id') if isinstance(event, dict) else event
            if event_id:
                # Check naming convention
                if not is_screaming_snake_case(event_id):
                    errors.append(f"Event '{event_id}' in {system_id} is not SCREAMING_SNAKE_CASE")

                # Check for duplicates
                existing = [e for e in events if e['id'] == event_id]
                if existing:
                    errors.append(
                        f"Duplicate event ID '{event_id}': "
                        f"defined in both {existing[0]['producer']} and {system_id}"
                    )
                else:
                    events.append({
                        'id': event_id,
                        'producer': system_id
                    })

        # Collect events.subscribes for validation
        for sub in events_data.get('subscribes', []):
            subscriptions.append({
                'system': system_id,
                'from': sub.get('from'),
                'event': sub.get('event')
            })

        # Collect interface.queries
        interface_data = system.get('interface', {})
        for query in interface_data.get('queries', []):
            query_id = query.get('id')
            if query_id:
                signature = build_signature(
                    query.get('args', {}),
                    query.get('returns')
                )
                # Use query_id as-is if it already contains system prefix, otherwise add it
                full_id = query_id if '.' in query_id else f"{system_id}.{query_id}"
                queries.append({
                    'id': full_id,
                    'signature': signature
                })

        # Collect interface.commands
        for command in interface_data.get('commands', []):
            command_id = command.get('id')
            if command_id:
                signature = build_signature(
                    command.get('args', {}),
                    command.get('returns')
                )
                # Use command_id as-is if it already contains system prefix, otherwise add it
                full_id = command_id if '.' in command_id else f"{system_id}.{command_id}"
                commands.append({
                    'id': full_id,
                    'signature': signature
                })

    # Validate subscriptions reference existing events
    event_ids = {e['id'] for e in events}
    event_producers = {e['id']: e['producer'] for e in events}

    for sub in subscriptions:
        event_id = sub['event']
        producer_system = sub['from']
        consumer_system = sub['system']

        if not event_id:
            continue

        # Check if the producer system exists
        if producer_system not in system_ids:
            errors.append(
                f"System '{consumer_system}' subscribes to event '{event_id}' "
                f"from '{producer_system}', but system '{producer_system}' doesn't exist"
            )
        # Check if the event exists
        elif event_id not in event_ids:
            errors.append(
                f"System '{consumer_system}' subscribes to event '{event_id}' "
                f"from '{producer_system}', but '{producer_system}' doesn't emit this event"
            )
        # Check if the event is produced by the expected system
        elif event_producers.get(event_id) != producer_system:
            actual_producer = event_producers.get(event_id, 'Unknown')
            errors.append(
                f"System '{consumer_system}' expects event '{event_id}' from '{producer_system}', "
                f"but it's actually emitted by '{actual_producer}'"
            )

    # Report errors
    if errors:
        print("\nErrors found:")
        for error in errors:
            print(f"  - {error}")
        return 1  # Validation errors found

    # Build registry
    registry = {
        'global_registry': {
            'events': events,
            'queries': queries,
            'commands': commands
        }
    }

    # Write output to parent directory (UnitsData/)
    output_file = intermediate_path.parent / "global_registry.yml"
    save_yaml(str(output_file), registry)

    print(f"\nGlobal registry built successfully:")
    print(f"  Events: {len(events)}")
    print(f"  Queries: {len(queries)}")
    print(f"  Commands: {len(commands)}")
    print(f"  Output: {output_file}")

    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"  - {warning}")

    return 0  # Success


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    intermediate_dir = sys.argv[1]

    if not os.path.isdir(intermediate_dir):
        print(f"Error: Directory not found: {intermediate_dir}")
        sys.exit(2)  # File I/O error

    exit_code = build_global_registry(intermediate_dir)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
