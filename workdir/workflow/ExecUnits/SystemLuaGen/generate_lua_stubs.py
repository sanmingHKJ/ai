#!/usr/bin/env python3
"""
SystemLuaGen Phase 2: Deterministic Lua Generation

Generates structural Lua code using Jinja2 templates.

Usage:
    python generate_lua_stubs.py <GAME_DIR>

Example:
    python generate_lua_stubs.py ../../../projects/castle_defense/
"""

import sys
import os
import yaml
from pathlib import Path
from typing import Dict, List, Any
from jinja2 import Environment, FileSystemLoader, Template
from behavior_converter import BehaviorConverter


class LuaStubGenerator:
    def __init__(self, game_dir: str):
        self.game_dir = Path(game_dir).resolve()
        self.units_data_dir = self.game_dir / "UnitsData"
        self.intermediate_dir = self.units_data_dir / "_intermediate"
        self.output_dir = self.game_dir / "ServiceNodes"

        # Template environment
        script_dir = Path(__file__).parent
        self.template_dir = script_dir / "templates"
        self.jinja_env = Environment(loader=FileSystemLoader(str(self.template_dir)))

        # Behavior converter
        self.behavior_converter = BehaviorConverter()

        # Loaded data
        self.generation_plan: Optional[Dict] = None
        self.entities_registry: Optional[Dict] = None

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

    def write_file(self, content: str, file_path: Path):
        """Write content to file."""
        try:
            file_path.parent.mkdir(parents=True, exist_ok=True)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ Generated: {file_path}")
        except Exception as e:
            print(f"Error writing {file_path}: {e}")
            sys.exit(2)

    def load_generation_plan(self):
        """Load generation plan from Phase 1."""
        plan_path = self.intermediate_dir / "lua_generation_plan.yml"
        print(f"Loading generation plan: {plan_path}")

        if not plan_path.exists():
            print(f"Error: lua_generation_plan.yml not found")
            print(f"Please run analyze_specs.py first")
            sys.exit(2)

        data = self.load_yaml(plan_path)
        self.generation_plan = data.get('generation_plan', {})
        print(f"✓ Generation plan loaded")

    def load_entities_registry(self):
        """Load entities registry from Phase 1."""
        entities_path = self.intermediate_dir / "entities_registry.yml"
        print(f"Loading entities registry: {entities_path}")

        if not entities_path.exists():
            print(f"Error: entities_registry.yml not found")
            print(f"Please run analyze_specs.py first")
            sys.exit(2)

        self.entities_registry = self.load_yaml(entities_path)
        print(f"✓ Entities registry loaded")

    def generate_protocol(self):
        """Generate Protocol.lua for network message IDs."""
        print("Generating Protocol.lua...")

        template = self.jinja_env.get_template('Protocol.lua.j2')

        context = {
            'client_messages': self.generation_plan.get('network_protocol', {}).get('client_messages', {}),
            'server_messages': self.generation_plan.get('network_protocol', {}).get('server_messages', {})
        }

        output = template.render(**context)

        output_path = self.output_dir / "MainStorage" / "Framework" / "Runtime" / "Protocol.lua"
        self.write_file(output, output_path)

        # Generate JSON config
        json_path = output_path.with_suffix('.json')
        json_content = self.generate_json_config("ModuleScript", "Protocol")
        self.write_file(json_content, json_path)

    def generate_event_ids(self):
        """Generate EventID.lua for event definitions."""
        print("Generating EventID.lua...")

        template = self.jinja_env.get_template('EventID.lua.j2')

        context = {
            'event_ids': self.generation_plan.get('event_ids', [])
        }

        output = template.render(**context)

        output_path = self.output_dir / "MainStorage" / "Framework" / "Runtime" / "EventID.lua"
        self.write_file(output, output_path)

        # Generate JSON config
        json_path = output_path.with_suffix('.json')
        json_content = self.generate_json_config("ModuleScript", "EventID")
        self.write_file(json_content, json_path)

    def generate_system(self, system: Dict, runtime: str):
        """Generate business system module (server or client)."""
        system_name = system['id']
        print(f"  Generating {system_name}{runtime.capitalize()}...")

        # Select appropriate template based on runtime
        if runtime.lower() == 'server':
            template = self.jinja_env.get_template('SystemServer.lua.j2')
        else:  # client
            template = self.jinja_env.get_template('SystemClient.lua.j2')

        # Convert behaviors to Lua code
        behaviors_with_code = []
        for behavior in system.get('behaviors', []):
            behavior_with_code = behavior.copy()
            # Generate Lua code for behavior
            lua_code = self.behavior_converter.convert_behavior(behavior, system_name)
            behavior_with_code['lua_code'] = lua_code
            behaviors_with_code.append(behavior_with_code)

        # Prepare context
        context = {
            'system_name': system_name,
            'system_description': system.get('description', ''),
            'dependencies': system.get('dependencies', []),
            'queries': system.get('queries', []),
            'commands': system.get('commands', []),
            'player_actions': system.get('player_actions', []),
            'behaviors': behaviors_with_code,
            'helpers': system.get('helpers', []),
            'has_network': len(system.get('player_actions', [])) > 0,
            'server_responses': system.get('server_responses', []),
            'needs_audio_visual': system.get('needs_audio_visual', False)
        }

        output = template.render(**context)

        # Write to file
        system_dir = self.output_dir / "MainStorage" / "Framework" / "GameSystems" / system_name
        file_name = f"{system_name}{runtime.capitalize()}"
        output_path = system_dir / f"{file_name}.lua"
        self.write_file(output, output_path)

        # Generate JSON config
        json_path = output_path.with_suffix('.json')
        json_content = self.generate_json_config("ModuleScript", file_name)
        self.write_file(json_content, json_path)

    def generate_all_systems(self):
        """Generate all business system modules."""
        print("Generating business systems...")

        # Track which system folders we've created
        system_folders_created = set()

        # Generate server systems
        server_systems = self.generation_plan.get('server_systems', [])
        for system in server_systems:
            system_name = system['id']

            # Generate folder .json once per system
            if system_name not in system_folders_created:
                system_folders_created.add(system_name)

                # Generate folder-level .json (simple format)
                folder_json_path = self.output_dir / "MainStorage" / "Framework" / "GameSystems" / f"{system_name}.json"
                folder_json_content = self.generate_folder_json(system_name)
                self.write_file(folder_json_content, folder_json_path)

            self.generate_system(system, 'Server')

        # Generate client systems
        client_systems = self.generation_plan.get('client_systems', [])
        for system in client_systems:
            # Folder already created when server system was generated
            self.generate_system(system, 'Client')

        print(f"✓ Generated {len(server_systems)} server systems and {len(client_systems)} client systems")

    def generate_server_main(self):
        """Generate ServerMain.lua entry point."""
        print("Generating ServerMain.lua...")

        template = self.jinja_env.get_template('ServerMain.lua.j2')

        context = {
            'systems': self.generation_plan.get('server_systems', [])
        }

        output = template.render(**context)

        output_path = self.output_dir / "ServerScriptService" / "ServerMain.lua"
        self.write_file(output, output_path)

        # Generate JSON config
        json_path = output_path.with_suffix('.json')
        json_content = self.generate_json_config("Script", "ServerMain")
        self.write_file(json_content, json_path)

    def generate_client_main(self):
        """Generate ClientMain.lua entry point."""
        print("Generating ClientMain.lua...")

        template = self.jinja_env.get_template('ClientMain.lua.j2')

        context = {
            'systems': self.generation_plan.get('client_systems', [])
        }

        output = template.render(**context)

        output_path = self.output_dir / "StartPlayer" / "StarterPlayerScripts" / "ClientMain.lua"
        self.write_file(output, output_path)

        # Generate JSON config
        json_path = output_path.with_suffix('.json')
        json_content = self.generate_json_config("LocalScript", "ClientMain")
        self.write_file(json_content, json_path)

    def generate_json_config(self, class_type: str, real_node_name: str) -> str:
        """Generate JSON config for a file."""
        import json
        metadata = {
            "ClassType": class_type,
            "realNodeName": real_node_name,
            "attribute": [],
            "flags": 0,
            "reflex": [
                {"Name": real_node_name},
                {"Tag": 0},
                {"Enabled": True}
            ]
        }
        return json.dumps(metadata, indent="\t")

    def generate_folder_json(self, folder_name: str) -> str:
        """Generate JSON metadata for a folder (SandboxNode)."""
        import json
        metadata = {
            "ClassType": "SandboxNode",
            "realNodeName": folder_name,
            "attribute": [],
            "flags": 0,
            "reflex": [
                {"Name": folder_name},
                {"Tag": 0},
                {"Enabled": True},
                {"SyncMode": 0},
                {"LocalSyncFlag": 0},
                {"ResourceDynamicLoad": False},
                {"IgnoreSafeMode": False},
                {"ResourceLoadMode": 0}
            ]
        }
        return json.dumps(metadata, indent="\t")

    def save_generation_metadata(self):
        """Save metadata about generated files."""
        print("Saving generation metadata...")

        metadata = {
            'generated_files': {
                'runtime': ['Protocol.lua', 'EventID.lua'],
                'server_systems': [s['id'] + 'Server.lua' for s in self.generation_plan.get('server_systems', [])],
                'client_systems': [s['id'] + 'Client.lua' for s in self.generation_plan.get('client_systems', [])],
                'entry_points': ['ServerMain.lua', 'ClientMain.lua']
            },
            'statistics': {
                'total_systems': len(self.generation_plan.get('server_systems', [])) + len(self.generation_plan.get('client_systems', [])),
                'total_events': len(self.generation_plan.get('event_ids', [])),
                'total_network_messages': len(self.generation_plan.get('network_protocol', {}).get('client_messages', {}))
            }
        }

        self.save_yaml(metadata, self.intermediate_dir / "lua_stubs_generated.yml")

    def run(self):
        """Run the complete generation pipeline."""
        print("=" * 60)
        print("SystemLuaGen Phase 2: Deterministic Lua Generation")
        print("=" * 60)
        print()

        # Load inputs
        self.load_generation_plan()
        self.load_entities_registry()

        # Generate runtime definitions
        print()
        print("Generating runtime definitions...")
        self.generate_protocol()
        self.generate_event_ids()

        # Generate business systems
        print()
        self.generate_all_systems()

        # Generate entry points
        print()
        print("Generating entry points...")
        self.generate_server_main()
        self.generate_client_main()

        # Save metadata
        print()
        self.save_generation_metadata()

        print()
        print("=" * 60)
        print("✓ Phase 2 Complete - Lua stubs generated")
        print("=" * 60)
        print()
        print("Next step: Run implement_functions.py to implement function bodies with LLM")

        return 0


def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_lua_stubs.py <GAME_DIR>")
        print()
        print("Example:")
        print("  python generate_lua_stubs.py ../../../projects/castle_defense/")
        sys.exit(1)

    game_dir = sys.argv[1]

    generator = LuaStubGenerator(game_dir)
    exit_code = generator.run()

    sys.exit(exit_code)


if __name__ == '__main__':
    main()
