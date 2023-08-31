import { JSDOM } from 'jsdom';
import fs from 'node:fs';

const file = './dist/index.html';

fs.readFile(file, 'utf-8', (err, data) => {
  if (err) {
    throw err;
  }

  const dom = new JSDOM(data);

  const window = dom.window;

  const stylesheet = window.document.querySelector('link[rel="stylesheet"]');

  stylesheet.setAttribute('preload', '');

  fs.writeFile(file, dom.serialize(), function(err) {
    if (err){
      throw err;
    }

    console.log('Stylesheet preload added');
  })
});
