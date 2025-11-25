#!/usr/bin/env python3
"""
Behavior DSL to Lua Converter

Converts behavior specifications (DSL) into executable Lua code with proper
control flow, error handling, and SGF framework integration.

Usage:
    from behavior_converter import BehaviorConverter

    converter = BehaviorConverter()
    lua_code = converter.convert_behavior(behavior_spec, system_name)
"""

from typing import Dict, List, Any, Optional
import re


class BehaviorConverter:
    """Converts behavior DSL to Lua code."""

    def __init__(self):
        self.indent_level = 0
        self.indent_size = 4
        self.current_trigger_type = None  # Track trigger type for context

    def indent(self, code: str = "") -> str:
        """Add indentation to code line."""
        if not code.strip():
            return ""
        return " " * (self.indent_level * self.indent_size) + code

    def convert_behavior(self, behavior: Dict, system_name: str) -> str:
        """Convert a complete behavior to Lua function."""
        behavior_id = behavior.get('id', '')
        trigger = behavior.get('trigger', {})
        steps = behavior.get('steps', [])
        summary = behavior.get('summary', '')

        # Store trigger type for context-aware arg conversion
        self.current_trigger_type = trigger.get('type', '')

        # Track assigned variables in this behavior
        self.assigned_vars = set()
        for step in steps:
            if step.get('assign_to'):
                self.assigned_vars.add(step['assign_to'])

        lines = []

        # Function signature
        handler_method = self.to_camel_case(behavior_id)

        if trigger.get('type') == 'event':
            lines.append(f"-- Behavior Handler: {behavior_id}")
            lines.append(f"-- Trigger: event {trigger.get('name', '')}")
            lines.append(f"-- Summary: {summary}")
            lines.append(f"function {system_name}Server:{handler_method}(data)")
        elif trigger.get('type') == 'timer':
            lines.append(f"-- Behavior Handler: {behavior_id}")
            lines.append(f"-- Trigger: timer every {trigger.get('every', '1.0')}s")
            lines.append(f"-- Summary: {summary}")
            lines.append(f"function {system_name}Server:{handler_method}()")
        elif trigger.get('type') == 'init':
            lines.append(f"-- Behavior Handler: {behavior_id}")
            lines.append(f"-- Trigger: init")
            lines.append(f"-- Summary: {summary}")
            lines.append(f"function {system_name}Server:{handler_method}()")
        elif trigger.get('type') == 'action':
            lines.append(f"-- Behavior Handler: {behavior_id}")
            lines.append(f"-- Trigger: player action {trigger.get('name', '')}")
            lines.append(f"-- Summary: {summary}")
            lines.append(f"function {system_name}Server:{handler_method}(userId, data)")
        else:
            lines.append(f"-- Behavior Handler: {behavior_id}")
            lines.append(f"function {system_name}Server:{handler_method}()")

        self.indent_level = 1

        # Convert behavior steps
        if steps:
            lines.append(self.indent("-- Behavior steps"))
            step_code = self.convert_steps(steps, system_name)
            lines.extend(step_code)
        else:
            lines.append(self.indent("-- TODO: Implement behavior logic"))

        # Log completion
        lines.append(self.indent())
        lines.append(self.indent(f'self.log:debug("[{system_name}Server] {behavior_id} completed")'))

        self.indent_level = 0
        lines.append("end")

        return "\n".join(lines)

    def convert_steps(self, steps: List[Dict], system_name: str) -> List[str]:
        """Convert behavior steps to Lua code."""
        lines = []

        for i, step in enumerate(steps):
            op = step.get('op', '')

            if op == 'query':
                lines.extend(self.convert_query_step(step, system_name))
            elif op == 'command':
                lines.extend(self.convert_command_step(step, system_name))
            elif op == 'emit':
                lines.extend(self.convert_emit_step(step, system_name))
            elif op == 'if' or op == 'if_true':
                lines.extend(self.convert_if_step(step, system_name))
            elif op == 'for' or op == 'for_each':
                lines.extend(self.convert_for_step(step, system_name))
            elif op == 'assign':
                lines.extend(self.convert_assign_step(step))
            elif op == 'call_method':
                lines.extend(self.convert_method_call_step(step))
            elif op == 'play_sound':
                lines.extend(self.convert_play_sound_step(step))
            elif op == 'animate':
                lines.extend(self.convert_animate_step(step))
            elif op == 'set_state':
                lines.extend(self.convert_set_state_step(step))
            else:
                lines.append(self.indent(f"-- TODO: Implement op '{op}'"))

            # Add blank line between steps (except last)
            if i < len(steps) - 1:
                lines.append(self.indent())

        return lines

    def convert_query_step(self, step: Dict, system_name: str) -> List[str]:
        """Convert query operation to Lua."""
        lines = []

        query_system = step.get('system', system_name)
        query_name = step.get('name', '')
        args = step.get('args', {})
        assign_to = step.get('assign_to', 'result')

        # Convert query name to method name
        method_name = self.to_camel_case(query_name)

        # Get dependency reference
        if query_system == system_name:
            system_ref = "self"
        else:
            system_ref = f"self.dependencies_cache.{query_system}"

        # Build args string
        args_list = []
        for arg_name, arg_value in args.items():
            lua_value = self.convert_arg_value(arg_value)
            args_list.append(lua_value)

        args_str = ", ".join(args_list) if args_list else ""

        lines.append(self.indent(f"-- Query: {query_system}.{query_name}"))

        # Check if system exists (for dependencies)
        if query_system != system_name:
            lines.append(self.indent(f"if not {system_ref} then"))
            self.indent_level += 1
            lines.append(self.indent(f'self.log:error("[{system_name}Server] Dependency not available: {query_system}")'))
            lines.append(self.indent("return"))
            self.indent_level -= 1
            lines.append(self.indent("end"))

        lines.append(self.indent(f"local {assign_to} = {system_ref}:{method_name}({args_str})"))

        return lines

    def convert_command_step(self, step: Dict, system_name: str) -> List[str]:
        """Convert command operation to Lua."""
        lines = []

        command_system = step.get('system', system_name)
        command_name = step.get('name', '')
        args = step.get('args', {})

        # Convert command name to method name
        method_name = self.to_camel_case(command_name)

        # Get dependency reference
        if command_system == system_name:
            system_ref = "self"
        else:
            system_ref = f"self.dependencies_cache.{command_system}"

        # Build args string
        args_list = []
        for arg_name, arg_value in args.items():
            lua_value = self.convert_arg_value(arg_value)
            args_list.append(lua_value)

        args_str = ", ".join(args_list) if args_list else ""

        lines.append(self.indent(f"-- Command: {command_system}.{command_name}"))

        # Check if system exists (for dependencies)
        if command_system != system_name:
            lines.append(self.indent(f"if not {system_ref} then"))
            self.indent_level += 1
            lines.append(self.indent(f'self.log:error("[{system_name}Server] Dependency not available: {command_system}")'))
            lines.append(self.indent("return"))
            self.indent_level -= 1
            lines.append(self.indent("end"))

        lines.append(self.indent(f"{system_ref}:{method_name}({args_str})"))

        return lines

    def convert_emit_step(self, step: Dict, system_name: str) -> List[str]:
        """Convert emit operation to Lua."""
        lines = []

        event_name = step.get('name', '')
        args = step.get('args', {})

        lines.append(self.indent(f"-- Emit event: {event_name}"))
        lines.append(self.indent("local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)"))
        lines.append(self.indent(f"self.events:emit(EventID.{event_name}, {{"))

        self.indent_level += 1
        for arg_name, arg_value in args.items():
            lua_value = self.convert_arg_value(arg_value)
            lines.append(self.indent(f"{arg_name} = {lua_value},"))
        self.indent_level -= 1

        lines.append(self.indent("})"))

        return lines

    def convert_if_step(self, step: Dict, system_name: str) -> List[str]:
        """Convert if/conditional operation to Lua."""
        lines = []

        condition = step.get('condition') or step.get('cond', '')
        then_steps = step.get('then', [])
        else_steps = step.get('else', [])

        # Convert condition to Lua
        lua_condition = self.convert_condition(condition)

        lines.append(self.indent(f"-- Conditional: {condition}"))
        lines.append(self.indent(f"if {lua_condition} then"))

        self.indent_level += 1
        if then_steps:
            lines.extend(self.convert_steps(then_steps, system_name))
        else:
            lines.append(self.indent("-- TODO: Implement then branch"))
        self.indent_level -= 1

        if else_steps:
            lines.append(self.indent("else"))
            self.indent_level += 1
            lines.extend(self.convert_steps(else_steps, system_name))
            self.indent_level -= 1

        lines.append(self.indent("end"))

        return lines

    def convert_for_step(self, step: Dict, system_name: str) -> List[str]:
        """Convert for/loop operation to Lua."""
        lines = []

        collection = step.get('collection', 'items')
        item_var = step.get('item', 'item')
        body_steps = step.get('body', [])

        lines.append(self.indent(f"-- Loop over: {collection}"))
        lines.append(self.indent(f"for _, {item_var} in ipairs({collection}) do"))

        self.indent_level += 1
        if body_steps:
            lines.extend(self.convert_steps(body_steps, system_name))
        else:
            lines.append(self.indent("-- TODO: Implement loop body"))
        self.indent_level -= 1

        lines.append(self.indent("end"))

        return lines

    def convert_assign_step(self, step: Dict) -> List[str]:
        """Convert assignment operation to Lua."""
        lines = []

        var_name = step.get('var', '')
        value = step.get('value', 'nil')

        lua_value = self.convert_arg_value(value)

        lines.append(self.indent(f"local {var_name} = {lua_value}"))

        return lines

    def convert_method_call_step(self, step: Dict) -> List[str]:
        """Convert method call operation to Lua."""
        lines = []

        method = step.get('method', '')
        args = step.get('args', {})

        args_list = [self.convert_arg_value(v) for v in args.values()]
        args_str = ", ".join(args_list) if args_list else ""

        lines.append(self.indent(f"self:{method}({args_str})"))

        return lines

    def convert_play_sound_step(self, step: Dict) -> List[str]:
        """Convert play_sound operation to Lua."""
        lines = []

        sound = step.get('sound', '')

        lines.append(self.indent(f'self:playSound("{sound}")'))

        return lines

    def convert_animate_step(self, step: Dict) -> List[str]:
        """Convert animate operation to Lua."""
        lines = []

        animation = step.get('animation', '')
        duration = step.get('duration_s', 1.0)
        target = step.get('target', 'data.target_ref')

        target_lua = self.convert_arg_value(target)

        lines.append(self.indent(f'self:animate({target_lua}, "{animation}", {duration})'))

        return lines

    def convert_set_state_step(self, step: Dict) -> List[str]:
        """Convert set_state operation to Lua."""
        lines = []

        state = step.get('state', {})
        target = step.get('target', 'data.target_ref')

        target_lua = self.convert_arg_value(target)

        # Convert state dict to Lua table
        state_pairs = []
        for k, v in state.items():
            lua_value = self.convert_arg_value(v)
            state_pairs.append(f"{k} = {lua_value}")

        state_str = "{ " + ", ".join(state_pairs) + " }" if state_pairs else "{}"

        lines.append(self.indent(f"self:setState({target_lua}, {state_str})"))

        return lines

    def convert_arg_value(self, value: Any) -> str:
        """Convert argument value to Lua representation."""
        if isinstance(value, str):
            # Check if it's already a full reference (e.g., "data.hero_id", "payload.target_id")
            if '.' in value:
                return value

            # Check if it's a simple variable name that needs to be extracted from data
            elif re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', value):
                # Check if this is a variable assigned within this behavior
                if hasattr(self, 'assigned_vars') and value in self.assigned_vars:
                    return value

                # For event triggers, simple variables likely come from the data parameter
                # unless they're known local variables
                known_locals = {'can_use', 'hero_stats', 'abilities', 'result', 'team_members',
                                'max_hp', 'stat_bonuses', 'stats', 'alive_heroes', 'cooldown_abilities',
                                'new_level', 'new_health', 'old_mana', 'new_mana', 'userId', 'data'}

                if self.current_trigger_type == 'event' and value not in known_locals:
                    # This is likely a field from the event payload
                    return f"data.{value}"
                else:
                    # It's a local variable or already defined
                    return value
            # It's a string literal
            else:
                return f'"{value}"'
        elif isinstance(value, bool):
            return "true" if value else "false"
        elif isinstance(value, (int, float)):
            return str(value)
        elif value is None:
            return "nil"
        elif isinstance(value, dict):
            # Convert dict to Lua table
            pairs = []
            for k, v in value.items():
                lua_value = self.convert_arg_value(v)
                pairs.append(f"{k} = {lua_value}")
            return "{ " + ", ".join(pairs) + " }"
        elif isinstance(value, list):
            # Convert list to Lua table
            items = [self.convert_arg_value(item) for item in value]
            return "{ " + ", ".join(items) + " }"
        else:
            return str(value)

    def convert_condition(self, condition: str) -> str:
        """Convert condition string to Lua."""
        # Simple conversion - handles basic comparisons
        # Replace == with ==, != with ~=, etc.
        lua_condition = condition
        lua_condition = lua_condition.replace('!=', '~=')
        lua_condition = lua_condition.replace('&&', ' and ')
        lua_condition = lua_condition.replace('||', ' or ')
        lua_condition = lua_condition.replace('!', 'not ')

        return lua_condition

    def to_camel_case(self, snake_str: str) -> str:
        """Convert SNAKE_CASE or snake_case to camelCase."""
        snake_str = snake_str.replace('ACTION_', '').replace('GET_', '').replace('SET_', '')
        components = snake_str.lower().split('_')
        return components[0] + ''.join(x.title() for x in components[1:])


# Example usage
if __name__ == '__main__':
    converter = BehaviorConverter()

    # Example behavior
    behavior = {
        'id': 'on_damage_dealt',
        'trigger': {
            'type': 'event',
            'name': 'DAMAGE_DEALT'
        },
        'summary': 'Reduces hero health when damage is received',
        'steps': [
            {
                'op': 'query',
                'system': 'HeroSystem',
                'name': 'GET_HERO_STATS',
                'args': {'hero_instance_id': 'data.target_id'},
                'assign_to': 'hero_stats'
            },
            {
                'op': 'command',
                'system': 'HeroSystem',
                'name': 'MODIFY_HERO_STAT',
                'args': {
                    'hero_instance_id': 'data.target_id',
                    'stat_name': 'current_health',
                    'delta': -10
                }
            },
            {
                'op': 'if',
                'condition': 'hero_stats.health <= 0',
                'then': [
                    {
                        'op': 'emit',
                        'name': 'HERO_DIED',
                        'args': {'hero_id': 'data.target_id'}
                    }
                ]
            }
        ]
    }

    lua_code = converter.convert_behavior(behavior, 'HeroSystem')
    print(lua_code)
