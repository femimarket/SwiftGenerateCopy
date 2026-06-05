leaning on 7generate.md and 7generate.complete.md so u can
compute the high level goal and vision

this is a screen for viewing videos from other creators
u get to view videos, comment to predefined creator post about song
turned contest and like videos.
that was the original idea kind of.

like a creator could post what state of mind was i in and the
closest answer wins a prize. this is a much more fulfilling
form of engagement thats 2 way. but this was half scrapped 
because it involved crypto as the prize money. i couldn't reconcile it
for some time. and just now i thought of the reward as credits.
but viewers are necessarily creators like the most ardent viewer
is probably not a creator coz they dont have time to view and on top 
of that comment to creator posts. howver i am thinking of credits
as currency to view, like and comment so they have functions as viewers
which is planned and practically signed off to develop.

The thing is the 2 way engagement idea is great. The creator determines 
how people engage via comments. The only thing is what should the reward be.
Credits were accurately descriptive but not necessarily prescriptive.
Like the way im thinking about this is rewards have to be tangible.
Digital rewards that only work digital is a route I don't want to go down.
Credits is that route. Crypto was not coz it can be exchanged for value
globally but crypto isn't accepted everywhere legally so not going down 
that route. Im thinking a artist giving a way free t shirt or something u know.
That 100% works, or free like artist cartoon image with them as cover of next album.
You know even that is not digital only coz it can be printed and having 
fan image on album cover is ubiquitous. Maybe i need to refine idea more. 
But i've arrived at artist need to prescribe their own rewards but its awkward
coz i have to cater to almost eveyrthing which is not possible. thats the dilema.
Coming back to this the only thing I can thinkiing is winner
gets to tell artist what kind of song to make next. Conceptually perfect.
Practically needs refinement. Thoguhts?

Apart from post contest, likes and views as already said which
all cost credits. Even downloading videos cost credit which charged bandwidth
covers anyway.

Oh yeah, so that last feature of feed I had thought of is you being able
to download music project files. So since they used our app to create it
other users can download the project and open it in our app. I think
creators can choose whether or not to allow this. Indifferent on that right now.


So there we have the core features of feed
- Creator posts, user comment contnets
- Like (I'm thinking different ctas for different intensity of like)
  - corresponding to more credits showing appreciation
  - i'd have to integrate stripe connected accounts or something coz likes go to creator not me (impl not required now)
- Download project so u can remix music video or whatever u want
  - it has a cost which goes to creator
  - need to figure out if this is fixed price always or set by creator
- Viewing
  - Well viewing meaning download bytes which impictly cost credits anyway which users are aware of

So that is the high level overview distilled of the feedscreen

The goal of the screen is allow users to watch music videos and 
engage with them.
At end of day user should confidently know how to engage with videos.


I like the tiktok full screen ui ux layout
But i like the apple music ui ux layout better when a 
song is being played. It literally changes colors of the
whole screen to match the album cover. So we're going for that.
So tiktok was good base to start from ideawise but I actually realised we're 
modeling after apple music ui ux.
The only thing is that we do not show those player controls.


Something I forgot to mention that is absolutely crucial. The acrchitecture
for our feed is astc videos played from disk streamed from memory.
It's not just astc frames simply played. A music videos consists of
astc frames representing indiviudal video scene laid out on a timeline json
structure dictating the start time for each scene, effects, and even text animations.
It's basically a dynamic real time music video player. What this means is potentially
we can dynamically alter video on fly. So building on top of apple ui ux
if we do have controls it'll be for dynamically altering music video
not for pausing, next or rewind.

I'm not sure if i want users to be able to skip a music video.
I'd need ur advice here based on ios ui ux expertise.
My reasoning is if u like videos overtime we'll only show u 
what u like. But if that is bad ux to force to watch video u dont like then
the mechanism of skipping video has to evaluated coz we're not doing what
tiktok does. swipe up for next video... no. I already have an idea,
something like u generate a picture or choose color range and we
derive from that semantics like genre or whatnot to show u a video.
I don't want the experience to be swipe for next easily dismissing playing video no.
I want the experience to be some kind of emotional investment where
selecting a color range or image or uploading a song whatever that is
used a entropy to show u a video ur likely to like. I'm not really into 
swipe swipe culture, every music videos is its own world that can capture anyone
thanks to our architecture that can dynamically tailor video in realtime
to user preferences. But ur the ios ui ux expert not me, i really on ur thoughts?

I think that covers the vibe im going for. U understand the technicals
at play. This is 100% ui ux so i rely on ur ios expertise.
But the video playing is real. I have the astc files and all the assets
you'll need for that so give me ur checklist

concerns:
i trust ur ui ux ios expertise


so to recap the purpose of this screen is to guide first time users which they
are if they're on this screen to create their first music video scene.

for this screen im thinking 2 images filling strips on top
and bottom of phone for some reason. i dont know how or
why but i see it in play somehow

the flow is the tutorial.
dont explicitly say do this or do that but following
as always -> the journey, the journey is the tutorial.


video playing specs:
# Scene1 — Brief

## Architecture

- **Audio is the clock** — `AVAudioPlayer.currentTime` drives everything; the renderer pulls it each frame at 60 Hz.
- **Video** — `clip.astc` is a 240-frame, 1280×720, ASTC 8×8 LDR stream uploaded once into a Metal `texture2d_array`. A 1-line decode shader extracts the current slice each frame.
- **Effects** — 8 transition shaders live as branches inside one MSL fragment shader, selected by `kind`. A transition fires on every lyric-line boundary, runs `t = 0 → 1` over ~400 ms, then drops back to the plain present pipeline.
- **Text** — SwiftUI per-character reveal driven by `lines.json` timings (opacity + scale + glow + blur).
- **Trigger** — every frame the renderer compares current `lineIndex` against the last seen; when it changes, snapshot the previous frame and arm the next transition. One `if` is the entire link.

## Composition schema

```rust
pub enum TimelineTrack {
    Audio,
    Video,
    Text,
    VideoCrossFade,
    VideoBarSwipe,
    VideoSwipe,
    VideoFlash,
    VideoIris,
    VideoPixelate,
    VideoGlitch,
    VideoZoomPunch,
    TextCharacterReveal,
}

pub struct Model {
    pub id: Uuid,
    pub user_id: String,
    pub track: TimelineTrack,
    pub resource_id: Uuid,        // chars / words / lines / videos / audio
    pub timeline_start_ms: i64,
    pub duration: i64,
    pub params: Option<Value>,    // per-row tuning, optional
}
```

`track` is the discriminator — it tells the renderer which subsystem handles the row and which resources table to look `resource_id` up in. `resource_id` stays an opaque UUID.

## Example composition (JSON)

```json
[
  { "track": "Audio", "resource_id": "<song-uuid>",
    "timeline_start_ms": 0, "duration": 60000 },

  { "track": "Video", "resource_id": "<clip-uuid>",
    "timeline_start_ms": 0, "duration": 60000 },

  { "track": "Text", "resource_id": "<char-I-uuid>",
    "timeline_start_ms": 10060, "duration": 100 },
  { "track": "Text", "resource_id": "<char-d-uuid>",
    "timeline_start_ms": 10200, "duration":  20 },

  { "track": "TextCharacterReveal", "resource_id": "<char-I-uuid>",
    "timeline_start_ms": 10060, "duration": 100 },
  { "track": "TextCharacterReveal", "resource_id": "<char-d-uuid>",
    "timeline_start_ms": 10200, "duration":  20 },

  { "track": "VideoBarSwipe", "resource_id": "<clip-uuid>",
    "timeline_start_ms": 10060, "duration": 400 },
  { "track": "VideoSwipe",    "resource_id": "<clip-uuid>",
    "timeline_start_ms": 11440, "duration": 400 },
  { "track": "VideoFlash",    "resource_id": "<clip-uuid>",
    "timeline_start_ms": 13520, "duration": 240 },
  { "track": "VideoIris",     "resource_id": "<clip-uuid>",
    "timeline_start_ms": 15880, "duration": 600 }
]
```

## Key properties

- Flat list, tagged-union shape — no graph, no N-arrays. New variants = new enum cases.
- `track` carries kind; `resource_id` is opaque UUID into a per-kind resources table.
- Same shape covers video FX and text animations; renderer dispatches to Metal or SwiftUI by track.
- Audio clock is master for every visual decision.


For now this means you have to use a line.json to compute required structure of 

```rust
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, ToSchema)]
pub struct LyricWord {
pub id: Uuid,
pub text: String,
pub start: f64,
pub end: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, ToSchema)]
pub struct LyricCharacter {
pub id: Uuid,
pub text: String,
pub start: f64,
pub end: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, ToSchema)]
pub struct LyricLine {
pub id: Uuid,
pub text: String,
pub start: f64,
pub end: f64,
pub annotation: String
}


#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, ToSchema)]
pub struct Lyric {
pub id: Uuid,
pub words: Vec<LyricWord>,
pub characters: Vec<LyricCharacter>,
pub lines: Vec<LyricLine>,
pub text: String,
}

```

to satisfy `{ "track": "TextCharacterReveal", "resource_id": "<char-I-uuid>",
    "timeline_start_ms": 10060, "duration": 100 }`
coz how else will u get the text uuid 


NO FALLBACKS!!!
