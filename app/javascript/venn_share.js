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
        vennCopyFallback(text, markDone);
      });
  } else if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text)
      .then(function() { markDone('Copied!'); })
      .catch(function() { vennCopyFallback(text, markDone); });
  } else {
    vennCopyFallback(text, markDone);
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
