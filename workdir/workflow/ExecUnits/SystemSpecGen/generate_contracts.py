#!/usr/bin/env python3
"""
Generate System Contracts

Phase 3 of SystemSpecGen workflow.
Analyzes individual system specs in specs/ directory and generates systems_contracts.yml
with integration graph, event/query/command contracts, and topology validation.

Usage:
    python generate_contracts.py <specs_dir> <output_file>

Example:
    python generate_contracts.py ./project/specs/ ./project/systems_contracts.yml

Exit codes:
    0: Success (may have warnings)
    1: Circular dependency detected
    4: File I/O error
"""

import sys
import os
import yaml
from pathlib import Path
from typing import Any
from collections import defaultdict
from glob import glob


def load_yaml(filepath: str) -> dict:
    """Load a YAML file and return its contents."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def save_yaml(filepath: str, data: dict) -> None:
    """Save data to a YAML file."""
    with open(filepath, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def detect_cycles(graph: dict) -> list:
    """
    Detect cycles in a directed graph using DFS.
    Returns list of cycles found.
    """
    cycles = []
    visited = set()
    rec_stack = set()
    path = []

    def dfs(node):
        visited.add(node)
        rec_stack.add(node)
        path.append(node)

        for neighbor in graph.get(node, []):
            if neighbor not in visited:
                cycle = dfs(neighbor)
                if cycle:
                    return cycle
            elif neighbor in rec_stack:
                # Found cycle
                cycle_start = path.index(neighbor)
                return path[cycle_start:] + [neighbor]

        path.pop()
        rec_stack.remove(node)
        return None

    for node in graph:
        if node not in visited:
            cycle = dfs(node)
            if cycle:
                cycles.append(cycle)

    return cycles


def generate_contracts(specs_dir: str, output_file: str) -> int:
    """
    Generate contracts from individual system spec files in specs/ directory.

    Returns exit code.
    """
    specs_path = Path(specs_dir)

    # Find all spec files
    spec_pattern = str(specs_path / "*.yml")
    spec_files = glob(spec_pattern)

    if not spec_files:
        print(f"Error: No spec files found in {specs_dir}")
        return 4

    print(f"Found {len(spec_files)} spec files")

    # Load all specs
    systems = []
    for spec_file in spec_files:
        try:
            data = load_yaml(spec_file)
            # Handle different spec file formats:
            # 1. systems_spec.systems array (multi-system file)
            # 2. system_spec wrapper (single system file)
            # 3. List of systems
            # 4. Single system dict
            if isinstance(data, dict):
                if 'systems_spec' in data and 'systems' in data['systems_spec']:
                    # Format: systems_spec.systems array
                    systems.extend(data['systems_spec']['systems'])
                elif 'system_spec' in data:
                    # Format: system_spec wrapper
                    systems.append(data['system_spec'])
                else:
                    # Single system dict (assume it's the system itself)
                    systems.append(data)
            elif isinstance(data, list):
                # List of systems
                systems.extend(data)
        except Exception as e:
            print(f"Error loading {spec_file}: {e}")
            return 4

    if not systems:
        print(f"Error: No systems found in spec files")
        return 4

    print(f"Analyzing {len(systems)} systems")

    # Build indices
    system_map = {s.get('id'): s for s in systems}
    event_producers = {}  # event_id -> producer_system_id
    event_payloads = {}   # event_id -> payload schema
    query_defs = {}       # "SystemId.query_id" -> query definition
    command_defs = {}     # "SystemId.command_id" -> command definition

    for system in systems:
        system_id = system.get('id')

        # Index events (handle both old and new format)
        events_data = system.get('events', {})
        events_emit = events_data.get('emits', []) if events_data else system.get('events_emit', [])

        for event in events_emit:
            event_id = event.get('id') if isinstance(event, dict) else event
            if event_id:
                event_producers[event_id] = system_id
                if isinstance(event, dict):
                    event_payloads[event_id] = event.get('payload', {})

        # Index queries (handle both old and new format)
        interface_data = system.get('interface', {})
        queries = interface_data.get('queries', []) if interface_data else system.get('queries', [])

        for query in queries:
            query_id = query.get('id')
            if query_id:
                # Use query_id as-is if it already contains system prefix, otherwise add it
                full_id = query_id if '.' in query_id else f"{system_id}.{query_id}"
                query_defs[full_id] = query

        # Index commands (handle both old and new format)
        commands = interface_data.get('commands', []) if interface_data else system.get('commands', [])

        for command in commands:
            command_id = command.get('id')
            if command_id:
                # Use command_id as-is if it already contains system prefix, otherwise add it
                full_id = command_id if '.' in command_id else f"{system_id}.{command_id}"
                command_defs[full_id] = command

    # Build integration graph
    integration_graph = []
    dependency_graph = {}  # For cycle detection

    for system in systems:
        system_id = system.get('id')

        # Handle both old and new format
        events_data = system.get('events', {})
        events_subscribes = events_data.get('subscribes', []) if events_data else system.get('events_subscribe', [])
        events_emit = events_data.get('emits', []) if events_data else system.get('events_emit', [])

        # Collect inbound events (events this system subscribes to)
        inbound_events = []
        for sub in events_subscribes:
            event = sub.get('event')
            if event:
                inbound_events.append(event)

        # Collect outbound events
        outbound_events = []
        for event in events_emit:
            event_id = event.get('id') if isinstance(event, dict) else event
            if event_id:
                outbound_events.append(event_id)

        # Collect queries/commands used
        integration = system.get('integration', {})
        queries_used = integration.get('queries_used', [])
        commands_used = integration.get('commands_used', [])

        # Build dependency graph for cycle detection
        depends_on = system.get('depends_on', [])
        dependency_graph[system_id] = depends_on

        integration_graph.append({
            'id': system_id,
            'depends_on': depends_on,
            'inbound_events': inbound_events,
            'outbound_events': outbound_events,
            'queries_used': queries_used,
            'commands_used': commands_used
        })

    # Build event contracts
    event_contracts = []
    event_subscribers = defaultdict(list)  # event_id -> list of (system, handler)

    for system in systems:
        system_id = system.get('id')

        # Handle both old and new format
        events_data = system.get('events', {})
        events_subscribes = events_data.get('subscribes', []) if events_data else system.get('events_subscribe', [])

        # Build a map of event -> behavior_id for this system
        event_handlers = {}
        for behavior in system.get('behaviors', []):
            trigger = behavior.get('trigger', {})
            if trigger.get('type') == 'event':
                event_name = trigger.get('name')
                if event_name:
                    event_handlers[event_name] = behavior.get('id', 'unknown')

        for sub in events_subscribes:
            event_id = sub.get('event')
            # Try to find handler from behaviors, fall back to 'unknown'
            handler = event_handlers.get(event_id, sub.get('handler', 'unknown'))
            if event_id:
                event_subscribers[event_id].append({
                    'system': system_id,
                    'handler': handler
                })

    for event_id, producer in event_producers.items():
        consumers = event_subscribers.get(event_id, [])
        payload = event_payloads.get(event_id, {})

        # Convert payload to schema format
        payload_schema = {}
        for field_name, field_def in payload.items():
            if isinstance(field_def, dict):
                payload_schema[field_name] = {
                    'type': field_def.get('type', 'unknown'),
                    'required': not field_def.get('nullable', False)
                }
            else:
                payload_schema[field_name] = {
                    'type': str(field_def),
                    'required': True
                }

        event_contracts.append({
            'event_id': event_id,
            'producer': producer,
            'consumers': consumers,
            'payload_schema': payload_schema
        })

    # Build query contracts
    query_contracts = []
    query_consumers = defaultdict(list)

    for system in systems:
        system_id = system.get('id')
        integration = system.get('integration', {})
        for query_ref in integration.get('queries_used', []):
            query_consumers[query_ref].append(system_id)

    for query_id, query_def in query_defs.items():
        consumers = query_consumers.get(query_id, [])
        provider = query_id.split('.')[0]

        # Build signature from args (dict) and returns (string)
        args = query_def.get('args', {})
        returns = query_def.get('returns', 'void')
        param_strs = [f"{name}: {type_str}" for name, type_str in args.items()]
        return_type = returns if isinstance(returns, str) else returns.get('type', 'void')
        signature = f"({', '.join(param_strs)}) -> {return_type}"

        query_contracts.append({
            'query_id': query_id,
            'provider': provider,
            'consumers': consumers,
            'signature': signature
        })

    # Build command contracts
    command_contracts = []
    command_consumers = defaultdict(list)

    for system in systems:
        system_id = system.get('id')
        integration = system.get('integration', {})
        for cmd_ref in integration.get('commands_used', []):
            command_consumers[cmd_ref].append(system_id)

    for cmd_id, cmd_def in command_defs.items():
        consumers = command_consumers.get(cmd_id, [])
        provider = cmd_id.split('.')[0]

        # Build signature from args (dict) and returns (string or None)
        args = cmd_def.get('args', {})
        returns = cmd_def.get('returns')
        param_strs = [f"{name}: {type_str}" for name, type_str in args.items()]
        return_type = returns if isinstance(returns, str) else (returns.get('type', 'void') if returns else 'void')
        signature = f"({', '.join(param_strs)}) -> {return_type}"

        command_contracts.append({
            'command_id': cmd_id,
            'provider': provider,
            'consumers': consumers,
            'signature': signature
        })

    # Validate topology
    warnings = {
        'orphan_events': [],
        'unused_queries': [],
        'unused_commands': [],
        'dependency_cycles': [],
        'high_coupling_systems': []
    }

    # Check for orphan events
    for event_id in event_producers:
        if event_id not in event_subscribers or not event_subscribers[event_id]:
            warnings['orphan_events'].append(event_id)

    # Check for unused queries
    for query_id in query_defs:
        if query_id not in query_consumers or not query_consumers[query_id]:
            warnings['unused_queries'].append(query_id)

    # Check for unused commands
    for cmd_id in command_defs:
        if cmd_id not in command_consumers or not command_consumers[cmd_id]:
            warnings['unused_commands'].append(cmd_id)

    # Detect cycles
    cycles = detect_cycles(dependency_graph)
    if cycles:
        for cycle in cycles:
            warnings['dependency_cycles'].append(' -> '.join(cycle))

    # Check for high coupling (>10 connections)
    for entry in integration_graph:
        total_connections = (
            len(entry['depends_on']) +
            len(entry['inbound_events']) +
            len(entry['outbound_events']) +
            len(entry['queries_used']) +
            len(entry['commands_used'])
        )
        if total_connections > 10:
            warnings['high_coupling_systems'].append(
                f"{entry['id']} ({total_connections} connections)"
            )

    # Build output
    contracts = {
        'systems_contracts': {
            'metadata': {
                'version': '1.1',
                'generated_from': 'specs/'
            },
            'integration_graph': integration_graph,
            'event_contracts': event_contracts,
            'query_contracts': query_contracts,
            'command_contracts': command_contracts,
            'warnings': warnings
        }
    }

    # Write output
    save_yaml(output_file, contracts)

    # Report results
    print(f"\nContracts generated:")
    print(f"  Integration graph entries: {len(integration_graph)}")
    print(f"  Event contracts: {len(event_contracts)}")
    print(f"  Query contracts: {len(query_contracts)}")
    print(f"  Command contracts: {len(command_contracts)}")
    print(f"  Output: {output_file}")

    # Report warnings
    has_warnings = False
    if warnings['orphan_events']:
        has_warnings = True
        print(f"\nWarning: {len(warnings['orphan_events'])} orphan events (no subscribers):")
        for e in warnings['orphan_events'][:5]:
            print(f"    - {e}")
        if len(warnings['orphan_events']) > 5:
            print(f"    ... and {len(warnings['orphan_events']) - 5} more")

    if warnings['dependency_cycles']:
        has_warnings = True
        print(f"\nError: {len(warnings['dependency_cycles'])} dependency cycles detected:")
        for cycle in warnings['dependency_cycles']:
            print(f"    - {cycle}")
        return 1

    if warnings['high_coupling_systems']:
        has_warnings = True
        print(f"\nWarning: {len(warnings['high_coupling_systems'])} high-coupling systems:")
        for s in warnings['high_coupling_systems']:
            print(f"    - {s}")

    if not has_warnings:
        print("\nNo warnings or errors.")

    return 0


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    specs_dir = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.isdir(specs_dir):
        print(f"Error: Directory not found: {specs_dir}")
        sys.exit(4)

    exit_code = generate_contracts(specs_dir, output_file)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
