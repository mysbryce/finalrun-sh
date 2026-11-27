import { request } from '@/lib/ipc/bridge'
import { formatMoney } from '@/lib/format'
import { useInventoryStore } from './inventoryStore'
import { BAG, DETAILS, EQUIPMENT, FOOTER_HEIGHT, TABS, TITLE } from './layout'
import { BagGrid } from './components/BagGrid'
import { DetailsPanel } from './components/DetailsPanel'
import { EquipmentPanel } from './components/EquipmentPanel'
import { KeyHint } from './components/KeyHint'
import { PanelHeader } from './components/PanelHeader'

export function InventoryScreen() {
  const inventory = useInventoryStore((s) => s.inventory)
  const selectedUid = useInventoryStore((s) => s.selectedUid)
  const select = useInventoryStore((s) => s.select)
  if (!inventory) return null

  const selected =
    inventory.bag.find((i) => i.uid === selectedUid) ?? inventory.gear.find((i) => i.uid === selectedUid)

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
      <div className="absolute" style={{ left: BAG.left, top: BAG.top }}>
        <PanelHeader title="BAG" right={formatMoney(inventory.bagValue)} />
        <div className="mt-1">
          <BagGrid items={inventory.bag} slots={inventory.bagSlots} selectedUid={selectedUid} onSelect={select} />
        </div>
      </div>
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
