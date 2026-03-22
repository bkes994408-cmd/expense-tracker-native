import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { App } from '../App'

describe('Web report center UI', () => {
  it('defaults to free plan and 1M summary', () => {
    render(<App />)

    expect(screen.getByText('Free 方案僅提供 1M 報表。升級 Pro 可解鎖 3M / 6M / 12M 趨勢分析。')).toBeInTheDocument()
    expect(screen.getByText('$72,000')).toBeInTheDocument()
    expect(screen.getByRole('option', { name: '3M（Pro）' })).toBeDisabled()
  })

  it('unlocks longer periods when switched to pro', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(screen.getByRole('button', { name: 'Pro' }))
    await user.selectOptions(screen.getByLabelText('區間'), '3')

    expect(screen.getByText('Pro 已啟用：可使用完整報表區間與進階分析。')).toBeInTheDocument()
    expect(screen.getByText('$80,500')).toBeInTheDocument()
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
