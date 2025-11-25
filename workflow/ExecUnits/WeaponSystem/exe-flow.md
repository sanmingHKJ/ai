# 武器生成模块说明

## 基本介绍
本模块用于自动生成游戏中的武器配置，包括近战武器和远程武器。

## 使用方式
运行 weapon_generator.py 来生成武器配置文件，保存到 weapon_config.yml。
生成的数据结构包含武器类型、攻击力、重量等内容。

## 示例
生成的配置文件会如下所示：
```yaml
weapons:
  - name: "长剑"
    type: "近战"
    damage: 10
    weight: 5.0
  - name: "弓箭"
    type: "远程"
    damage: 8
    weight: 3.0
```
