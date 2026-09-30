<div align="center">

<img src="docs/icon.png" width="120" alt="MacRemote icon">

# MacRemote

**Your Mac's basic controls on your iPhone. Local network only.**
**I controlli base del tuo Mac sul tuo iPhone. Solo rete locale.**

![macOS](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white)
![SwiftPM](https://img.shields.io/badge/Swift_Package_Manager-supported-F05138?logo=swift&logoColor=white)
![AppKit](https://img.shields.io/badge/AppKit-menu_bar_app-0A84FF)
![Network.framework](https://img.shields.io/badge/Network.framework-HTTP_%2B_Bonjour-0A84FF)
![HTML/JS](https://img.shields.io/badge/Web_UI-vanilla_HTML%2FCSS%2FJS-E34F26?logo=html5&logoColor=white)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)
![Network](https://img.shields.io/badge/network-LAN_only-informational)

[🇮🇹 Italiano](#it) · [🇬🇧 English](#en)

</div>

---

<a id="it"></a>

## 🇮🇹 Italiano

[→ Switch to English](#en)

### Cos'è

MacRemote è un telecomando per il Mac, pensato per la situazione tipica: Mac collegato a un monitor, tu a letto, e ogni volta ti devi alzare per abbassare il volume o mettere in pausa.

Sul Mac gira una piccola app nella barra dei menu. Sull'iPhone non installi nulla: apri una pagina web in Safari (scansionando un QR code) e controlli il Mac da lì.

### Cosa fa davvero

- **Volume**: su, giù, muto (tasti multimediali di sistema).
- **Media**: play/pausa, traccia precedente e successiva.
- **Luminosità**, con controlli separati per lo schermo del Mac e per il monitor esterno.
- **Navigazione**: frecce, OK (Invio), Esc, Tab, Maiusc+Tab, Spazio. Serve per muoversi tra gli elementi cliccabili senza mouse.
- **Testo**: scrivi dall'iPhone nel campo attivo sul Mac.
- **Schermo**: spegni il display (il Mac resta acceso) oppure blocca il Mac.
- **Batteria del Mac** in alto nella pagina (percentuale, collegato o in carica).
- Le sezioni luminosità si nascondono se lo schermo corrispondente non è attivo.
- Tenendo premuto volume, luminosità e frecce il comando si ripete.
- La pagina si può aggiungere alla Home dell'iPhone e si apre come un'app.

### Screenshot

La pagina che si apre sull'iPhone. A sinistra la parte alta: volume, luminosità (Mac e monitor separati), media e navigazione, con la batteria del Mac in alto a destra. A destra scorrendo verso il basso: la navigazione, il campo di testo e i comandi dello schermo.

<div align="center">
<img src="docs/screenshot-1.png" width="280" alt="Interfaccia iPhone: volume, luminosità, media e navigazione">
&nbsp;&nbsp;&nbsp;
<img src="docs/screenshot-2.png" width="280" alt="Interfaccia iPhone: navigazione, testo, spegni schermo e blocca">
</div>

---

| Sezione | Cosa controlla |
| --- | --- |
| Volume | Diminuisci, muto, aumenta |
| Luminosità | Schermo del Mac e monitor esterno, separati |
| Media | Traccia precedente, play/pausa (viola), traccia successiva |
| Navigazione | Frecce, OK (Invio), Esc, Tab, Maiusc+Tab, Spazio |
| Testo | Scrive sul Mac, con cancella e invio |
| Schermo | Spegni il display o blocca il Mac |

### Cosa NON fa

- **Non funziona fuori casa**: solo Mac e iPhone sulla stessa rete Wi-Fi/LAN. Non c'è nessun server in cloud.
- **Non è cifrato**: usa HTTP semplice, protetto da un token casuale nel link. Va bene su una rete di casa di cui ti fidi, non su Wi-Fi pubblici.
- **Non è un mouse/trackpad** e non mostra lo schermo del Mac.
- **Non è testato ovunque**: è stato provato solo su un MacBook Pro M3 Pro con un monitor Alienware AW3425DWM. Altri monitor possono comportarsi in modo diverso (vedi sotto).

### Come funziona la luminosità

1. Prima usa lo stesso controllo delle barre di luminosità di macOS (`DisplayServices`, API privata di Apple), uno schermo alla volta, e verifica che il valore sia cambiato.
2. Se non funziona sul monitor esterno, prova il DDC/CI (`IOAVService`, API privata, solo Apple Silicon).
3. Se nemmeno il DDC risponde, scurisce lo schermo via software (gamma), fino al 10%. Questo scurisce l'immagine ma non abbassa la retroilluminazione.

Essendo API private, un aggiornamento di macOS potrebbe romperle.

### Requisiti

- Un Mac con macOS 13 o successivo.
- Strumenti da riga di comando di Apple, con Swift 5.9 o superiore (`xcode-select --install`). Non serve Xcode.
- Un iPhone (o qualsiasi telefono con un browser) sulla stessa rete del Mac.

### Installazione

```bash
git clone https://github.com/jimmyxan/MacRemote.git
cd MacRemote
./build.sh
open MacRemote.app
```

`build.sh` compila il progetto, genera le icone e crea `MacRemote.app`. Puoi spostarla in `/Applications`.

**Al primo avvio** macOS chiede due permessi:

1. **Accessibilità** (Impostazioni di Sistema → Privacy e sicurezza → Accessibilità → attiva MacRemote). Senza questo permesso i tasti volume, media, frecce e testo non funzionano; la luminosità sì.
2. **Rete locale**: accetta la richiesta, altrimenti l'iPhone non riesce a collegarsi.

Poi chiudi MacRemote dalla barra dei menu (Esci) e riaprilo.

Consigliato: nel menu di MacRemote attiva **Avvia al login**.

### Utilizzo

1. Apri MacRemote: appare l'icona nella barra dei menu e una finestra con un QR code.
2. Inquadra il QR con la fotocamera dell'iPhone (stessa Wi-Fi) e apri il link in Safari.
3. Facoltativo: Condividi → **Aggiungi a Home** per avere l'icona come un'app.
4. Usa i pulsanti. Il messaggio in alto mostra l'esito (ad esempio `Monitor 80%`).

**Menu di MacRemote:** mostra QR, copia link, rigenera token (invalida i vecchi link), avvia al login, esci.

**Per muoverti tra i cliccabili con Tab** in tutte le app: Impostazioni di Sistema → Tastiera → attiva "Accesso completo da tastiera".

### Risoluzione problemi

| Problema | Soluzione |
| --- | --- |
| I pulsanti non fanno nulla, la pagina dice "Permesso Accessibilità mancante" | Attiva MacRemote in Accessibilità, poi esci e riapri l'app. Se non basta, rimuovi la voce con "−" e riaggiungila. |
| L'iPhone non si collega | Stessa Wi-Fi? Hai accettato "Rete locale"? Alcuni router isolano i client (AP isolation). |
| Il volume non cambia | Se l'audio esce da un monitor HDMI/DP con volume fisso, il Mac non può cambiarlo. |
| La luminosità del monitor non cambia | Vedi "Come funziona la luminosità". Come ripiego si scurisce via software. |
| Il link non funziona più | Hai rigenerato il token: scansiona di nuovo il QR. |

### Sicurezza

- Il server accetta solo connessioni da indirizzi di rete privata (192.168.x.x, 10.x.x.x, 172.16-31.x.x, link-local, loopback).
- Ogni richiesta richiede un token casuale a 128 bit generato al primo avvio.
- Limite di 40 richieste al secondo.
- Traffico non cifrato: chiunque sulla tua rete che intercetti il link può usare il telecomando.

### Struttura del progetto

```
Package.swift            Swift Package (nessuna dipendenza)
build.sh                 compila e crea MacRemote.app (con icone)
tools/make_icon.swift    genera le icone
Sources/MacRemote/
  main.swift             app barra dei menu, QR, token, avvio al login
  Server.swift           server HTTP (Network.framework) + Bonjour
  Commands.swift         azioni dei pulsanti
  Input.swift            tasti multimediali, tastiera, testo, blocco/spegni schermo
  Brightness.swift       luminosità: DisplayServices, DDC/CI, gamma
  Battery.swift          stato batteria
  WebUI.swift            pagina web per l'iPhone (HTML/CSS/JS incorporati)
```

---

<a id="en"></a>

## 🇬🇧 English

[→ Passa all'italiano](#it)

### What it is

MacRemote is a remote control for your Mac, built for a typical situation: the Mac is connected to a monitor, you are in bed, and every time you need to change the volume or pause something you have to get up.

A small menu bar app runs on the Mac. Nothing to install on the iPhone: you open a web page in Safari (by scanning a QR code) and control the Mac from there.

### What it really does

- **Volume**: up, down, mute (system media keys).
- **Media**: play/pause, previous and next track.
- **Brightness**, with separate controls for the Mac's own display and the external monitor.
- **Navigation**: arrows, OK (Return), Esc, Tab, Shift+Tab, Space. Use them to move between clickable elements without a mouse.
- **Text**: type on the iPhone into the field that is focused on the Mac.
- **Screen**: turn the display off (the Mac stays on) or lock the Mac.
- **Mac battery** at the top of the page (percentage, plugged in or charging).
- Brightness sections hide when the matching display is not active.
- Holding volume, brightness and arrow buttons repeats the command.
- The page can be added to the iPhone Home Screen and opens like an app.

### Screenshots

The page that opens on the iPhone. Left: the top part, with volume, brightness (Mac and monitor separate), media and navigation, and the Mac battery at the top right. Right: scrolled down, showing navigation, the text field and the screen controls.

<div align="center">
<img src="docs/screenshot-1.png" width="280" alt="iPhone interface: volume, brightness, media and navigation">
&nbsp;&nbsp;&nbsp;
<img src="docs/screenshot-2.png" width="280" alt="iPhone interface: navigation, text, display off and lock">
</div>

---

| Section | What it controls |
| --- | --- |
| Volume | Down, mute, up |
| Brightness | Mac display and external monitor, separate |
| Media | Previous track, play/pause (purple), next track |
| Navigation | Arrows, OK (Return), Esc, Tab, Shift+Tab, Space |
| Text | Types on the Mac, with backspace and send |
| Screen | Turn the display off or lock the Mac |

### What it does NOT do

- **It does not work away from home**: Mac and iPhone must be on the same Wi-Fi/LAN. There is no cloud server.
- **It is not encrypted**: plain HTTP, protected by a random token in the link. Fine on a home network you trust, not on public Wi-Fi.
- **It is not a mouse/trackpad** and it does not show the Mac's screen.
- **It is not tested everywhere**: it has only been tried on a MacBook Pro M3 Pro with an Alienware AW3425DWM monitor. Other monitors may behave differently (see below).

### How brightness works

1. It first uses the same control as the macOS brightness sliders (`DisplayServices`, a private Apple API), one display at a time, and checks that the value actually changed.
2. If that does not work on the external monitor, it tries DDC/CI (`IOAVService`, private API, Apple Silicon only).
3. If DDC does not respond either, it dims the screen in software (gamma), down to 10%. This darkens the image but does not lower the backlight.

These are private APIs, so a macOS update could break them.

> Note: the app menu and the web page labels are currently in Italian.

### Requirements

- A Mac running macOS 13 or later.
- Apple command line tools with Swift 5.9 or later (`xcode-select --install`). Full Xcode is not needed.
- An iPhone (or any phone with a browser) on the same network as the Mac.

### Installation

```bash
git clone https://github.com/jimmyxan/MacRemote.git
cd MacRemote
./build.sh
open MacRemote.app
```

`build.sh` builds the project, generates the icons and creates `MacRemote.app`. You can move it to `/Applications`.

**On first launch** macOS asks for two permissions:

1. **Accessibility** (System Settings → Privacy & Security → Accessibility → enable MacRemote). Without it, volume, media, arrows and text do not work; brightness does.
2. **Local Network**: accept the prompt, otherwise the iPhone cannot connect.

Then quit MacRemote from the menu bar (Quit) and open it again.

Recommended: turn on **Start at login** in the MacRemote menu.

### Usage

1. Open MacRemote: a menu bar icon appears, along with a window showing a QR code.
2. Scan the QR with the iPhone camera (same Wi-Fi) and open the link in Safari.
3. Optional: Share → **Add to Home Screen** to get an app-like icon.
4. Use the buttons. The message at the top shows the result (for example `Monitor 80%`).

**MacRemote menu:** show QR, copy link, regenerate token (invalidates old links), start at login, quit.

**To move between clickable items with Tab** in every app: System Settings → Keyboard → turn on "Keyboard navigation".

### Troubleshooting

| Problem | Fix |
| --- | --- |
| Buttons do nothing, the page says "Permesso Accessibilità mancante" (Accessibility permission missing) | Enable MacRemote in Accessibility, then quit and reopen the app. If that is not enough, remove the entry with "−" and add it again. |
| The iPhone cannot connect | Same Wi-Fi? Did you accept "Local Network"? Some routers isolate clients (AP isolation). |
| Volume does not change | If audio plays through an HDMI/DP monitor with fixed volume, the Mac cannot change it. |
| Monitor brightness does not change | See "How brightness works". Software dimming is the fallback. |
| The link stopped working | You regenerated the token: scan the QR again. |

### Security

- The server only accepts connections from private network addresses (192.168.x.x, 10.x.x.x, 172.16-31.x.x, link-local, loopback).
- Every request needs a random 128-bit token generated on first launch.
- Rate limit of 40 requests per second.
- Traffic is not encrypted: anyone on your network who intercepts the link can use the remote.

### Project layout

```
Package.swift            Swift Package (no dependencies)
build.sh                 builds and creates MacRemote.app (with icons)
tools/make_icon.swift    generates the icons
Sources/MacRemote/
  main.swift             menu bar app, QR, token, start at login
  Server.swift           HTTP server (Network.framework) + Bonjour
  Commands.swift         button actions
  Input.swift            media keys, keyboard, text, lock / display sleep
  Brightness.swift       brightness: DisplayServices, DDC/CI, gamma
  Battery.swift          battery status
  WebUI.swift            iPhone web page (embedded HTML/CSS/JS)
```

<div align="right">

[↑ Top](#it) · [🇮🇹 Italiano](#it) · [🇬🇧 English](#en)

</div>
