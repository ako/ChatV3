// Items 2 (KB), 4, 5, 8, 9 and the monitoring pages, driven in the running app. Writes evidence/*.txt + *.png.
const { withSession, openMenu } = require('./browser');
const fs = require('fs');
const ev = (n) => 'evidence/' + n;
const only = process.argv.slice(2);
const want = (n) => only.length === 0 || only.includes(n);

async function ask(page, menu, label, question, name, waitMs = 90000) {
  await openMenu(page, menu);
  const box = page.getByLabel(label).first();
  await box.waitFor({ timeout: 30000 });
  await box.fill(question);
  await box.press('Tab');
  await page.getByRole('button', { name: 'Ask' }).first().click();
  await page.waitForFunction(() => { const t = [...document.querySelectorAll('textarea')].map(x => x.value).join(''); return t.length > 3; }, null, { timeout: waitMs }).catch(() => {});
  await page.waitForTimeout(1500);
  const answer = await page.evaluate(() => [...document.querySelectorAll('textarea')].map(x => x.value).join('\n'));
  await page.screenshot({ path: ev(name + '.png') });
  fs.writeFileSync(ev(name + '.txt'), 'Q: ' + question + '\nA: ' + answer + '\n');
  console.log('--', name, '\n' + answer.slice(0, 600));
}

withSession(async (page) => {
  if (want('policy')) await ask(page, 'Policy search', 'Policy question', 'How long do I have to return a battery, and how must it be packed?', 'policy-search');
  if (want('graph')) await ask(page, 'Product graph', 'SKU or SPARQL SELECT', 'what fits on EB-200', 'sparql-graph');
  if (want('runtime')) await ask(page, 'OpenRouter agent', 'Question (name a SKU, e.g. BAT-418)', 'What does BAT-418 cost?', 'openrouter-agent', 150000);
  if (want('ticket')) {
    await openMenu(page, 'Tickets');
    await page.getByRole('button', { name: 'New ticket' }).click();
    await page.locator('.mx-name-tbSubject input').waitFor({ timeout: 30000 });
    await page.locator('.mx-name-tbSubject input').fill('Battery arrived defective');
    await page.locator('.mx-name-taBody textarea').fill('The battery I received does not hold a charge. It looks broken and I want a refund or replacement under warranty.');
    await page.locator('.mx-name-taBody textarea').press('Tab');
    await page.getByRole('button', { name: 'Submit ticket' }).click();
    await page.waitForTimeout(40000);
    await openMenu(page, 'Tickets');
    await page.waitForTimeout(2000);
    await page.screenshot({ path: ev('workflow-tickets.png') });
    fs.writeFileSync(ev('workflow-tickets.txt'), await page.evaluate(() => document.body.innerText));
    await openMenu(page, 'Task inbox');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: ev('workflow-inbox.png') });
    fs.writeFileSync(ev('workflow-inbox.txt'), await page.evaluate(() => document.body.innerText));
    console.log('-- inbox\n' + (await page.evaluate(() => document.body.innerText)).slice(0, 500));
  }
  if (want('monitor')) {
    await openMenu(page, 'Traces'); await page.waitForTimeout(4000);
    await page.screenshot({ path: ev('conversationalui-traces.png') });
    fs.writeFileSync(ev('conversationalui-traces.txt'), await page.evaluate(() => document.body.innerText));
    await openMenu(page, 'Token usage'); await page.waitForTimeout(4000);
    await page.screenshot({ path: ev('conversationalui-token-usage.png') });
    fs.writeFileSync(ev('conversationalui-token-usage.txt'), await page.evaluate(() => document.body.innerText));
  }
}).catch(e => { console.error('FAILED', e.message); process.exit(1); });
