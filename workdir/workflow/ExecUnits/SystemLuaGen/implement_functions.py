#!/usr/bin/env python3
"""
SystemLuaGen Phase 3: LLM Implementation

Uses LLM to implement query/command/player_action function bodies.

Usage:
    python implement_functions.py <GAME_DIR> [--system <system_name>] [--dry-run] [--parallel]

Example:
    python implement_functions.py ../../../projects/castle_defense/
    python implement_functions.py ../../../projects/castle_defense/ --system HeroSystem
    python implement_functions.py ../../../projects/castle_defense/ --parallel
"""

import sys
import os
import yaml
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import argparse
import anthropic
import concurrent.futures
from threading import Lock


class LuaFunctionImplementor:
    def __init__(self, game_dir: str, config: Dict, dry_run: bool = False, parallel: bool = False):
        self.game_dir = Path(game_dir).resolve()
        self.units_data_dir = self.game_dir / "UnitsData"
        self.intermediate_dir = self.units_data_dir / "_intermediate"
        self.service_nodes_dir = self.game_dir / "ServiceNodes"
        self.config = config
        self.dry_run = dry_run
        self.parallel = parallel

        # Loaded data
        self.generation_plan: Optional[Dict] = None
        self.entities_registry: Optional[Dict] = None

        # LLM client
        self.llm_client = None
        self.initialize_llm()

        # Implementation log
        self.implementation_log = {
            'timestamp': datetime.now().isoformat(),
            'implementations': [],
            'successes': 0,
            'failures': 0,
            'skipped': 0
        }

        # Thread-safe logging
        self.log_lock = Lock()

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

    def initialize_llm(self):
        """Initialize LLM client based on config."""
        provider = self.config.get('llm', {}).get('provider', 'anthropic')
        api_key_env = self.config.get('llm', {}).get('api_key_env', 'ANTHROPIC_API_KEY')

        api_key = os.getenv(api_key_env)
        if not api_key:
            print(f"Warning: {api_key_env} not found in environment")
            print(f"LLM implementation will be skipped")
            return

        if provider == 'anthropic':
            self.llm_client = anthropic.Anthropic(api_key=api_key)
        else:
            print(f"Error: Unsupported LLM provider: {provider}")
            sys.exit(2)

    def load_generation_plan(self):
        """Load generation plan from Phase 1."""
        plan_path = self.intermediate_dir / "lua_generation_plan.yml"
        if not plan_path.exists():
            print(f"Error: lua_generation_plan.yml not found")
            sys.exit(2)

        data = self.load_yaml(plan_path)
        self.generation_plan = data.get('generation_plan', {})

    def load_entities_registry(self):
        """Load entities registry from Phase 1."""
        entities_path = self.intermediate_dir / "entities_registry.yml"
        if entities_path.exists():
            self.entities_registry = self.load_yaml(entities_path)

    def find_todo_llm_markers(self, lua_file: Path) -> List[Tuple[int, str, str]]:
        """Find TODO_LLM markers in Lua file."""
        markers = []

        try:
            with open(lua_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            in_llm_section = False
            llm_type = None
            function_start = 0

            for i, line in enumerate(lines):
                # Check for LLM_IMPL marker
                if '-- LLM_IMPL' in line:
                    in_llm_section = True
                    function_start = i
                    continue

                # Check for function signature
                if in_llm_section and 'function ' in line:
                    # Extract function name
                    match = re.search(r'function\s+\w+:(\w+)\s*\(', line)
                    if match:
                        function_name = match.group(1)

                        # Determine type based on markers above
                        context_lines = lines[max(0, i-5):i]
                        context = ''.join(context_lines)

                        if '-- Query:' in context:
                            llm_type = 'query'
                        elif '-- Command:' in context:
                            llm_type = 'command'
                        elif '-- Player Action:' in context:
                            llm_type = 'player_action'
                        else:
                            llm_type = 'unknown'

                        markers.append((function_start, function_name, llm_type))
                        in_llm_section = False

        except Exception as e:
            print(f"Error reading {lua_file}: {e}")

        return markers

    def extract_function_context(self, lua_file: Path, function_name: str) -> Dict[str, Any]:
        """Extract context for a function to be implemented."""
        context = {
            'file': lua_file.name,
            'system': lua_file.parent.name,
            'function_name': function_name,
            'signature': '',
            'description': '',
            'params': [],
            'returns': '',
            'emits': [],
            'entities': {}
        }

        try:
            with open(lua_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Find the function
            pattern = rf'-- LLM_IMPL.*?function\s+\w+:{function_name}\s*\([^)]*\).*?end'
            match = re.search(pattern, content, re.DOTALL)

            if match:
                function_block = match.group(0)

                # Extract description
                desc_match = re.search(r'-- (?:Query|Command|Player Action):\s*(.+)', function_block)
                if desc_match:
                    context['description'] = desc_match.group(1)

                # Extract more description
                summary_match = re.search(r'-- Description:\s*(.+)', function_block)
                if summary_match:
                    context['description'] += ' ' + summary_match.group(1)

                # Extract signature
                sig_match = re.search(r'function\s+(\w+:\w+\s*\([^)]*\))', function_block)
                if sig_match:
                    context['signature'] = sig_match.group(1)

                # Extract parameters
                params_match = re.search(r'-- Parameters:\s*(.+)', function_block)
                if params_match:
                    context['params'] = [p.strip() for p in params_match.group(1).split(',')]

                # Extract returns
                returns_match = re.search(r'-- Returns:\s*(.+)', function_block)
                if returns_match:
                    context['returns'] = returns_match.group(1).strip()

                # Extract emits
                emits_match = re.search(r'-- Emits:\s*(.+)', function_block)
                if emits_match:
                    context['emits'] = [e.strip() for e in emits_match.group(1).split(',')]

            # Extract entities for this system
            system_name = context['system']
            if self.entities_registry:
                entities = self.entities_registry.get('entities', {})
                system_entities = {
                    name: entity for name, entity in entities.items()
                    if entity.get('defined_by') == system_name
                }
                context['entities'] = system_entities

        except Exception as e:
            print(f"Error extracting context for {function_name}: {e}")

        return context

    def build_llm_prompt(self, context: Dict, llm_type: str) -> str:
        """Build LLM prompt for implementing a function."""
        system_name = context['system']
        function_name = context['function_name']
        description = context['description']
        params = context['params']
        returns = context['returns']
        emits = context['emits']
        entities = context['entities']

        prompt = f"""You are implementing a Lua method for a business system in MiniWorld Studio's SGF Framework.

SYSTEM: {system_name}Server
METHOD: {function_name}
TYPE: {llm_type}

FUNCTION SIGNATURE (DO NOT CHANGE):
{context['signature']}
    -- returns: {returns}
end

SPECIFICATION:
- Description: {description}
- Parameters: {', '.join(params) if params else 'none'}
- Returns: {returns}
"""

        if emits:
            prompt += f"- Must Emit Events: {', '.join(emits)}\n"

        if entities:
            prompt += f"\nENTITY DEFINITIONS FOR THIS SYSTEM:\n"
            for entity_name, entity_data in entities.items():
                prompt += f"\n{entity_name}:\n"
                fields = entity_data.get('fields', {})
                for field_name, field_type in fields.items():
                    prompt += f"  - {field_name}: {field_type}\n"

        prompt += """
ENTITY ACCESS PATTERN:
- Entities are stored in self.data.EntityName
- Use a dictionary/table structure: self.data.EntityName[id]
- Example: local hero = self.data.HeroInstance[hero_instance_id]
- Always check if entity exists before accessing fields

EVENT EMISSION:
- Load EventID module: local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
- Emit events: self.events:emit(EventID.EVENT_NAME, { payload })

LOGGING:
- Use self.log:info("message") for important operations
- Use self.log:error("message") for errors
- Use self.log:debug("message") for detailed info

DEPENDENCIES:
- Access other systems: self.dependencies_cache.SystemName
- Always check if dependency exists before calling methods
- Example: if self.dependencies_cache.CombatSystem then ... end

SGF FRAMEWORK CONTEXT:
- self.sgf = framework instance
- self.log = logging service
- self.events = event bus
- self.data = system data storage (store entities here)
- self.dependencies_cache = cached system references

REQUIREMENTS:
1. Keep the exact function signature (DO NOT CHANGE)
2. Implement complete, working logic (not stubs)
3. Handle edge cases (nil checks, empty tables)
4. Return the correct type as specified
5. Use proper Lua syntax (not, ~=, and, or)
6. Add helpful log messages
7. Follow MiniWorld Studio patterns

IMPLEMENTATION GUIDELINES:
"""

        if llm_type == 'query':
            prompt += """
- Queries are READ-ONLY operations
- DO NOT modify state or emit events
- DO NOT have side effects
- Return calculated values based on current state
- Example: calculating max HP, checking if ability is ready, getting item price
"""
        elif llm_type == 'command':
            prompt += """
- Commands MODIFY state
- MUST emit all specified events
- Can call other commands and queries
- Update self.data with new state
- Example: reviving hero, applying damage, adding item to inventory
"""
        elif llm_type == 'player_action':
            prompt += """
- Player actions are network request handlers
- Validate input from userId and data parameters
- Call appropriate commands/queries to handle the action
- Return a table with { success = bool, error = string (optional) }
- Example: handling move request, ability cast, item purchase
"""

        prompt += """
IMPORTANT:
- Provide ONLY the function body (code between 'function' and 'end')
- Do NOT include the function signature line
- Do NOT include the 'end' line
- Start directly with the first line of implementation
- Use proper indentation (4 spaces)

IMPLEMENT THE FUNCTION BODY NOW:
"""

        return prompt

    def call_llm(self, prompt: str, context: Dict) -> Optional[str]:
        """Call LLM to generate function implementation."""
        if not self.llm_client:
            return None

        try:
            model = self.config.get('llm', {}).get('model', 'claude-sonnet-4-5-20250929')
            temperature = self.config.get('llm', {}).get('temperature', 0.2)
            max_tokens = self.config.get('llm', {}).get('max_tokens', 1000)

            response = self.llm_client.messages.create(
                model=model,
                max_tokens=max_tokens,
                temperature=temperature,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )

            if response.content:
                raw_text = response.content[0].text
                # Clean up markdown code fences if present
                return self.clean_llm_response(raw_text)

        except Exception as e:
            print(f"Error calling LLM: {e}")
            return None

    def clean_llm_response(self, text: str) -> str:
        """Remove markdown code fences and other formatting from LLM response."""
        # Remove opening code fence with optional language (```lua, ```Lua, ```)
        # Handle both at start of string and after whitespace
        text = re.sub(r'^\s*```[a-zA-Z]*\s*\n', '', text, flags=re.MULTILINE)

        # Remove closing code fence
        text = re.sub(r'\n\s*```\s*$', '', text)

        # Also remove any stray code fences in the middle
        text = re.sub(r'\n\s*```[a-zA-Z]*\s*\n', '\n', text)
        text = re.sub(r'\n\s*```\s*\n', '\n', text)

        # Trim leading/trailing whitespace
        text = text.strip()

        # Normalize indentation - remove common leading whitespace
        lines = text.split('\n')
        # Find minimum indentation (excluding empty lines)
        non_empty_lines = [line for line in lines if line.strip()]
        if non_empty_lines:
            min_indent = min(len(line) - len(line.lstrip()) for line in non_empty_lines)
            # Remove the common indentation from all lines
            normalized_lines = []
            for line in lines:
                if line.strip():  # Non-empty line
                    normalized_lines.append(line[min_indent:])
                else:  # Empty line
                    normalized_lines.append('')
            text = '\n'.join(normalized_lines)

        return text

    def validate_implementation(self, implementation: str, context: Dict) -> Tuple[bool, str]:
        """Validate LLM-generated implementation."""
        errors = []

        # Check not empty
        if not implementation.strip():
            errors.append("Empty implementation")

        # Check doesn't include function signature
        if 'function ' in implementation:
            errors.append("Implementation includes function signature (should be body only)")

        # Check doesn't include end statement
        lines = implementation.strip().split('\n')
        if lines and lines[-1].strip() == 'end':
            errors.append("Implementation includes 'end' statement (should be body only)")

        # Check for required event emissions
        emits = context.get('emits', [])
        for event in emits:
            if event not in implementation:
                errors.append(f"Missing required event emission: {event}")

        # Check basic Lua syntax (balanced keywords)
        if_count = implementation.count(' if ')
        then_count = implementation.count(' then')
        end_count = implementation.count('\nend') + implementation.count(' end')

        # This is a heuristic check
        if if_count > 0 and then_count == 0:
            errors.append("'if' without 'then'")

        if errors:
            return False, "; ".join(errors)

        return True, "OK"

    def replace_todo_llm(self, lua_file: Path, function_name: str, implementation: str) -> bool:
        """Replace TODO_LLM marker with actual implementation."""
        try:
            with open(lua_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Find the function
            pattern = rf'(-- LLM_IMPL.*?function\s+\w+:{function_name}\s*\([^)]*\)\s*\n)(.*?)(end)'

            def replace_body(match):
                header = match.group(1)
                footer = match.group(3)
                # Add proper indentation to implementation
                indented_impl = '\n'.join('    ' + line if line.strip() else ''
                                         for line in implementation.split('\n'))
                return header + indented_impl + '\n' + footer

            new_content = re.sub(pattern, replace_body, content, flags=re.DOTALL)

            if new_content != content:
                with open(lua_file, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                return True
            else:
                print(f"Warning: No replacement made for {function_name}")
                return False

        except Exception as e:
            print(f"Error replacing function {function_name}: {e}")
            return False

    def implement_function(self, lua_file: Path, function_name: str, llm_type: str) -> Dict:
        """Implement a single function using LLM."""
        result = {
            'file': lua_file.name,
            'function': function_name,
            'type': llm_type,
            'status': 'pending',
            'error': None
        }

        try:
            # Extract context
            context = self.extract_function_context(lua_file, function_name)

            # Build prompt
            prompt = self.build_llm_prompt(context, llm_type)

            if self.dry_run:
                print(f"\n{'='*60}")
                print(f"DRY RUN - {lua_file.name}:{function_name}")
                print(f"{'='*60}")
                print(prompt)
                result['status'] = 'dry_run'
                return result

            # Call LLM
            print(f"  Implementing {function_name} ({llm_type})...", end=' ')
            implementation = self.call_llm(prompt, context)

            if not implementation:
                result['status'] = 'failed'
                result['error'] = 'LLM returned empty response'
                print("FAILED (empty response)")
                return result

            # Validate implementation
            valid, error = self.validate_implementation(implementation, context)
            if not valid:
                result['status'] = 'failed'
                result['error'] = f'Validation failed: {error}'
                print(f"FAILED ({error})")
                return result

            # Replace in file
            if self.replace_todo_llm(lua_file, function_name, implementation):
                result['status'] = 'success'
                print("✓")
            else:
                result['status'] = 'failed'
                result['error'] = 'Failed to replace in file'
                print("FAILED (replacement)")

        except Exception as e:
            result['status'] = 'failed'
            result['error'] = str(e)
            print(f"ERROR: {e}")

        return result

    def implement_system(self, system: Dict) -> List[Dict]:
        """Implement all functions for a system."""
        system_name = system['id']
        runtime = system['runtime']

        print(f"\n{'='*60}")
        print(f"System: {system_name}{runtime.capitalize()}")
        print(f"{'='*60}")

        # Find the Lua file
        lua_file = self.service_nodes_dir / "MainStorage" / "Framework" / "GameSystems" / system_name / f"{system_name}{runtime.capitalize()}.lua"

        if not lua_file.exists():
            print(f"Error: {lua_file} not found")
            return []

        # Find TODO_LLM markers
        markers = self.find_todo_llm_markers(lua_file)

        if not markers:
            print("No TODO_LLM markers found")
            return []

        print(f"Found {len(markers)} functions to implement")

        results = []

        if self.parallel:
            # Parallel implementation
            with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
                futures = []
                for _, function_name, llm_type in markers:
                    future = executor.submit(self.implement_function, lua_file, function_name, llm_type)
                    futures.append(future)

                for future in concurrent.futures.as_completed(futures):
                    result = future.result()
                    results.append(result)
        else:
            # Sequential implementation
            for _, function_name, llm_type in markers:
                result = self.implement_function(lua_file, function_name, llm_type)
                results.append(result)

        return results

    def run(self, target_system: Optional[str] = None):
        """Run the complete LLM implementation pipeline."""
        print("=" * 60)
        print("SystemLuaGen Phase 3: LLM Implementation")
        print("=" * 60)
        print()

        if self.dry_run:
            print("DRY RUN MODE - No changes will be made")
            print()

        if self.parallel:
            print("PARALLEL MODE - Multiple LLM calls in parallel")
            print()

        # Load data
        self.load_generation_plan()
        self.load_entities_registry()

        # Get systems to process
        server_systems = self.generation_plan.get('server_systems', [])
        client_systems = self.generation_plan.get('client_systems', [])
        all_systems = server_systems + client_systems

        if target_system:
            all_systems = [s for s in all_systems if s['id'] == target_system]
            if not all_systems:
                print(f"Error: System '{target_system}' not found")
                sys.exit(1)

        # Process each system
        for system in all_systems:
            results = self.implement_system(system)

            with self.log_lock:
                self.implementation_log['implementations'].extend(results)
                for result in results:
                    if result['status'] == 'success':
                        self.implementation_log['successes'] += 1
                    elif result['status'] == 'failed':
                        self.implementation_log['failures'] += 1
                    else:
                        self.implementation_log['skipped'] += 1

        # Save log
        if not self.dry_run:
            self.save_yaml(
                {'implementation_log': self.implementation_log},
                self.intermediate_dir / "llm_implementation_log.yml"
            )

        # Summary
        print()
        print("=" * 60)
        print("✓ Phase 3 Complete - LLM Implementation")
        print("=" * 60)
        print()
        print(f"Successes: {self.implementation_log['successes']}")
        print(f"Failures:  {self.implementation_log['failures']}")
        print(f"Skipped:   {self.implementation_log['skipped']}")
        print()

        if self.implementation_log['failures'] > 0:
            print("Failed implementations:")
            for impl in self.implementation_log['implementations']:
                if impl['status'] == 'failed':
                    print(f"  ✗ {impl['file']}:{impl['function']} - {impl['error']}")
            print()

        return 0 if self.implementation_log['failures'] == 0 else 1


def main():
    parser = argparse.ArgumentParser(description='Implement Lua functions using LLM')
    parser.add_argument('game_dir', help='Game directory path')
    parser.add_argument('--system', help='Only process specific system')
    parser.add_argument('--dry-run', action='store_true', help='Show prompts without calling LLM')
    parser.add_argument('--parallel', action='store_true', help='Use parallel LLM calls for speed')

    args = parser.parse_args()

    # Load config
    script_dir = Path(__file__).parent
    config_path = script_dir / "config.yml"

    if config_path.exists():
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
    else:
        config = {}

    implementor = LuaFunctionImplementor(
        args.game_dir,
        config,
        dry_run=args.dry_run,
        parallel=args.parallel
    )

    exit_code = implementor.run(target_system=args.system)
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
