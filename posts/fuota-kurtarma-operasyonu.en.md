# Without Breaking the Seal: Closing a Security Hole with FUOTA

Yesterday we were on the last break of the day. My colleague Semi Avcı and I had grabbed a coffee and were chatting. The subject was work again, but we weren't at our desks; we were talking with that break-time head on — looser sentences, more "what if" in the questions.

Then something occurred to me and I asked Semi. Before I'd finished the question his face changed too. We both understood at the same moment.

There was a security vulnerability in the remote-read water meter module we build for a water and sewerage utility. And 1,900 of those modules had already shipped.

Let me describe what goes through your head at that moment. In order: "no way", "am I getting this wrong", "I really wish I were getting this wrong".

Worth noting: that vulnerability wasn't caught by a test, and it wasn't caught by an analysis tool. It was caught by two people drinking coffee. Don't underestimate breaks — sometimes stepping away from the screen does more work than staring at it.

Good news: none of the devices had been installed yet. Bad news: by the time we recalled them, nearly half had already been boxed and sealed.

We started updating this afternoon. By the evening I had run FUOTA on 160 devices on my own, without breaking a single seal.

## The code I liked least turned out to be the code that saved me

The code I was least comfortable writing in this project was the FUOTA (Firmware Update Over The Air) code.

The reason is simple: if an update stops halfway, you're left with a device that won't come up. A brick. And since that device can no longer talk to your software, there's no second chance either — the recovery mechanism itself ends up needing recovery. These were the functions I feared most, tested most, and trusted least.

Yesterday evening I realised those weeks of hesitation were the most profitable investment in the project.

Because a sealed box means this: you have a cable in your hand and nowhere to plug it in. Break the seal and the device can't reach the customer "never opened" any more — repacking, resealing, reshipping, and a fresh chance of error at every step. Without FUOTA the job would have become: open 1,900 boxes one by one, cable them one by one, put them back one by one. Instead the boxes stayed shut, and we just talked to the radio on the other side of the lid.

The devices that hadn't been boxed yet were flashed over the wire with the current firmware, along with the new features we'd added to our production application.

![The recalled boxes and the crate of modules waiting to be updated](posts/gorseller/fuota-kutular.jpg)

## Same software, two computers, two different personalities

The thing that surprised me most today was a technical inconsistency. Same application, same devices, two different computers:

- **Desktop with an external Bluetooth adapter** — visibly slower transfers, but disconnects were almost non-existent.
- **Laptop with built-in Bluetooth** — far faster transfers, but a disconnect rate clearly above the desktop's.

Same firmware, same room, same distance. The only variable was the radio on the other end and the stack driving it.

I haven't measured the cause yet. My first suspect is the laptop's combined Wi-Fi/Bluetooth chip: it shares the 2.4 GHz band, and in most designs the antenna too, with Wi-Fi — the two take turns on the air. On the external adapter, both the radio and the antenna work alone. But for now that's only a hypothesis; I won't claim anything until I switch Wi-Fi off on the laptop and repeat the same test. When I measure it, I'll write it up here.

![Two FUOTA sessions running in parallel on two screens, both showing the "device firmware updating" view](posts/gorseller/fuota-masaustu.jpg)

This is exactly where the gap between a test in the office and the actual job shows up. The character of a link isn't set by the device you built alone; every piece of hardware you put on the other end reshapes it.

## Mistakes and people

My first feeling, once the break was over and we were back at our desks, was fear. What suppressed it wasn't a technical fix — it was our general manager Tahsin Önkol's reaction: instead of fixating on the mistake and getting angry, he cleared the way for us to focus on the fix. The fastest way for a mistake to get closed is for the person who finds it not to hesitate before speaking up. I saw that first-hand yesterday.

The second thing was the production and FUOTA application Semi built. The software Semi writes has one thing in common: it's fast. He treats that not as a detail to look at later but as a design goal set from the start. In this application too he put serious work into flashing firmware as quickly as possible — and today we collected on that work. If I was able to update 160 devices on my own, it's because the seconds per device were trimmed months ago. You find out whether a tool is really any good by using it eight hours straight; by the evening my only remaining complaint was my back.

## What I take away

Embedded systems engineering isn't about writing flawless code. It's about aiming for flawless, then building the path that lets you make up for a mistake into the system from the very start.

FUOTA wasn't a feature for us, it was an insurance policy. Until yesterday evening we'd never claimed on it. Today we did, for the first time, and it paid out.

The operation continues. I'm not the one keeping the overall count, but for today I'm at 160. Those 1,900 devices are in another city; next week we're heading there to update them on site.
