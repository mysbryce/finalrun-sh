# Art Direction

Decided by the owner on 2026-11-27. Changed from stylized low-poly to semi-realistic by the owner on 2026-11-27.

## Style: semi-realistic
- Realistic adult human proportions, simplified detail: PBR materials with modest texture detail, no photoreal skin or hair.
- Our own look: original faces, outfits and masks. No other game's character designs.
- Roles must read at a distance: Criminal mask, Cop uniform, Citizen casual. Silhouette first, color second.
- Budget per character (all slots equipped): ~15-25k tris at LOD0, with LOD1/LOD2 for distance; one material per body plus one per slot item where possible.

## Source: CC0 base + Blender edits
- Base humans from MakeHuman via the MPFB2 Blender add-on (exported models are CC0), game-engine rig. Animations from a CC0 set (candidate: Quaternius Universal Animation Library), retargeted to that rig. Record source URL and license of everything in `assets/CREDITS.md`.
- Customize and build original outfits, hair, masks in Blender (Blender MCP is available to the supervisor).
- Until this lands the game uses Kenney Mini Characters (CC0) as a stand-in.
- Export GLB to Godot (`godot-export` workflow), one shared skeleton for male and female bodies so animations are reused.

## Modular character
- Body types: male, female (same skeleton, different base mesh).
- Slots: head, hair, top, bottom, shoes, hat, glasses, accessory, mask.
- Each slot item is a `CosmeticData` Resource pointing at a mesh skinned to the shared skeleton. Swapping is data only.
- Skin tone and hair color via material parameters, not separate meshes.

## Vehicles and props
- Same semi-realistic language. Vehicle skins = material/paint swaps plus optional wrap decal; rims as a separate mesh slot.
- Loot bag: one base mesh, skins are material swaps.
