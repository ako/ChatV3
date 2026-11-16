// Drives the Helpdesk chat page and asks the brief's question. Security is Off here, so there is no login and no
// session to log out of; the script closes its browser context on exit either way.
const { chromium } = require('playwright');
const q = process.argv[2] || 'What does BAT-418 cost, and what fits on EB-200?';
const out = process.argv[3] || 'evidence/chat';
(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  try {
    await page.goto('http://localhost:8080/', { waitUntil: 'networkidle', timeout: 60000 });
    const box = page.locator('textarea').first();
    await box.waitFor({ timeout: 60000 });
    await box.fill(q);
    await box.press('Enter');
    // wait for an assistant message that is not the prompt
    await page.waitForFunction(() => document.querySelectorAll('[class*="message"]').length >= 2, null, { timeout: 120000 }).catch(() => {});
    await page.waitForTimeout(45000);
    await page.screenshot({ path: out + '.png', fullPage: true });
    const text = await page.evaluate(() => document.body.innerText);
    require('fs').writeFileSync(out + '.txt', text);
    console.log(text.slice(0, 1500));
  } finally { await ctx.close(); await browser.close(); }
})().catch(e => { console.error('FAILED', e.message); process.exit(1); });
