

This screen is for generation and also a tutorial page that
teaches how to operate the screen. After screen completion
users will know how to use screen effectively.

The should should start with some onboarding like intro
that builds up context to goal of screen.

Then the first cta screen after onboarding should just
have a start generating button.

Before I continue, let me explain what this screen is about from another
angle. You generate images. From those images you can
generate videos. Videos serve as scenes to music video. 
We'll build on this understanding as we go alone.

So they click first cta button after onboarding and it
makes call to server to generate images. I'll get into the detail
of what calls to make later. But clicking buttons make some calls
to server that result in multiple image generations.

It's a good point to mention now that at this point the screen
should transition to a grid view. Because thats the only way
I can think of to display multiple images at once in ios. It
reminds me of the photos app which is a perfect example. I thought
of display full images 1 by 1 but that doesn't work for multiple images.
I hope that aligns with ios ui ux best practices.

Back to image generation. So bear in mind this screen is also
serving as a tutorial at the same time. So it's desirable
to have pop ups or interactive animations or ux transitions
that serve as informational guides point that user attention
to key parts of screen and giving thoughtful lessons of the 
process.

On the back of this, generating images is not free. Behind the scenes
the call to generate a image is actually first generating
a prompt via llm to pass to the image generation model. Thats multiple
costs involved. It's not necessary for a user to know every single
step behind the scenes but its critical they are aware of costs
which you show them on demand. How im thinkong about this
is first time they click generate show more elaborate ui form
of copy than subsequent minimial ubiquitous interface.

The costs are fixed because we're tracking every interaction
with 3rd party provider to ensure we're profitable every call
so we don't ever have unpredictable prices we can't show users.
In generating images it is a call to llm and then text2image model.
That becomes apparent when deriving new images from existing image
that we'll get to it.

When images are generated user can see them in the grid view
I talked about. At this point the next step in the tutorial is that 
we want them to select an image. So they can't do anything but select
an image as that is the action we want users to take at this point
that I hope the tutorial ux can do smoothly. 

When they click image they should be taken to a screen with
text box. The idea here is that the user can input in natural
language changes they'd like to make to the image they just clicked.
This ties into what I said earlier about deriving new images
from existing images. The user should be informed so they're not
confused as to what they're doing on the screen. Remember, the
cta here is a paid action.

When they click the cta for that screen it should summise, go back
to the grid view screen to display the new images. So up to this point
the user should know how to generate images and derive new images
from existing. 

Moving on from that is where I need ur ios ui ux expertise. Each image
can be liked. This is important metadata we track because we should be
able to declutter screen filtering to just liked images. But thats not all,
in this same screen is the ability to generate videos. However videos can only be 
created from liked images. You do not derive new videos from existing videos. 
To achieve similar, you just select same images to generate video.
Same process with liking images you can like videos.
The maximum liked images they can select to generate video is 3 and minimum is 1.


I think this is a good point to mention that the user should be guided to 
like images to create videos and to like a video. That is the flow I want
the tutorial to force because users are learning how to use the app this way.

The final flow is about primarily creating a video from liked images.
You've learnt all there is to learn at this point.

// Note to self: ability generate videos from videos is a paid feature.
// we are not doing that now. Will revisit later after app release.

I want mention intermiediery flows that
exist beforehand. Users always have the option to upload their own images
liking them to arrive at final flow. So it is not mandatory
they pay to generate content as they can upload their own content, like them 
to get to the final flow. Users should know that via good ui and user journey.

Not a flow per say, but when users are generating content, screen should
play audio. To even be in this screen guarantees there is audio to play as
the final generation and audio linked up. For all intents and purposes
generating a video is audio2video (for u to know not user).
So playing the audio while generating content serves to keep user in flow state. 
The audio plays loops a specific range. This range can be adjusted by the user. 
Default to short range based on 1st audioline.starttime. Bear in the 
generate video will be made with that audio range.

// Note to self: casting characters to image and video is a paid feature.
// we are not doing that now. Will revisit later after app release.

I assume most of the time spent now has been between grid view and the input text
screen. To create single video from multiple liked images requires of course
selecting them. This is where I rely on ur ui ux expertise to signal that in this
guided tutorial screen when they've reach the state of having liked images for
the first time. 

The services you'll likely involved in this screen are:
- credit service (non mutating service, read only)
- project service (to get project)
- image service (to generate images)
- video service (to generate videos)
- chat service (to generate llm prompt which is used to generate images via image service)
- pricing service (to get pricing information)
- other implicit services maybe not mentioned so check apis

To play audio u probably have to download it first if is not already exist locally.
call https://femi.market/<filename> with auth token
if you're going to download it, it has a cost. user should agree before proceeding.
information about this cost is here
[
bandwdith cost per gb so its 100 credit per gb. minimum charge is 1 credit and what that means is basically any download of audio,video or images will incur always minimum charge of 1 credit..... so basically if the size if `kb well that unit is to small to charge but will charge 1 credit anyway. if size is 1gb we charge 1gb u get it. honesly it sounds like something u'd put deep in terms and conditions and we will in more detail but we brielf show it here.
the reason why we charge bandwidth is because its not free and capital backed comapinies eat that costs. im solo dev and cant do that but pass on cost to consumer
not expecting u say that but help word framing
]


ui ux vibe = dark colors but vibrant - this is flagship part of app so make it count
tutorial wizard flow
similar to ios photos app
once theyve generated their first video, screen completes

concerns:
i trust ur ui ux ios expertise but i need to bring to ur attention the filtering mechanism
coz i thought about it. if clicking a image opens that text view and perhaps long pressing
image puts it in select mode; good ux yes but limits what other interactions we can do right?
so something to think about when ur implementing filtering and liking coz i delegate that to 
ur expertise completely

since i imagine videos will be in the grid view? probably they should auto play on mute.
i think thats a familiar ux with that feature apple has with moving photos or something.
bringing to ur attention.

apple login token bearer header
Bearer eyJraWQiOiI1UkZPU2lOSVVtIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoibWFya2V0LmZlbWkiLCJleHAiOjE3ODAyNDk5NjcsImlhdCI6MTc4MDE2MzU2Nywic3ViIjoiMDAwNTM5LjFjMGFhZmZlY2NjNTQwNjI5ODc1OTliMDEwM2U2ZWNkLjExMTEiLCJjX2hhc2giOiJaempPSkFmYXRzY1hVbnNkN2daa3FBIiwiZW1haWwiOiJidXNpbmVzc0BmZW1pLm1hcmtldCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdXRoX3RpbWUiOjE3ODAxNjM1NjcsIm5vbmNlX3N1cHBvcnRlZCI6dHJ1ZX0.gu0nxZdOhU5qbaDQ4dDVxrnU5NVwAspewRUCp0AZ5L7x8zodT0CdbKGfoWW4m905dea2DuNMuhmbdidkj_IBuPf7LgP1rYUkJwxOMnFbYQdmSb01doTSx07wZuPa6x6Qj0ble2T260iZoj9GYSdktEwjdaU-AwbJiStObLPhdA1vJohs4JKVbHsdI-RHYVLDYqKGFgvQMv7Yf5Xp0uFn_GzM7zkoCCqhbeTKz8oorpIMUAXUzXIxdv23-7r8UfXpW9OiZlXRlwcinB6H-7MPswUq4k-gGubMv_jdw9AV_hdnuvXrnDVgG2KQaBVF1XnPBHYQHHZFtsrLZv52QaSoww

for topup
product ids are
creator
artist
director

they are already plugged into app store conenct in app purchases
remember show information and just the right time

If users do not have enough credit show topup view.
Use credit service to get balance. Credit service is read only so cannot be set.
Remeber show information at the right time when needed.
So topup view only comes into play at last moment when theyve triggered
something that 100% requires it.

so to recap the purpose of this screen is to guide first time users which they
are if they're on this screen to create their first music video scene.
At end of doing that, they should confidently know how to create music video scenes.