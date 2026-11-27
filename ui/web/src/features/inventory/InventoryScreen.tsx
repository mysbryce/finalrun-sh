import { useRef, useState } from 'react'
import { DndContext, DragOverlay, PointerSensor, pointerWithin, useSensor, useSensors } from '@dnd-kit/core'
import type { DragEndEvent, DragOverEvent, DragStartEvent } from '@dnd-kit/core'
import { request } from '@/lib/ipc/bridge'
import { formatMoney } from '@/lib/format'
import type { InventoryView } from '@/lib/ipc/protocol'
import { useInventoryStore } from './inventoryStore'
import { useConfirmedMove } from './useConfirmedMove'
import { BAG_COL, EQUIP_COL, PANEL } from './layout'
import { BAG_COLUMNS, BAG_GRID, BAG_ROWS, cellBox } from '@/lib/grid/gridLayout'
import { moveBagItem, placeBagItems, slotFromDropId, targetSlot } from '@/lib/grid/placement'
import { unzoomModifier } from './dragZoom'
import { rarityOf } from '@/lib/grid/rarity'
import { BagGrid } from './components/BagGrid'
import { EquipmentPanel } from './components/EquipmentPanel'
import { ItemTile } from '@/lib/grid/ItemTile'
import { KeyHint } from '@/lib/ui/KeyHint'

type Preview = { slot: number; w: number; h: number; ok: boolean }

const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi)

export function InventoryScreen({ embedded = false }: { embedded?: boolean }) {
  const inventory = useInventoryStore((s) => s.inventory)
  const selectedUid = useInventoryStore((s) => s.selectedUid)
  const select = useInventoryStore((s) => s.select)
  const notice = useInventoryStore((s) => s.notice)
  const commitMove = useConfirmedMove()
  const [activeUid, setActiveUid] = useState<number | null>(null)
  const [preview, setPreview] = useState<Preview | null>(null)
  const grab = useRef<{ offCol: number; offRow: number }>({ offCol: 0, offRow: 0 })
  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 4 } }))

  // Target top-left slot for the dragged item, plus its current slot.
  const resolve = (inv: InventoryView, uid: number, overId: string | number | null | undefined) => {
    const item = inv.bag.find((i) => i.uid === uid)
    if (!item) return null
    const pointer = slotFromDropId(overId)
    const target = pointer === null ? null : targetSlot(pointer, grab.current.offCol, grab.current.offRow, BAG_COLUMNS)
    const current = placeBagItems(inv.bag, inv.bagSlots, BAG_COLUMNS).find((p) => p.item.uid === uid)?.slot
    return { item, target, current }
  }

  const clearDrag = () => {
    setActiveUid(null)
    setPreview(null)
  }

  const onDragStart = (event: DragStartEvent) => {
    const uid = Number(event.active.id)
    setActiveUid(uid)
    const item = useInventoryStore.getState().inventory?.bag.find((i) => i.uid === uid)
    const pe = event.activatorEvent as PointerEvent | null
    const r = (pe?.target as Element | null)?.closest('button')?.getBoundingClientRect()
    if (!r || !item || !pe) {
      grab.current = { offCol: 0, offRow: 0 }
      return
    }
    const w = item.w
    const h = item.h
    grab.current = {
      offCol: clamp(Math.floor((pe.clientX - r.left) / (r.width / w)), 0, w - 1),
      offRow: clamp(Math.floor((pe.clientY - r.top) / (r.height / h)), 0, h - 1),
    }
  }

  const onDragOver = (event: DragOverEvent) => {
    const inv = useInventoryStore.getState().inventory
    if (!inv) return
    const uid = Number(event.active.id)
    const res = resolve(inv, uid, event.over?.id)
    let next: Preview | null = null
    if (res && res.target !== null) {
      const ok =
        res.target === res.current || moveBagItem(inv.bag, uid, res.target, inv.bagSlots, BAG_COLUMNS) !== inv.bag
      next = { slot: res.target, w: res.item.w, h: res.item.h, ok }
    }
    setPreview((prev) => {
      if (prev === null && next === null) return prev
      if (prev !== null && next !== null && prev.slot === next.slot && prev.ok === next.ok) return prev
      return next
    })
  }

  const onDragEnd = (event: DragEndEvent) => {
    clearDrag()
    const inv = useInventoryStore.getState().inventory
    if (!inv) return
    const uid = Number(event.active.id)
    const res = resolve(inv, uid, event.over?.id)
    if (!res || res.target === null || res.target === res.current) return
    if (moveBagItem(inv.bag, uid, res.target, inv.bagSlots, BAG_COLUMNS) === inv.bag) return
    commitMove(uid, res.target)
  }

  const selected =
    inventory?.bag.find((i) => i.uid === selectedUid) ?? inventory?.gear.find((i) => i.uid === selectedUid)
  const activeItem = activeUid === null ? undefined : inventory?.bag.find((i) => i.uid === activeUid)

  return (
    <div className="pointer-events-none fixed inset-0 text-white">
      <div
        className="pointer-events-auto absolute overflow-hidden bg-black/60 backdrop-blur-md"
        style={{ right: PANEL.right, top: PANEL.top, width: PANEL.width, height: PANEL.height }}
      >
        <div className="absolute inset-x-0 top-0 bg-black/40" style={{ height: PANEL.header }}>
          <div
            className="absolute flex items-center justify-between"
            style={{ left: BAG_COL.left, width: BAG_GRID.width, height: PANEL.header }}
          >
            <span className="text-lg font-bold uppercase tracking-wide">BAG</span>
            <span className="text-sm font-semibold text-white/80">{inventory ? formatMoney(inventory.bagValue) : '—'}</span>
          </div>
          <div
            className="absolute flex items-center"
            style={{ left: EQUIP_COL.left, width: EQUIP_COL.width, height: PANEL.header }}
          >
            <span className="text-lg font-bold uppercase tracking-wide">EQUIPMENT</span>
          </div>
        </div>
        {inventory ? (
          <DndContext
            sensors={sensors}
            collisionDetection={pointerWithin}
            onDragStart={onDragStart}
            onDragOver={onDragOver}
            onDragEnd={onDragEnd}
            onDragCancel={clearDrag}
          >
            <div className="absolute" style={{ left: BAG_COL.left, top: BAG_COL.top }}>
              <BagGrid
                items={inventory.bag}
                slots={inventory.bagSlots}
                selectedUid={selectedUid}
                onSelect={select}
                preview={preview}
              />
            </div>
            <DragOverlay modifiers={[unzoomModifier]}>
              {activeItem ? (
                <ItemTile
                  item={activeItem}
                  size={{ w: cellBox(0, activeItem.w, activeItem.h).width, h: cellBox(0, activeItem.w, activeItem.h).height }}
                />
              ) : null}
            </DragOverlay>
          </DndContext>
        ) : (
          <div className="absolute" style={{ left: BAG_COL.left, top: BAG_COL.top }}>
            <BagGrid items={[]} slots={BAG_COLUMNS * BAG_ROWS} selectedUid={null} onSelect={select} />
          </div>
        )}
        <div className="absolute" style={{ left: EQUIP_COL.left, top: EQUIP_COL.top }}>
          <EquipmentPanel gear={inventory?.gear ?? []} selectedUid={selectedUid} onSelect={select} />
        </div>
        <div
          className="absolute inset-x-0 bottom-0 flex items-center justify-between bg-black/40"
          style={{ height: PANEL.footer, paddingLeft: PANEL.inset, paddingRight: PANEL.inset }}
        >
          {notice ? (
            <span className="text-xs text-amber-300">{notice}</span>
          ) : !inventory ? (
            <span className="text-xs text-white/50">Loading inventory…</span>
          ) : selected ? (
            <div className="flex items-baseline gap-2">
              <span className="text-sm font-bold">{selected.label}</span>
              <span className="text-xs font-semibold">{formatMoney(selected.value)}</span>
              <span className="text-[10px] uppercase text-white/60">{rarityOf(selected.value)}</span>
            </div>
          ) : (
            <span className="text-xs text-white/50">Select an item</span>
          )}
          <div className="flex items-center gap-4">
            {!embedded && (
              <button
                type="button"
                className="flex h-[22px] items-center rounded-sm bg-white/10 px-2"
                onClick={() => void request('inventory.close', {})}
              >
                <KeyHint k="ESC" label="Back" />
              </button>
            )}
            {!embedded && <KeyHint k="TAB" label="Close" />}
            <KeyHint k="LMB" label="Select" />
          </div>
        </div>
      </div>
    </div>
  )
}
