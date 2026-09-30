enum WebUI {
    static let html = #"""
<!doctype html>
<html lang="it"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="theme-color" content="#000000">
<link rel="apple-touch-icon" href="/icon.png">
<title>MacRemote</title>
<style>
:root{color-scheme:dark;--bg:#000;--card:#111113;--btn:#1d1d20;--btn-on:#34343a;--fg:#f2f2f7;--dim:#8e8e93;--accent:#7c7cff;--ok:#30d158;--bad:#ff453a}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent;-webkit-user-select:none;user-select:none;touch-action:manipulation}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.2 -apple-system,system-ui,sans-serif;
  padding:max(14px,env(safe-area-inset-top)) 16px max(28px,env(safe-area-inset-bottom));max-width:480px;margin-inline:auto}
header{display:flex;align-items:center;justify-content:space-between;padding:4px 4px 14px}
header h1{font-size:20px;font-weight:700;margin:0;letter-spacing:-.01em}
#bat{display:none;align-items:center;gap:6px;font-size:14px;font-weight:600;color:var(--dim);background:var(--card);border-radius:99px;padding:7px 12px}
#bat.chg{color:var(--ok)}#bat.low{color:var(--bad)}
.card{background:var(--card);border-radius:24px;padding:14px;margin-bottom:12px}
.card[hidden]{display:none}
.label{font-size:12px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:var(--dim);margin:0 4px 10px}
.row{display:flex;gap:8px;align-items:center}
.row+.row{margin-top:8px}
.row .name{flex:0 0 68px;font-size:15px;color:var(--dim);padding-left:4px}
button{flex:1;min-height:56px;border:0;border-radius:16px;background:var(--btn);color:var(--fg);font:600 16px -apple-system,system-ui,sans-serif;
  display:flex;align-items:center;justify-content:center;gap:8px;transition:transform .08s,background .12s}
button:active,button.on{background:var(--btn-on);transform:scale(.96)}
button.accent{background:var(--accent);color:#fff}
button.accent:active,button.accent.on{background:#5f5fe6}
.i{width:24px;height:24px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
.dpad{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
.dpad button{min-height:60px}
.dpad .e{visibility:hidden}
.dpad .up .i{transform:none}.dpad .dn .i{transform:rotate(180deg)}.dpad .lf .i{transform:rotate(-90deg)}.dpad .rt .i{transform:rotate(90deg)}
form{display:flex;gap:8px}
input{flex:1;min-width:0;min-height:56px;border:0;border-radius:16px;background:var(--btn);color:var(--fg);font-size:17px;padding:0 16px;outline:none;-webkit-user-select:text;user-select:text}
input::placeholder{color:var(--dim)}
form button{flex:0 0 76px}
#toast{position:fixed;left:50%;top:max(10px,env(safe-area-inset-top));transform:translate(-50%,-80px);background:rgba(44,44,48,.95);
  -webkit-backdrop-filter:blur(12px);backdrop-filter:blur(12px);padding:10px 16px;border-radius:99px;font-size:14px;font-weight:600;
  transition:transform .25s;pointer-events:none;max-width:90%;text-align:center}
#toast.show{transform:translate(-50%,0)}#toast.err{color:var(--bad)}
</style></head><body>
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
<symbol id="minus" viewBox="0 0 24 24"><path d="M5 12h14"/></symbol>
<symbol id="plus" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></symbol>
<symbol id="spk" viewBox="0 0 24 24"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/></symbol>
<symbol id="mute" viewBox="0 0 24 24"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="m22 9-6 6m0-6 6 6"/></symbol>
<symbol id="sun" viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></symbol>
<symbol id="prev" viewBox="0 0 24 24"><path d="M19 6v12L9 12z"/><path d="M5 6v12"/></symbol>
<symbol id="next" viewBox="0 0 24 24"><path d="M5 6v12l10-6z"/><path d="M19 6v12"/></symbol>
<symbol id="play" viewBox="0 0 24 24"><path d="M7 4.5v15l12-7.5z"/></symbol>
<symbol id="chev" viewBox="0 0 24 24"><path d="m6 15 6-6 6 6"/></symbol>
<symbol id="back" viewBox="0 0 24 24"><path d="M21 5H9l-6 7 6 7h12z"/><path d="m14 9 4 6m0-6-4 6"/></symbol>
<symbol id="moon" viewBox="0 0 24 24"><path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"/></symbol>
<symbol id="lock" viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></symbol>
</defs></svg>

<header><h1>MacRemote</h1><div id="bat"></div></header>

<section class="card">
  <p class="label">Volume</p>
  <div class="row">
    <button data-a="vol_down" data-hold><svg class="i"><use href="#minus"/></svg></button>
    <button data-a="mute"><svg class="i"><use href="#mute"/></svg></button>
    <button data-a="vol_up" data-hold><svg class="i"><use href="#plus"/></svg></button>
  </div>
</section>

<section class="card" id="sec-bright">
  <p class="label">Luminosità</p>
  <div class="row" id="sec-mac"><span class="name">Mac</span>
    <button data-a="bright_down" data-hold><svg class="i"><use href="#minus"/></svg></button>
    <button data-a="bright_up" data-hold><svg class="i"><use href="#sun"/></svg><svg class="i"><use href="#plus"/></svg></button>
  </div>
  <div class="row" id="sec-ext"><span class="name">Monitor</span>
    <button data-a="ext_bright_down" data-hold><svg class="i"><use href="#minus"/></svg></button>
    <button data-a="ext_bright_up" data-hold><svg class="i"><use href="#sun"/></svg><svg class="i"><use href="#plus"/></svg></button>
  </div>
</section>

<section class="card">
  <p class="label">Media</p>
  <div class="row">
    <button data-a="prev"><svg class="i"><use href="#prev"/></svg></button>
    <button class="accent" data-a="play"><svg class="i"><use href="#play"/></svg></button>
    <button data-a="next"><svg class="i"><use href="#next"/></svg></button>
  </div>
</section>

<section class="card">
  <p class="label">Navigazione</p>
  <div class="dpad">
    <button data-a="shift_tab">⇤ Tab</button>
    <button class="up" data-a="up" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button data-a="tab">Tab ⇥</button>
    <button class="lf" data-a="left" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button class="accent" data-a="enter">OK</button>
    <button class="rt" data-a="right" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button data-a="esc">Esc</button>
    <button class="dn" data-a="down" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button data-a="space">Spazio</button>
  </div>
</section>

<section class="card">
  <p class="label">Testo</p>
  <form id="tf">
    <input id="ti" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder="Scrivi sul Mac…">
    <button data-a="backspace" type="button" style="flex:0 0 56px"><svg class="i"><use href="#back"/></svg></button>
    <button class="accent" type="submit">Invia</button>
  </form>
</section>

<section class="card">
  <p class="label">Schermo</p>
  <div class="row">
    <button data-a="display_sleep"><svg class="i"><use href="#moon"/></svg>Spegni</button>
    <button data-a="lock"><svg class="i"><use href="#lock"/></svg>Blocca</button>
  </div>
</section>

<div id="toast"></div>
<script>
const p=new URLSearchParams(location.search);
if(p.get('t'))try{localStorage.t=p.get('t')}catch(e){}
const T=p.get('t')||(()=>{try{return localStorage.t}catch(e){}})()||'';
const $=id=>document.getElementById(id);
let toastTimer;
function toast(text,err){
  if(!text)return;
  const t=$('toast');t.textContent=text;t.className='show'+(err?' err':'');
  clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.className='',1800);
}
async function send(action,value){
  try{
    const r=await fetch('/cmd',{method:'POST',headers:{'X-Token':T},body:JSON.stringify({action,value})});
    if(!r.ok)return toast('Errore '+r.status,true);
    const j=await r.json();
    if(!j.ok)toast(j.info||'Comando fallito',true);else toast(j.info);
  }catch(e){toast('Mac non raggiungibile',true)}
}
async function status(){
  try{
    const r=await fetch('/status',{headers:{'X-Token':T}});
    if(!r.ok)return;
    const j=await r.json(),b=$('bat');
    $('sec-mac').hidden=j.hasMacDisplay===false;
    $('sec-ext').hidden=j.hasExternalDisplay===false;
    $('sec-bright').hidden=j.hasMacDisplay===false&&j.hasExternalDisplay===false;
    if(!j.hasBattery){b.style.display='none';return}
    b.style.display='flex';
    b.className=j.charging?'chg':(j.percent<=20&&!j.plugged?'low':'');
    b.textContent=(j.charging?'⚡ ':j.plugged?'🔌 ':'🔋 ')+j.percent+'%';
  }catch(e){}
}
status();setInterval(status,15000);
document.addEventListener('visibilitychange',()=>{if(!document.hidden)status()});
document.querySelectorAll('button[data-a]').forEach(b=>{
  let t=null,d=null;
  const stop=()=>{clearTimeout(d);clearInterval(t);t=d=null;b.classList.remove('on')};
  b.addEventListener('pointerdown',e=>{
    e.preventDefault();b.classList.add('on');send(b.dataset.a);
    if(b.hasAttribute('data-hold'))d=setTimeout(()=>{t=setInterval(()=>send(b.dataset.a),150)},400);
  });
  ['pointerup','pointercancel','pointerleave'].forEach(ev=>b.addEventListener(ev,stop));
});
$('tf').addEventListener('submit',e=>{
  e.preventDefault();const i=$('ti');
  if(i.value){send('text',i.value);i.value=''}
});
</script></body></html>
"""#
}
