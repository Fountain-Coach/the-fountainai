function params() {
  const p = new URLSearchParams(location.search);
  return {
    persist: p.get('persist') || 'http://persist.local',
    sem: p.get('sem') || 'http://semantic-browser.local'
  };
}

async function fetchJSON(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return await r.json();
}

function el(tag, attrs = {}, ...children) {
  const e = document.createElement(tag);
  Object.entries(attrs).forEach(([k,v])=>e.setAttribute(k,v));
  children.forEach(c => e.append(c));
  return e;
}

window.Gui = { params, fetchJSON, el };

