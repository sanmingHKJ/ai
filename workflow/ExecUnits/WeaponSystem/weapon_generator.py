import yaml

# 模板配置数据
weapon_template = [
    {"name": "长剑", "type": "近战", "damage": 10, "weight": 5.0},
    {"name": "弓箭", "type": "远程", "damage": 8, "weight": 3.0},
]

# 保存武器配置到文件
def save_weapons_to_file(config_file="weapon_config.yml"):
    with open(config_file, "w", encoding="utf-8") as f:
        yaml.dump({"weapons": weapon_template}, f, allow_unicode=True)
    print(f"武器配置文件已保存到 {config_file}")

if __name__ == "__main__":
    save_weapons_to_file()