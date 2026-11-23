extends RefCounted
const Blocks = preload("res://scripts/monster/structure.gd")
const Fractured = preload("res://scripts/monster/fractured_structure.gd")
const BlockArena = preload("res://scripts/monster/arena.gd")
const FracturedArena = preload("res://scripts/monster/fractured_arena.gd")

static func create(id: String):
 var entry = preload("res://scripts/monster/catalog.gd").find(id)
 return Fractured.new() if entry.get("format") == "fractured" else Blocks.new()

static func arena_for(model):
 return FracturedArena.new() if model is Fractured else BlockArena.new()
