import { create } from 'zustand'
import type { SearchView } from '@/lib/ipc/protocol'

type SearchStore = {
  search: SearchView | null
  setSearch: (view: SearchView | null) => void
}

export const useSearchStore = create<SearchStore>((set) => ({
  search: null,
  setSearch: (view) => set({ search: view }),
}))
