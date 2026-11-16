// Shared browser helpers. The trial licence allows few sessions, so every script logs out in `finally`.
const { chromium } = require('playwright');
const BASE = process.env.HELPDESK_URL || 'http://localhost:8080';
const USER = process.env.HELPDESK_USER || 'helpdesk';
const PASS = process.env.HELPDESK_PASSWORD || 'Helpdesk2026Demo'; // local demo user from 12-security.mdl

async function login(page) {
  await page.goto(BASE + '/login.html', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.fill('#usernameInput', USER);
  await page.fill('#passwordInput', PASS);
  await page.click('#loginButton');
  await page.waitForSelector('.mx-name-navigationTree3, .mx-navbar, .mx-page', { timeout: 90000 });
}

async function logout(page) {
  try { await page.evaluate(() => mx.session.logout()); await page.waitForTimeout(1500); } catch (e) { /* page may be gone */ }
}

// run(page) with login first and logout always
async function withSession(run, opts = {}) {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  try { await login(page); return await run(page); }
  finally { await logout(page); await ctx.close(); await browser.close(); }
}

async function openMenu(page, caption) {
  await page.getByText(caption, { exact: true }).first().click();
  await page.waitForTimeout(2500);
}

module.exports = { withSession, openMenu, BASE };
