const puppeteer = require('puppeteer');

(async () => {
  console.log('Starting headless font check...');
  const url = 'https://hiromg.github.io/Busqueda-del-tesoro/';
  console.log('Launching browser...');
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'] });
  console.log('Launched browser:', await browser.version());
  const page = await browser.newPage();
  try {
    console.log('Opening page:', url);
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
    console.log('Page loaded:', url);
    console.log('Waiting for document.fonts.ready...');
    const fontsRequested = [];
    page.on('request', (req) => {
      try {
        if (req.url().toLowerCase().indexOf('/fonts/') >= 0 || req.url().toLowerCase().endsWith('.woff2')) {
          fontsRequested.push(req.url());
        }
      } catch (e) { }
    });
    page.on('requestfinished', (req) => {
      try {
        if (req.resourceType() === 'font') {
          fontsRequested.push(req.url());
        }
      } catch (e) { /* ignore */ }
    });
    const result = await page.evaluate(async () => {
      await document.fonts.ready;
      const fonts = [
        { name: 'Open Sans', css: '1rem "Open Sans"' },
        { name: 'Cinzel Decorative', css: '1rem "Cinzel Decorative"' },
        { name: 'Great Vibes', css: '1rem "Great Vibes"' }
      ];
      const loaded = fonts.map(f => ({ name: f.name, loaded: document.fonts.check(f.css) }));
      // Try to explicitly load fonts
      for (const f of fonts) {
        try { await document.fonts.load(f.css); } catch(e) { }
      }
      // Re-evaluate loaded state after explicit load
      const loadedAfter = fonts.map(f => ({ name: f.name, loaded: document.fonts.check(f.css) }));
      const cssFaces = [];
      try {
        Array.from(document.styleSheets).forEach(s => {
          try {
            Array.from(s.cssRules || []).forEach(r => {
              if (r.type === CSSRule.FONT_FACE_RULE) cssFaces.push(r.cssText);
            });
          } catch(e) { /* cross-origin style sheets will throw */ }
        });
      } catch (e) { /* ignore */ }
      const sample = {
        body: getComputedStyle(document.body).fontFamily,
        h1: (function() { const el = document.querySelector('h1'); return el ? getComputedStyle(el).fontFamily : null })(),
        scriptText: (function() { const el = document.querySelector('.script-text'); return el ? getComputedStyle(el).fontFamily : null })()
      };
      return { loaded, loadedAfter, cssFaces, sample };
    });
    console.log('Fonts requested:', JSON.stringify(fontsRequested, null, 2));

    // Force a fetch to the font URL to see if it is accessible
    const testFetch = await page.evaluate(async () => {
      try {
        const response = await fetch('fonts/OpenSans-Regular.woff2');
        return { status: response.status, ok: response.ok };
      } catch (err) { return { error: String(err) } }
    });
    console.log('Test fetch of fonts/OpenSans-Regular.woff2:', JSON.stringify(testFetch));
    console.log('Font check result (true = loaded):');
    console.log(JSON.stringify(result, null, 2));
    console.log('End headless check.');
  } catch (err) {
    console.error('Error during headless test:', err);
    process.exitCode = 2;
  } finally {
    await browser.close();
  }
})();
