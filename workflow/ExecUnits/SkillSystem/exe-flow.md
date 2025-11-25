# 技能生成模块说明

## 基本介绍
本模块用于自动生成游戏中的技能配置，包括攻击技能和治疗技能。

## 使用方式
运行 skill_generator.py 来生成技能配置文件，保存到 skill_config.yml。
生成的数据结构包含技能类型、效果和魔法消耗等内容。

## 示例
生成的配置文件会如下所示：
```yaml
skills:
  - name: "火球术"
    type: "攻击"
    effect: "造成范围火焰伤害"
    mana_cost: 20
  - name: "治愈术"
    type: "治疗"
    effect: "恢复指定目标的生命值"
    mana_cost: 15
```