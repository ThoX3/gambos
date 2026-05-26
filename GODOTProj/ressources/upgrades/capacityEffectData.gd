extends Resource
class_name capacityEffectData

enum TargetCapacityEffect {PLAYER_HEALTH, PLAYER_SPEED, PLAYER_DAMAGE, PLAYER_ATTACK_SPEED, PLAYER_ATTACK_RANGE, PLAYER_COLLECT_RANGE}

@export var targetCapacity: TargetCapacityEffect
@export var value: float
