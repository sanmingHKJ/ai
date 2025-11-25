#!/usr/bin/env python3
"""
SystemLuaGen Phase 1: Analysis & Preparation

Loads and validates system specifications, builds generation plan.

Usage:
    python analyze_specs.py <GAME_DIR>

Example:
    python analyze_specs.py ../../../projects/castle_defense/
"""

import sys
import os
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional


class SpecAnalyzer:
    def __init__(self, game_dir: str):
        self.game_dir = Path(game_dir).resolve()
        self.units_data_dir = self.game_dir / "UnitsData"
        self.specs_dir = self.units_data_dir / "specs"
        self.intermediate_dir = self.units_data_dir / "_intermediate"

        # Loaded data
        self.specs: Dict[str, Dict] = {}
        self.global_registry: Optional[Dict] = None
        self.systems_contracts: Optional[Dict] = None

        # Generated data
        self.entities_registry: Dict[str, Any] = {}
        self.generation_plan: Dict[str, Any] = {}

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

    def load_all_specs(self):
        """Load all system specification files."""
        print(f"Loading specs from: {self.specs_dir}")

        if not self.specs_dir.exists():
            print(f"Error: Specs directory not found: {self.specs_dir}")
            sys.exit(2)

        spec_files = list(self.specs_dir.glob("*.yml"))
        if not spec_files:
            print(f"Error: No spec files found in {self.specs_dir}")
            sys.exit(2)

        for spec_file in spec_files:
            system_id = spec_file.stem
            data = self.load_yaml(spec_file)

            # Unwrap system_spec if present
            if 'system_spec' in data:
                spec = data['system_spec']
            else:
                spec = data

            # Validate spec has required fields
            if 'id' not in spec:
                print(f"Warning: Spec {spec_file} missing 'id' field")
                spec['id'] = system_id

            self.specs[spec['id']] = spec
            print(f"  Loaded: {spec['id']}")

        print(f"✓ Loaded {len(self.specs)} system specs")

    def load_global_registry(self):
        """Load global registry file."""
        registry_path = self.units_data_dir / "global_registry.yml"
        print(f"Loading global registry: {registry_path}")

        if not registry_path.exists():
            print(f"Error: global_registry.yml not found")
            sys.exit(2)

        self.global_registry = self.load_yaml(registry_path)

        # Count items
        events = len(self.global_registry.get('global_registry', {}).get('events', []))
        queries = len(self.global_registry.get('global_registry', {}).get('queries', []))
        commands = len(self.global_registry.get('global_registry', {}).get('commands', []))

        print(f"✓ Registry loaded: {events} events, {queries} queries, {commands} commands")

    def load_systems_contracts(self):
        """Load systems contracts file."""
        contracts_path = self.units_data_dir / "systems_contracts.yml"
        print(f"Loading systems contracts: {contracts_path}")

        if not contracts_path.exists():
            print(f"Warning: systems_contracts.yml not found")
            self.systems_contracts = {}
            return

        self.systems_contracts = self.load_yaml(contracts_path)
        print(f"✓ Systems contracts loaded")

    def extract_entities(self):
        """Extract entity definitions from all specs."""
        print("Extracting entity definitions...")

        entities = {}

        for system_id, spec in self.specs.items():
            # Extract entities from data.entities section
            spec_entities = spec.get('data', {}).get('entities', [])

            for entity in spec_entities:
                entity_name = entity.get('name')
                if not entity_name:
                    continue

                entities[entity_name] = {
                    'defined_by': system_id,
                    'fields': entity.get('fields', {})
                }

        self.entities_registry = {'entities': entities}
        print(f"✓ Extracted {len(entities)} entity definitions")

    def convert_param_name(self, param: str) -> str:
        """Convert parameter name to camelCase."""
        # Simple conversion: hero_id -> heroId
        parts = param.split('_')
        if len(parts) == 1:
            return param
        return parts[0] + ''.join(word.capitalize() for word in parts[1:])


    def build_generation_plan(self):
        """Build comprehensive generation plan."""
        print("Building generation plan...")

        plan = {
            'metadata': {
                'game_id': self.game_dir.name,
                'total_systems': len(self.specs)
            },
            'server_systems': [],
            'client_systems': [],
            'network_protocol': {
                'client_messages': {},
                'server_messages': {}
            },
            'event_ids': [],
            'functions_needing_llm': []
        }

        # Extract all event IDs from global registry
        registry_data = self.global_registry.get('global_registry', {})
        for event in registry_data.get('events', []):
            event_id = event.get('id')
            if event_id and event_id not in plan['event_ids']:
                plan['event_ids'].append(event_id)

        # Generate message IDs
        msg_id_counter = 1000

        # Process each system
        for system_id, spec in self.specs.items():
            # Determine if client code is needed
            runtime_config = self.determine_runtime(spec)

            system_plan = {
                'id': system_id,
                'runtime': 'server',  # Server systems always generated
                'needs_client': runtime_config['needs_client'],
                'client_reasons': runtime_config['reasons'],
                'description': spec.get('role', ''),
                'dependencies': self.extract_dependencies(spec),
                'queries': [],
                'commands': [],
                'player_actions': [],
                'behaviors': [],
                'helpers': [],
                'server_responses': []  # For client to receive server updates
            }

            # Process queries
            for query in spec.get('interface', {}).get('queries', []):
                query_id = query.get('id')

                # Read returns and args directly from spec (per schema)
                return_type = query.get('returns', 'void')
                args_dict = query.get('args', {})
                params = list(args_dict.keys()) if args_dict else []

                # Convert query_id to method name (GET_HERO_STATS -> getHeroStats)
                method_name = self.to_camel_case(query_id)

                query_plan = {
                    'id': query_id,
                    'method_name': method_name,
                    'params': params,
                    'returns': return_type,
                    'description': query.get('summary', '')
                }

                system_plan['queries'].append(query_plan)

                # Add to LLM implementation list
                plan['functions_needing_llm'].append({
                    'system': system_id,
                    'runtime': 'server',  # Queries are server-side
                    'type': 'query',
                    'method': method_name,
                    'spec': query_plan
                })

            # Process commands
            for command in spec.get('interface', {}).get('commands', []):
                command_id = command.get('id')

                # Read args directly from spec (per schema)
                args_dict = command.get('args', {})
                params = list(args_dict.keys()) if args_dict else []

                # Convert command_id to method name
                method_name = self.to_camel_case(command_id)

                # Extract emits from spec or infer from behaviors
                emits = []

                command_plan = {
                    'id': command_id,
                    'method_name': method_name,
                    'params': params,
                    'returns': 'void',  # Commands typically don't return values
                    'emits': emits,
                    'description': command.get('summary', '')
                }

                system_plan['commands'].append(command_plan)

                # Add to LLM implementation list
                plan['functions_needing_llm'].append({
                    'system': system_id,
                    'runtime': 'server',  # Commands are server-side
                    'type': 'command',
                    'method': method_name,
                    'spec': command_plan
                })

            # Process player actions
            for action in spec.get('interface', {}).get('player_actions', []):
                action_id = action.get('id')

                # Generate network message ID
                msg_id = msg_id_counter
                msg_id_counter += 1

                # Extract input params
                input_params = list(action.get('input', {}).keys())

                # Convert action_id to method name (ACTION_SELECT_HERO -> handleSelectHero)
                method_name = 'handle' + self.to_pascal_case(action_id.replace('ACTION_', ''))
                message_id = action_id.replace('ACTION_', '') + '_REQ'

                action_plan = {
                    'id': action_id,
                    'method_name': method_name,
                    'message_id': message_id,
                    'params': input_params,
                    'description': action.get('effect_summary', '')
                }

                system_plan['player_actions'].append(action_plan)

                # Add to network protocol
                plan['network_protocol']['client_messages'][message_id] = msg_id

                # Add to LLM implementation list
                plan['functions_needing_llm'].append({
                    'system': system_id,
                    'runtime': 'server',  # Player actions handled server-side
                    'type': 'player_action',
                    'method': method_name,
                    'spec': action_plan
                })

            # Process behaviors
            for behavior in spec.get('behaviors', []):
                behavior_id = behavior.get('id')
                trigger = behavior.get('trigger', {})

                # Convert behavior_id to handler method name
                handler_method = self.to_camel_case(behavior_id)

                behavior_plan = {
                    'id': behavior_id,
                    'trigger': trigger,
                    'handler_method': handler_method,
                    'summary': behavior.get('summary', ''),
                    'steps': behavior.get('steps', [])
                }

                system_plan['behaviors'].append(behavior_plan)

                # Extract helper methods needed from behavior actions
                self.extract_helpers_from_behavior(behavior, system_plan['helpers'])

            # Add system to server_systems (always generate server code)
            plan['server_systems'].append(system_plan)

            # If client code is needed, also add to client_systems
            if runtime_config['needs_client']:
                # Create a client system plan (subset of server plan)
                client_plan = {
                    'id': system_id,
                    'runtime': 'client',
                    'needs_client': True,
                    'client_reasons': runtime_config['reasons'],
                    'description': spec.get('role', ''),
                    'dependencies': self.extract_dependencies(spec),
                    'player_actions': system_plan['player_actions'],  # For sending requests
                    'server_responses': [],  # For receiving updates
                    'behaviors': system_plan['behaviors'],  # For client-side handlers
                    'helpers': system_plan['helpers'],
                    'needs_audio_visual': self._needs_audio_visual(spec)
                }
                plan['client_systems'].append(client_plan)

        self.generation_plan = {'generation_plan': plan}

        print(f"✓ Generation plan built:")
        print(f"  - Server systems: {len(plan['server_systems'])}")
        print(f"  - Client systems: {len(plan['client_systems'])}")
        print(f"  - Events: {len(plan['event_ids'])}")
        print(f"  - Functions needing LLM: {len(plan['functions_needing_llm'])}")

    def _needs_audio_visual(self, spec: Dict) -> bool:
        """Check if system needs audio/visual effects on client"""
        # Check behaviors for audio/visual steps
        behaviors = spec.get('behaviors', [])
        for behavior in behaviors:
            for step in behavior.get('steps', []):
                step_op = step.get('op', '').lower()
                if any(keyword in step_op for keyword in ['audio', 'visual', 'sound', 'effect', 'animate']):
                    return True

        # Check events that might trigger visual feedback
        emits = spec.get('events', {}).get('emits', [])
        for event in emits:
            event_id = event.get('id', '').lower()
            if any(keyword in event_id for keyword in ['visual', 'audio', 'sound', 'effect', 'animation']):
                return True

        return False

    def determine_runtime(self, spec: Dict) -> Dict:
        """
        Determine if a system needs client code based on:
        1. Explicit 'needs_client' field in spec
        2. Presence of player_actions (require client to send requests)
        3. Behaviors with UI/audio/visual actions
        4. Events that should be visualized on client

        Returns dict with 'needs_client' and 'reasons' (like Workflow 2)
        """
        reasons = []
        needs_client = False

        # Check explicit configuration (like Workflow 2)
        if spec.get('needs_client', False):
            needs_client = True
            reasons.append("Explicit needs_client flag")

        # Auto-detection: player_actions require client code
        player_actions = spec.get('interface', {}).get('player_actions', [])
        if player_actions:
            needs_client = True
            reasons.append(f"Has {len(player_actions)} player_actions (require client input)")

        # Auto-detection: check behavior action types for UI/audio/visual
        behaviors = spec.get('behaviors', [])
        for behavior in behaviors:
            for step in behavior.get('steps', []):
                # Check if step involves UI updates or visual feedback
                step_op = step.get('op', '')
                if 'ui' in step_op.lower() or 'visual' in step_op.lower() or 'audio' in step_op.lower():
                    needs_client = True
                    reasons.append(f"Behavior {behavior.get('id')} has UI/visual/audio actions")
                    break

        # Auto-detection: events with UI implications
        emits = spec.get('events', {}).get('emits', [])
        ui_event_keywords = ['ui', 'visual', 'display', 'show', 'notification', 'update']
        for event in emits:
            event_id = event.get('id', '').lower()
            if any(keyword in event_id for keyword in ui_event_keywords):
                needs_client = True
                reasons.append(f"Event {event.get('id')} implies UI updates")
                break

        if not reasons:
            reasons.append("Server-only (no client features detected)")

        return {
            'needs_client': needs_client,
            'reasons': reasons
        }

    def extract_dependencies(self, spec: Dict) -> List[str]:
        """Extract system dependencies from behaviors."""
        dependencies = set()

        for behavior in spec.get('behaviors', []):
            for step in behavior.get('steps', []):
                op = step.get('op')
                if op in ['query', 'command']:
                    system = step.get('system')
                    if system and system != spec.get('id'):
                        dependencies.add(system)

        return sorted(list(dependencies))

    def extract_helpers_from_behavior(self, behavior: Dict, helpers: List[Dict]):
        """Extract helper method names from behavior actions."""
        # Common helper methods
        helper_methods = {
            'play_sound': {'name': 'playSound', 'params': ['soundName']},
            'animate': {'name': 'animate', 'params': ['entityId', 'animName', 'duration']},
            'set_state': {'name': 'setState', 'params': ['entityId', 'state']}
        }

        for step in behavior.get('steps', []):
            if step.get('op') in helper_methods:
                helper_info = helper_methods[step['op']]
                # Check if not already added
                if not any(h['name'] == helper_info['name'] for h in helpers):
                    helpers.append(helper_info)


    def to_camel_case(self, snake_str: str) -> str:
        """Convert SNAKE_CASE or snake_case to camelCase."""
        # Remove ACTION_ prefix if present
        snake_str = snake_str.replace('ACTION_', '').replace('GET_', '').replace('SET_', '')

        components = snake_str.lower().split('_')
        return components[0] + ''.join(x.title() for x in components[1:])

    def to_pascal_case(self, snake_str: str) -> str:
        """Convert SNAKE_CASE or snake_case to PascalCase."""
        components = snake_str.lower().split('_')
        return ''.join(x.title() for x in components)

    def validate(self):
        """Validate loaded data for consistency."""
        print("Validating specifications...")

        errors = []
        warnings = []

        # Check that all subscribed events exist in registry
        registry_events = {e['id'] for e in self.global_registry.get('global_registry', {}).get('events', [])}

        for system_id, spec in self.specs.items():
            for sub in spec.get('events', {}).get('subscribes', []):
                event_id = sub.get('event')
                if event_id not in registry_events:
                    warnings.append(f"{system_id}: subscribes to unknown event '{event_id}'")

            for emit in spec.get('events', {}).get('emits', []):
                event_id = emit.get('id')
                if event_id not in registry_events:
                    warnings.append(f"{system_id}: emits unknown event '{event_id}'")

        if errors:
            print("✗ Validation errors:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)

        if warnings:
            print("⚠ Validation warnings:")
            for warning in warnings:
                print(f"  - {warning}")

        print("✓ Validation passed")

    def run(self):
        """Run the complete analysis pipeline."""
        print("=" * 60)
        print("SystemLuaGen Phase 1: Analysis & Preparation")
        print("=" * 60)
        print()

        # Load inputs
        self.load_all_specs()
        self.load_global_registry()
        self.load_systems_contracts()

        # Extract and process
        self.extract_entities()
        self.build_generation_plan()

        # Validate
        self.validate()

        # Save outputs
        print()
        print("Saving intermediate outputs...")
        self.save_yaml(self.entities_registry, self.intermediate_dir / "entities_registry.yml")
        self.save_yaml(self.generation_plan, self.intermediate_dir / "lua_generation_plan.yml")

        print()
        print("=" * 60)
        print("✓ Phase 1 Complete - Analysis successful")
        print("=" * 60)
        print()
        print("Next step: Run generate_lua_stubs.py")

        return 0


def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_specs.py <GAME_DIR>")
        print()
        print("Example:")
        print("  python analyze_specs.py ../../../projects/castle_defense/")
        sys.exit(1)

    game_dir = sys.argv[1]

    analyzer = SpecAnalyzer(game_dir)
    exit_code = analyzer.run()

    sys.exit(exit_code)


if __name__ == '__main__':
    main()
