#import "../../lib/class.typ": note
#import "../introduction/introduction.typ": C1, C2, C3, C4

= Vulgariserende samenvatting

Programma's schrijven is moeilijk, en ontwikkelaars maken onvermijdelijk fouten, die we in de informatica bugs noemen.
Het opsporen van deze bugs, debugging, neemt een groot deel van de ontwikkelaar's tijd in beslag.
Helaas zijn de hulpmiddelen die hen hierbij zouden moeten helpen, zogenaamde debuggers, in de praktijk vaak nogal verouderd#note["Verouderd" is hier het juiste woord, aangezien breakpoints al in de jaren zestig zijn uitgevonden.].
Dit geldt vooral voor _microcontrollers_, ofwel embedded apparaten---heel kleine computers, die noodzakelijk beperkt zijn in hun capaciteit, maar daarom vaak worden gebruikt in internet-of-things toepassingen, zoals je slimme thermostaat, fitness tracker, WiFi-lampen, enzovoort.

Er is een duidelijke behoefte aan betere debugging-tools bij de ontwikkeling van embedded software.
Echter, de aard van deze apparaten brengt verschillende obstakels met zich mee die de ontwikkeling van geavanceerdere debugging-technieken bemoeilijken.
Deze obstakels kunnen worden onderverdeeld in vier hoofduitdagingen.

/ C1: Ontwikkeling van embedded software wordt gekenmerkt door een trage ontwikkelcyclus.

/ C2: De hardwarebeperkingen van embedded apparaten maken het moeilijk om debuggers naast de software uit te voeren.

/ C3: Typische interrupt-gedreven programma’s verstoren het debugproces.

/ C4: Huidige embedded debuggers zijn niet uitgerust om niet-deterministische bugs te debuggen.

Op dit moment gebruiken ontwikkelaars van microcontrollers twee inefficiënte debugging-technieken, die niet voldoende zijn om deze uitdagingen te overkomen.

Ten eerste gebruiken ontwikkelaars _print statement debugging_, waarbij ze print statements toevoegen aan hun code om informatie op bepaalde punten in het programma af te drukken.
Op deze manier proberen ze na afloop informatie over de uitvoering van het programma af te leiden.
Dit leidt tot een trage, iteratieve cyclus van print statements toevoegen en verwijderen, opnieuw compileren, opnieuw uploaden en opnieuw uitvoeren van de software.

Ten tweede kunnen ontwikkelaars proberen een hardware-debugger op te zetten, een extra stuk hardware dat verbinding maakt met de microcontroller—en zo inspectie van de programmastatus mogelijk maakt.
Deze hardware-debuggers zijn echter vaak duur en lastig op te zetten.
Bovendien ondersteunen de bijbehorende softwaretools, met name _remote debuggers_, alleen de meest eenvoudige, en standaard debugbewerkingen.

In dit proefschrift stellen we verschillende nieuwe debugging-technieken voor die specifiek zijn ontworpen om deze uitdagingen te overwinnen, en hopelijk de weg vrijmaken voor een nog bredere variëteit aan geavanceerde en betere debugging-technieken.

Onze eerste bijdrage is een nieuwe manier van remote debugging voor embedded apparaten, gebaseerd op een virtuele machine in plaats van op hardware-debugers.
We hebben een op WebAssembly gebaseerde virtuele machine ontwikkeld, genaamd WARDuino, die op de microcontroller draait.
Dit stelt ontwikkelaars in staat om hun apparaten te programmeren in abstractere programmeertalen zoals JavaScript, Python en Rust, en om een remote debugger te gebruiken zonder dat er hardware-debuggers nodig zijn.

Onze tweede bijdrage bouwt voort op de eerste, door een nieuwe debugging-techniek toe te voegen, die we _stateful out-of-place debugging_ noemen.
Deze techniek verplaatst het grootste deel van de debug-sessie van de microcontroller (server) naar de computer van de ontwikkelaar (client), waar men kan profiteren van de volledige rekenkracht van moderne computers.
Hierdoor kunnen debuggers de beperkingen van de microcontroller omzeilen en makkelijker geavanceerde debugging-technieken ondersteunen.
Tegelijkertijd behoudt de techniek toegang tot de hardware-specifieke functies van de microcontroller, waardoor er nog steeds de illusie is van remote debugging.

De stateful out-of-place debugger pakt ook de derde uitdaging aan, door alle asynchrone gebeurtenissen, zoals hardware-interrupts, vast te leggen en door te sturen naar de client.
Daar onderbreken deze gebeurtenissen de uitvoering van het programma niet automatisch; in plaats daarvan kan de ontwikkelaar via de debugger zelf kiezen op welk moment een gebeurtenis wordt geactiveerd.
Dit voorkomt de verwarring die kan ontstaan wanneer een debug-sessie plotseling wordt onderbroken door hardware-interrupts, en geeft ontwikkelaars meer middelen om specifieke _interleavings_ van gebeurtenissen of andere voorwaarden die tot bugs leiden, te recreëren.

De vierde uitdaging wordt aangepakt door onze laatste debugger, genaamd MIO: een _multiverse debugger_ voor input- en outputprogramma's op microcontrollers.
Multiverse debugging maakt het eenvoudiger om niet-deterministische programma’s te debuggen, door ontwikkelaars de mogelijkheid te geven om alle mogelijke uitvoeringspaden te verkennen.
Helaas kan het debuggen van programma’s met input/output-operaties via bestaande multiverse debuggers leiden tot het verkennen van ontoegankelijke programmastaten—staten die tijdens normale uitvoering niet voorkomen.
Dit kan het debugproces ernstig belemmeren, omdat de programmeur veel tijd kan besteden aan het onderzoeken van dergelijke staten, of erger nog, ten onrechte kan aannemen dat er een bug in de code zit, terwijl het probleem in werkelijkheid door de debugger zelf wordt veroorzaakt.
Om dit op te lossen, introduceert MIO een nieuwe benadering van multiverse debugging, die een breed scala aan input/output-operaties kan ondersteunen—en deze zo nodig kan omkeren tijdens het verkennen van het _"multiverse"_ aan uitvoeringspaden.

Onze vierde bijdrage is een nieuw testframework, genaamd Latch, voor het testen van embedded apparaten, en in het bijzonder de in dit proefschrift ontwikkelde debuggers.
Ten eerste implementeert het framework een nieuwe testmethode, die we _managed testing_ noemen, waarbij een debugger wordt gebruikt om geautomatiseerde tests op de microcontroller uit te voeren—gelijkaardig aan de handmatige testscenario’s die ontwikkelaars normaal zelf op de hardware uitvoeren.
Ten tweede gebruikt Latch hetzelfde principe als stateful out-of-place debugging om grote test suites op microcontrollers uit te voeren.
