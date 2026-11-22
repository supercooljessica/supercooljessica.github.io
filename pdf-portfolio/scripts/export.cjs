const { chromium } = require('playwright');
const path = require('node:path');
const fs = require('node:fs/promises');
const { pathToFileURL } = require('node:url');

async function main() {
  const root = path.resolve(__dirname, '..');
  const output = path.join(root, 'output');
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({
    ...(process.env.PORTFOLIO_BROWSER ? { executablePath: process.env.PORTFOLIO_BROWSER } : {}),
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1000, height: 1200 } });
    const failures = [];
    page.on('requestfailed', request => failures.push(request.url()));
    await page.goto(pathToFileURL(path.join(root, 'index.html')).href, { waitUntil: 'load' });
    await page.emulateMedia({ media: 'print' });
    await page.evaluate(() => document.fonts.ready);
    const issues = await page.evaluate(() => {
      const errors = [...document.images].filter(img => !img.complete || !img.naturalWidth)
        .map(img => `Missing image: ${img.getAttribute('src')}`);
      for (const [i, sheet] of [...document.querySelectorAll('.page')].entries()) {
        if (sheet.scrollHeight > sheet.clientHeight + 1 || sheet.scrollWidth > sheet.clientWidth + 1) {
          errors.push(`Page ${i + 1} overflows. Shorten the copy or adjust the layout.`);
        }
      }
      return errors;
    });
    if (failures.length || issues.length) throw new Error([...failures, ...issues].join('\n'));
    const pdf = path.join(output, 'jessica-portfolio-draft.pdf');
    await page.pdf({ path: pdf, preferCSSPageSize: true, printBackground: true, tagged: true, displayHeaderFooter: false });
    for (const [i, sheet] of (await page.locator('.page').all()).entries()) {
      await sheet.screenshot({ path: path.join(output, `page-${i + 1}.png`) });
    }
    console.log(`Exported ${await page.locator('.page').count()} pages to ${pdf}`);
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
