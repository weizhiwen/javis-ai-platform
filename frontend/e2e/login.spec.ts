import { test, expect } from '@playwright/test'

test.describe('Login', () => {
  test('should show login page', async ({ page }) => {
    await page.goto('/login')
    await expect(page).toHaveTitle(/Javis/)
  })
})
