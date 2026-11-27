# Art Direction

Decided by the owner on 2026-11-27.

## Style: stylized low-poly
- Chunky, readable silhouettes; flat or soft-gradient colors; minimal texture detail.
- Roles must read at a distance: Criminal mask, Cop uniform, Citizen casual. Silhouette first, color second.
- Budget per character (all slots equipped): ~5-8k tris, 1 shared atlas material where possible.

## Source: CC0 base + Blender edits
- Start from a CC0 modular humanoid and CC0 animation set (license must be CC0; record source URL and license in `assets/CREDITS.md`).
- Customize and build original outfits, hair, masks in Blender (Blender MCP is available to the supervisor).
- Export GLB to Godot (`godot-export` workflow), one shared skeleton for male and female bodies so animations are reused.

## Modular character
- Body types: male, female (same skeleton, different base mesh).
- Slots: head, hair, top, bottom, shoes, hat, glasses, accessory, mask.
- Each slot item is a `CosmeticData` Resource pointing at a mesh skinned to the shared skeleton. Swapping is data only.
- Skin tone and hair color via material parameters, not separate meshes.

## Vehicles and props
- Same low-poly language. Vehicle skins = material/paint swaps plus optional wrap decal; rims as a separate mesh slot.
- Loot bag: one base mesh, skins are material swaps.
