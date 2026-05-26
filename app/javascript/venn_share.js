if (typeof gtag === 'undefined') { window.gtag = function() {}; }

// Inject the copy popover once on first use
function vennEnsurePopover() {
  if (document.getElementById('venn-share-popover')) return;
  var el = document.createElement('div');
  el.id = 'venn-share-popover';
  el.innerHTML = [
    '<div id="venn-share-backdrop" style="position:fixed;inset:0;background:rgba(0,0,0,0.35);z-index:9998;"></div>',
    '<div style="position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:9999;',
         'background:white;border-radius:18px;padding:20px 20px 16px;max-width:340px;width:calc(100% - 40px);',
         'box-shadow:0 8px 40px rgba(0,0,0,0.18);box-sizing:border-box;">',
      '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">',
        '<span style="font-size:13px;font-weight:700;color:#1a1a2e;font-family:\'Inter\',system-ui,sans-serif;">Share your score</span>',
        '<button id="venn-share-close" style="background:none;border:none;cursor:pointer;font-size:20px;color:#bbb;padding:0 2px;line-height:1;font-family:sans-serif;">&times;</button>',
      '</div>',
      '<pre id="venn-share-text" style="font-family:\'Inter\',system-ui,sans-serif;font-size:13px;line-height:1.55;',
           'color:#1a1a2e;background:#f8f8f8;border-radius:10px;padding:12px;white-space:pre-wrap;',
           'word-break:break-word;margin:0 0 12px;max-height:220px;overflow-y:auto;"></pre>',
      '<button id="venn-copy-btn" style="width:100%;background:#1a1a2e;color:white;font-weight:700;font-size:14px;',
             'border:none;border-radius:10px;padding:12px;cursor:pointer;font-family:\'Inter\',system-ui,sans-serif;">',
        'Copy to clipboard',
      '</button>',
    '</div>'
  ].join('');
  document.body.appendChild(el);

  document.getElementById('venn-share-backdrop').addEventListener('click', vennClosePopover);
  document.getElementById('venn-share-close').addEventListener('click', vennClosePopover);
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') vennClosePopover();
  });
  document.getElementById('venn-copy-btn').addEventListener('click', function() {
    var text = document.getElementById('venn-share-text').textContent;
    var btn = document.getElementById('venn-copy-btn');
    navigator.clipboard.writeText(text).then(function() {
      btn.textContent = 'Copied!';
      setTimeout(function() { btn.textContent = 'Copy to clipboard'; }, 2000);
    }).catch(function() {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0;pointer-events:none;';
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand('copy'); btn.textContent = 'Copied!'; setTimeout(function() { btn.textContent = 'Copy to clipboard'; }, 2000); } catch(e) {}
      document.body.removeChild(ta);
    });
  });
}

window.vennShowCopyPopover = function(text) {
  vennEnsurePopover();
  document.getElementById('venn-share-text').textContent = text;
  document.getElementById('venn-copy-btn').textContent = 'Copy to clipboard';
  document.getElementById('venn-share-popover').style.display = 'block';
};

window.vennClosePopover = function() {
  var el = document.getElementById('venn-share-popover');
  if (el) el.style.display = 'none';
};

window.vennShare = function(text, gameId) {
  gtag('event', 'share_score', { 'game_id': gameId });
  var btn = document.getElementById('share-score-btn');
  function markDone(label) {
    if (!btn) return;
    btn.textContent = label;
    setTimeout(function() { btn.textContent = 'Share score'; }, 2000);
  }
  if (navigator.share) {
    navigator.share({ text: text })
      .then(function() { markDone('Shared!'); })
      .catch(function(err) {
        if (err && err.name === 'AbortError') return;
        vennShowCopyPopover(text);
      });
  } else {
    vennShowCopyPopover(text);
  }
};

window.vennCopyFallback = function(text, onDone) {
  var ta = document.createElement('textarea');
  ta.value = text;
  ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0;pointer-events:none;';
  document.body.appendChild(ta);
  ta.select();
  try { document.execCommand('copy'); onDone('Copied!'); } catch(e) {}
  document.body.removeChild(ta);
};
