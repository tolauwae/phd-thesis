#import "../../lib/class.typ": note
#import "../introduction/introduction.typ": C1, C2, C3, C4

= Vulgariserende samenvatting

Programma's schrijven is moeilijk, en ontwikkelaars maken onvermijdelijk fouten, die we in de informatica bugs noemen.
Het werk om deze bugs te vinden, debugging (foutopsporing), neemt veel tijd in beslag voor ontwikkelaars.
Helaas zijn de hulpmiddelen die hen hierbij zouden moeten helpen, de zogenaamde debuggers, in de praktijk vaak nogal verouderd#note["Verouderd" is hier het juiste woord, aangezien breakpoints al in de jaren zestig zijn uitgevonden.].
Dit geldt vooral voor beperkte apparaten, oftewel embedded apparaten: kleine computers die vaak worden gebruikt in internet-of-things toepassingen, zoals je slimme thermostaat, fitness tracker, WiFi-lampen, enzovoort.

Er is een duidelijke behoefte aan betere debugging-tools bij de ontwikkeling van embedded software.
Echter, de aard van deze apparaten brengt verschillende lastige obstakels met zich mee die de ontwikkeling van geavanceerdere debugging-technieken bemoeilijken.
Deze obstakels kunnen worden onderverdeeld in vier hoofduitdagingen.

#C1

#C2

#C3

#C4

Op dit moment gebruiken ontwikkelaars van embedded apparaten twee inefficiënte debugging-technieken, die niet goed zijn toegerust om de uitdagingen van het debuggen van beperkte apparaten aan te gaan.

Ten eerste gebruiken ontwikkelaars print statement debugging, waarbij ze printstatements toevoegen aan hun code om informatie op bepaalde punten in het programma af te drukken.
Op deze manier proberen ze na afloop informatie over de uitvoering van het programma af te leiden.
Dit leidt tot een trage, iteratieve cyclus van printstatements toevoegen en verwijderen, opnieuw compileren, opnieuw uploaden en opnieuw uitvoeren van de software.

Ten tweede kunnen ontwikkelaars proberen een hardware-debugger op te zetten, een extra stuk hardware dat verbinding maakt met het embedded apparaat—en zo inspectie van de programmastatus mogelijk maakt.
Deze hardware-debuggers zijn echter vaak duur en lastig op te zetten.
Bovendien ondersteunen de bijbehorende softwaretools, met name remote debuggers, alleen de meest basale debugbewerkingen.

In dit proefschrift stellen we verschillende nieuwe debugging-technieken voor die specifiek zijn ontworpen om deze uitdagingen te overwinnen, en hopelijk de weg vrijmaken voor een nog bredere variëteit aan geavanceerde en betere debugging-technieken.

Onze eerste bijdrage is een nieuwe benadering van remote debugging voor embedded apparaten, gebaseerd op een virtuele machine in plaats van op hardware.
We hebben een op WebAssembly gebaseerde virtuele machine ontwikkeld, genaamd WARDuino, die op het embedded apparaat draait.
Dit stelt ontwikkelaars in staat om hun apparaten te programmeren in hogere programmeertalen zoals JavaScript, Python en Rust, en om een remote debugger te gebruiken zonder dat er hardware-debuggers nodig zijn.

Onze tweede bijdrage bouwt voort op de eerste, door een nieuwe debugging-techniek toe te voegen genaamd stateful out-of-place debugging.
Deze techniek verplaatst het grootste deel van de debug-sessie van het embedded apparaat (server) naar de computer van de ontwikkelaar (client), waar men kan profiteren van de volledige rekenkracht van moderne computers.
Hierdoor kunnen debuggers de beperkingen van het embedded apparaat omzeilen en gebruik maken van geavanceerde debugging-technieken.
Tegelijkertijd behoudt de techniek toegang tot de hardware-specifieke functies van het embedded apparaat, waardoor het lijkt alsof er remote debugging plaatsvindt.

De stateful out-of-place debugger pakt ook de derde uitdaging aan, door alle asynchrone gebeurtenissen, zoals hardware-interrupts, vast te leggen en door te sturen naar de client.
Daar onderbreken deze gebeurtenissen de uitvoering van het programma niet automatisch; in plaats daarvan kan de ontwikkelaar via de debugger zelf kiezen op welk moment een gebeurtenis wordt geactiveerd.
Dit voorkomt de verwarring die kan ontstaan wanneer een debug-sessie plotseling wordt onderbroken door hardware-interrupts, en geeft ontwikkelaars meer middelen om specifieke interleavings van gebeurtenissen of andere voorwaarden die tot bugs leiden, te recreëren.

De vierde uitdaging wordt aangepakt door onze derde bijdrage, en laatste debugger, genaamd MIO: een multiversum-debugger voor input- en outputprogramma's op beperkte apparaten.
Multiversum-debugging maakt het eenvoudiger om niet-deterministische programma’s te debuggen, door ontwikkelaars de mogelijkheid te geven om alle mogelijke uitvoeringspaden te verkennen.
Helaas kan het debuggen van programma’s met input/output-operaties via bestaande multiversum-debuggers leiden tot het verkennen van ontoegankelijke programmastaten—staten die tijdens normale uitvoering niet voorkomen.
Dit kan het debugproces ernstig belemmeren, omdat de programmeur veel tijd kan besteden aan het onderzoeken van dergelijke staten, of erger nog, ten onrechte kan aannemen dat er een bug in de code zit, terwijl het probleem in werkelijkheid door de debugger zelf wordt veroorzaakt.
Om dit op te lossen, introduceert MIO een nieuwe benadering van multiversum-debugging, die een breed scala aan input/output-operaties kan ondersteunen—en deze zo nodig kan omkeren tijdens het verkennen van het multiversum aan uitvoeringspaden.

Onze vierde bijdrage is een nieuw testframework, genaamd Latch, voor het testen van embedded apparaten, en in het bijzonder de in dit proefschrift ontwikkelde debuggers.
Ten eerste implementeert het framework een nieuwe testmethode, die we managed testing noemen, waarbij een debugger wordt gebruikt om geautomatiseerde tests op het embedded apparaat uit te voeren—vergelijkbaar met de handmatige testscenario’s die ontwikkelaars normaal zelf op de hardware uitvoeren.
Ten tweede gebruikt Latch hetzelfde principe als stateful out-of-place debugging om grote test suites op embedded apparaten uit te voeren.
