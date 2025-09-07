function params() {
  const p = new URLSearchParams(location.search);
  return {
    persist: p.get('persist') || 'http://persist.local',
    sem: p.get('sem') || 'http://semantic-browser.local',
    apiKey: p.get('apiKey') || ''
  };
}

async function doFetch(url, opts={}) {
  const p = params();
  const headers = Object.assign({}, opts.headers || {});
  if (p.apiKey) headers['X-API-Key'] = p.apiKey;
  const r = await fetch(url, Object.assign({}, opts, { headers }));
  return r;
}

async function fetchJSON(url, opts={}) {
  const r = await doFetch(url, opts);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return await r.json();
}

async function fetchText(url, opts={}) {
  const r = await doFetch(url, opts);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return await r.text();
}

async function postJSON(url, bodyObj) {
  const r = await doFetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(bodyObj)
  });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  const ct = r.headers.get('content-type') || '';
  if (ct.includes('application/json')) return await r.json();
  return await r.text();
}

function el(tag, attrs = {}, ...children) {
  const e = document.createElement(tag);
  Object.entries(attrs).forEach(([k,v])=>e.setAttribute(k,v));
  children.forEach(c => e.append(c));
  return e;
}

window.Gui = { params, fetchJSON, fetchText, postJSON, el };
