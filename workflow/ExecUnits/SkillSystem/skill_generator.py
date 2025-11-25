import yaml

# 模板配置数据
skill_template = [
    {"name": "火球术", "type": "攻击", "effect": "造成范围火焰伤害", "mana_cost": 20},
    {"name": "治愈术", "type": "治疗", "effect": "恢复指定目标的生命值", "mana_cost": 15},
]

# 保存技能配置到文件
def save_skills_to_file(config_file="skill_config.yml"):
    with open(config_file, "w", encoding="utf-8") as f:
        yaml.dump({"skills": skill_template}, f, allow_unicode=True)
    print(f"技能配置文件已保存到 {config_file}")

if __name__ == "__main__":
    save_skills_to_file()