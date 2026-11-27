class_name CosmeticData
extends Resource
## One cosmetic item for a character appearance slot.
##
## Pure visual: no stats. The mesh is a placeholder primitive for now; later it
## is skinned to the shared character skeleton.

@export var id: String = ""
@export var slot: String = ""
@export var mesh: Mesh
@export var color: Color = Color.WHITE
## Position relative to the player origin (at the feet).
@export var offset: Vector3 = Vector3.ZERO
