window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.type === 'coma_show') {
    document.getElementById('wrap').style.display = data.show ? 'flex' : 'none';
  }
  if (data.type === 'coma_time') {
    const ms = Math.max(0, Number(data.ms || 0));
    const sec = Math.floor(ms / 1000);
    const mm = String(Math.floor(sec / 60)).padStart(2,'0');
    const ss = String(sec % 60).padStart(2,'0');
    document.getElementById('timer').textContent = mm + ':' + ss;
  }
});
