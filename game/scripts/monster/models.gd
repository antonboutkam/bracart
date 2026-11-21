extends RefCounted
const Blocks = preload("res://scripts/monster/structure.gd")
const Fractured = preload("res://scripts/monster/fractured_structure.gd")
const BlockArena = preload("res://scripts/monster/arena.gd")
const FracturedArena = preload("res://scripts/monster/fractured_arena.gd")

static func create(id: String):
 return Fractured.new() if id == Fractured.ID else Blocks.new()

static func arena_for(model):
 return FracturedArena.new() if model is Fractured else BlockArena.new()
