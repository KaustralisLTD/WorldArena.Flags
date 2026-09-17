# -*- coding: utf-8 -*-
# Translations for 68 facts: de, fr, it, pl, nl, pt-BR, es, uk, ca, zh.
# Same order as facts_68_data.FACTS_EN. Each list must have 68 (title, desc).

from facts_68_data import FACTS_EN

def _parse(raw):
    return [tuple(line.split("|", 1)) for line in raw.strip().split("\n") if line.strip()]

# German (68)
DE_RAW = """Älteste durchgehend genutzte Flagge|Dänemarks Dannebrog gilt als die älteste seit 1219 ununterbrochen genutzte Nationalflagge.
Einzige quadratische Nationalflagge|Die Schweiz hat die einzige quadratische Nationalflagge der Welt. Der Vatikan hat ebenfalls eine quadratische Flagge, ist aber ein Stadtstaat.
Nicht-rechteckige Flagge|Nepal hat die einzige Nationalflagge der Welt, die nicht rechteckig ist.
Ohne Rot, Weiß oder Blau|Jamaika ist das einzige Land mit einer Flagge ohne Rot, Weiß oder Blau.
Flagge die nie auf halbmast gesetzt wird|Die Flagge Saudi-Arabiens wird wegen der heiligen Inschrift nie auf halbmast gesetzt.
Junge Nationalflagge|Die Flagge des Südsudan wurde 2011 nach der Unabhängigkeit angenommen.
Flagge mit AK-47|Mosambik ist das einzige Land, dessen Flagge eine moderne Waffe zeigt – das Kalaschnikow-Gewehr.
Fast identische Flaggen|Die Flaggen Rumäniens und des Tschads sind sehr ähnlich; sie werden meist am Blauton unterschieden.
Symbolik der Ukraine|Die blau-gelbe Flagge der Ukraine wird traditionell als Himmel über einem Weizenfeld gedeutet.
Einfachste Flagge|Libyens Flagge war von 1977 bis 2011 einfarbig grün ohne Symbole oder Muster.
Flagge mit Karte|Die Flagge Zyperns zeigt den Umriss der Insel – ein seltener Fall bei Nationalflaggen.
Flagge mit Bibel|Die Flagge der Dominikanischen Republik zeigt eine geöffnete Bibel und ist die einzige Nationalflagge mit einem religiösen Buch.
Beliebteste Farbe|Rot ist die häufigste Farbe auf Nationalflaggen weltweit.
Flagge mit Text|Text auf Nationalflaggen ist selten; ein bekanntes Beispiel ist Saudi-Arabien.
Flaggen-Etikette|In vielen Ländern gelten strenge Regeln für den Umgang mit der Nationalflagge.
Flagge mit unterschiedlichen Seiten|Paraguay hat die einzige Nationalflagge der Welt mit unterschiedlichen Motiven auf Vorder- und Rückseite.
Olympische Symbolik|Die Farben der Olympischen Ringe wurden so gewählt, dass mindestens eine Farbe auf jeder Landesflagge vorkommt.
Flagge mit dem komplexesten Wappen|Mexikos Flagge zeigt einen Adler auf einem Kaktus mit einer Schlange – eines der detailliertesten Wappen auf Flaggen.
Kopierte Flagge|Die Flaggen Monacos und Indonesiens sind fast identisch – rot oben, weiß unten. Der einzige Unterschied sind die Proportionen.
Flagge mit 50 Sternen|Die US-Flagge hat 50 Sterne, einen für jeden Bundesstaat. Das Design wurde seit 1777 27-mal geändert.
Nördlichste Flaggen|In arktischen Regionen werden nationale und regionale Flaggen mit einzigartiger Symbolik verwendet.
Flagge mit Kreuz|29 Länder haben ein Kreuz auf ihrer Flagge, eines der beliebtesten Symbole auf Nationalflaggen.
Trikoloren|Viele Länder nutzen ein einfaches Drei-Streifen-Design als historisch bewährte Flaggenform.
Flagge mit Halbmond|Der Halbmond erscheint auf den Flaggen von 12 Ländern, meist muslimischen, und symbolisiert den islamischen Glauben.
Sonnensymbol|Die Sonne ist eines der häufigsten Symbole auf Flaggen in Asien und Südamerika.
Flagge mit Baum|Der Libanon ist das einzige Land mit einem Baum (der Libanonzeder) auf seiner Flagge, Symbol für Ewigkeit und Frieden.
Schmalste Flagge|Katars Flagge hat das ungewöhnlichste Seitenverhältnis aller Nationalflaggen – 11:28.
Komplexe Wappen|Wappen auf lateinamerikanischen Flaggen enthalten oft viele Details und historische Symbole.
Regenbogenflagge|Bolivien hat zwei offizielle Flaggen – die traditionelle Trikolore und die indigene Wiphala-Regenbogenflagge.
Flagge mit Gebäude|Kambodschas Flagge zeigt den Angkor-Wat-Tempel, die einzige Nationalflagge mit einem Gebäude.
Historische Streitigkeiten|Das Design einiger Flaggen änderte sich durch historische und politische Auseinandersetzungen.
Flagge mit Schwert|Sri Lankas Flagge zeigt einen Löwen mit Schwert und symbolisiert den Mut der Singhalesen.
Flagge ohne Blau|Nur vier Länder verwenden kein Blau auf ihren Flaggen: Jamaika, Mauretanien, Sri Lanka und der Vatikan.
Vögel auf Flaggen|Adler und andere Vögel auf Flaggen symbolisieren Stärke, Unabhängigkeit und Edelmut.
Antarktis-Symbol|Die Antarktis hat keine offizielle Nationalflagge, es werden mehrere inoffizielle Entwürfe genutzt.
Sterne auf Flaggen|Der Stern ist eines der verbreitetsten Symbole auf Flaggen weltweit.
Ähnliche Farbschemata|Einige Flaggen ähneln sich in den Farben, unterscheiden sich aber in der Anordnung der Streifen und Embleme.
Flaggen internationaler Verbände|Überstaatliche Organisationen haben ebenfalls eigene Flaggen mit gemeinsamen Werten.
Insel-Symbolik|Flaggen von Inselstaaten zeigen oft Symbole von Ozean, Sonne und Navigation.
Wandel im Lauf der Zeit|Einige Nationalflaggen haben sich dutzende Male mit der politischen Geschichte des Landes geändert.
Sonne Nordmazedoniens|Die Flagge Nordmazedoniens zeigt eine Sonne mit acht Strahlen für einen Neuanfang.
Holzfäller in Belize|Belizes Flagge gehört zu den wenigen, die Menschen zeigen: Holzfäller mit Werkzeugen.
Kondor Ecuadors|Ecuadors Flagge zeigt den Andenkondor für Stärke und Souveränität.
Zwei Flaggen Boliviens|Bolivien führt die Wiphala neben der Trikolore als offizielles Symbol.
27 Sterne Brasiliens|Die brasilianische Flagge hat 27 Sterne, einen für jeden Bundesstaat und den Bundesdistrikt.
Ahornblatt|Kanadas Flagge zeigt ein einzelnes 11-zackiges Ahornblatt, einzigartig unter Nationalflaggen.
Union Jack|Die britische Flagge vereint die Kreuze dreier Heiliger: England, Schottland und Irland.
Japans aufgehende Sonne|Der rote Kreis auf Weiß steht für die aufgehende Sonne und wird in Japan seit dem 7. Jahrhundert verwendet.
Ashoka-Chakra|Indiens Flagge zeigt ein 24-speichiges Rad als Symbol für Gesetz und Bewegung.
Südliches Kreuz Australiens|Australiens Flagge zeigt das Kreuz des Südens, nur auf der Südhalbkugel sichtbar.
Südliches Kreuz Neuseelands|Neuseelands Flagge zeigt ebenfalls das Kreuz des Südens, aber mit roten, weiß gesäumten Sternen.
Taegeuk Südkoreas|Südkoreas Flagge zeigt das traditionelle Taegeuk (Yin-Yang) und Trigramme.
Armillarsphäre Portugals|Portugals Flagge zeigt eine Armillarsphäre, ein antikes Navigationsinstrument.
Doppelköpfiger Adler Albaniens|Albaniens Flagge zeigt einen schwarzen Doppeladler als Symbol der Souveränität.
Schild Kenias|Kenyas Flagge zeigt einen Massai-Schild und gekreuzte Speere.
Drache Wales|Der rote Drache auf der Flagge Wales ist eines der ältesten nationalen Symbole der Welt.
Andreaskreuz|Schottlands Flagge ist ein weißes Schrägkreuz auf Blau, das Kreuz des heiligen Andreas.
Kreis Grönlands|Grönlands Flagge hat einen rot-weißen Kreis für die Sonne über dem Eis.
Panafrikanische Farben|Grün, Gelb und Rot werden oft als panafrikanische Farben bezeichnet und erscheinen auf vielen afrikanischen Flaggen.
Nordische Kreuze|Fünf Länder nutzen das Nordische Kreuz: Dänemark, Norwegen, Schweden, Finnland und Island.
Französische Trikolore|Die französische Blau-Weiß-Rot-Trikolore wurde Vorbild für viele revolutionäre und nationale Flaggen.
UN-Flagge|Die UN-Flagge zeigt die Welt umgeben von Olivenzweigen auf blauem Grund.
EU-Flagge|Zwölf goldene Sterne im Kreis auf Blau symbolisieren die Einheit der Europäischen Union.
Olympische Flagge|Die fünf Ringe auf Weiß stehen für die fünf bewohnten Kontinente und den globalen Charakter der Spiele.
Quadratische Flagge des Vatikans|Der Vatikan hat wie die Schweiz eine quadratische Nationalflagge.
12 Strahlen Naurus|Naurus Flagge hat einen 12-strahligen Stern für die zwölf Stämme der Insel.
Teppichmuster Turkmenistans|Turkmenistans Flagge zeigt traditionelle Teppichmuster am Fahnenmast.
Moschee auf Afghanistans Flagge|Afghanistans Flagge hat in verschiedenen Epochen eine Moschee gezeigt."""

FACTS_DE = _parse(DE_RAW)
assert len(FACTS_DE) == 68, "DE: expected 68, got %d" % len(FACTS_DE)

# French (68)
FR_RAW = """Drapeau national le plus ancien|Le Dannebrog du Danemark est considéré comme le plus ancien drapeau national en usage continu depuis 1219.
Seul drapeau national carré|La Suisse a le seul drapeau national carré au monde. Le Vatican a aussi un drapeau carré mais c'est une cité-État.
Drapeau non rectangulaire|Le Népal a le seul drapeau national au monde qui ne soit pas rectangulaire.
Sans rouge, blanc ni bleu|La Jamaïque est le seul pays avec un drapeau sans rouge, blanc ni bleu.
Drapeau jamais mis en berne|Le drapeau de l'Arabie saoudite n'est jamais mis en berne à cause du texte sacré.
Jeune drapeau national|Le drapeau du Soudan du Sud a été adopté en 2011 après l'indépendance.
Drapeau avec AK-47|Le Mozambique est le seul pays dont le drapeau comporte une arme moderne – le fusil Kalachnikov.
Drapeaux presque identiques|Les drapeaux de la Roumanie et du Tchad sont très similaires ; on les distingue généralement par la teinte de bleu.
Symbolique de l'Ukraine|Le drapeau bleu et jaune de l'Ukraine est traditionnellement interprété comme le ciel au-dessus d'un champ de blé.
Drapeau le plus simple|Le drapeau de la Libye de 1977 à 2011 était entièrement vert sans symboles ni motifs.
Drapeau avec une carte|Le drapeau de Chypre montre le contour de l'île – un cas rare parmi les drapeaux nationaux.
Drapeau avec une Bible|Le drapeau de la République dominicaine montre une Bible ouverte, le seul drapeau national avec un livre religieux.
Couleur la plus fréquente|Le rouge est la couleur la plus courante sur les drapeaux nationaux dans le monde.
Drapeau avec du texte|Le texte sur les drapeaux nationaux est rare ; un exemple connu est l'Arabie saoudite.
Étiquette des drapeaux|De nombreux pays ont des règles strictes sur le traitement du drapeau national.
Drapeau avec deux faces différentes|Le Paraguay a le seul drapeau national au monde avec des motifs différents au recto et au verso.
Symbolique olympique|Les couleurs des anneaux olympiques ont été choisies pour qu'au moins une couleur figure sur chaque drapeau national.
Drapeau au blason le plus complexe|Le drapeau du Mexique montre un aigle sur un cactus tenant un serpent – l'un des blasons les plus détaillés.
Drapeaux copiés|Les drapeaux de Monaco et de l'Indonésie sont presque identiques – rouge en haut, blanc en bas. Seules les proportions diffèrent.
Drapeau à 50 étoiles|Le drapeau américain a 50 étoiles, une par État. Le design a été modifié 27 fois depuis 1777.
Drapeaux les plus au nord|Les régions arctiques utilisent des drapeaux nationaux et régionaux avec une symbolique unique.
Drapeau avec une croix|29 pays ont une croix sur leur drapeau, l'un des symboles les plus courants.
Tricolores|De nombreux pays utilisent un design à trois bandes comme forme de drapeau historiquement stable.
Drapeau avec un croissant|Le croissant figure sur les drapeaux de 12 pays, surtout musulmans, symbolisant la foi islamique.
Symbole du soleil|Le soleil est l'un des symboles les plus courants sur les drapeaux en Asie et en Amérique du Sud.
Drapeau avec un arbre|Le Liban est le seul pays avec un arbre (le cèdre du Liban) sur son drapeau, symbolisant l'éternité et la paix.
Drapeau le plus étroit|Le drapeau du Qatar a le rapport d'aspect le plus inhabituel – 11:28.
Blasons complexes|Les blasons sur les drapeaux d'Amérique latine comportent souvent de nombreux détails et symboles historiques.
Drapeau arc-en-ciel|La Bolivie a deux drapeaux officiels – le tricolore traditionnel et le Wiphala indigène.
Drapeau avec un bâtiment|Le drapeau du Cambodge montre le temple d'Angkor Wat, le seul drapeau national avec un bâtiment.
Différends historiques|Le design de certains drapeaux a changé à cause de différends historiques et politiques.
Drapeau avec une épée|Le drapeau du Sri Lanka montre un lion tenant une épée, symbolisant le courage des Cinghalais.
Drapeau sans bleu|Seuls quatre pays n'utilisent pas le bleu : Jamaïque, Mauritanie, Sri Lanka et Vatican.
Oiseaux sur les drapeaux|L'aigle et d'autres oiseaux symbolisent la force, l'indépendance et la noblesse.
Symbole antarctique|L'Antarctique n'a pas de drapeau national officiel, mais plusieurs modèles non officiels sont utilisés.
Étoiles sur les drapeaux|L'étoile est l'un des symboles les plus répandus sur les drapeaux du monde.
Schémas de couleurs similaires|Certains drapeaux se ressemblent par les couleurs mais diffèrent par l'ordre des bandes et des emblèmes.
Drapeaux d'unions internationales|Les organisations supranationales ont aussi leurs drapeaux reflétant des valeurs partagées.
Symbolique insulaire|Les drapeaux des États insulaires montrent souvent l'océan, le soleil et la navigation.
Changements dans le temps|Certains drapeaux nationaux ont changé des dizaines de fois avec l'histoire politique du pays.
Soleil de Macédoine du Nord|Le drapeau de la Macédoine du Nord a un soleil à huit rayons pour un nouveau départ.
Bûcherons du Belize|Le drapeau du Belize est l'un des rares à montrer des personnes : des bûcherons avec des outils.
Condor de l'Équateur|Le drapeau de l'Équateur inclut le condor des Andes pour la force et la souveraineté.
Deux drapeaux de la Bolivie|La Bolivie utilise le Wiphala aux côtés du tricolore comme symbole officiel.
27 étoiles du Brésil|Le drapeau brésilien a 27 étoiles, une par État et le district fédéral.
Feuille d'érable|Le drapeau du Canada comporte une seule feuille d'érable à 11 pointes, unique parmi les drapeaux nationaux.
Union Jack|Le drapeau britannique combine les croix de trois saints : Angleterre, Écosse et Irlande.
Soleil levant du Japon|Le cercle rouge sur blanc représente le soleil levant et est utilisé au Japon depuis le VIIe siècle.
Ashoka Chakra|Le drapeau de l'Inde comporte une roue à 24 rayons, symbolisant la loi et le mouvement.
Croix du Sud de l'Australie|Le drapeau australien montre la constellation de la Croix du Sud, visible seulement dans l'hémisphère sud.
Croix du Sud de la Nouvelle-Zélande|Le drapeau néo-zélandais montre aussi la Croix du Sud, avec des étoiles rouges bordées de blanc.
Taegeuk de la Corée du Sud|Le drapeau sud-coréen comporte le taegeuk (yin-yang) traditionnel et des trigrammes.
Sphère armillaire du Portugal|Le drapeau du Portugal comporte une sphère armillaire, un ancien instrument de navigation.
Aigle bicéphale de l'Albanie|Le drapeau albanais montre un aigle bicéphale noir, symbole de souveraineté.
Bouclier du Kenya|Le drapeau du Kenya comporte un bouclier masaï et des lances croisées.
Dragon du pays de Galles|Le dragon rouge du pays de Galles est l'un des plus anciens symboles nationaux au monde.
Croix de saint André|Le drapeau écossais est une croix blanche diagonale sur fond bleu, la croix de saint André.
Cercle du Groenland|Le drapeau du Groenland a un cercle rouge et blanc pour le soleil sur la glace.
Couleurs panafricaines|Le vert, le jaune et le rouge sont souvent appelés couleurs panafricaines et figurent sur de nombreux drapeaux africains.
Croix nordiques|Cinq pays utilisent la croix nordique : Danemark, Norvège, Suède, Finlande et Islande.
Tricolore français|Le tricolore bleu-blanc-rouge français a servi de modèle à de nombreux drapeaux révolutionnaires et nationaux.
Drapeau de l'ONU|Le drapeau de l'ONU montre le monde entouré de rameaux d'olivier sur fond bleu.
Drapeau de l'UE|Douze étoiles d'or en cercle sur bleu symbolisent l'unité de l'Union européenne.
Drapeau olympique|Les cinq anneaux sur blanc représentent les cinq continents habités et la dimension mondiale des Jeux.
Drapeau carré du Vatican|Le Vatican a un drapeau national carré comme la Suisse.
12 pointes de Nauru|Le drapeau de Nauru a une étoile à 12 branches pour les 12 tribus de l'île.
Tapis du Turkménistan|Le drapeau du Turkménistan comporte des motifs de tapis le long de la hampe.
Mosquée sur le drapeau afghan|Le drapeau de l'Afghanistan a représenté une mosquée à différentes époques."""

FACTS_FR = _parse(FR_RAW)
assert len(FACTS_FR) == 68, "FR: expected 68, got %d" % len(FACTS_FR)

# Spanish (68)
ES_RAW = """Bandera nacional más antigua|El Dannebrog de Dinamarca se considera la bandera nacional en uso continuo más antigua desde 1219.
Única bandera nacional cuadrada|Suiza tiene la única bandera nacional cuadrada del mundo. El Vaticano también tiene bandera cuadrada pero es una ciudad-estado.
Bandera no rectangular|Nepal tiene la única bandera nacional del mundo que no es rectangular.
Sin rojo, blanco ni azul|Jamaica es el único país con una bandera sin rojo, blanco ni azul.
Bandera que nunca se iza a media asta|La bandera de Arabia Saudí nunca se iza a media asta por el texto sagrado.
Bandera nacional joven|La bandera de Sudán del Sur se adoptó en 2011 tras la independencia.
Bandera con AK-47|Mozambique es el único país cuya bandera muestra un arma moderna: el fusil Kalashnikov.
Banderas casi idénticas|Las banderas de Rumanía y Chad son muy similares; se distinguen por el tono de azul.
Simbolismo de Ucrania|La bandera azul y amarilla de Ucrania se interpreta tradicionalmente como el cielo sobre un campo de trigo.
Bandera más simple|La bandera de Libia de 1977 a 2011 era solo verde sin símbolos ni motivos.
Bandera con mapa|La bandera de Chipre muestra el contorno de la isla, un caso raro entre banderas nacionales.
Bandera con Biblia|La bandera de República Dominicana muestra una Biblia abierta, la única bandera nacional con un libro religioso.
Color más frecuente|El rojo es el color más común en las banderas nacionales del mundo.
Bandera con texto|El texto en banderas nacionales es raro; un ejemplo conocido es Arabia Saudí.
Protocolo de banderas|Muchos países tienen normas estrictas sobre el uso de la bandera nacional.
Bandera con dos caras distintas|Paraguay tiene la única bandera nacional con diseños distintos en anverso y reverso.
Simbolismo olímpico|Los colores de los anillos olímpicos se eligieron para que al menos uno figure en cada bandera nacional.
Bandera con el escudo más complejo|La bandera de México muestra un águila sobre un cactus con una serpiente, uno de los escudos más detallados.
Banderas copiadas|Las banderas de Mónaco e Indonesia son casi idénticas: rojo arriba, blanco abajo. Solo cambian las proporciones.
Bandera con 50 estrellas|La bandera de EE. UU. tiene 50 estrellas, una por estado. El diseño ha cambiado 27 veces desde 1777.
Banderas más al norte|Las regiones árticas usan banderas nacionales y regionales con simbolismo único.
Bandera con cruz|29 países tienen una cruz en su bandera, uno de los símbolos más usados.
Tricolores|Muchos países usan un diseño de tres franjas como forma histórica de bandera.
Bandera con media luna|La media luna aparece en las banderas de 12 países, mayormente musulmanes, simbolizando la fe islámica.
Símbolo del sol|El sol es uno de los símbolos más comunes en banderas de Asia y Sudamérica.
Bandera con árbol|Líbano es el único país con un árbol (el cedro) en su bandera, simbolizando eternidad y paz.
Bandera más estrecha|La bandera de Catar tiene la proporción más inusual entre banderas nacionales: 11:28.
Escudos complejos|Los escudos en banderas latinoamericanas suelen tener muchos detalles y símbolos históricos.
Bandera arcoíris|Bolivia tiene dos banderas oficiales: el tricolor tradicional y la Wiphala indígena.
Bandera con edificio|La bandera de Camboya muestra el templo de Angkor Wat, la única bandera nacional con un edificio.
Disputas históricas|El diseño de algunas banderas ha cambiado por disputas históricas y políticas.
Bandera con espada|La bandera de Sri Lanka muestra un león con espada, simbolizando el valor del pueblo cingalés.
Bandera sin azul|Solo cuatro países no usan azul en su bandera: Jamaica, Mauritania, Sri Lanka y Vaticano.
Aves en banderas|El águila y otras aves en banderas simbolizan fuerza, independencia y nobleza.
Símbolo antártico|La Antártida no tiene bandera nacional oficial, pero se usan varios diseños no oficiales.
Estrellas en banderas|La estrella es uno de los símbolos más extendidos en banderas del mundo.
Esquemas de color similares|Algunas banderas se parecen en colores pero difieren en el orden de franjas y emblemas.
Banderas de uniones internacionales|Las organizaciones supranacionales también tienen banderas que reflejan valores comunes.
Simbolismo insular|Las banderas de estados insulares suelen mostrar océano, sol y navegación.
Cambios en el tiempo|Algunas banderas nacionales han cambiado decenas de veces con la historia política del país.
Sol de Macedonia del Norte|La bandera de Macedonia del Norte tiene un sol de ocho rayos para un nuevo comienzo.
Leñadores de Belice|La bandera de Belice es una de las pocas que muestra personas: leñadores con herramientas.
Cóndor de Ecuador|La bandera de Ecuador incluye el cóndor andino por fuerza y soberanía.
Dos banderas de Bolivia|Bolivia usa la Wiphala junto al tricolor como símbolo oficial.
27 estrellas de Brasil|La bandera brasileña tiene 27 estrellas, una por estado y el distrito federal.
Hoja de arce|La bandera de Canadá tiene una hoja de arce de 11 puntas, única entre banderas nacionales.
Union Jack|La bandera británica combina las cruces de tres santos: Inglaterra, Escocia e Irlanda.
Sol naciente de Japón|El círculo rojo sobre blanco representa el sol naciente y se usa en Japón desde el siglo VII.
Ashoka Chakra|La bandera de India tiene una rueda de 24 radios, simbolizando ley y movimiento.
Cruz del Sur de Australia|La bandera australiana muestra la constelación Cruz del Sur, visible solo en el hemisferio sur.
Cruz del Sur de Nueva Zelanda|La bandera neozelandesa también muestra la Cruz del Sur, con estrellas rojas fileteadas en blanco.
Taegeuk de Corea del Sur|La bandera surcoreana muestra el taegeuk (yin-yang) tradicional y trigramas.
Esfera armilar de Portugal|La bandera de Portugal muestra una esfera armilar, un antiguo instrumento de navegación.
Águila bicéfala de Albania|La bandera albanesa muestra un águila bicéfala negra, símbolo de soberanía.
Escudo de Kenia|La bandera de Kenia muestra un escudo masái y lanzas cruzadas.
Dragón de Gales|El dragón rojo de Gales es uno de los símbolos nacionales más antiguos del mundo.
Cruz de San Andrés|La bandera escocesa es una cruz diagonal blanca sobre azul, la cruz de San Andrés.
Círculo de Groenlandia|La bandera de Groenlandia tiene un círculo rojo y blanco que representa el sol sobre el hielo.
Colores panafricanos|El verde, amarillo y rojo se suelen llamar colores panafricanos y aparecen en muchas banderas africanas.
Cruces nórdicas|Cinco países usan la cruz nórdica: Dinamarca, Noruega, Suecia, Finlandia e Islandia.
Tricolor francés|El tricolor azul-blanco-rojo francés fue modelo de muchas banderas revolucionarias y nacionales.
Bandera de la ONU|La bandera de la ONU muestra el mundo rodeado de ramas de olivo sobre fondo azul.
Bandera de la UE|Doce estrellas doradas en círculo sobre azul simbolizan la unidad de la Unión Europea.
Bandera olímpica|Los cinco anillos sobre blanco representan los cinco continentes habitados y el carácter global de los Juegos.
Bandera cuadrada del Vaticano|El Vaticano tiene bandera nacional cuadrada como Suiza.
12 puntas de Nauru|La bandera de Nauru tiene una estrella de 12 puntas por las 12 tribus de la isla.
Alfombra de Turkmenistán|La bandera de Turkmenistán tiene motivos de alfombra a lo largo del asta.
Mezquita en la bandera afgana|La bandera de Afganistán ha mostrado una mezquita en distintas épocas."""

FACTS_ES = _parse(ES_RAW)
assert len(FACTS_ES) == 68

# Italian (68)
IT_RAW = """Bandiera nazionale più antica|Il Dannebrog danese è considerato la bandiera nazionale in uso continuativo più antica dal 1219.
Unica bandiera nazionale quadrata|La Svizzera ha l'unica bandiera nazionale quadrata al mondo. Anche il Vaticano ha bandiera quadrata ma è una città-stato.
Bandiera non rettangolare|Il Nepal ha l'unica bandiera nazionale al mondo che non è rettangolare.
Senza rosso, bianco o blu|La Giamaica è l'unico paese con una bandiera senza rosso, bianco o blu.
Bandiera mai a mezz'asta|La bandiera dell'Arabia Saudita non viene mai issata a mezz'asta per il testo sacro.
Bandiera nazionale giovane|La bandiera del Sudan del Sud è stata adottata nel 2011 dopo l'indipendenza.
Bandiera con AK-47|Il Mozambico è l'unico paese la cui bandiera mostra un'arma moderna: il fucile Kalashnikov.
Bandiere quasi identiche|Le bandiere di Romania e Ciad sono molto simili; si distinguono per la tonalità del blu.
Simbolismo dell'Ucraina|La bandiera blu e gialla dell'Ucraina è tradizionalmente interpretata come il cielo su un campo di grano.
Bandiera più semplice|La bandiera della Libia dal 1977 al 2011 era solo verde senza simboli o motivi.
Bandiera con mappa|La bandiera di Cipro mostra il contorno dell'isola, un caso raro tra le bandiere nazionali.
Bandiera con Bibbia|La bandiera della Repubblica Dominicana mostra una Bibbia aperta, l'unica bandiera nazionale con un libro religioso.
Colore più diffuso|Il rosso è il colore più comune sulle bandiere nazionali del mondo.
Bandiera con testo|Il testo sulle bandiere nazionali è raro; un esempio noto è l'Arabia Saudita.
Galateo delle bandiere|Molti paesi hanno regole severe sul trattamento della bandiera nazionale.
Bandiera con due lati diversi|Il Paraguay ha l'unica bandiera nazionale al mondo con disegni diversi su recto e verso.
Simbolismo olimpico|I colori degli anelli olimpici furono scelti così che almeno uno appaia su ogni bandiera nazionale.
Bandiera con lo stemma più complesso|La bandiera del Messico mostra un'aquila su un cactus con un serpente, uno degli stemmi più dettagliati.
Bandiere copiate|Le bandiere di Monaco e Indonesia sono quasi identiche: rosso sopra, bianco sotto. Solo le proporzioni differiscono.
Bandiera con 50 stelle|La bandiera USA ha 50 stelle, una per ogni stato. Il design è cambiato 27 volte dal 1777.
Bandiere più a nord|Le regioni artiche usano bandiere nazionali e regionali con simbolismo unico.
Bandiera con croce|29 paesi hanno una croce sulla bandiera, uno dei simboli più usati.
Tricolori|Molti paesi usano un design a tre strisce come forma di bandiera storicamente stabile.
Bandiera con mezzaluna|La mezzaluna appare sulle bandiere di 12 paesi, soprattutto musulmani, simbolo della fede islamica.
Simbolo del sole|Il sole è uno dei simboli più comuni sulle bandiere in Asia e Sudamerica.
Bandiera con albero|Il Libano è l'unico paese con un albero (il cedro) sulla bandiera, simbolo di eternità e pace.
Bandiera più stretta|La bandiera del Qatar ha il rapporto d'aspetto più insolito: 11:28.
Stemmi complessi|Gli stemmi sulle bandiere latinoamericane includono spesso molti dettagli e simboli storici.
Bandiera arcobaleno|La Bolivia ha due bandiere ufficiali: il tricolore tradizionale e la Wiphala indigena.
Bandiera con edificio|La bandiera della Cambogia mostra il tempio di Angkor Wat, l'unica bandiera nazionale con un edificio.
Dispute storiche|Il design di alcune bandiere è cambiato per dispute storiche e politiche.
Bandiera con spada|La bandiera dello Sri Lanka mostra un leone con spada, simbolo del coraggio dei singalesi.
Bandiera senza blu|Solo quattro paesi non usano il blu: Giamaica, Mauritania, Sri Lanka e Vaticano.
Uccelli sulle bandiere|L'aquila e altri uccelli sulle bandiere simboleggiano forza, indipendenza e nobiltà.
Simbolo antartico|L'Antartide non ha bandiera nazionale ufficiale, ma si usano diversi disegni non ufficiali.
Stelle sulle bandiere|La stella è uno dei simboli più diffusi sulle bandiere del mondo.
Schemi di colore simili|Alcune bandiere sono simili nei colori ma differiscono nell'ordine di strisce ed emblemi.
Bandiere di unioni internazionali|Anche le organizzazioni sovranazionali hanno bandiere che riflettono valori comuni.
Simbolismo insulare|Le bandiere degli stati insulari mostrano spesso oceano, sole e navigazione.
Cambiamenti nel tempo|Alcune bandiere nazionali sono cambiate decine di volte con la storia politica del paese.
Sole della Macedonia del Nord|La bandiera della Macedonia del Nord ha un sole a otto raggi per un nuovo inizio.
Boscaioli del Belize|La bandiera del Belize è una delle poche a mostrare persone: boscaioli con attrezzi.
Condor dell'Ecuador|La bandiera dell'Ecuador include il condor delle Ande per forza e sovranità.
Due bandiere della Bolivia|La Bolivia usa la Wiphala accanto al tricolore come simbolo ufficiale.
27 stelle del Brasile|La bandiera brasiliana ha 27 stelle, una per stato e il distretto federale.
Foglia d'acero|La bandiera del Canada ha una sola foglia d'acero a 11 punte, unica tra le bandiere nazionali.
Union Jack|La bandiera britannica combina le croci di tre santi: Inghilterra, Scozia e Irlanda.
Sole nascente del Giappone|Il cerchio rosso su bianco rappresenta il sole nascente e si usa in Giappone dal VII secolo.
Ashoka Chakra|La bandiera dell'India ha una ruota a 24 raggi, simbolo di legge e movimento.
Croce del Sud dell'Australia|La bandiera australiana mostra la costellazione della Croce del Sud, visibile solo nell'emisfero sud.
Croce del Sud della Nuova Zelanda|Anche la bandiera neozelandese mostra la Croce del Sud, con stelle rosse bordate di bianco.
Taegeuk della Corea del Sud|La bandiera sudcoreana mostra il taegeuk (yin-yang) tradizionale e trigrammi.
Sfera armillare del Portogallo|La bandiera del Portogallo mostra una sfera armillare, antico strumento di navigazione.
Aquila bicipite dell'Albania|La bandiera albanese mostra un'aquila bicipite nera, simbolo di sovranità.
Scudo del Kenya|La bandiera del Kenya mostra uno scudo masai e lance incrociate.
Drago del Galles|Il drago rosso del Galles è uno dei simboli nazionali più antichi al mondo.
Croce di sant'Andrea|La bandiera scozzese è una croce diagonale bianca su blu, la croce di sant'Andrea.
Cerchio della Groenlandia|La bandiera della Groenlandia ha un cerchio rosso e bianco per il sole sul ghiaccio.
Colori panafricani|Verde, giallo e rosso sono spesso detti colori panafricani e compaiono su molte bandiere africane.
Croci nordiche|Cinque paesi usano la croce nordica: Danimarca, Norvegia, Svezia, Finlandia e Islanda.
Tricolore francese|Il tricolore blu-bianco-rosso francese è stato modello per molte bandiere rivoluzionarie e nazionali.
Bandiera dell'ONU|La bandiera dell'ONU mostra il mondo circondato da rami d'ulivo su sfondo blu.
Bandiera dell'UE|Dodici stelle d'oro in cerchio su blu simboleggiano l'unità dell'Unione europea.
Bandiera olimpica|I cinque anelli su bianco rappresentano i cinque continenti abitati e la natura globale dei Giochi.
Bandiera quadrata del Vaticano|Il Vaticano ha bandiera nazionale quadrata come la Svizzera.
12 punte di Nauru|La bandiera di Nauru ha una stella a 12 punte per le 12 tribù dell'isola.
Tappeto del Turkmenistan|La bandiera del Turkmenistan ha motivi di tappeto lungo l'asta.
Moschea sulla bandiera afghana|La bandiera dell'Afghanistan ha mostrato una moschea in diverse epoche."""

FACTS_IT = _parse(IT_RAW)
assert len(FACTS_IT) == 68

# Polish (68)
PL_RAW = """Najstarsza flaga w ciągłym użyciu|Duński Dannebrog uznawany jest za najstarszą flagę narodową w nieprzerwanym użyciu od 1219 roku.
Jedyna kwadratowa flaga narodowa|Szwajcaria ma jedyną kwadratową flagę narodową na świecie. Watykan też ma flagę kwadratową, ale to miasto-państwo.
Flaga nieprostokątna|Nepal ma jedyną na świecie flagę narodową, która nie jest prostokątna.
Bez czerwieni, bieli ani niebieskiego|Jamaika to jedyny kraj z flagą bez czerwieni, bieli i niebieskiego.
Flaga nigdy nie opuszczana do połowy|Flaga Arabii Saudyjskiej nigdy nie jest opuszczana do połowy masztu z powodu świętego tekstu.
Młoda flaga narodowa|Flaga Sudanu Południowego została przyjęta w 2011 roku po uzyskaniu niepodległości.
Flaga z AK-47|Mozambik to jedyny kraj, na którego fladze widnieje nowoczesna broń – karabin Kałasznikowa.
Prawie identyczne flagi|Flagi Rumunii i Czadu są bardzo podobne; rozróżnia je zwykle odcień niebieskiego.
Symbolika Ukrainy|Niebiesko-żółta flaga Ukrainy jest tradycyjnie interpretowana jako niebo nad polem zboża.
Najprostsza flaga|Flaga Libii w latach 1977–2011 była w całości zielona, bez symboli ani wzorów.
Flaga z mapą|Flaga Cypru pokazuje zarys wyspy – rzadki przypadek wśród flag narodowych.
Flaga z Biblią|Flaga Dominikany pokazuje otwartą Biblię, to jedyna flaga narodowa z księgą religijną.
Najpopularniejszy kolor|Czerwień to najczęstszy kolor na flagach narodowych na świecie.
Flaga z tekstem|Tekst na flagach narodowych jest rzadki; znanym przykładem jest Arabia Saudyjska.
Etykieta flag|W wielu krajach obowiązują surowe zasady obchodzenia się z flagą narodową.
Flaga z dwiema różnymi stronami|Paragwaj ma jedyną na świecie flagę narodową z różnymi wzorami na awersie i rewersie.
Symbolika olimpijska|Kolory kół olimpijskich dobrano tak, by przynajmniej jeden występował na fladze każdego kraju.
Flaga z najbardziej złożonym herbem|Flaga Meksyku pokazuje orła na kaktusie ze wężem – jeden z najbardziej szczegółowych herbów.
Skopiowane flagi|Flagi Monako i Indonezji są niemal identyczne – czerwony u góry, biały u dołu. Różnią się tylko proporcjami.
Flaga z 50 gwiazdami|Flaga USA ma 50 gwiazd, po jednej na każdy stan. Projekt zmieniano 27 razy od 1777 roku.
Flagi najbardziej na północ|Regiony arktyczne używają flag narodowych i regionalnych z unikalną symboliką.
Flaga z krzyżem|29 krajów ma krzyż na fladze, jeden z najpopularniejszych symboli na flagach narodowych.
Trójkolorowe|Wiele krajów używa prostego układu trzech pasów jako historycznie trwałej formy flagi.
Flaga z półksiężycem|Półksiężyc występuje na flagach 12 krajów, głównie muzułmańskich, symbolizując wiarę islamską.
Symbol słońca|Słońce to jeden z najczęstszych symboli na flagach w Azji i Ameryce Południowej.
Flaga z drzewem|Liban to jedyny kraj z drzewem (cedrem libańskim) na fladze, symbolizującym wieczność i pokój.
Najwęższa flaga|Flaga Kataru ma najbardziej nietypowy stosunek boków wśród flag narodowych – 11:28.
Złożone herby|Herby na flagach Ameryki Łacińskiej często zawierają wiele detali i symboli historycznych.
Flaga tęczowa|Boliwia ma dwie oficjalne flagi – tradycyjną trójkolorową i indiańską Wiphalę.
Flaga z budynkiem|Flaga Kambodży pokazuje świątynię Angkor Wat, jedyna flaga narodowa z budowlą.
Spory historyczne|Wygląd niektórych flag zmieniał się z powodu sporów historycznych i politycznych.
Flaga z mieczem|Flaga Sri Lanki pokazuje lwa z mieczem, symbolizując odwagę Syngalezów.
Flaga bez niebieskiego|Tylko cztery kraje nie używają niebieskiego: Jamajka, Mauretania, Sri Lanka i Watykan.
Ptaki na flagach|Orzeł i inne ptaki na flagach symbolizują siłę, niezależność i szlachetność.
Symbol Antarktydy|Antarktyda nie ma oficjalnej flagi narodowej, używane są różne nieoficjalne wersje.
Gwiazdy na flagach|Gwiazda to jeden z najczęstszych symboli na flagach świata.
Podobne schematy kolorów|Niektóre flagi są podobne kolorystycznie, ale różnią się układem pasów i emblematów.
Flagi organizacji międzynarodowych|Organizacje ponadnarodowe też mają flagi odzwierciedlające wspólne wartości.
Symbolika wyspiarska|Flagi państw wyspiarskich często pokazują ocean, słońce i nawigację.
Zmiany w czasie|Niektóre flagi narodowe zmieniały się dziesiątki razy wraz z historią polityczną kraju.
Słońce Macedonii Północnej|Flaga Macedonii Północnej ma słońce z ośmioma promieniami na nowy początek.
Drwale z Belize|Flaga Belize należy do nielicznych z postaciami ludzi: drwale z narzędziami.
Kondor Ekwadoru|Flaga Ekwadoru zawiera kondora andyjskiego jako symbol siły i suwerenności.
Dwie flagi Boliwii|Boliwia uznaje Wiphalę obok trójkoloru za symbol oficjalny.
27 gwiazd Brazylii|Flaga Brazylii ma 27 gwiazd, po jednej na stan i dystrykt federalny.
Liść klonowy|Flaga Kanady ma jeden 11-ramienny liść klonu, unikalny wśród flag narodowych.
Union Jack|Flaga brytyjska łączy krzyże trzech świętych: Anglii, Szkocji i Irlandii.
Wschodzące słońce Japonii|Czerwony krąg na białym to wschodzące słońce, używane w Japonii od VII wieku.
Ashoka Chakra|Flaga Indii ma koło z 24 szprychami, symbol prawa i ruchu.
Krzyż Południa Australii|Flaga Australii pokazuje konstelację Krzyża Południa, widoczną tylko na półkuli południowej.
Krzyż Południa Nowej Zelandii|Flaga Nowej Zelandii też ma Krzyż Południa, z czerwonymi gwiazdami w białej obwódce.
Taegeuk Korei Południowej|Flaga Korei Południowej ma tradycyjny taegeuk (yin-yang) i trigramy.
Sfera armilarna Portugalii|Flaga Portugalii ma sferę armilarną, starożytne narzędzie nawigacyjne.
Orzeł dwugłowy Albanii|Flaga Albanii pokazuje czarnego orła dwugłowego, symbol suwerenności.
Tarcza Kenii|Flaga Kenii ma tarczę Masajów i skrzyżowane włócznie.
Smok Walii|Czerwony smok Walii to jeden z najstarszych symboli narodowych na świecie.
Krzyż św. Andrzeja|Flaga Szkocji to biały krzyż ukośny na niebieskim, krzyż św. Andrzeja.
Koło Grenlandii|Flaga Grenlandii ma czerwono-białe koło oznaczające słońce nad lodem.
Kolory panafrykańskie|Zielony, żółty i czerwony to tzw. kolory panafrykańskie na wielu flagach afrykańskich.
Krzyże nordyckie|Pięć krajów używa krzyża nordyckiego: Dania, Norwegia, Szwecja, Finlandia i Islandia.
Trikolor francuski|Francuski niebiesko-biało-czerwony trikolor był wzorem dla wielu flag rewolucyjnych i narodowych.
Flaga ONZ|Flaga ONZ pokazuje świat w otoczeniu gałązek oliwnych na niebieskim tle.
Flaga UE|Dwanaście złotych gwiazd w kole na niebieskim symbolizuje jedność Unii Europejskiej.
Flaga olimpijska|Pięć kół na białym to pięć zamieszkanych kontynentów i globalny charakter Igrzysk.
Kwadratowa flaga Watykanu|Watykan ma kwadratową flagę narodową jak Szwajcaria.
12 punktów Nauru|Flaga Nauru ma 12-ramienną gwiazdę dla 12 plemion wyspy.
Wzory dywanów Turkmenistanu|Flaga Turkmenistanu ma wzory dywanów wzdłuż drzewca.
Meczet na fladze Afganistanu|Flaga Afganistanu przedstawiała meczet w różnych okresach."""

FACTS_PL = _parse(PL_RAW)
assert len(FACTS_PL) == 68

# Dutch (68)
NL_RAW = """Oudste continu gebruikte vlag|De Deense Dannebrog wordt beschouwd als de oudste nationale vlag in continu gebruik sinds 1219.
Enige vierkante nationale vlag|Zwitserland heeft de enige vierkante nationale vlag ter wereld. Het Vaticaan heeft ook een vierkante vlag maar is een stadstaat.
Niet-rechthoekige vlag|Nepal heeft de enige nationale vlag ter wereld die niet rechthoekig is.
Zonder rood, wit of blauw|Jamaica is het enige land met een vlag zonder rood, wit of blauw.
Vlag die nooit halfstok gaat|De vlag van Saoedi-Arabië wordt nooit halfstok gehesen vanwege de heilige tekst.
Jonge nationale vlag|De vlag van Zuid-Soedan werd in 2011 aangenomen na de onafhankelijkheid.
Vlag met AK-47|Mozambique is het enige land waarvan de vlag een modern wapen toont – het Kalasjnikov-geweer.
Bijna identieke vlaggen|De vlaggen van Roemenië en Tsjaad lijken sterk op elkaar; ze worden meestal aan de blauwtint onderscheiden.
Symboliek van Oekraïne|De blauw-gele vlag van Oekraïne wordt traditioneel uitgelegd als de lucht boven een graanveld.
Eenvoudigste vlag|De vlag van Libië was van 1977 tot 2011 effen groen zonder symbolen of patronen.
Vlag met kaart|De vlag van Cyprus toont de omtrek van het eiland – een zeldzaamheid onder nationale vlaggen.
Vlag met Bijbel|De vlag van de Dominicaanse Republiek toont een geopende Bijbel, de enige nationale vlag met een religieus boek.
Meest voorkomende kleur|Rood is de meest voorkomende kleur op nationale vlaggen wereldwijd.
Vlag met tekst|Tekst op nationale vlaggen is zeldzaam; een bekend voorbeeld is Saoedi-Arabië.
Vlagetiquette|Veel landen hebben strikte regels voor het behandelen van de nationale vlag.
Vlag met verschillende kanten|Paraguay heeft de enige nationale vlag ter wereld met verschillende ontwerpen op voor- en achterkant.
Olympische symboliek|De kleuren van de olympische ringen zijn zo gekozen dat minstens één kleur op elke vlag voorkomt.
Vlag met het complexste wapen|De vlag van Mexico toont een adelaar op een cactus met een slang – een van de meest gedetailleerde wapens.
Gekopieerde vlaggen|De vlaggen van Monaco en Indonesië zijn bijna identiek – rood boven, wit onder. Alleen de verhoudingen verschillen.
Vlag met 50 sterren|De Amerikaanse vlag heeft 50 sterren, één per staat. Het ontwerp is 27 keer gewijzigd sinds 1777.
Noordelijkste vlaggen|Arctische gebieden gebruiken nationale en regionale vlaggen met unieke symboliek.
Vlag met kruis|29 landen hebben een kruis op hun vlag, een van de populairste symbolen.
Driekleuren|Veel landen gebruiken een eenvoudig drie-strepen ontwerp als historisch stabiele vlagvorm.
Vlag met halve maan|De halve maan komt voor op de vlaggen van 12 landen, vooral islamitische, als symbool van het geloof.
Zonsymbool|De zon is een van de meest voorkomende symbolen op vlaggen in Azië en Zuid-Amerika.
Vlag met boom|Libanon is het enige land met een boom (de Libanonceder) op de vlag, symbool van eeuwigheid en vrede.
Smalste vlag|De vlag van Qatar heeft de meest ongebruikelijke beeldverhouding onder nationale vlaggen – 11:28.
Complexe wapens|Wapens op Latijns-Amerikaanse vlaggen bevatten vaak veel details en historische symbolen.
Regenboogvlag|Bolivia heeft twee officiële vlaggen – de traditionele driekleur en de inheemse Wiphala.
Vlag met gebouw|De vlag van Cambodja toont de tempel Angkor Wat, de enige nationale vlag met een gebouw.
Historische geschillen|Het ontwerp van sommige vlaggen veranderde door historische en politieke geschillen.
Vlag met zwaard|De vlag van Sri Lanka toont een leeuw met zwaard, symbool van de moed van de Singalezen.
Vlag zonder blauw|Slechts vier landen gebruiken geen blauw: Jamaica, Mauritanië, Sri Lanka en het Vaticaan.
Vogels op vlaggen|De adelaar en andere vogels op vlaggen symboliseren kracht, onafhankelijkheid en edelmoedigheid.
Antarctisch symbool|Antarctica heeft geen officiële nationale vlag, maar er worden verschillende niet-officiële ontwerpen gebruikt.
Sterren op vlaggen|De ster is een van de meest voorkomende symbolen op vlaggen wereldwijd.
Vergelijkbare kleurenschema's|Sommige vlaggen lijken qua kleur maar verschillen in volgorde van banen en emblemen.
Vlaggen van internationale unies|Supranationale organisaties hebben ook eigen vlaggen met gedeelde waarden.
Eilandsymboliek|Vlaggen van eilandstaten tonen vaak oceanen, zon en navigatie.
Veranderingen in de tijd|Sommige nationale vlaggen zijn tientallen keren veranderd met de politieke geschiedenis.
Zon van Noord-Macedonië|De vlag van Noord-Macedonië heeft een zon met acht stralen voor een nieuw begin.
Houthakkers van Belize|De vlag van Belize is een van de weinige met mensen: houthakkers met gereedschap.
Condor van Ecuador|De vlag van Ecuador toont de Andescondor voor kracht en soevereiniteit.
Twee vlaggen van Bolivia|Bolivia gebruikt de Wiphala naast de driekleur als officieel symbool.
27 sterren van Brazilië|De Braziliaanse vlag heeft 27 sterren, één per staat en het federaal district.
Esdoornblad|De vlag van Canada heeft een enkel 11-puntig esdoornblad, uniek onder nationale vlaggen.
Union Jack|De Britse vlag combineert de kruisen van drie heiligen: Engeland, Schotland en Ierland.
Rijzende zon van Japan|De rode cirkel op wit staat voor de rijzende zon en wordt in Japan sinds de 7e eeuw gebruikt.
Ashoka Chakra|De vlag van India heeft een wiel met 24 spaken, symbool van wet en beweging.
Zuiderkruis van Australië|De vlag van Australië toont het sterrenbeeld Zuiderkruis, alleen zichtbaar op het zuidelijk halfrond.
Zuiderkruis van Nieuw-Zeeland|De vlag van Nieuw-Zeeland heeft ook het Zuiderkruis, met rode sterren met witte rand.
Taegeuk van Zuid-Korea|De vlag van Zuid-Korea toont de traditionele taegeuk (yin-yang) en trigrammen.
Armillairsfeer van Portugal|De vlag van Portugal toont een armillairsfeer, een oud navigatie-instrument.
Tweekoppige adelaar van Albanië|De vlag van Albanië toont een zwarte tweekoppige adelaar, symbool van soevereiniteit.
Schild van Kenia|De vlag van Kenia toont een Massai-schild en gekruiste speren.
Draak van Wales|De rode draak van Wales is een van de oudste nationale symbolen ter wereld.
Kruis van Sint-Andreas|De Schotse vlag is een wit diagonaal kruis op blauw, het kruis van Sint-Andreas.
Cirkel van Groenland|De vlag van Groenland heeft een rood-witte cirkel voor de zon boven het ijs.
Pan-Afrikaanse kleuren|Groen, geel en rood worden vaak pan-Afrikaanse kleuren genoemd en komen op veel Afrikaanse vlaggen voor.
Nordische kruisen|Vijf landen gebruiken het nordische kruis: Denemarken, Noorwegen, Zweden, Finland en IJsland.
Franse driekleur|De Franse blauw-wit-rode driekleur werd een voorbeeld voor veel revolutionaire en nationale vlaggen.
Vlag van de VN|De VN-vlag toont de wereld omringd door olijftakken op een blauwe achtergrond.
Vlag van de EU|Twaalf gouden sterren in een cirkel op blauw symboliseren de eenheid van de EU.
Olympische vlag|De vijf ringen op wit staan voor de vijf bewoonde continenten en het mondiale karakter van de Spelen.
Vierkante vlag van het Vaticaan|Het Vaticaan heeft net als Zwitserland een vierkante nationale vlag.
12 punten van Nauru|De vlag van Nauru heeft een 12-puntige ster voor de 12 stammen van het eiland.
Tapijtpatronen van Turkmenistan|De vlag van Turkmenistan heeft tapijtpatronen langs de stok.
Moskee op de vlag van Afghanistan|De vlag van Afghanistan heeft in verschillende periodes een moskee getoond."""

FACTS_NL = _parse(NL_RAW)
assert len(FACTS_NL) == 68

# Portuguese-BR (68)
PT_BR_RAW = """Bandeira nacional mais antiga em uso|O Dannebrog da Dinamarca é considerada a bandeira nacional em uso contínuo mais antiga desde 1219.
Única bandeira nacional quadrada|A Suíça tem a única bandeira nacional quadrada do mundo. O Vaticano também tem bandeira quadrada mas é cidade-Estado.
Bandeira não retangular|O Nepal tem a única bandeira nacional do mundo que não é retangular.
Sem vermelho, branco ou azul|A Jamaica é o único país com bandeira sem vermelho, branco ou azul.
Bandeira que nunca é hasteada a meio mastro|A bandeira da Arábia Saudita nunca é hasteada a meio mastro por causa do texto sagrado.
Bandeira nacional jovem|A bandeira do Sudão do Sul foi adotada em 2011 após a independência.
Bandeira com AK-47|Moçambique é o único país cuja bandeira mostra uma arma moderna – o fuzil Kalashnikov.
Bandeiras quase idênticas|As bandeiras da Romênia e do Chade são muito parecidas; costumam ser distinguidas pelo tom de azul.
Simbolismo da Ucrânia|A bandeira azul e amarela da Ucrânia é tradicionalmente interpretada como o céu sobre um campo de trigo.
Bandeira mais simples|A bandeira da Líbia de 1977 a 2011 era só verde, sem símbolos ou padrões.
Bandeira com mapa|A bandeira do Chipre mostra o contorno da ilha – caso raro entre bandeiras nacionais.
Bandeira com Bíblia|A bandeira da República Dominicana mostra uma Bíblia aberta, a única bandeira nacional com livro religioso.
Cor mais popular|O vermelho é a cor mais comum em bandeiras nacionais no mundo.
Bandeira com texto|Texto em bandeiras nacionais é raro; um exemplo conhecido é a Arábia Saudita.
Protocolo de bandeiras|Muitos países têm regras rígidas sobre o uso da bandeira nacional.
Bandeira com lados diferentes|O Paraguai tem a única bandeira nacional do mundo com desenhos diferentes no anverso e reverso.
Simbolismo olímpico|As cores dos anéis olímpicos foram escolhidas para que pelo menos uma apareça em cada bandeira nacional.
Bandeira com o brasão mais complexo|A bandeira do México mostra uma águia num cacto com uma serpente – um dos brasões mais detalhados.
Bandeiras copiadas|As bandeiras de Mônaco e Indonésia são quase idênticas – vermelho em cima, branco embaixo. Só as proporções diferem.
Bandeira com 50 estrelas|A bandeira dos EUA tem 50 estrelas, uma por estado. O desenho mudou 27 vezes desde 1777.
Bandeiras mais ao norte|Regiões árticas usam bandeiras nacionais e regionais com simbolismo único.
Bandeira com cruz|29 países têm uma cruz na bandeira, um dos símbolos mais usados.
Tricolores|Muitos países usam um desenho de três listras como forma histórica de bandeira.
Bandeira com crescente|O crescente aparece nas bandeiras de 12 países, em sua maioria muçulmanos, simbolizando a fé islâmica.
Símbolo do sol|O sol é um dos símbolos mais comuns em bandeiras da Ásia e da América do Sul.
Bandeira com árvore|O Líbano é o único país com uma árvore (o cedro do Líbano) na bandeira, simbolizando eternidade e paz.
Bandeira mais estreita|A bandeira do Catar tem a proporção mais incomum entre bandeiras nacionais – 11:28.
Brasões complexos|Brasões em bandeiras latino-americanas costumam ter muitos detalhes e símbolos históricos.
Bandeira arco-íris|A Bolívia tem duas bandeiras oficiais – o tricolor tradicional e a Wiphala indígena.
Bandeira com edificação|A bandeira do Camboja mostra o templo de Angkor Wat, a única bandeira nacional com um prédio.
Disputas históricas|O desenho de algumas bandeiras mudou por disputas históricas e políticas.
Bandeira com espada|A bandeira do Sri Lanka mostra um leão com espada, simbolizando a coragem dos cingaleses.
Bandeira sem azul|Só quatro países não usam azul: Jamaica, Mauritânia, Sri Lanka e Vaticano.
Aves em bandeiras|A águia e outras aves em bandeiras simbolizam força, independência e nobreza.
Símbolo antártico|A Antártida não tem bandeira nacional oficial, mas há vários desenhos não oficiais.
Estrelas em bandeiras|A estrela é um dos símbolos mais difundidos em bandeiras do mundo.
Esquemas de cores parecidos|Algumas bandeiras são parecidas em cor mas diferem na ordem das listras e emblemas.
Bandeiras de uniões internacionais|Organizações supranacionais também têm bandeiras que refletem valores comuns.
Simbolismo insular|Bandeiras de Estados insulares costumam mostrar oceano, sol e navegação.
Mudanças no tempo|Algumas bandeiras nacionais mudaram dezenas de vezes com a história política do país.
Sol da Macedônia do Norte|A bandeira da Macedônia do Norte tem um sol de oito raios para um novo começo.
Lenhadores de Belize|A bandeira de Belize é uma das poucas que mostra pessoas: lenhadores com ferramentas.
Condor do Equador|A bandeira do Equador inclui o condor dos Andes por força e soberania.
Duas bandeiras da Bolívia|A Bolívia usa a Wiphala junto ao tricolor como símbolo oficial.
27 estrelas do Brasil|A bandeira brasileira tem 27 estrelas, uma por estado e o distrito federal.
Folha de bordo|A bandeira do Canadá tem uma única folha de bordo de 11 pontas, única entre bandeiras nacionais.
Union Jack|A bandeira britânica combina as cruzes de três santos: Inglaterra, Escócia e Irlanda.
Sol nascente do Japão|O círculo vermelho no branco representa o sol nascente e é usado no Japão desde o século VII.
Ashoka Chakra|A bandeira da Índia tem uma roda de 24 raios, simbolizando lei e movimento.
Cruzeiro do Sul da Austrália|A bandeira da Austrália mostra a constelação do Cruzeiro do Sul, visível só no hemisfério sul.
Cruzeiro do Sul da Nova Zelândia|A bandeira da Nova Zelândia também tem o Cruzeiro do Sul, com estrelas vermelhas em borda branca.
Taegeuk da Coreia do Sul|A bandeira da Coreia do Sul tem o taegeuk (yin-yang) tradicional e trigramas.
Esfera armilar de Portugal|A bandeira de Portugal tem uma esfera armilar, instrumento de navegação antigo.
Águia bicéfala da Albânia|A bandeira da Albânia mostra uma águia bicéfala negra, símbolo de soberania.
Escudo do Quênia|A bandeira do Quênia tem um escudo massai e lanças cruzadas.
Dragão do País de Gales|O dragão vermelho do País de Gales é um dos símbolos nacionais mais antigos do mundo.
Cruz de Santo André|A bandeira da Escócia é uma cruz diagonal branca no azul, a cruz de Santo André.
Círculo da Groenlândia|A bandeira da Groenlândia tem um círculo vermelho e branco para o sol sobre o gelo.
Cores pan-africanas|Verde, amarelo e vermelho são chamados cores pan-africanas e aparecem em muitas bandeiras africanas.
Cruzes nórdicas|Cinco países usam a cruz nórdica: Dinamarca, Noruega, Suécia, Finlândia e Islândia.
Tricolor francês|O tricolor azul-branco-vermelho francês foi modelo para muitas bandeiras revolucionárias e nacionais.
Bandeira da ONU|A bandeira da ONU mostra o mundo rodeado de ramos de oliveira em fundo azul.
Bandeira da UE|Doze estrelas douradas em círculo no azul simbolizam a unidade da União Europeia.
Bandeira olímpica|Os cinco anéis no branco representam os cinco continentes habitados e o caráter global dos Jogos.
Bandeira quadrada do Vaticano|O Vaticano tem bandeira nacional quadrada como a Suíça.
12 pontas de Nauru|A bandeira de Nauru tem uma estrela de 12 pontas pelas 12 tribos da ilha.
Tapete do Turcomenistão|A bandeira do Turcomenistão tem padrões de tapete ao longo do mastro.
Mesquita na bandeira do Afeganistão|A bandeira do Afeganistão já mostrou uma mesquita em diferentes épocas."""

FACTS_PT_BR = _parse(PT_BR_RAW)
assert len(FACTS_PT_BR) == 68

# Ukrainian (68)
UK_RAW = """Найстаріший прапор у безперервному вжитку|Данський Даннеброг вважається найстарішим державним прапором у світі, який використовується безперервно з 1219 року.
Єдиний квадратний державний прапор|Швейцарія має єдиний квадратний національний прапор у світі. Ватикан також має квадратний прапор, але це місто-держава.
Непрямокутний прапор|Непал має єдиний національний прапор у світі, який не є прямокутним.
Без червоного, білого та синього|Ямайка — єдина країна з прапором без червоного, білого та синього кольорів.
Прапор, який ніколи не приспускають|Прапор Саудівської Аравії ніколи не приспускають до половини щогли через священний напис.
Молодий національний прапор|Прапор Південного Судану прийнято в 2011 році після здобуття незалежності.
Прапор з АК-47|Мозамбік — єдина країна в світі, на прапорі якої зображено сучасну зброю — автомат Калашникова.
Майже однакові прапори|Прапори Румунії та Чаду дуже схожі; їх зазвичай відрізняють за відтінком синього.
Символіка України|Синьо-жовтий прапор України традиційно тлумачать як небо над пшеничним полем.
Найпростіший прапор|Прапор Лівії з 1977 по 2011 рік складався лише з зеленого кольору без символів чи візерунків.
Прапор з картою|На прапорі Кіпру зображено контур острова — рідкісний випадок для державних прапорів.
Прапор з Біблією|На прапорі Домініканської Республіки зображено відкриту Біблію, що робить його єдиним національним прапором з релігійною книгою.
Найпопулярніший колір|Червоний — найпоширеніший колір на національних прапорах світу.
Прапор з текстом|Текст на національному прапорі зустрічається рідко; один із відомих прикладів — Саудівська Аравія.
Етикет використання прапора|У багатьох країнах діють суворі правила поводження з державним прапором.
Прапор з різними сторонами|Парагвай має єдиний у світі національний прапор з різними зображеннями на лицьовій та зворотній сторонах.
Олімпійська символіка|Кольори олімпійських кілець підібрані так, щоб хоча б один колір зустрічався на прапорі кожної країни.
Прапор з найскладнішим гербом|На прапорі Мексики зображено орла, що сидить на кактусі і тримає в дзьобі змію — один із найдетальніших гербів на прапорах.
Прапор-копія|Прапори Монако та Індонезії майже ідентичні — червона смуга зверху, біла знизу. Відрізняються лише пропорції.
Прапор з 50 зірками|На прапорі США 50 зірок, по одній на кожний штат. Дизайн прапора змінювався 27 разів з моменту прийняття в 1777 році.
Найпівнічніші прапори|В арктичних регіонах використовують як державні, так і регіональні прапори з унікальною символікою.
Прапор з хрестом|29 країн світу мають хрест на своєму прапорі, що робить його одним із найпопулярніших символів на національних прапорах.
Триколори|Багато країн використовують простий трисмуговий дизайн як історично стійку форму прапора.
Прапор із півмісяцем|Півмісяць присутній на прапорах 12 країн, переважно мусульманських, символізуючи ісламську віру.
Символ сонця|Сонце — один із найпоширеніших символів на прапорах Азії та Південної Америки.
Прапор з деревом|Ліван — єдина країна, на прапорі якої зображено дерево (ліванський кедр), що символізує вічність і мир.
Найвужчий прапор|Прапор Катару має найнезвичайніше співвідношення сторін серед усіх національних прапорів — 11:28.
Складні герби|Герби на прапорах Латинської Америки часто включають багато деталей та історичних символів.
Прапор-веселка|Болівія має два офіційні прапори — традиційний триколор та веселковий прапор корінних народів Віпала.
Прапор з королівським символом|На прапорі Камбоджі зображено храм Ангкор-Ват, що робить його єдиним національним прапором із будівлею.
Історичні суперечки|Дизайн деяких прапорів змінювався через історичні та політичні суперечки між країнами.
Прапор з мечем|На прапорі Шрі-Ланки зображено лева, що тримає меч, що символізує мужність сингальського народу.
Прапор без синього|Лише 4 країни в світі не використовують синій колір на своїх прапорах: Ямайка, Мавританія, Шрі-Ланка та Ватикан.
Птахи на прапорах|Орел та інші птахи на прапорах символізують силу, незалежність та висоту духу.
Антарктичний символ|У Антарктиди немає офіційного державного прапора, але використовується кілька неофіційних варіантів.
Зірки на прапорах|Зірка — один із найпоширеніших символів на прапорах у всьому світі.
Схожі кольорові схеми|Деякі прапори схожі за кольорами, але відрізняються порядком смуг та емблемами.
Прапори міжнародних союзів|Наднаціональні об'єднання також мають свої прапори, які відображають спільні цінності учасників.
Острівна символіка|На прапорах острівних держав часто присутні символи океану, сонця та навігації.
Зміни в часі|Деякі національні прапори змінювалися десятки разів разом з політичною історією країни.
Сонце Північної Македонії|На прапорі Північної Македонії зображено сонце з вісьмома променями — символ нового початку.
Люди на прапорі Белізу|Прапор Белізу — один з небагатьох, на яких зображено людей: лісоруби з інструментами.
Кондор Еквадору|На прапорі Еквадору зображено андійського кондора — символ сили та суверенітету.
Два прапори Болівії|Болівія визнає Віпалу нарівні з триколором офіційним символом.
27 зірок Бразилії|На прапорі Бразилії 27 зірок: по одній на кожний штат та федеральний округ.
Кленовий лист|Символ Канади — кленовий лист з 11 кінчиками, він єдиний на державному прапорі.
Юніон Джек|Прапор Великої Британії об'єднує хрести трьох святих: Англії, Шотландії та Ірландії.
Східне сонце Японії|Червоний круг на білому тлі символізує східне сонце та відображений на прапорі Японії з VII століття.
Ашока Чакра|На прапорі Індії зображено колесо з 24 спицями — символ закону та руху.
Південний Хрест Австралії|На прапорі Австралії зображено сузір'я Південного Хреста, видиме лише в Південній півкулі.
Південний Хрест Нової Зеландії|Прапор Нової Зеландії також має Південний Хрест, але з червоними зірками з білою обводкою.
Інь і ян Південної Кореї|На прапорі Південної Кореї зображено традиційний символ тегик (інь-ян) та триграми.
Сфера Португалії|На прапорі Португалії зображено армілярну сферу — старовинний навігаційний інструмент.
Двоголовий орел Албанії|На прапорі Албанії зображено чорного двоголового орла — символ суверенітету.
Щит Кенії|На прапорі Кенії зображено щит та схрещені списа масаїв.
Дракон Уельсу|Червоний дракон на прапорі Уельсу — один із найстаріших національних символів у світі.
Хрест святого Андрія|Шотландський прапор — білий діагональний хрест на синьому, символ святого Андрія.
Коло Гренландії|Прапор Гренландії — червоно-біле коло на полотнищі, символізує сонце над льодами.
Панафриканські кольори|Зелений, жовтий та червоний часто називають панафриканськими та вони зустрічаються на багатьох прапорах Африки.
Північні хрести|П'ять країн використовують скандинавський хрест: Данія, Норвегія, Швеція, Фінляндія та Ісландія.
Французький триколор|Французький синьо-біло-червоний прапор став зразком для багатьох революційних та національних прапорів.
Прапор ООН|Прапор ООН зображає мир, оточений оливковими гілками, на блакитному тлі.
Прапор ЄС|12 золотих зірок по колу на синьому — символ єдності Європейського союзу.
Олімпійський прапор|П'ять кілець на білому тлі представляють п'ять населених континентів та всесвітність Ігор.
Квадратний прапор Ватикану|Ватикан нарівні зі Швейцарією має квадратний національний прапор.
12 променів Науру|На прапорі Науру зображено 12-променеву зірку за кількістю племен острова.
Килимові візерунки Туркменістану|На прапорі Туркменістану вздовж древка зображено килимові візерунки.
Мечеть на прапорі Афганістану|На прапорі Афганістану в різні періоди зображалася мечеть."""

FACTS_UK = _parse(UK_RAW)
assert len(FACTS_UK) == 68

# Catalan (68)
CA_RAW = """Bandera nacional més antiga en ús continuat|El Dannebrog de Dinamarca es considera la bandera nacional en ús continuat més antiga des del 1219.
Única bandera nacional quadrada|Suïssa té l'única bandera nacional quadrada del món. El Vaticà també en té una de quadrada però és una ciutat-estat.
Bandera no rectangular|El Nepal té l'única bandera nacional del món que no és rectangular.
Sense vermell, blanc ni blau|Jamaica és l'únic país amb una bandera sense vermell, blanc ni blau.
Bandera que mai no es redueix a mig pal|La bandera d'Aràbia Saudita mai no es redueix a mig pal pel text sagrat.
Bandera nacional jove|La bandera del Sudan del Sud va ser adoptada el 2011 després de la independència.
Bandera amb AK-47|Moçambic és l'únic país la bandera del qual mostra una arma moderna: el fusell Kalashnikov.
Banderes gairebé idèntiques|Les banderes de Romania i el Txad són molt semblants; es distingeixen pel to de blau.
Simbolisme d'Ucraïna|La bandera blava i groga d'Ucraïna s'interpreta tradicionalment com el cel sobre un camp de blat.
Bandera més simple|La bandera de Líbia del 1977 al 2011 era només verda sense símbols ni patrons.
Bandera amb mapa|La bandera de Xipre mostra el contorn de l'illa, un cas rar entre banderes nacionals.
Bandera amb Bíblia|La bandera de la República Dominicana mostra una Bíblia oberta, l'única bandera nacional amb un llibre religiós.
Color més freqüent|El vermell és el color més comú a les banderes nacionals del món.
Bandera amb text|El text a les banderes nacionals és rar; un exemple conegut és Aràbia Saudita.
Protocol de banderes|Molts països tenen normes estrictes sobre el tractament de la bandera nacional.
Bandera amb dos costats diferents|Paraguai té l'única bandera nacional del món amb dissenys diferents a l'anvers i el revers.
Simbolisme olímpic|Els colors dels anells olímpics es van triar perquè almenys un aparegui a cada bandera nacional.
Bandera amb l'escut més complex|La bandera de Mèxic mostra una àguila sobre un cactus amb una serp, un dels escuts més detallats.
Banderes copiades|Les banderes de Mònaco i Indonèsia són gairebé idèntiques: vermell dalt, blanc baix. Només les proporcions difereixen.
Bandera amb 50 estrelles|La bandera dels EUA té 50 estrelles, una per estat. El disseny ha canviat 27 vegades des del 1777.
Banderes més al nord|Les regions àrtiques fan servir banderes nacionals i regionals amb simbolisme únic.
Bandera amb creu|29 països tenen una creu a la bandera, un dels símbols més usats.
Tricolors|Molts països fan servir un disseny de tres franges com a forma de bandera històricament estable.
Bandera amb mitja lluna|La mitja lluna apareix a les banderes de 12 països, majoritàriament musulmans, simbolitzant la fe islàmica.
Símbol del sol|El sol és un dels símbols més comuns a les banderes d'Àsia i Amèrica del Sud.
Bandera amb arbre|El Líban és l'únic país amb un arbre (el cedre del Líban) a la bandera, simbolitzant eternitat i pau.
Bandera més estreta|La bandera de Qatar té la proporció més inusual entre banderes nacionals: 11:28.
Escuts complexos|Els escuts a les banderes llatinoamericanes sovint inclouen molts detalls i símbols històrics.
Bandera arc de Sant Martin|Bolívia té dues banderes oficials: el tricolor tradicional i la Wiphala indígena.
Bandera amb edifici|La bandera de Cambodja mostra el temple d'Angkor Wat, l'única bandera nacional amb un edifici.
Disputes històriques|El disseny d'algunes banderes ha canviat per disputes històriques i polítiques.
Bandera amb espasa|La bandera de Sri Lanka mostra un lleó amb espasa, simbolitzant el coratge dels singalesos.
Bandera sense blau|Només quatre països no fan servir blau: Jamaica, Mauritània, Sri Lanka i el Vaticà.
Ocells a les banderes|L'àguila i altres ocells a les banderes simbolitzen força, independència i noblesa.
Símbol antàrtic|L'Antàrtida no té bandera nacional oficial, però s'usen diversos dissenys no oficials.
Estrelles a les banderes|L'estrella és un dels símbols més estesos a les banderes del món.
Esquemes de color semblants|Algunes banderes són semblants en color però difereixen en l'ordre de franges i emblemes.
Banderes d'unions internacionals|Les organitzacions supranacionals també tenen banderes que reflecteixen valors comuns.
Simbolisme insular|Les banderes d'estats insulars mostren sovint l'oceà, el sol i la navegació.
Canvis en el temps|Algunes banderes nacionals han canviat desenes de vegades amb la història política del país.
Sol de Macedònia del Nord|La bandera de Macedònia del Nord té un sol de vuit raigs per a un nou començament.
Llenyataires de Belize|La bandera de Belize és una de les poques que mostra persones: llenyataires amb eines.
Còndor de l'Equador|La bandera de l'Equador inclou el còndor dels Andes per força i sobirania.
Dues banderes de Bolívia|Bolívia fa servir la Wiphala al costat del tricolor com a símbol oficial.
27 estrelles del Brasil|La bandera del Brasil té 27 estrelles, una per estat i el districte federal.
Fullla d'auró|La bandera del Canadà té una sola fullla d'auró d'11 puntes, única entre banderes nacionals.
Union Jack|La bandera britànica combina les creus de tres sants: Anglaterra, Escòcia i Irlanda.
Sol naixent del Japó|El cercle vermell sobre blanc representa el sol naixent i s'usa al Japó des del segle VII.
Ashoka Chakra|La bandera de l'Índia té una roda de 24 raigs, simbolitzant llei i moviment.
Creu del Sud d'Austràlia|La bandera d'Austràlia mostra la constel·lació de la Creu del Sud, visible només a l'hemisferi sud.
Creu del Sud de Nova Zelanda|La bandera de Nova Zelanda també té la Creu del Sud, amb estrelles vermelles vorejades de blanc.
Taegeuk de Corea del Sud|La bandera de Corea del Sud té el taegeuk (yin-yang) tradicional i trigrames.
Esfera armil·lar de Portugal|La bandera de Portugal té una esfera armil·lar, un instrument de navegació antic.
Àguila bicèfala d'Albània|La bandera d'Albània mostra una àguila bicèfala negra, símbol de sobirania.
Escut de Kenya|La bandera de Kenya té un escut massai i llances creuades.
Drac de Gal·les|El drac vermell de Gal·les és un dels símbols nacionals més antics del món.
Creu de sant Andreu|La bandera d'Escòcia és una creu diagonal blanca sobre blau, la creu de sant Andreu.
Cercle de Groenlàndia|La bandera de Groenlàndia té un cercle vermell i blanc per al sol sobre el gel.
Colors panafricans|El verd, groc i vermell s'anomenen colors panafricans i apareixen a moltes banderes africanes.
Creus nòrdiques|Cinc països fan servir la creu nòrdica: Dinamarca, Noruega, Suècia, Finlàndia i Islàndia.
Tricolor francès|El tricolor blau-blanc-vermell francès va ser model per a moltes banderes revolucionàries i nacionals.
Bandera de l'ONU|La bandera de l'ONU mostra el món envoltat de branques d'olivera sobre fons blau.
Bandera de la UE|Dotze estrelles d'or en cercle sobre blau simbolitzen la unitat de la Unió Europea.
Bandera olímpica|Els cinc anells sobre blanc representen els cinc continents habitats i el caràcter global dels Jocs.
Bandera quadrada del Vaticà|El Vaticà té una bandera nacional quadrada com Suïssa.
12 puntes de Nauru|La bandera de Nauru té una estrella de 12 puntes per les 12 tribus de l'illa.
Estampats de catifa del Turkmenistan|La bandera del Turkmenistan té motius de catifa al llarg del pal.
Mesquita a la bandera de l'Afganistan|La bandera de l'Afganistan ha mostrat una mesquita en diferents èpoques."""

FACTS_CA = _parse(CA_RAW)
assert len(FACTS_CA) == 68

# Chinese Simplified (68)
ZH_RAW = """使用最久的国旗|丹麦的丹尼布洛被认为是自1219年起连续使用最久的国旗。
唯一正方形国旗|瑞士拥有世界上唯一正方形国旗。梵蒂冈也是正方形，但是城邦。
非矩形国旗|尼泊尔拥有世界上唯一非矩形的国旗。
无红白蓝三色|牙买加是唯一国旗上没有红、白、蓝三色的国家。
永不降半旗|沙特阿拉伯国旗因上有神圣文字而从不下半旗。
年轻的国旗|南苏丹国旗于2011年独立后采用。
带AK-47的国旗|莫桑比克是唯一在国旗上出现现代武器——卡拉什尼科夫步枪的国家。
几乎相同的国旗|罗马尼亚与乍得国旗非常相似，通常以蓝色深浅区分。
乌克兰的象征|乌克兰蓝黄旗传统上被解读为麦田上的天空。
最简单的国旗|利比亚国旗在1977至2011年间为纯绿色，无任何符号或图案。
带地图的国旗|塞浦路斯国旗上有岛屿轮廓，在国旗中较为罕见。
带圣经的国旗|多米尼加共和国国旗上有打开的圣经，是唯一带宗教书籍的国旗。
最常见的颜色|红色是世界上国旗上最常见的颜色。
带文字的国旗|国旗上出现文字很少见，著名一例是沙特阿拉伯。
国旗礼仪|许多国家对国旗的使用有严格规定。
正反面不同的国旗|巴拉圭拥有世界上唯一正反面图案不同的国旗。
奥运象征|奥运五环颜色被设计为至少一种颜色出现在每个国家的国旗上。
徽章最复杂的国旗|墨西哥国旗上有鹰立于仙人掌持蛇的图案，是细节最丰富的国旗徽章之一。
复制版国旗|摩纳哥与印度尼西亚国旗几乎相同——上红下白，仅比例不同。
50星旗|美国国旗有50颗星，每州一颗。自1777年以来设计变更了27次。
最北的国旗|北极地区使用具有独特象征意义的国家和地区旗帜。
带十字的国旗|29个国家国旗上有十字，是最常见的符号之一。
三色旗|许多国家采用简单的三条纹设计作为历史上稳定的旗帜形式。
带新月的国旗|新月出现在12国国旗上，多为穆斯林国家，象征伊斯兰信仰。
太阳象征|太阳是亚洲和南美国旗上最常见的符号之一。
带树的国旗|黎巴嫩是唯一国旗上有树（黎巴嫩雪松）的国家，象征永恒与和平。
最窄的国旗|卡塔尔国旗的宽高比在所有国旗中最特别——11:28。
复杂徽章|拉丁美洲国旗上的徽章常包含大量细节和历史符号。
彩虹旗|玻利维亚有两面官方旗帜——传统三色旗与土著维帕拉彩虹旗。
带建筑的国旗|柬埔寨国旗上有吴哥窟，是唯一带建筑的国旗。
历史争议|部分国旗设计因历史与政治争议而改变。
带剑的国旗|斯里兰卡国旗上有持剑狮子，象征僧伽罗人的勇气。
无蓝色的国旗|仅四国国旗不用蓝色：牙买加、毛里塔尼亚、斯里兰卡和梵蒂冈。
国旗上的鸟|鹰及其他鸟类在国旗上象征力量、独立与高贵。
南极象征|南极洲没有官方国旗，但存在多种非官方设计。
国旗上的星|星是全世界国旗上最普遍的符号之一。
相似配色|部分国旗颜色相近但条纹顺序与徽章不同。
国际组织旗帜|超国家组织也有反映共同价值的旗帜。
岛屿象征|岛国国旗常出现海洋、太阳与航海符号。
随时间变化|部分国旗随国家政治史变更过数十次。
北马其顿太阳|北马其顿国旗上有八道光芒的太阳，象征新的开始。
伯利兹伐木工|伯利兹国旗是少数出现人物的国旗之一：持工具的伐木工。
厄瓜多尔神鹰|厄瓜多尔国旗上有安第斯神鹰，象征力量与主权。
玻利维亚双旗|玻利维亚将维帕拉与三色旗并列为官方象征。
巴西27星|巴西国旗有27颗星，每州和联邦区各一。
枫叶|加拿大国旗上有唯一的11角枫叶，在各国国旗中独有。
米字旗|英国国旗融合了三个圣徒的十字：英格兰、苏格兰与爱尔兰。
日本旭日|白底上的红圈代表旭日，日本自7世纪起使用。
阿育王法轮|印度国旗上有24辐法轮，象征法与动。
澳大利亚南十字|澳大利亚国旗上有南十字星座，仅在南半球可见。
新西兰南十字|新西兰国旗也有南十字，但为红星白边。
韩国太极|韩国国旗上有传统太极（阴阳）与八卦。
葡萄牙浑天仪|葡萄牙国旗上有浑天仪，古代航海仪器。
阿尔巴尼亚双头鹰|阿尔巴尼亚国旗上有黑色双头鹰，象征主权。
肯尼亚盾|肯尼亚国旗上有马赛盾与交叉长矛。
威尔士红龙|威尔士红龙是世界上最古老的国家象征之一。
圣安德烈十字|苏格兰国旗为蓝底白斜十字，即圣安德烈十字。
格陵兰圆|格陵兰国旗上有红白圆，象征冰原上的太阳。
泛非色彩|绿、黄、红常被称为泛非色，出现在许多非洲国旗上。
北欧十字|五国使用北欧十字：丹麦、挪威、瑞典、芬兰与冰岛。
法国三色|法国蓝白红三色旗成为许多革命与民族旗帜的范本。
联合国旗|联合国旗为蓝底上地球与橄榄枝。
欧盟旗|蓝底上12颗金星成环，象征欧盟团结。
奥运旗|白底五环代表五大洲与奥运的全球性。
梵蒂冈方旗|梵蒂冈与瑞士一样使用正方形国旗。
瑙鲁12芒|瑙鲁国旗上有12芒星，代表岛上12个部落。
土库曼地毯纹|土库曼斯坦国旗沿旗杆一侧有传统地毯图案。
阿富汗清真寺|阿富汗国旗在不同时期曾出现清真寺图案。"""

FACTS_ZH = _parse(ZH_RAW)
assert len(FACTS_ZH) == 68

TRANSLATIONS = {
    "de": FACTS_DE,
    "fr": FACTS_FR,
    "es": FACTS_ES,
    "it": FACTS_IT,
    "pl": FACTS_PL,
    "nl": FACTS_NL,
    "pt-BR": FACTS_PT_BR,
    "uk": FACTS_UK,
    "ca": FACTS_CA,
    "zh": FACTS_ZH,
}
