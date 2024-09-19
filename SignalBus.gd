extends Node

signal unit_died(unit)


func on_unit_died(unit):
	unit_died.emit(unit)
