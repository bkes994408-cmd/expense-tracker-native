import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { App } from '../App'

describe('Web report center UI', () => {
  it('updates summary when period changes', async () => {
    const user = userEvent.setup()
    render(<App />)

    expect(screen.getByText('$80,500')).toBeInTheDocument()
    await user.selectOptions(screen.getByLabelText('區間'), '1')
    expect(screen.getByText('$72,000')).toBeInTheDocument()
  })

  it('supports filter and chart mode controls', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.selectOptions(screen.getByLabelText('資料篩選'), 'expense')
    await user.selectOptions(screen.getByLabelText('圖表'), 'bar')

    expect((screen.getByLabelText('資料篩選') as HTMLSelectElement).value).toBe('expense')
    expect((screen.getByLabelText('圖表') as HTMLSelectElement).value).toBe('bar')
  })
})
