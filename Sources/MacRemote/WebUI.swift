enum WebUI {
    static let html = #"""
<!doctype html>
<html lang="en"><head>
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
#lang{display:flex;background:var(--card);border-radius:99px;padding:3px;margin-right:8px}
#lang span{font-size:12px;font-weight:700;color:var(--dim);padding:6px 10px;border-radius:99px}
#lang span.sel{background:var(--btn-on);color:var(--fg)}
.hr{display:flex;align-items:center}
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
#np{display:flex;gap:14px;align-items:center}
#np[hidden]{display:none}
#np-art{width:76px;height:76px;border-radius:14px;background:var(--btn);object-fit:cover;flex:0 0 76px}
#np-info{flex:1;min-width:0}
#np-title{font-size:17px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#np-artist{font-size:14px;color:var(--dim);margin-top:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#np-bar{height:4px;border-radius:2px;background:var(--btn-on);margin-top:12px;overflow:hidden}
#np-fill{height:100%;width:0;background:var(--accent)}
#np-time{display:flex;justify-content:space-between;font-size:11px;color:var(--dim);margin-top:5px;font-variant-numeric:tabular-nums}
.head{display:flex;align-items:center;justify-content:space-between;margin:0 4px 10px}
.head .label{margin:0}
.sw{position:relative;width:51px;height:31px;flex:0 0 51px}
.sw input{position:absolute;inset:0;width:100%;height:100%;min-height:0;opacity:0;margin:0;z-index:1}
.sw span{position:absolute;inset:0;border-radius:99px;background:var(--btn-on);transition:background .2s}
.sw span::after{content:"";position:absolute;top:2px;left:2px;width:27px;height:27px;border-radius:50%;background:#fff;transition:transform .2s}
.sw input:checked+span{background:var(--ok)}
.sw input:checked+span::after{transform:translateX(20px)}
#pv-body{margin-top:12px}
#pv-body[hidden]{display:none}
#pv-img{display:block;width:100%;border-radius:14px;background:var(--btn);min-height:120px;object-fit:contain}
#pv-iv{margin-top:10px}
#pv-iv button{min-height:40px;font-size:14px;border-radius:12px}
#pv-iv button.sel{background:var(--accent);color:#fff}
#pv-hint{font-size:12px;color:var(--dim);margin:8px 4px 0;text-align:center}
#tp-head{display:flex;align-items:center;gap:10px;margin:0 0 10px}
#tp-head .label{margin:0}
#tp-big{flex:0 0 34px;width:34px;min-height:34px;height:34px;border-radius:11px;padding:0;color:var(--dim)}
#tp-big .i{width:17px;height:17px}
#tp-big .x{display:none}#tp-card.big #tp-big .x{display:block}#tp-card.big #tp-big .e{display:none}
#tp-back{position:fixed;inset:0;z-index:59;background:rgba(0,0,0,.6);-webkit-backdrop-filter:blur(8px);backdrop-filter:blur(8px);
  opacity:0;pointer-events:none;transition:opacity .2s;touch-action:none}
html.tpbig{overflow:hidden}
html.tpbig #tp-back{opacity:1;pointer-events:auto}
#tp-card.big #tp-box{position:fixed;z-index:60;left:50%;top:50%;transform:translate(-50%,-50%);width:min(calc(100vw - 24px),480px);
  height:70vh;height:70dvh;display:flex;flex-direction:column;background:var(--card);border-radius:24px;padding:14px;
  box-shadow:0 20px 60px rgba(0,0,0,.6)}
#tp-card.big #tp{flex:1;min-height:0;aspect-ratio:auto}
#tp{position:relative;aspect-ratio:16/10;border-radius:18px;background:var(--btn);overflow:hidden;
  box-shadow:inset 0 0 0 1px rgba(255,255,255,.05);transition:box-shadow .2s;-webkit-touch-callout:none}
#tp.on{touch-action:none;box-shadow:inset 0 0 0 1px rgba(124,124,255,.4)}
#tp.drag{box-shadow:inset 0 0 0 2px var(--accent)}
#tp-lock{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;
  background:rgba(0,0,0,.28);transition:opacity .25s}
#tp.on #tp-lock{opacity:0;pointer-events:none}
#tp-go{flex:0 0 auto;min-height:44px;padding:0 20px;border-radius:99px;font-size:15px;background:rgba(255,255,255,.1);
  box-shadow:inset 0 0 0 1px rgba(255,255,255,.16);-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px)}
#tp-go:active{background:rgba(255,255,255,.18)}
#tp-go .i{width:18px;height:18px}
#tp-help{margin:0;padding:0 14px;font-size:11.5px;line-height:1.55;color:var(--dim);text-align:center}
#tp .dot{position:absolute;left:0;top:0;width:40px;height:40px;margin:-20px 0 0 -20px;border-radius:50%;
  background:rgba(255,255,255,.12);pointer-events:none}
#tp.drag .dot{background:rgba(124,124,255,.45)}
.tp-btns{margin-top:8px}
.tp-btns button{min-height:44px;font-size:14px;border-radius:12px;transition:transform .08s,background .12s,opacity .2s}
#tp-card.off .tp-btns button{opacity:.35;pointer-events:none}
#toast{position:fixed;z-index:70;left:50%;top:max(10px,env(safe-area-inset-top));transform:translate(-50%,-80px);background:rgba(44,44,48,.95);
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
<symbol id="expand" viewBox="0 0 24 24"><path d="M14 4h6v6M10 20H4v-6M20 4l-6.5 6.5M4 20l6.5-6.5"/></symbol>
<symbol id="shrink" viewBox="0 0 24 24"><path d="M20 10h-6V4M4 14h6v6M14 10l6.5-6.5M10 14l-6.5 6.5"/></symbol>
<symbol id="cur" viewBox="0 0 24 24"><path d="M5 3.5 19 10l-6.2 2.1L10.5 19z"/></symbol>
</defs></svg>

<header><h1>MacRemote</h1><div class="hr"><div id="lang"><span data-l="en">EN</span><span data-l="it">IT</span></div><div id="bat"></div></div></header>

<section class="card" id="np" hidden>
  <img id="np-art" alt="">
  <div id="np-info">
    <div id="np-title"></div><div id="np-artist"></div>
    <div id="np-bar"><div id="np-fill"></div></div>
    <div id="np-time"><span id="np-pos">0:00</span><span id="np-dur">0:00</span></div>
  </div>
</section>

<section class="card">
  <p class="label">Volume</p>
  <div class="row">
    <button data-a="vol_down" data-hold><svg class="i"><use href="#minus"/></svg></button>
    <button data-a="mute"><svg class="i"><use href="#mute"/></svg></button>
    <button data-a="vol_up" data-hold><svg class="i"><use href="#plus"/></svg></button>
  </div>
</section>

<section class="card" id="sec-bright">
  <p class="label" data-i18n="bright">Luminosità</p>
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

<div id="tp-back"></div>
<section class="card off" id="tp-card">
 <div id="tp-box">
  <div id="tp-head">
    <button id="tp-big" type="button"><svg class="i e"><use href="#expand"/></svg><svg class="i x"><use href="#shrink"/></svg></button>
    <p class="label">Touchpad</p>
  </div>
  <div id="tp">
    <div id="tp-lock">
      <button id="tp-go" type="button"><svg class="i"><use href="#cur"/></svg><span id="tp-go-l" data-i18n="tpStart">Activate touchpad</span></button>
      <p id="tp-help"><span data-i18n="tpH1"></span><br><span data-i18n="tpH2"></span><br><span data-i18n="tpH3"></span></p>
    </div>
  </div>
  <div class="row tp-btns">
    <button id="tp-l" type="button"><span data-i18n="click">Click</span></button>
    <button id="tp-r" type="button"><span data-i18n="rclick">Right click</span></button>
  </div>
 </div>
</section>

<section class="card">
  <p class="label" data-i18n="nav">Navigazione</p>
  <div class="dpad">
    <button data-a="shift_tab">⇤ Tab</button>
    <button class="up" data-a="up" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button data-a="tab">Tab ⇥</button>
    <button class="lf" data-a="left" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button class="accent" data-a="enter">OK</button>
    <button class="rt" data-a="right" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button data-a="esc">Esc</button>
    <button class="dn" data-a="down" data-hold><svg class="i"><use href="#chev"/></svg></button>
    <button data-a="space"><span data-i18n="space">Space</span></button>
  </div>
</section>

<section class="card">
  <p class="label" data-i18n="text">Testo</p>
  <form id="tf">
    <input id="ti" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder="Type on the Mac…" data-i18n-ph="ph">
    <button data-a="backspace" type="button" style="flex:0 0 56px"><svg class="i"><use href="#back"/></svg></button>
    <button class="accent" type="submit"><span data-i18n="send">Send</span></button>
  </form>
</section>

<section class="card">
  <p class="label" data-i18n="screen">Schermo</p>
  <div class="row">
    <button data-a="display_sleep"><svg class="i"><use href="#moon"/></svg><span data-i18n="off">Turn off</span></button>
    <button data-a="lock"><svg class="i"><use href="#lock"/></svg><span data-i18n="lock">Lock</span></button>
  </div>
</section>

<section class="card">
  <p class="label" data-i18n="close">Chiudi</p>
  <div class="row">
    <button data-a="quit_app" data-confirm="confirmApp"><span data-i18n="app">Current app</span></button>
    <button data-a="quit_self" data-confirm="confirmSelf">MacRemote</button>
  </div>
</section>

<section class="card" id="pv" hidden>
  <div class="head"><p class="label" data-i18n="preview">Anteprima schermo</p>
    <label class="sw"><input type="checkbox" id="pv-sw"><span></span></label></div>
  <div id="pv-body" hidden>
    <img id="pv-img" alt="">
    <div class="row" id="pv-iv">
      <button data-s="1000">1s</button><button data-s="2000" class="sel">2s</button><button data-s="5000">5s</button>
    </div>
    <p id="pv-hint"></p>
  </div>
</section>

<div id="toast"></div>
<script>
const p=new URLSearchParams(location.search);
if(p.get('t'))try{localStorage.t=p.get('t')}catch(e){}
const T=p.get('t')||(()=>{try{return localStorage.t}catch(e){}})()||'';
const $=id=>document.getElementById(id);

/* i18n: English is the default; Italian when the phone is set to Italian or the user picks it. */
const L={
 en:{bright:'Brightness',nav:'Navigation',text:'Text',screen:'Screen',close:'Close',preview:'Screen preview',space:'Space',send:'Send',off:'Turn off',lock:'Lock',app:'Current app',
  ph:'Type on the Mac…',confirmApp:'Quit the frontmost app on the Mac?',confirmSelf:'Quit MacRemote? You will need the Mac to open it again.',
  err:'Error ',unreachable:'Mac unreachable',failed:'Command failed',pvUnavailable:'Preview unavailable',media:'Media content',
  hint:(i,n)=>'Tap the image to switch display ('+i+'/'+n+')',
  tpStart:'Activate touchpad',tpResume:'Resume',tpExpand:'Enlarge touchpad',tpShrink:'Shrink touchpad',click:'Click',rclick:'Right click',
  tpH1:'1 finger: move · tap: click · hold: drag',tpH2:'2 fingers: scroll · pinch: zoom · tap: right click',tpH3:'3 fingers: swipe for Spaces and Mission Control'},
 it:{bright:'Luminosità',nav:'Navigazione',text:'Testo',screen:'Schermo',close:'Chiudi',preview:'Anteprima schermo',space:'Spazio',send:'Invia',off:'Spegni',lock:'Blocca',app:'App in uso',
  ph:'Scrivi sul Mac…',confirmApp:"Chiudere l'app in primo piano sul Mac?",confirmSelf:'Chiudere MacRemote? Per riaprirlo servirà il Mac.',
  err:'Errore ',unreachable:'Mac non raggiungibile',failed:'Comando fallito',pvUnavailable:'Anteprima non disponibile',media:'Contenuto multimediale',
  hint:(i,n)=>"Tocca l'immagine per cambiare schermo ("+i+'/'+n+')',
  tpStart:'Attiva touchpad',tpResume:'Riprendi',tpExpand:'Ingrandisci touchpad',tpShrink:'Riduci touchpad',click:'Clic',rclick:'Clic destro',
  tpH1:'1 dito: muovi · tocca: clic · tieni: trascina',tpH2:'2 dita: scorri · pizzica: zoom · tocca: clic destro',tpH3:'3 dita: swipe per Spazi e Mission Control'}};
/* Messages coming from the Mac are English; these pairs translate them (substring replace). */
const SRV=[['Accessibility permission missing: System Settings › Privacy › Accessibility','Permesso Accessibilità mancante: Impostazioni › Privacy › Accessibilità'],
 ['Screen Recording permission missing: System Settings › Privacy › Screen Recording','Permesso Registrazione schermo mancante: Impostazioni › Privacy › Registrazione schermo'],
 ['Screen Recording permission missing','Permesso Registrazione schermo mancante'],['Preview off','Anteprima disattivata'],['No display','Nessuno schermo'],
 ['Screen capture timed out','Timeout cattura schermo'],['Encoding failed','Codifica fallita'],['Capture failed','Cattura fallita'],
 ['Mac display not active','Schermo Mac non attivo'],['No external monitor','Nessun monitor esterno'],['Mac display','Schermo Mac'],
 ['brightness not controllable','luminosità non controllabile'],['No app to quit','Nessuna app da chiudere'],['Quit: ','Chiusa: '],
 ['MacRemote quit','MacRemote chiuso'],['Unknown action','Azione sconosciuta']];
function pickLang(stored,prefs){
  if(stored==='en'||stored==='it')return stored;
  for(const l of prefs||[])if(/^it\b/i.test(l))return 'it';
  return 'en';
}
let lang=pickLang((()=>{try{return localStorage.lang}catch(e){}})(),navigator.languages||[navigator.language]);
const t=k=>L[lang][k];
const srv=m=>lang==='it'?SRV.reduce((x,[a,b])=>x.split(a).join(b),m):m;
function applyLang(){
  document.documentElement.lang=lang;
  document.querySelectorAll('[data-i18n]').forEach(e=>e.textContent=t(e.dataset.i18n));
  document.querySelectorAll('[data-i18n-ph]').forEach(e=>e.placeholder=t(e.dataset.i18nPh));
  document.querySelectorAll('#lang span').forEach(e=>e.classList.toggle('sel',e.dataset.l===lang));
  if(typeof pvHint==='function')pvHint();
  if(typeof tpBigSync==='function')tpBigSync();
  if(typeof drawNP==='function'&&np&&np.active)$('np-title').textContent=np.title||t('media');
}
document.querySelectorAll('#lang span').forEach(e=>e.addEventListener('click',()=>{
  lang=e.dataset.l;try{localStorage.lang=lang}catch(x){}applyLang();
}));
let toastTimer;
function toast(text,err){
  if(!text)return;
  const t=$('toast');t.textContent=text;t.className='show'+(err?' err':'');
  clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.className='',1800);
}
async function send(action,value){
  try{
    const r=await fetch('/cmd',{method:'POST',headers:{'X-Token':T},body:JSON.stringify({action,value})});
    if(!r.ok)return toast(t('err')+r.status,true);
    const j=await r.json();
    if(!j.ok)toast(srv(j.info||t('failed')),true);else toast(srv(j.info||''));
  }catch(e){toast(t('unreachable'),true)}
}
async function status(){
  try{
    const r=await fetch('/status',{headers:{'X-Token':T}});
    if(!r.ok)return;
    const j=await r.json(),b=$('bat');
    $('sec-mac').hidden=j.hasMacDisplay===false;
    $('sec-ext').hidden=j.hasExternalDisplay===false;
    $('sec-bright').hidden=j.hasMacDisplay===false&&j.hasExternalDisplay===false;
    $('pv').hidden=false;pv.n=j.displayCount||1;pvHint();
    if(!j.hasBattery){b.style.display='none';return}
    b.style.display='flex';
    b.className=j.charging?'chg':(j.percent<=20&&!j.plugged?'low':'');
    b.textContent=(j.charging?'⚡ ':j.plugged?'🔌 ':'🔋 ')+j.percent+'%';
  }catch(e){}
}
status();setInterval(status,15000);
document.addEventListener('visibilitychange',()=>{if(!document.hidden)status()});
document.querySelectorAll('button[data-a]').forEach(b=>{
  let rep=null,d=null;   // not `t`: that would shadow the translate function t()
  const stop=()=>{clearTimeout(d);clearInterval(rep);rep=d=null;b.classList.remove('on')};
  b.addEventListener('pointerdown',e=>{
    e.preventDefault();
    if(b.dataset.confirm&&!confirm(t(b.dataset.confirm)))return;
    b.classList.add('on');send(b.dataset.a);
    if(b.hasAttribute('data-hold'))d=setTimeout(()=>{rep=setInterval(()=>send(b.dataset.a),150)},400);
  });
  ['pointerup','pointercancel','pointerleave'].forEach(ev=>b.addEventListener(ev,stop));
});

/* Now Playing */
let np=null,npAt=0,npKey='',npArt=false;
const fmt=t=>{t=Math.max(0,Math.floor(t||0));return Math.floor(t/60)+':'+String(t%60).padStart(2,'0')};
async function pollNP(){
  if(document.hidden)return;
  try{
    const r=await fetch('/nowplaying',{headers:{'X-Token':T}});
    if(!r.ok)return;
    np=await r.json();npAt=performance.now();
    $('np').hidden=!np.active;
    if(!np.active)return;
    $('np-title').textContent=np.title||t('media');
    $('np-artist').textContent=[np.artist,np.album].filter(Boolean).join(' · ');
    if(np.art!==npKey||!npArt){
      if(np.art!==npKey){npKey=np.art;npArt=false;$('np-art').removeAttribute('src')}
      fetch('/artwork?k='+encodeURIComponent(np.art),{headers:{'X-Token':T}}).then(r=>r.ok?r.blob():null).then(b=>{
        if(b&&npKey===np.art){npArt=true;$('np-art').src=URL.createObjectURL(b)}
      }).catch(()=>{});
    }
    drawNP();
  }catch(e){}
}
function drawNP(){
  if(!np||!np.active)return;
  let pos=np.position+(np.playing?(performance.now()-npAt)/1000:0);
  if(np.duration)pos=Math.min(pos,np.duration);
  $('np-fill').style.width=(np.duration?pos/np.duration*100:0)+'%';
  $('np-pos').textContent=fmt(pos);$('np-dur').textContent=fmt(np.duration);
}
pollNP();setInterval(pollNP,2000);setInterval(drawNP,500);
document.addEventListener('visibilitychange',()=>{if(!document.hidden)pollNP()});

/* Screen preview: off by default, never persisted, switched off when the page is hidden */
const pv={on:false,iv:2000,d:0,timer:null,url:null,n:1};
function pvShow(url){if(pv.url)URL.revokeObjectURL(pv.url);pv.url=url;if(url)$('pv-img').src=url;else $('pv-img').removeAttribute('src')}
async function pvTick(){
  if(!pv.on)return;
  try{
    const r=await fetch('/screen?d='+pv.d+'&_='+Date.now(),{headers:{'X-Token':T}});
    if(!pv.on)return;
    if(!r.ok){toast(srv(await r.text()),true);return pvSet(false)}
    pvShow(URL.createObjectURL(await r.blob()));
  }catch(e){}
  if(pv.on)pv.timer=setTimeout(pvTick,pv.iv);
}
async function pvSet(on){
  clearTimeout(pv.timer);pv.on=false;
  $('pv-sw').checked=on;$('pv-body').hidden=!on;
  if(on){
    try{
      const r=await fetch('/cmd',{method:'POST',headers:{'X-Token':T},body:JSON.stringify({action:'preview_on'})});
      const j=await r.json();
      if(!j.ok){toast(srv(j.info||t('pvUnavailable')),true);$('pv-sw').checked=false;$('pv-body').hidden=true;return}
    }catch(e){toast(t('unreachable'),true);$('pv-sw').checked=false;$('pv-body').hidden=true;return}
    pv.on=true;pvTick();
  }else{
    pvShow(null);
    try{fetch('/cmd',{method:'POST',headers:{'X-Token':T},body:JSON.stringify({action:'preview_off'}),keepalive:true})}catch(e){}
  }
}
function pvHint(){$('pv-hint').textContent=pv.n>1?t('hint')(pv.d%pv.n+1,pv.n):''}
$('pv-sw').addEventListener('change',e=>pvSet(e.target.checked));
$('pv-img').addEventListener('click',()=>{if(pv.n>1){pv.d=(pv.d+1)%pv.n;pvHint();clearTimeout(pv.timer);pvTick()}});
document.querySelectorAll('#pv-iv button').forEach(b=>b.addEventListener('click',()=>{
  pv.iv=+b.dataset.s;document.querySelectorAll('#pv-iv button').forEach(x=>x.classList.toggle('sel',x===b));
}));
document.addEventListener('visibilitychange',()=>{if(document.hidden&&pv.on)pvSet(false)});
window.addEventListener('pagehide',()=>{if(pv.on)pvSet(false)});

/* Trackpad: locked until the pill is tapped, relocks after 20 s without touches.
   Gestures become small ops (see Pointer.swift), coalesced and sent one request at a time. */
const TP={idle:20000,hold:400,tap:300,tapSlop:10,dead:3,scrollDead:8,pinchDead:8,pinchStep:26,swipe:40,sens:1.25,scroll:1.5,friction:.9965};
const tp={on:false,q:[],busy:false,last:0,idle:null,raf:0,pts:new Map(),s:null,btn:false};
const pad=$('tp');
/* Pointer acceleration: slow strokes stay precise, fast flicks cross the screen. v in px/ms. */
const tpGain=v=>TP.sens*(1+2.2*Math.min(1,Math.max(0,(v-.08)/1.1)));
function tpPush(op){
  const l=tp.q[tp.q.length-1];
  if(l&&l[0]===op[0]&&(op[0]==='m'||op[0]==='s')){l[1]+=op[1];l[2]+=op[2]}else tp.q.push(op);
  tpFlush();
}
async function tpFlush(){
  if(tp.busy||!tp.q.length)return;
  const wait=12-(performance.now()-tp.last);
  if(wait>0){tp.busy=true;setTimeout(()=>{tp.busy=false;tpFlush()},wait);return}
  tp.busy=true;tp.last=performance.now();
  const ops=tp.q.map(o=>o.map(v=>typeof v==='number'?Math.round(v*100)/100:v));tp.q=[];
  try{
    const r=await fetch('/pointer',{method:'POST',headers:{'X-Token':T},body:JSON.stringify(ops)});
    if(r.ok){const j=await r.json();if(!j.ok){toast(srv(j.info||t('failed')),true);tpLock()}}
    else if(r.status!==429){toast(t('err')+r.status,true);tpLock()}
  }catch(e){toast(t('unreachable'),true);tpLock()}
  tp.busy=false;tpFlush();
}
function tpWake(){clearTimeout(tp.idle);tp.idle=setTimeout(tpLock,TP.idle)}
function tpUnlock(){
  if(document.activeElement)document.activeElement.blur();   // a focused field would turn 3 fingers into iOS undo
  tp.on=true;pad.classList.add('on');$('tp-card').classList.remove('off');tpWake();
}
function tpLock(){
  if(!tp.on)return;
  tp.on=false;clearTimeout(tp.idle);tpStopInertia();
  const held=(tp.s&&tp.s.held)||tp.btn;
  if(tp.s)clearTimeout(tp.s.hold);
  tp.s=null;tp.btn=false;$('tp-l').classList.remove('on');
  tp.pts.forEach(p=>p.dot.remove());tp.pts.clear();
  tp.q=held?[['u']]:[];tpFlush();
  pad.classList.remove('on','drag');$('tp-card').classList.add('off');
  const l=$('tp-go-l');l.dataset.i18n='tpResume';l.textContent=t('tpResume');
}
function tpInertia(vx,vy){
  if(Math.hypot(vx,vy)<.2)return;
  let last=performance.now();
  const step=now=>{
    const dt=Math.min(50,now-last),f=Math.pow(TP.friction,dt);last=now;
    vx*=f;vy*=f;tpPush(['s',vx*dt,vy*dt]);
    tp.raf=Math.hypot(vx,vy)>.02?requestAnimationFrame(step):0;
  };
  tp.raf=requestAnimationFrame(step);
}
function tpStopInertia(){cancelAnimationFrame(tp.raf);tp.raf=0}
function tpMove(s,x,y){s.sx+=x;s.sy+=y;tpPush(['m',x,y])}
function tpDist(){const [a,b]=[...tp.pts.values()];return Math.hypot(a.x-b.x,a.y-b.y)}
function tpDot(p){
  const r=pad.getBoundingClientRect();
  p.dot.style.transform='translate('+(p.x-r.left)+'px,'+(p.y-r.top)+'px)';
}
pad.addEventListener('pointerdown',e=>{
  if(!tp.on)return;
  e.preventDefault();
  try{pad.setPointerCapture(e.pointerId)}catch(x){}
  tpWake();tpStopInertia();tp.q=tp.q.filter(o=>o[0]!=='s');   // a new touch stops any momentum
  if(!tp.pts.size)tp.s={t0:e.timeStamp,max:0,mode:'move',lead:e.pointerId,travel:0,moved:false,held:false,swiped:false,bx:0,by:0,gx:0,gy:0,cx:0,cy:0,d0:0,zr:0,hist:[],hold:0,sx:0,sy:0,v:0,acted:false};
  const s=tp.s,p={x:e.clientX,y:e.clientY,t:e.timeStamp,dot:document.createElement('i')};
  p.dot.className='dot';pad.appendChild(p.dot);tpDot(p);
  tp.pts.set(e.pointerId,p);
  s.max=Math.max(s.max,tp.pts.size);
  if(tp.pts.size>=2){   // a finger that landed first may have jittered: judge the gesture afresh
    s.d0=tpDist();s.moved=s.swiped=false;s.travel=s.cx=s.cy=s.gx=s.gy=0;
    if(e.timeStamp-s.t0<150&&(s.sx||s.sy)){tpPush(['m',-s.sx,-s.sy]);s.sx=s.sy=0}   // and the cursor goes back where it was
  }
  clearTimeout(s.hold);
  if(s.held)return;   // while dragging, extra fingers are ignored
  s.mode=s.max>=3?'swipe':s.max===2?'scroll':'move';
  if(s.max===1)s.hold=setTimeout(()=>{
    if(tp.s===s&&!s.moved&&tp.pts.size===1){s.held=true;pad.classList.add('drag');tpPush(['d'])}
  },TP.hold);
});
pad.addEventListener('pointermove',e=>{
  const p=tp.pts.get(e.pointerId),s=tp.s;
  if(!p||!s)return;
  const dx=e.clientX-p.x,dy=e.clientY-p.y,dt=Math.max(1,e.timeStamp-p.t);
  p.x=e.clientX;p.y=e.clientY;p.t=e.timeStamp;
  if(!dx&&!dy)return;
  tpDot(p);tpWake();
  const n=tp.pts.size;
  s.travel+=Math.hypot(dx,dy);
  if(s.mode==='move'||s.held){
    if(e.pointerId!==s.lead)return;
    if(!s.moved){   // small dead zone: a tap must not nudge the cursor off its target
      s.bx+=dx;s.by+=dy;
      if(s.travel<TP.dead)return;
      s.moved=true;clearTimeout(s.hold);
      return tpMove(s,s.bx*TP.sens,s.by*TP.sens);
    }
    // Speed from one event is noisy (iOS timestamps jitter), and a noisy gain makes the cursor surge
    // and stall; a short moving average keeps the acceleration steady.
    const v=Math.hypot(dx,dy)/dt;s.v=s.v?s.v*.6+v*.4:v;
    const g=tpGain(s.v);
    tpMove(s,dx*g,dy*g);
  }else if(s.mode==='scroll'){
    if(n<2)return;
    if(!s.moved){
      // Two fingers are either a scroll (both move together) or a pinch (the distance changes while
      // the midpoint stays put). The midpoint's drift is a vector sum, so opposite moves cancel out.
      s.cx+=dx/n;s.cy+=dy/n;
      const dd=Math.abs(tpDist()-s.d0),cm=Math.hypot(s.cx,s.cy);
      const pinch=dd>=TP.pinchDead&&dd>=cm*.8;   // real pinches are lopsided: one finger usually does most of the moving
      if(!pinch&&cm<TP.scrollDead)return;
      s.moved=true;
      if(pinch){s.mode='pinch';s.zr=tpDist();return}
    }
    const sx=dx/n*TP.scroll,sy=dy/n*TP.scroll;   // each finger moves the centroid by 1/n
    s.hist.push([e.timeStamp,sx,sy]);
    while(e.timeStamp-s.hist[0][0]>100)s.hist.shift();
    s.acted=true;tpPush(['s',sx,sy]);
  }else if(s.mode==='pinch'){
    if(n<2)return;
    const d=tpDist();   // one step per pinchStep px of finger distance, as many as the move covers
    while(d-s.zr>=TP.pinchStep){s.zr+=TP.pinchStep;s.acted=true;tpPush(['z','i'])}
    while(s.zr-d>=TP.pinchStep){s.zr-=TP.pinchStep;s.acted=true;tpPush(['z','o'])}
  }else if(!s.swiped){
    s.gx+=dx/n;s.gy+=dy/n;
    if(Math.hypot(s.gx,s.gy)>TP.swipe){
      s.swiped=s.moved=s.acted=true;
      tpPush(['g',Math.abs(s.gx)>Math.abs(s.gy)?(s.gx<0?'l':'r'):(s.gy<0?'u':'d')]);
    }
  }
});
function tpUp(e){
  const p=tp.pts.get(e.pointerId),s=tp.s;
  if(!p)return;
  p.dot.remove();tp.pts.delete(e.pointerId);
  if(tp.pts.size||!s)return;
  clearTimeout(s.hold);tp.s=null;
  if(s.held){pad.classList.remove('drag');return tpPush(['u'])}
  if(e.type==='pointercancel')return;
  /* A tap is short and nearly still. Fingers on glass drift a few px, so up to tapSlop px per finger still
     counts; whatever the cursor moved meanwhile is sent back first, so the click lands where it was aimed. */
  if(e.timeStamp-s.t0<TP.tap&&!s.acted&&s.travel<TP.tapSlop*s.max){
    if(s.max===1){if(s.sx||s.sy)tpPush(['m',-s.sx,-s.sy]);tpPush(['c'])}
    else if(s.max===2)tpPush(['r']);
  }else if(s.mode==='scroll'&&s.hist.length&&e.timeStamp-s.hist[s.hist.length-1][0]<60){
    const h=s.hist,span=Math.max(16,h[h.length-1][0]-h[0][0]+16);   // momentum from the last ~100 ms
    tpInertia(h.reduce((a,x)=>a+x[1],0)/span,h.reduce((a,x)=>a+x[2],0)/span);
  }
}
pad.addEventListener('pointerup',tpUp);
pad.addEventListener('pointercancel',tpUp);
pad.addEventListener('contextmenu',e=>e.preventDefault());
/* iOS Safari would otherwise take two-finger pinches for its own page zoom and cancel our pointers */
['gesturestart','gesturechange','gestureend'].forEach(ev=>document.addEventListener(ev,e=>e.preventDefault()));
pad.addEventListener('touchmove',e=>{if(tp.on)e.preventDefault()},{passive:false});

/* Enlarged touchpad: a fixed panel over a dimmed backdrop; touching the backdrop shrinks it back. */
const tpCard=$('tp-card');
function tpBigSync(){const b=tpCard.classList.contains('big'),k=t(b?'tpShrink':'tpExpand');$('tp-big').title=k;$('tp-big').setAttribute('aria-label',k)}
function tpBig(on){
  if(on===tpCard.classList.contains('big'))return;
  if(on)tpCard.style.height=tpCard.offsetHeight+'px';   // the card keeps its place in the page while the panel floats
  else tpCard.style.height='';
  tpCard.classList.toggle('big',on);document.documentElement.classList.toggle('tpbig',on);
  tpBigSync();if(tp.on)tpWake();
}
$('tp-big').addEventListener('click',()=>tpBig(!tpCard.classList.contains('big')));
$('tp-back').addEventListener('pointerdown',e=>{e.preventDefault();if(!tp.pts.size)tpBig(false)});   // a stray finger mid-gesture must not close it
document.addEventListener('visibilitychange',()=>{if(document.hidden)tpBig(false)});

$('tp-go').addEventListener('click',tpUnlock);
const tpL=$('tp-l');
tpL.addEventListener('pointerdown',e=>{
  e.preventDefault();if(!tp.on||tp.btn)return;
  tpWake();tp.btn=true;tpL.classList.add('on');tpPush(['d']);   // hold + move on the pad = drag
});
['pointerup','pointercancel','pointerleave'].forEach(ev=>tpL.addEventListener(ev,()=>{
  if(!tp.btn)return;
  tp.btn=false;tpL.classList.remove('on');tpPush(['u']);
}));
$('tp-r').addEventListener('pointerdown',e=>{e.preventDefault();if(tp.on){tpWake();tpPush(['r'])}});
document.addEventListener('visibilitychange',()=>{if(document.hidden)tpLock()});
window.addEventListener('pagehide',tpLock);
$('tf').addEventListener('submit',e=>{
  e.preventDefault();const i=$('ti');
  if(i.value){send('text',i.value);i.value=''}
});
applyLang();
</script></body></html>
"""#
}
