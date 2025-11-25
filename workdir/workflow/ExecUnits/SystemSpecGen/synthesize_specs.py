#!/usr/bin/env python3
"""
Synthesize System Specifications

Phase 3 of SystemSpecGen workflow.
Reads all spec_*.yml files, validates cross-references,
and combines into unified systems_spec.yml.

Usage:
    python synthesize_specs.py <intermediate_dir> <output_file> [game_name]

Example:
    python synthesize_specs.py ./project/_intermediate/ ./project/systems_spec.yml "My Game"

Exit codes:
    0: Success
    1: Missing system reference
    2: Missing event reference
    3: Missing query/command reference
    4: File I/O error
"""

import sys
import os
import yaml
from glob import glob
from pathlib import Path
from difflib import get_close_matches
from typing import Any


def load_yaml(filepath: str) -> dict:
    """Load a YAML file and return its contents."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def save_yaml(filepath: str, data: dict) -> None:
    """Save data to a YAML file."""
    with open(filepath, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def suggest_fix(invalid: str, valid_options: list) -> str:
    """Suggest a fix for an invalid reference using fuzzy matching."""
    matches = get_close_matches(invalid, valid_options, n=1, cutoff=0.6)
    if matches:
        return f" (did you mean '{matches[0]}'?)"
    return ""


def synthesize_specs(intermediate_dir: str, output_file: str, game_name: str = "Unknown Game") -> int:
    """
    Synthesize all spec files into unified systems_spec.yml.

    Returns exit code.
    """
    intermediate_path = Path(intermediate_dir)

    # Find all spec files
    spec_pattern = str(intermediate_path / "spec_*.yml")
    spec_files = glob(spec_pattern)

    if not spec_files:
        print(f"Error: No spec files found matching {spec_pattern}")
        return 4

    print(f"Found {len(spec_files)} spec files")

    # Load all specs
    systems = []
    system_ids = set()

    for spec_file in spec_files:
        print(f"  Loading: {os.path.basename(spec_file)}")

        try:
            data = load_yaml(spec_file)
        except Exception as e:
            print(f"    Error loading {spec_file}: {e}")
            return 4

        # Handle both list format and single system format
        if isinstance(data, list):
            system = data[0] if data else {}
        else:
            system = data

        system_id = system.get('id', 'Unknown')
        system_ids.add(system_id)
        systems.append(system)

    print(f"\nLoaded {len(systems)} systems: {', '.join(sorted(system_ids))}")

    # Collect all events, queries, commands for validation
    all_events = {}  # event_id -> producer_system
    all_queries = set()  # "SystemId.query_id"
    all_commands = set()  # "SystemId.command_id"

    for system in systems:
        system_id = system.get('id')

        # Collect events
        for event in system.get('events_emit', []):
            event_id = event.get('id') if isinstance(event, dict) else event
            if event_id:
                all_events[event_id] = system_id

        # Collect queries
        for query in system.get('queries', []):
            query_id = query.get('id')
            if query_id:
                all_queries.add(f"{system_id}.{query_id}")

        # Collect commands
        for command in system.get('commands', []):
            command_id = command.get('id')
            if command_id:
                all_commands.add(f"{system_id}.{command_id}")

    # Validate cross-references
    errors = []

    for system in systems:
        system_id = system.get('id')

        # Validate depends_on
        for dep in system.get('depends_on', []):
            if dep not in system_ids:
                suggestion = suggest_fix(dep, list(system_ids))
                errors.append(
                    f"[{system_id}] depends_on references non-existent system '{dep}'{suggestion}"
                )

        # Validate events_subscribe
        for sub in system.get('events_subscribe', []):
            from_system = sub.get('from')
            event_id = sub.get('event')

            # Check if source system exists
            if from_system and from_system not in system_ids and from_system != "ANY":
                suggestion = suggest_fix(from_system, list(system_ids))
                errors.append(
                    f"[{system_id}] events_subscribe.from references non-existent system '{from_system}'{suggestion}"
                )

            # Check if event exists
            if event_id and event_id not in all_events:
                suggestion = suggest_fix(event_id, list(all_events.keys()))
                errors.append(
                    f"[{system_id}] subscribes to non-existent event '{event_id}'{suggestion}"
                )

        # Validate integration.queries_used
        integration = system.get('integration', {})
        for query_ref in integration.get('queries_used', []):
            if query_ref not in all_queries:
                suggestion = suggest_fix(query_ref, list(all_queries))
                errors.append(
                    f"[{system_id}] references non-existent query '{query_ref}'{suggestion}"
                )

        # Validate integration.commands_used
        for cmd_ref in integration.get('commands_used', []):
            if cmd_ref not in all_commands:
                suggestion = suggest_fix(cmd_ref, list(all_commands))
                errors.append(
                    f"[{system_id}] references non-existent command '{cmd_ref}'{suggestion}"
                )

    # Report errors
    if errors:
        print("\nValidation errors found:")
        for error in errors:
            print(f"  - {error}")

        # Determine exit code
        if any("depends_on" in e or "events_subscribe.from" in e for e in errors):
            return 1
        if any("subscribes to non-existent event" in e for e in errors):
            return 2
        return 3

    # Build unified spec
    unified_spec = {
        'systems_spec': {
            'metadata': {
                'version': '1.0',
                'game_name': game_name,
                'notes': f'Generated by SystemSpecGen. Contains {len(systems)} systems.'
            },
            'systems': systems
        }
    }

    # Write output
    save_yaml(output_file, unified_spec)

    print(f"\nSynthesis complete:")
    print(f"  Systems: {len(systems)}")
    print(f"  Events: {len(all_events)}")
    print(f"  Queries: {len(all_queries)}")
    print(f"  Commands: {len(all_commands)}")
    print(f"  Output: {output_file}")

    return 0


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    intermediate_dir = sys.argv[1]
    output_file = sys.argv[2]
    game_name = sys.argv[3] if len(sys.argv) > 3 else "Unknown Game"

    if not os.path.isdir(intermediate_dir):
        print(f"Error: Directory not found: {intermediate_dir}")
        sys.exit(4)

    exit_code = synthesize_specs(intermediate_dir, output_file, game_name)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
