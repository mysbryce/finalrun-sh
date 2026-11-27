import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it } from 'vitest'
import { DEMO_RECEIPT_DEATH } from './demoOverlay'
import { useOverlayStore } from './overlayStore'
import { ReceiptCard } from './ReceiptCard'

describe('ReceiptCard', () => {
  beforeEach(() => {
    useOverlayStore.setState({ overlay: null, transfer: null })
  })

  it('shows the title and the dismiss hint', () => {
    useOverlayStore.setState({ overlay: DEMO_RECEIPT_DEATH })
    render(<ReceiptCard />)
    expect(screen.getByText('You died')).toBeInTheDocument()
    expect(screen.getByText('Esc or click to dismiss')).toBeInTheDocument()
  })

  it('renders nothing without an overlay', () => {
    const { container } = render(<ReceiptCard />)
    expect(container).toBeEmptyDOMElement()
  })
})
