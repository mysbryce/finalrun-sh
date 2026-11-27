import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import type { SearchItem, SearchView } from '@/lib/ipc/protocol'
import { SearchScreen } from './SearchScreen'
import { useSearchStore } from './searchStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => new Promise(() => {})) }))

const item = (uid: number, w: number, h: number): SearchItem => ({
  uid,
  id: `item_${uid}`,
  label: `Item ${uid}`,
  value: 100,
  source: 'bag',
  w,
  h,
  slot: -1,
})

const view = (items: SearchItem[]): SearchView => ({ target: 7, title: 'Body of Player 7', items })

describe('SearchScreen', () => {
  beforeEach(() => {
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation(() => new Promise(() => {}))
    useSearchStore.setState({ search: null })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('places tiles at the packed cell boxes', () => {
    useSearchStore.setState({ search: view([item(1, 6, 1), item(2, 2, 2), item(3, 1, 1)]) })
    render(<SearchScreen />)
    expect(screen.getByRole('button', { name: 'Item 1' }).parentElement).toHaveStyle({
      left: '0px',
      top: '0px',
      width: '305px',
      height: '50px',
    })
    expect(screen.getByRole('button', { name: 'Item 2' }).parentElement).toHaveStyle({
      left: '0px',
      top: '51px',
      width: '101px',
      height: '101px',
    })
    expect(screen.getByRole('button', { name: 'Item 3' }).parentElement).toHaveStyle({
      left: '102px',
      top: '51px',
    })
    expect(screen.getByText('3 items')).toBeInTheDocument()
  })

  it('sizes the content to the packed rows', () => {
    useSearchStore.setState({ search: view(Array.from({ length: 14 }, (_, i) => item(i + 1, 6, 1))) })
    render(<SearchScreen />)
    expect(screen.getByTestId('body-content')).toHaveStyle({ height: `${14 * 51 - 1}px` })
  })

  it('sends search.take once while the request is unsettled', () => {
    useSearchStore.setState({ search: view([item(1, 1, 1)]) })
    render(<SearchScreen />)
    const tile = screen.getByRole('button', { name: 'Item 1' })
    fireEvent.click(tile)
    fireEvent.click(tile)
    expect(request).toHaveBeenCalledTimes(1)
    expect(request).toHaveBeenCalledWith('search.take', { target: 7, uid: 1 })
    expect(tile.parentElement).toHaveAttribute('aria-busy', 'true')
  })

  it('shows Search closed. on no_search and frees the tile', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('no_search')))
    useSearchStore.setState({ search: view([item(1, 1, 1)]) })
    render(<SearchScreen />)
    const tile = screen.getByRole('button', { name: 'Item 1' })
    fireEvent.click(tile)
    await act(async () => {})
    expect(screen.getByText('Search closed.')).toBeInTheDocument()
    expect(tile.parentElement).not.toHaveAttribute('aria-busy')
    fireEvent.click(tile)
    expect(request).toHaveBeenCalledTimes(2)
  })

  it('scrolls a focused tile into view', () => {
    const scroll = vi.fn()
    Element.prototype.scrollIntoView = scroll
    useSearchStore.setState({ search: view([item(1, 1, 1)]) })
    render(<SearchScreen />)
    act(() => screen.getByRole('button', { name: 'Item 1' }).focus())
    expect(scroll).toHaveBeenCalledWith({ block: 'nearest' })
    delete (Element.prototype as { scrollIntoView?: unknown }).scrollIntoView
  })

  it('shows the empty body text', () => {
    useSearchStore.setState({ search: view([]) })
    render(<SearchScreen />)
    expect(screen.getByText('Nothing left to take')).toBeInTheDocument()
  })

  it('shows Searching… with Close disabled while search is null', () => {
    render(<SearchScreen />)
    expect(screen.getByText('Searching…')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Close/ })).toBeDisabled()
    expect(screen.queryByTestId('body-content')).toBeNull()
  })

  it('Close sends search.close', () => {
    useSearchStore.setState({ search: view([]) })
    render(<SearchScreen />)
    fireEvent.click(screen.getByRole('button', { name: /Close/ }))
    expect(request).toHaveBeenCalledWith('search.close', { target: 7 })
  })
})
