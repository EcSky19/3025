(() => {
// Mobile menu
const btn = document.querySelector('.menu-btn'), nav = document.getElementById('site-nav');
if (btn && nav) {
  btn.addEventListener('click', () => {
    const open = nav.classList.toggle('open');
    btn.setAttribute('aria-expanded', open);
    btn.textContent = open ? 'Close' : 'Menu';
  });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && nav.classList.contains('open')) { btn.click(); btn.focus(); } });
}

// Copy email
document.querySelectorAll('[data-copy]').forEach(b => b.addEventListener('click', async () => {
  const text = b.getAttribute('data-copy');
  try { await navigator.clipboard.writeText(text); b.textContent = 'Copied'; }
  catch { const r = document.createRange(); const t = document.querySelector(b.getAttribute('data-target')); if (t) { r.selectNodeContents(t); const s = getSelection(); s.removeAllRanges(); s.addRange(r); } b.textContent = 'Selected'; }
  setTimeout(() => { b.textContent = 'Copy'; }, 1800);
}));

// Project filters
const fbtns = [...document.querySelectorAll('[data-filter]')];
if (fbtns.length) {
  const cards = [...document.querySelectorAll('[data-tags]')], status = document.getElementById('filter-status');
  fbtns.forEach(b => b.addEventListener('click', () => {
    const f = b.dataset.filter;
    fbtns.forEach(x => x.setAttribute('aria-pressed', x === b));
    let n = 0;
    cards.forEach(c => { const show = f === 'all' || c.dataset.tags.split(' ').includes(f); c.hidden = !show; if (show) n++; });
    if (status) status.textContent = `Showing ${n} project${n === 1 ? '' : 's'}${f === 'all' ? '' : ' tagged ' + b.textContent.trim()}.`;
  }));
}

// Pickers: one list of buttons drives one detail panel
document.querySelectorAll('[data-picker]').forEach(root => {
  const data = JSON.parse(root.querySelector('script[type="application/json"]').textContent);
  const picks = [...root.querySelectorAll('.pick')];
  const out = { step: root.querySelector('[data-f=step]'), title: root.querySelector('[data-f=title]'), a: root.querySelector('[data-f=a]'), b: root.querySelector('[data-f=b]') };
  const select = id => {
    const i = data.findIndex(d => d.id === id), d = data[i];
    picks.forEach(p => { const on = p.dataset.id === id; p.setAttribute('aria-expanded', on); p.querySelector('.chev').textContent = on ? '−' : '+'; });
    out.step.textContent = d.step || `${i + 1} of ${data.length}`; out.title.textContent = d.title; out.a.textContent = d.a; out.b.textContent = d.b;
  };
  picks.forEach(p => p.addEventListener('click', () => select(p.dataset.id)));
  select(root.dataset.picker);
});

// Steppers: Previous / Next through a sequence
document.querySelectorAll('[data-stepper]').forEach(root => {
  const steps = [...root.querySelectorAll('[data-step]')], prev = root.querySelector('[data-prev]'), next = root.querySelector('[data-next]'), pos = root.querySelector('[data-pos]');
  let i = 0;
  const show = k => {
    i = Math.max(0, Math.min(steps.length - 1, k));
    steps.forEach((s, j) => { s.classList.toggle('on', j <= i); s.setAttribute('aria-current', j === i ? 'step' : 'false'); });
    pos.textContent = `Step ${i + 1} of ${steps.length}: ${steps[i].dataset.step}`;
    prev.disabled = i === 0; next.disabled = i === steps.length - 1;
  };
  prev.addEventListener('click', () => show(i - 1)); next.addEventListener('click', () => show(i + 1));
  show(0);
});
})();
