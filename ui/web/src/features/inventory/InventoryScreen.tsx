import { useState } from 'react'
import { DndContext, DragOverlay, PointerSensor, useSensor, useSensors } from '@dnd-kit/core'
import type { DragEndEvent, DragStartEvent } from '@dnd-kit/core'
import { useMutation } from '@tanstack/react-query'
import { request } from '@/lib/ipc/bridge'
import { formatMoney } from '@/lib/format'
import { useInventoryStore } from './inventoryStore'
import { BAG, DETAILS, EQUIPMENT, FOOTER_HEIGHT, TABS, TILE, TITLE } from './layout'
import { placeBagItems, slotFromDropId } from './placement'
import { BagGrid } from './components/BagGrid'
import { DetailsPanel } from './components/DetailsPanel'
import { EquipmentPanel } from './components/EquipmentPanel'
import { ItemTile } from './components/ItemTile'
import { KeyHint } from './components/KeyHint'
import { PanelHeader } from './components/PanelHeader'

export function InventoryScreen() {
  const inventory = useInventoryStore((s) => s.inventory)
  const selectedUid = useInventoryStore((s) => s.selectedUid)
  const select = useInventoryStore((s) => s.select)
  const moveLocal = useInventoryStore((s) => s.moveLocal)
  const [activeUid, setActiveUid] = useState<number | null>(null)
  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 4 } }))
  const move = useMutation({
    mutationFn: (v: { uid: number; slot: number }) => request('inventory.move', v),
  })

  const onDragStart = (event: DragStartEvent) => setActiveUid(Number(event.active.id))
  const onDragCancel = () => setActiveUid(null)
  const onDragEnd = (event: DragEndEvent) => {
    setActiveUid(null)
    const inv = useInventoryStore.getState().inventory
    if (!inv) return
    const uid = Number(event.active.id)
    const slot = slotFromDropId(event.over?.id)
    if (slot === null) return
    const current = placeBagItems(inv.bag, inv.bagSlots).findIndex((c) => c?.uid === uid)
    if (current === slot) return
    moveLocal(uid, slot)
    move.mutate({ uid, slot })
  }

  if (!inventory) return null

  const selected =
    inventory.bag.find((i) => i.uid === selectedUid) ?? inventory.gear.find((i) => i.uid === selectedUid)
  const activeItem = activeUid === null ? undefined : inventory.bag.find((i) => i.uid === activeUid)

  return (
    <div className="pointer-events-auto fixed inset-0 bg-zinc-950/85 text-white">
      <div
        className="absolute text-[44px] font-black uppercase leading-none tracking-tight"
        style={{ left: TITLE.left, top: TITLE.top }}
      >
        INVENTORY
      </div>
      <div className="absolute" style={{ left: TABS.left, top: TABS.top }}>
        <div className="grid h-[27px] w-[132px] place-items-center bg-amber-400 text-sm font-bold uppercase text-zinc-900">
          BAG
        </div>
      </div>
      <div className="absolute rounded bg-zinc-800/90 px-3 py-1 text-lg font-bold" style={{ right: 80, top: 26 }}>
        {formatMoney(inventory.cash)}
      </div>
      <div
        className="absolute"
        style={{ left: DETAILS.left, top: DETAILS.top, width: DETAILS.width, height: DETAILS.height }}
      >
        <DetailsPanel item={selected} />
      </div>
      <DndContext sensors={sensors} onDragStart={onDragStart} onDragEnd={onDragEnd} onDragCancel={onDragCancel}>
        <div className="absolute" style={{ left: BAG.left, top: BAG.top }}>
          <PanelHeader title="BAG" right={formatMoney(inventory.bagValue)} />
          <div className="mt-1">
            <BagGrid items={inventory.bag} slots={inventory.bagSlots} selectedUid={selectedUid} onSelect={select} />
          </div>
        </div>
        <DragOverlay>{activeItem ? <ItemTile item={activeItem} size={{ w: TILE, h: TILE }} /> : null}</DragOverlay>
      </DndContext>
      <div className="absolute" style={{ left: EQUIPMENT.left, top: EQUIPMENT.top, width: EQUIPMENT.width }}>
        <EquipmentPanel gear={inventory.gear} selectedUid={selectedUid} onSelect={select} />
      </div>
      <div
        className="absolute inset-x-0 bottom-0 flex items-center gap-8 bg-zinc-900/95 px-[30px]"
        style={{ height: FOOTER_HEIGHT }}
      >
        <button type="button" onClick={() => void request('inventory.close', {})}>
          <KeyHint k="ESC" label="Back" />
        </button>
        <KeyHint k="TAB" label="Close" />
        <KeyHint k="LMB" label="Select" />
      </div>
    </div>
  )
}
