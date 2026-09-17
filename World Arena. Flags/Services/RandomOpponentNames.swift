import Foundation

/// Имена «случайных соперников» по локали приложения (как у реальных пользователей из 12 стран).
enum RandomOpponentNames {
    private static let namesByLocale: [String: [String]] = [
        "en": [
            "Alex", "Maria", "David", "Sophie", "Max", "Anna", "Leo", "Ella", "Mark", "Lina",
            "Nick", "Julia", "James", "Kate", "Dan", "Nina", "Paul", "Rosa", "Sam", "Mia",
            "Tom", "Emma", "Chris", "Olivia", "Jack", "Lily", "Ryan", "Chloe", "Luke", "Zoe",
            "Ben", "Grace", "Adam", "Hannah", "Jake", "Emily", "Matt", "Sarah", "Alex", "Laura",
            "Kevin", "Rachel", "Steve", "Amy", "Mike", "Lisa", "Dave", "Jenny", "John", "Mary",
            "Oliver", "Isabella", "Noah", "Mia", "Liam", "Ava", "Mason", "Charlotte", "Ethan", "Amelia"
        ],
        "ru": [
            "Александр", "Мария", "Дмитрий", "София", "Максим", "Анна", "Лев", "Елизавета", "Марк", "Полина",
            "Никита", "Юлия", "Иван", "Екатерина", "Даниил", "Виктория", "Павел", "Алина", "Артём", "Дарья",
            "Михаил", "Александра", "Кирилл", "Валерия", "Андрей", "Кристина", "Илья", "Наталья", "Роман", "Ольга",
            "Егор", "Татьяна", "Сергей", "Елена", "Николай", "Светлана", "Владимир", "Ирина", "Алексей", "Марина",
            "Денис", "Надежда", "Станислав", "Людмила", "Олег", "Галина", "Виктор", "Лариса", "Глеб", "Вероника",
            "Тимофей", "Ульяна", "Матвей", "Ксения", "Фёдор", "Василиса", "Ярослав", "Милана", "Богдан", "Арина"
        ],
        "uk": [
            "Олександр", "Марія", "Дмитро", "Софія", "Максим", "Анна", "Лев", "Єлизавета", "Марк", "Поліна",
            "Нікіта", "Юлія", "Іван", "Катерина", "Данило", "Вікторія", "Павло", "Аліна", "Артем", "Дар'я",
            "Михайло", "Олександра", "Кирило", "Валерія", "Андрій", "Христина", "Ілля", "Наталія", "Роман", "Ольга",
            "Єгор", "Тетяна", "Сергій", "Олена", "Микола", "Світлана", "Володимир", "Ірина", "Олексій", "Марина",
            "Денис", "Надія", "Станіслав", "Людмила", "Олег", "Галина", "Віктор", "Лариса", "Гліб", "Вероніка",
            "Тимофій", "Уляна", "Матвій", "Ксенія", "Федір", "Василина", "Ярослав", "Мілана", "Богдан", "Аріна"
        ],
        "de": [
            "Alexander", "Maria", "David", "Sophie", "Max", "Anna", "Leon", "Emma", "Mark", "Lina",
            "Niklas", "Julia", "Paul", "Laura", "Felix", "Lena", "Tim", "Sarah", "Jan", "Lisa",
            "Tom", "Laura", "Finn", "Hannah", "Jonas", "Lea", "Ben", "Marie", "Lukas", "Julia",
            "Maximilian", "Katharina", "Philipp", "Christina", "Sebastian", "Stefanie", "Tobias", "Andrea",
            "Michael", "Sabine", "Stefan", "Claudia", "Andreas", "Petra", "Christian", "Monika",
            "Martin", "Susanne", "Thomas", "Angela", "Daniel", "Jennifer", "Simon", "Melanie", "Florian", "Nadine"
        ],
        "fr": [
            "Alexandre", "Marie", "David", "Sophie", "Maxime", "Anne", "Léo", "Emma", "Marc", "Léa",
            "Nicolas", "Julie", "Thomas", "Camille", "Pierre", "Chloé", "Antoine", "Manon", "Julien", "Laura",
            "Louis", "Pauline", "Hugo", "Marine", "Gabriel", "Clara", "Raphaël", "Sarah", "Arthur", "Lucie",
            "Jules", "Marie", "Lucas", "Julie", "Adam", "Charlotte", "Nathan", "Océane", "Enzo", "Lola",
            "Clément", "Margot", "Romain", "Juliette", "Alexandre", "Inès", "Pierre", "Élise", "Nicolas", "Anaïs",
            "Michel", "Françoise", "Jean", "Catherine", "Philippe", "Isabelle", "Patrick", "Sylvie", "Christophe", "Nathalie"
        ],
        "es": [
            "Alejandro", "María", "David", "Sofía", "Marcos", "Ana", "Leo", "Elena", "Pablo", "Laura",
            "Daniel", "Julia", "Carlos", "Carmen", "Miguel", "Isabel", "Javier", "Lucía", "Antonio", "Eva",
            "José", "Paula", "Francisco", "Raquel", "Manuel", "Rosa", "Pedro", "Marta", "Ángel", "Sara",
            "Fernando", "Cristina", "Roberto", "Patricia", "Luis", "Andrea", "Jorge", "Natalia", "Diego", "Claudia",
            "Raúl", "Silvia", "Sergio", "Beatriz", "Alberto", "Lorena", "Andrés", "Marina", "Víctor", "Irene",
            "Adrián", "Noelia", "Rubén", "Celia", "Iván", "Mónica", "Óscar", "Rocío", "Héctor", "Verónica"
        ],
        "it": [
            "Alessandro", "Maria", "Davide", "Sofia", "Marco", "Anna", "Leonardo", "Giulia", "Matteo", "Francesca",
            "Lorenzo", "Chiara", "Andrea", "Elena", "Francesco", "Laura", "Luca", "Valentina", "Simone", "Martina",
            "Giuseppe", "Federica", "Antonio", "Alessandra", "Giovanni", "Silvia", "Paolo", "Roberta", "Stefano", "Elena",
            "Riccardo", "Monica", "Federico", "Claudia", "Alessandro", "Serena", "Matteo", "Ilaria", "Lorenzo", "Giada",
            "Marco", "Arianna", "Luca", "Beatrice", "Andrea", "Camilla", "Filippo", "Sara", "Nicola", "Giorgia",
            "Salvatore", "Rosa", "Vincenzo", "Teresa", "Angelo", "Lucia", "Mario", "Caterina", "Bruno", "Paola"
        ],
        "nl": [
            "Alexander", "Maria", "David", "Sophie", "Max", "Anna", "Levi", "Emma", "Mark", "Lisa",
            "Daan", "Julia", "Bram", "Eva", "Sem", "Sanne", "Lucas", "Laura", "Milan", "Fleur",
            "Jesse", "Iris", "Tim", "Sara", "Thomas", "Lotte", "Ruben", "Nina", "Finn", "Isa",
            "Noah", "Evi", "Luuk", "Roos", "Mees", "Tess", "Stijn", "Anne", "Thijs", "Fenna",
            "Jan", "Petra", "Peter", "Linda", "Hans", "Monique", "Willem", "Ingrid", "Kees", "Marieke",
            "Pieter", "Els", "Henk", "Janneke", "Gerard", "Marijke", "Bert", "Hanneke", "Frank", "Corrie"
        ],
        "pl": [
            "Aleksander", "Maria", "Dawid", "Zofia", "Maks", "Anna", "Leon", "Julia", "Marek", "Lena",
            "Nikodem", "Natalia", "Jan", "Katarzyna", "Daniel", "Wiktoria", "Paweł", "Aleksandra", "Bartosz", "Martyna",
            "Michał", "Karolina", "Kacper", "Magdalena", "Jakub", "Dominika", "Filip", "Natalia", "Krzysztof", "Paulina",
            "Tomasz", "Monika", "Piotr", "Agnieszka", "Marcin", "Ewa", "Łukasz", "Joanna", "Adam", "Justyna",
            "Michał", "Patrycja", "Mateusz", "Sylwia", "Damian", "Iwona", "Rafał", "Renata", "Grzegorz", "Dorota",
            "Szymon", "Beata", "Mariusz", "Małgorzata", "Tadeusz", "Halina", "Stanisław", "Irena", "Jerzy", "Danuta"
        ],
        "pt-BR": [
            "Alexandre", "Maria", "David", "Sophia", "Enzo", "Ana", "Leonardo", "Julia", "Miguel", "Laura",
            "Rafael", "Beatriz", "Gabriel", "Isabella", "Lucas", "Manuela", "Pedro", "Mariana", "Bruno", "Larissa",
            "Felipe", "Camila", "Gustavo", "Amanda", "Matheus", "Fernanda", "Rodrigo", "Patricia", "André", "Carla",
            "Thiago", "Renata", "Marcos", "Daniela", "Paulo", "Adriana", "Carlos", "Sandra", "Ricardo", "Luciana",
            "Eduardo", "Claudia", "Fernando", "Roberta", "Roberto", "Alessandra", "João", "Marina", "Diego", "Vanessa",
            "Antônio", "Francisca", "José", "Tereza", "Francisco", "Rosa", "Luiz", "Catarina", "Sebastião", "Aparecida"
        ],
        "zh": [
            "伟强", "芳芳", "明磊", "静雯", "海洋", "丽华", "军伟", "艳玲", "杰伦", "涛涛",
            "敏敏", "秀英", "超群", "霞姐", "平哥", "娜娜", "刚毅", "建华", "勇军", "玉兰",
            "鹏飞", "秀兰", "斌斌", "桂英", "波波", "丽娜", "浩宇", "秀珍", "鑫鑫", "桂兰",
            "亮亮", "凤英", "峰峰", "桂珍", "龙飞", "秀芳", "伟明", "玉梅", "涛涛", "桂芳",
            "强强", "秀梅", "磊磊", "玉英", "明远", "敏君", "杰杰", "丽丽", "超超", "静雅",
            "鹏程", "秀华", "飞飞", "霞霞", "小伟", "小芳", "小明", "小丽", "小军", "小华"
        ],
        "ca": [
            "Alexandre", "Maria", "David", "Sofia", "Marc", "Anna", "Lluís", "Júlia", "Pau", "Laura",
            "Nil", "Carla", "Jan", "Martina", "Pol", "Laia", "Biel", "Ona", "Arnau", "Marta",
            "Roger", "Clàudia", "Gerard", "Aina", "Eric", "Núria", "Adrià", "Irene", "Víctor", "Alba",
            "Jordi", "Cristina", "Albert", "Elena", "Oriol", "Sílvia", "Miquel", "Rosa", "Ferran", "Montserrat",
            "Ramon", "Teresa", "Joan", "Carme", "Antoni", "Dolors", "Francesc", "Mercè", "Josep", "Concepció",
            "Carles", "Anna", "Pere", "Maria", "Salvador", "Josefa", "Francesc", "Isabel", "Joaquim", "Rosa"
        ]
    ]

    /// Имена для текущей локали приложения (языковой код: en, ru, uk, de, fr, es, it, nl, pl, pt-BR, zh, ca). Fallback — en.
    static func names(for languageCode: String) -> [String] {
        let code = languageCode.lowercased()
        if code.hasPrefix("pt") {
            return namesByLocale["pt-BR"] ?? namesByLocale["en"]!
        }
        if let list = namesByLocale[code] {
            return list
        }
        return namesByLocale["en"]!
    }

    /// Случайное имя соперника с учётом региона: >50% из списка локали пользователя, остальные — латиница (en).
    static func randomName(for languageCode: String) -> String {
        let localeNames = names(for: languageCode)
        let enNames = namesByLocale["en"]!
        let useLocale = languageCode != "en" && Double.random(in: 0..<1) < 0.58
        let list = useLocale ? localeNames : enNames
        return list.randomElement() ?? enNames[0]
    }
}
