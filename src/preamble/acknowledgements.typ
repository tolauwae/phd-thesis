#import "../../lib/environments.typ": note
#import "../../lib/fonts.typ": small

= Acknowledgements

// Christophe
This dissertation could not have been written without the help and support of a long list of people.
First and foremost, I must thank my supervisor _Christophe Scholliers_ for being a tremendous tutor and teacher.
I am forever grateful for your guidance, and enthusiasm; and for giving me the opportunities to write this dissertation.

// (Peter)
I want to thank my co-supervisor _Peter Dawyndt_, and
// The jury
the members of the examination board, _Robert Hirschfeld_, _Quentin Stiévenart_, _Bart Coppens_, _Yvan Saeys_, and _Chris Cornelis_ for their time and valued feedback on the early manuscript.
I'm also grateful to _Bart Mesuere_, for his willingness to serve as backup on my committee.

I wish to thank all my collaborators and co-authors.
// Robbert
An especially grateful thanks goes to _Robbert Gurdeep Singh_ as the creator of the WARDuino virtual machine.
In his role as my predecessor in the lab, Robbert's guidance during my first year as a predoctoral student was invaluable.
// Elisa
Another important guide was _Elisa González Boix_.
Her perspective on my work was always insightful, and very impactful.
It was great working together on the MPLR paper and DEBT, and it is always a pleasure to visit the VUB.
I am looking forward to our future collaborations.

// Matteo
Staying with the VUB for a moment, special thanks need to go to _Matteo Marra_ for his original work on out-of-place debugging without which @chapter:oop would not exist.
// Carlos
Similar thanks go to _Carlos Rojas Castillo_ for his work on out-of-place debugging on WARDuino, and the great collaboration during the writing and coding of the MPLR paper---which is still a large part of @chapter:oop. Our meetings together were always both enjoyable and fruitful.

// Stefan
Without _Stefan Marr_ and the research stay at his lab in Kent, @chapter:testing would not have been written.
// Octave Larose and Sophie Kaleba
I would like to thank him and his students, _Octave Larose_ and _Sophie Kaleba_, for their generous welcome.

// Maarten
Finally, my thanks to _Maarten Steevens_. It was wonderful collaborating on the multiverse debugger together, your hard work helped shape @chap:multiverse enormously.
// Jonas
I want to thank _Jonas Sys_ as well. The arrival of the new TOPL members has made this past year at the lab especially rewarding, and I’m confident they’ll produce fantastic research in the years ahead.

Aside from the co-authors who contributed to this dissertation, I wish to thank _Francisco Ferreira Ruiz_ for providing the hardware that enabled the research on multiverse debugging in @chap:multiverse, and _Oliver Dukes_ for his advice on the performance analysis in @chapter:testing.

// Collega's: Jonathan, Charlotte, Niko, Steven, Jorg en anderen
I want to thank my past and present colleagues at WINST (formerly TWIST) for making the office really a joyful place to be.
I am reminded of a speech by Hugh Laurie, #note[Permit me to paraphrase.]_"I know everyone says they have wonderful [colleagues], and logically that can't be the case. Somebody somewhere is working with a crew of drunken thieves, but it is not me"_.

There are too many names to list so allow me to limit myself to handful of people.
Thanks go first to _Jonathan Peck_ for being a wonderful office mate whose knowledge and intellect are always inspiring.
I want to thank _Charlotte Van Petegem_ as the cornerstone of the wonderful atmosphere at TWIST during my time, _Niko Strijbol_ for the many laughs and his advice for the typography of this book, and _Steven Van Overberghe_ for indulging my weird mathematics questions.
Thanks likewise go to _Thomas Van Mullem_ for being an awesome graduate student and wonderful colleague, and _Jorg Van Renterghem_ for many stimulating political discussions---it is always great to have assumptions challenged.

I want to thank _Rien Maertens_ for all his help with the administrative challenges of finishing a PhD.
I could always rely on Rien for a quick and helpful answer to any question I had.

// de vakgroep (ook alle lesgevers van de opleiding)
I want to thank all the lecturers I had through my bachelor and master eduction at Ghent University.
One should not admit to having favorites, but I do want to explicitly thank a few people not previously mentioned---_Felix Van der Jeugt_, _Nico Van Cleemput_, and _Jan Goedgebeur_.

I would also like to thank the people who mean a great deal to me in a none professional capacity---my friends and family.

// Vrienden: Jorg, Max, Wout, Kieran, Jasper, Michiel, the maestro Tibo, Alex, Nicole, Christine
I want to thank Bachachus for being such an amazing and inseparable group of friends, thank you _Jorg_, _Max_, _Wout_, _Kieran_ and _Jasper_.
I want to thank _Tibo_ and _Michiel_ for our time at university together.
Finally, I wish to thank my longest friends, _Christine_, _Nicole_, and _Alex_ for their lifelong friendship.

// Xiaoyu
Special loving thanks go to my darling _Xiaoyu_ (#text(size: small, "晓雨")) for bringing a spark to my life that fuels me to reach higher and further than I ever could alone.

// Family
Finally, I want to thank my family, _mama_, _papa_, _Fien_ and _Anna_ for everything.
Particular thanks to Fien for proofreading the early manuscript, and helping with the design of the cover.
There is of course much more to be thankful for, one can hardly put it into words.

#{
  set par(leading: 1.00em)
  v(1fr)
  set align(right)
  text(style: "italic")[Tom Lauwaerts \ August, 2025]
}
