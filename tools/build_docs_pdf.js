// Renders docs/technical-documentation.html to docs/technical-documentation.pdf
// with Playwright's Chromium. Run from the repo root: node tools/build_docs_pdf.js
const path = require('path');
const { chromium } = require('playwright');

(async () => {
	const root = path.resolve(__dirname, '..');
	const src = path.join(root, 'docs', 'technical-documentation.html');
	const out = path.join(root, 'docs', 'technical-documentation.pdf');
	const browser = await chromium.launch();
	const page = await browser.newPage();
	await page.goto('file://' + src, { waitUntil: 'networkidle' });
	await page.pdf({ path: out, format: 'A4', printBackground: true, preferCSSPageSize: true });
	await browser.close();
	console.log('wrote ' + path.relative(root, out));
})();
