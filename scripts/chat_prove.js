// Item 3: ask the chat the brief's question and keep the screenshot + text as evidence.
const { withSession } = require('./browser');
const fs = require('fs');
const q = process.argv[2] || 'What does BAT-418 cost, and what fits on EB-200?';
const out = process.argv[3] || 'evidence/chat';
withSession(async (page) => {
  const box = page.locator('textarea').first();
  await box.waitFor({ timeout: 60000 });
  await box.fill(q);
  await box.press('Tab');
  await box.evaluate(el => { const b = el.closest('form, .chat-input-container, div').parentElement.querySelectorAll('button'); b[b.length - 1].click(); });
  await page.waitForFunction(() => /Assistant/.test(document.body.innerText) && !/Thinking|Generating/.test(document.body.innerText), null, { timeout: 150000 }).catch(() => {});
  await page.waitForTimeout(8000);
  await page.screenshot({ path: out + '.png', fullPage: true });
  const text = await page.evaluate(() => document.body.innerText);
  fs.writeFileSync(out + '.txt', text);
  console.log(text.slice(0, 1200));
}).catch(e => { console.error('FAILED', e.message); process.exit(1); });
