import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyWord {
  final String id;
  final String word;
  final String translation;
  final String pronunciation;
  final String example;
  final String category;
  bool isLearned;
  final DateTime addedAt;

  VocabularyWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.pronunciation,
    required this.example,
    required this.category,
    this.isLearned = false,
    required this.addedAt,
  });

  VocabularyWord copyWith({bool? isLearned}) {
    return VocabularyWord(
      id: id,
      word: word,
      translation: translation,
      pronunciation: pronunciation,
      example: example,
      category: category,
      isLearned: isLearned ?? this.isLearned,
      addedAt: addedAt,
    );
  }
}

class VocabularySet {
  final String language;
  final List<VocabularyWord> words;

  VocabularySet({
    required this.language,
    required this.words,
  });
}

class VocabularySampleData {
  static final List<String> languages = [
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Mandarin',
    'Japanese',
    'Korean',
    'Russian',
    'Arabic',
    'Hindi',
  ];

  static final Map<String, List<VocabularyWord>> _memoryCache = {};

  /// Fetch vocabulary from Firebase or return local fallback
  static Future<List<VocabularyWord>> getSampleDataFromFirebase(
    String language, {
    required dynamic firestoreService,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available
    if (!forceRefresh && _memoryCache.containsKey(language)) {
      return _memoryCache[language]!;
    }

    try {
      final vocabList = await firestoreService.getVocabularyByLanguage(language);
      
      if (vocabList.isNotEmpty) {
        final words = vocabList
            .map((vocab) => VocabularyWord(
                  id: vocab['id'] ?? '',
                  word: vocab['word'] ?? '',
                  translation: vocab['translation'] ?? '',
                  pronunciation: vocab['pronunciation'] ?? '',
                  example: vocab['example'] ?? '',
                  category: vocab['category'] ?? '',
                  isLearned: vocab['isLearned'] ?? false,
                  addedAt: vocab['addedAt'] is String
                      ? DateTime.parse(vocab['addedAt'])
                      : (vocab['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                ))
            .toList();
        
        _memoryCache[language] = words;
        return words;
      }
    } catch (e) {
      print('Error fetching vocabulary from Firebase: $e');
    }
    
    final localWords = _getLocalVocabulary(language);
    _memoryCache[language] = localWords;
    return localWords;
  }

  static List<VocabularyWord> _getLocalVocabulary(String language) {
    switch (language) {
      case 'Spanish':
        return _spanishVocabulary();
      case 'French':
        return _frenchVocabulary();
      case 'German':
        return _germanVocabulary();
      case 'Italian':
        return _italianVocabulary();
      case 'Portuguese':
        return _portugueseVocabulary();
      case 'Mandarin':
        return _mandarinVocabulary();
      case 'Japanese':
        return _japaneseVocabulary();
      case 'Korean':
        return _koreanVocabulary();
      case 'Russian':
        return _russianVocabulary();
      case 'Arabic':
        return _arabicVocabulary();
      case 'Hindi':
        return _hindiVocabulary();
      default:
        return _spanishVocabulary();
    }
  }

  static List<VocabularyWord> getSampleData(String language) {
    return _getLocalVocabulary(language);
  }

  // SPANISH VOCABULARY (25+ words)
  static List<VocabularyWord> _spanishVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'Hola', translation: 'Hello', pronunciation: 'OH-lah', example: 'Hola, ¿cómo estás?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'Adiós', translation: 'Goodbye', pronunciation: 'ah-dee-OHS', example: 'Adiós, hasta luego.', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'Buenos días', translation: 'Good morning', pronunciation: 'BWEH-nos DEE-as', example: 'Buenos días, ¿cómo amaneciste?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'Por favor', translation: 'Please', pronunciation: 'por fah-VOR', example: 'Un café, por favor.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'Gracias', translation: 'Thank you', pronunciation: 'GRAH-see-as', example: 'Gracias por tu ayuda.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'De nada', translation: 'You\'re welcome', pronunciation: 'deh NAH-dah', example: 'De nada, fue un placer.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'Pan', translation: 'Bread', pronunciation: 'pahn', example: 'Me gustaría pan tostado.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'Agua', translation: 'Water', pronunciation: 'AH-gwah', example: 'Un vaso de agua fría, por favor.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'Manzana', translation: 'Apple', pronunciation: 'man-SAH-nah', example: 'La manzana roja es deliciosa.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'Casa', translation: 'House', pronunciation: 'KAH-sah', example: 'Mi casa está en la ciudad.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'Biblioteca', translation: 'Library', pronunciation: 'bee-blee-oh-TEH-kah', example: 'Voy a la biblioteca a estudiar.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'Amigo', translation: 'Friend', pronunciation: 'ah-MEE-goh', example: 'Mi amigo es muy amable.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'Familia', translation: 'Family', pronunciation: 'fah-MEE-lee-ah', example: 'Mi familia es grande.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'Gato', translation: 'Cat', pronunciation: 'GAH-toh', example: 'El gato es muy bonito.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'Perro', translation: 'Dog', pronunciation: 'PEH-rroh', example: 'El perro juega en el parque.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'Pájaro', translation: 'Bird', pronunciation: 'PAH-hah-roh', example: 'El pájaro canta por la mañana.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'Rojo', translation: 'Red', pronunciation: 'ROH-hoh', example: 'Me gusta el color rojo.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'Azul', translation: 'Blue', pronunciation: 'ah-SOOL', example: 'El cielo es azul.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'Verde', translation: 'Green', pronunciation: 'BEHR-deh', example: 'Las plantas son verdes.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'Uno', translation: 'One', pronunciation: 'OO-noh', example: 'Tengo una manzana.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'Dos', translation: 'Two', pronunciation: 'dohs', example: 'Tengo dos hermanos.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'Tres', translation: 'Three', pronunciation: 'trehs', example: 'Hay tres gatos aquí.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'Café', translation: 'Coffee', pronunciation: 'kah-FEH', example: 'Bebo café cada mañana.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'Libro', translation: 'Book', pronunciation: 'LEE-broh', example: 'Me encanta leer este libro.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'Escuela', translation: 'School', pronunciation: 'es-KWEH-lah', example: 'Mi escuela está cerca de casa.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'Amor', translation: 'Love', pronunciation: 'ah-MOR', example: 'Amo a mi familia.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'Feliz', translation: 'Happy', pronunciation: 'feh-LEES', example: 'Soy muy feliz hoy.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // FRENCH VOCABULARY (25+ words)
  static List<VocabularyWord> _frenchVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'Bonjour', translation: 'Hello', pronunciation: 'bon-ZHOOR', example: 'Bonjour, comment allez-vous?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'Au revoir', translation: 'Goodbye', pronunciation: 'oh ruh-VWAHR', example: 'Au revoir, à bientôt!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'Bonsoir', translation: 'Good evening', pronunciation: 'bon-SWAHR', example: 'Bonsoir madame.', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'S\'il vous plaît', translation: 'Please', pronunciation: 'see voo pleh', example: 'Un café, s\'il vous plaît.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'Merci', translation: 'Thank you', pronunciation: 'mehr-SEE', example: 'Merci beaucoup!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'De rien', translation: 'You\'re welcome', pronunciation: 'duh ree-YAN', example: 'De rien, c\'est un plaisir.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'Pain', translation: 'Bread', pronunciation: 'pan', example: 'Je voudrais du pain frais.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'Eau', translation: 'Water', pronunciation: 'oh', example: 'Un verre d\'eau, s\'il vous plaît.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'Pomme', translation: 'Apple', pronunciation: 'pohm', example: 'La pomme rouge est délicieuse.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'Maison', translation: 'House', pronunciation: 'meh-ZON', example: 'Ma maison est près du parc.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'Bibliothèque', translation: 'Library', pronunciation: 'bee-blee-oh-TEK', example: 'Je vais à la bibliothèque.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'Ami', translation: 'Friend', pronunciation: 'ah-MEE', example: 'Mon ami est très gentil.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'Famille', translation: 'Family', pronunciation: 'fah-MEE', example: 'Ma famille est grande.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'Chat', translation: 'Cat', pronunciation: 'shah', example: 'Le chat est mignon.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'Chien', translation: 'Dog', pronunciation: 'shee-YAN', example: 'Le chien joue dans le parc.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'Oiseau', translation: 'Bird', pronunciation: 'wah-ZOH', example: 'L\'oiseau chante le matin.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'Rouge', translation: 'Red', pronunciation: 'ROOZH', example: 'J\'aime la couleur rouge.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'Bleu', translation: 'Blue', pronunciation: 'bluh', example: 'Le ciel est bleu.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'Vert', translation: 'Green', pronunciation: 'vair', example: 'Les plantes sont vertes.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'Un', translation: 'One', pronunciation: 'uhn', example: 'J\'ai une pomme.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'Deux', translation: 'Two', pronunciation: 'duh', example: 'J\'ai deux frères.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'Trois', translation: 'Three', pronunciation: 'twah', example: 'Il y a trois chats ici.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'Café', translation: 'Coffee', pronunciation: 'kah-FEH', example: 'Je bois du café chaque matin.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'Livre', translation: 'Book', pronunciation: 'LEE-vr', example: 'J\'aime lire ce livre.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'École', translation: 'School', pronunciation: 'eh-KOHL', example: 'Mon école est près de ma maison.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'Amour', translation: 'Love', pronunciation: 'ah-MOOR', example: 'J\'aime ma famille.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'Heureux', translation: 'Happy', pronunciation: 'uh-RUH', example: 'Je suis très heureux aujourd\'hui.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // GERMAN VOCABULARY (25+ words)
  static List<VocabularyWord> _germanVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'Hallo', translation: 'Hello', pronunciation: 'HAH-loh', example: 'Hallo, wie geht es dir?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'Auf Wiedersehen', translation: 'Goodbye', pronunciation: 'owf VEE-der-zay-en', example: 'Auf Wiedersehen, bis später!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'Guten Morgen', translation: 'Good morning', pronunciation: 'GOO-ten MOR-gen', example: 'Guten Morgen, wie schläfst du?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'Bitte', translation: 'Please', pronunciation: 'BIT-tuh', example: 'Ein Kaffee, bitte.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'Danke', translation: 'Thank you', pronunciation: 'DAHN-kuh', example: 'Danke für deine Hilfe!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'Gerne', translation: 'You\'re welcome', pronunciation: 'GEHR-nuh', example: 'Gerne, es war mein Vergnügen.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'Brot', translation: 'Bread', pronunciation: 'broht', example: 'Ich möchte frisches Brot.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'Wasser', translation: 'Water', pronunciation: 'VAHS-ser', example: 'Ein Glas Wasser, bitte.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'Apfel', translation: 'Apple', pronunciation: 'AHP-fel', example: 'Der rote Apfel ist köstlich.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'Haus', translation: 'House', pronunciation: 'hous', example: 'Mein Haus ist in der Stadt.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'Bibliothek', translation: 'Library', pronunciation: 'bee-blee-oh-TEK', example: 'Ich gehe zur Bibliothek zum Lernen.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'Freund', translation: 'Friend', pronunciation: 'FROYT', example: 'Mein Freund ist sehr freundlich.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'Familie', translation: 'Family', pronunciation: 'fah-MEE-lee-uh', example: 'Meine Familie ist groß.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'Katze', translation: 'Cat', pronunciation: 'KAHT-suh', example: 'Die Katze ist sehr süß.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'Hund', translation: 'Dog', pronunciation: 'hoont', example: 'Der Hund spielt im Park.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'Vogel', translation: 'Bird', pronunciation: 'FOH-gel', example: 'Der Vogel singt am Morgen.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'Rot', translation: 'Red', pronunciation: 'roht', example: 'Ich mag die Farbe rot.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'Blau', translation: 'Blue', pronunciation: 'blou', example: 'Der Himmel ist blau.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'Grün', translation: 'Green', pronunciation: 'GROON', example: 'Die Pflanzen sind grün.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'Eins', translation: 'One', pronunciation: 'AYNS', example: 'Ich habe einen Apfel.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'Zwei', translation: 'Two', pronunciation: 'TSVAY', example: 'Ich habe zwei Brüder.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'Drei', translation: 'Three', pronunciation: 'DRY', example: 'Es gibt drei Katzen hier.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'Kaffee', translation: 'Coffee', pronunciation: 'kah-FEH', example: 'Ich trinke jeden Morgen Kaffee.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'Buch', translation: 'Book', pronunciation: 'book', example: 'Ich lese dieses Buch gerne.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'Schule', translation: 'School', pronunciation: 'SHOO-luh', example: 'Meine Schule ist in der Nähe.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'Liebe', translation: 'Love', pronunciation: 'LEE-buh', example: 'Ich liebe meine Familie.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'Glücklich', translation: 'Happy', pronunciation: 'GLICK-lich', example: 'Ich bin heute sehr glücklich.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // ITALIAN VOCABULARY (25+ words)
  static List<VocabularyWord> _italianVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'Ciao', translation: 'Hello/Goodbye', pronunciation: 'CHOW', example: 'Ciao, come stai?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'Arrivederci', translation: 'Goodbye', pronunciation: 'ah-ree-vuh-DEHR-chee', example: 'Arrivederci, a presto!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'Buongiorno', translation: 'Good morning', pronunciation: 'bwon-JOR-noh', example: 'Buongiorno, come va?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'Per favore', translation: 'Please', pronunciation: 'pair fah-VOH-reh', example: 'Un caffè, per favore.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'Grazie', translation: 'Thank you', pronunciation: 'GRAHT-see-eh', example: 'Grazie per il tuo aiuto!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'Prego', translation: 'You\'re welcome', pronunciation: 'PREH-goh', example: 'Prego, è stato un piacere.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'Pane', translation: 'Bread', pronunciation: 'PAH-neh', example: 'Vorrei pane fresco.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'Acqua', translation: 'Water', pronunciation: 'AHK-kwah', example: 'Un bicchiere d\'acqua, per favore.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'Mela', translation: 'Apple', pronunciation: 'MEH-lah', example: 'La mela rossa è deliziosa.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'Casa', translation: 'House', pronunciation: 'KAH-sah', example: 'La mia casa è in città.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'Biblioteca', translation: 'Library', pronunciation: 'bee-blee-oh-TEH-kah', example: 'Vado in biblioteca per studiare.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'Amico', translation: 'Friend', pronunciation: 'ah-MEE-koh', example: 'Il mio amico è molto gentile.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'Famiglia', translation: 'Family', pronunciation: 'fahm-EEL-yah', example: 'La mia famiglia è grande.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'Gatto', translation: 'Cat', pronunciation: 'GAHT-toh', example: 'Il gatto è bellissimo.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'Cane', translation: 'Dog', pronunciation: 'KAH-neh', example: 'Il cane gioca nel parco.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'Uccello', translation: 'Bird', pronunciation: 'oo-CHEL-loh', example: 'L\'uccello canta al mattino.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'Rosso', translation: 'Red', pronunciation: 'ROHS-soh', example: 'Mi piace il colore rosso.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'Blu', translation: 'Blue', pronunciation: 'bloo', example: 'Il cielo è blu.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'Verde', translation: 'Green', pronunciation: 'VEHR-deh', example: 'Le piante sono verdi.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'Uno', translation: 'One', pronunciation: 'OO-noh', example: 'Ho una mela.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'Due', translation: 'Two', pronunciation: 'DOO-eh', example: 'Ho due fratelli.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'Tre', translation: 'Three', pronunciation: 'treh', example: 'Ci sono tre gatti qui.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'Caffè', translation: 'Coffee', pronunciation: 'kah-FEH', example: 'Bevo caffè ogni mattina.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'Libro', translation: 'Book', pronunciation: 'LEE-broh', example: 'Mi piace leggere questo libro.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'Scuola', translation: 'School', pronunciation: 'SKWOH-lah', example: 'La mia scuola è vicino a casa.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'Amore', translation: 'Love', pronunciation: 'ah-MOH-reh', example: 'Amo la mia famiglia.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'Felice', translation: 'Happy', pronunciation: 'feh-LEE-cheh', example: 'Sono molto felice oggi.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // PORTUGUESE VOCABULARY (25+ words)
  static List<VocabularyWord> _portugueseVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'Olá', translation: 'Hello', pronunciation: 'oh-LAH', example: 'Olá, como você está?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'Adeus', translation: 'Goodbye', pronunciation: 'ah-deh-OOS', example: 'Adeus, até logo!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'Bom dia', translation: 'Good morning', pronunciation: 'bom DEE-ah', example: 'Bom dia, como você amanheceu?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'Por favor', translation: 'Please', pronunciation: 'por fah-VOR', example: 'Um café, por favor.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'Obrigado', translation: 'Thank you', pronunciation: 'oh-BREE-gah-doh', example: 'Obrigado pela sua ajuda!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'De nada', translation: 'You\'re welcome', pronunciation: 'duh NAH-dah', example: 'De nada, foi um prazer.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'Pão', translation: 'Bread', pronunciation: 'pown', example: 'Gostaria de pão fresco.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'Água', translation: 'Water', pronunciation: 'AH-gwah', example: 'Um copo de água fria, por favor.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'Maçã', translation: 'Apple', pronunciation: 'mah-SAH', example: 'A maçã vermelha é deliciosa.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'Casa', translation: 'House', pronunciation: 'KAH-sah', example: 'Minha casa fica na cidade.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'Biblioteca', translation: 'Library', pronunciation: 'bee-blee-oh-TEH-kah', example: 'Vou à biblioteca para estudar.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'Amigo', translation: 'Friend', pronunciation: 'ah-MEE-goh', example: 'Meu amigo é muito gentil.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'Família', translation: 'Family', pronunciation: 'fah-MEE-lee-ah', example: 'Minha família é grande.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'Gato', translation: 'Cat', pronunciation: 'GAH-toh', example: 'O gato é muito bonito.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'Cachorro', translation: 'Dog', pronunciation: 'kah-SHOR-roh', example: 'O cachorro brinca no parque.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'Pássaro', translation: 'Bird', pronunciation: 'PAHS-sah-roh', example: 'O pássaro canta pela manhã.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'Vermelho', translation: 'Red', pronunciation: 'vehr-MEH-loh', example: 'Gosto da cor vermelha.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'Azul', translation: 'Blue', pronunciation: 'ah-SOOL', example: 'O céu é azul.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'Verde', translation: 'Green', pronunciation: 'VEHR-duh', example: 'As plantas são verdes.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'Um', translation: 'One', pronunciation: 'oom', example: 'Tenho uma maçã.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'Dois', translation: 'Two', pronunciation: 'doys', example: 'Tenho dois irmãos.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'Três', translation: 'Three', pronunciation: 'trehs', example: 'Há três gatos aqui.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'Café', translation: 'Coffee', pronunciation: 'kah-FEH', example: 'Bebo café todas as manhãs.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'Livro', translation: 'Book', pronunciation: 'LEE-vroh', example: 'Gosto de ler este livro.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'Escola', translation: 'School', pronunciation: 'es-KOH-lah', example: 'Minha escola fica perto de casa.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'Amor', translation: 'Love', pronunciation: 'ah-MOR', example: 'Amo minha família.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'Feliz', translation: 'Happy', pronunciation: 'feh-LEES', example: 'Sou muito feliz hoje.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // MANDARIN VOCABULARY (25+ words)
  static List<VocabularyWord> _mandarinVocabulary() {
    return [
      VocabularyWord(id: '1', word: '你好', translation: 'Hello', pronunciation: 'nǐ hǎo', example: '你好,你好吗?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: '再见', translation: 'Goodbye', pronunciation: 'zài jiàn', example: '再见,我们稍后见!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: '早上好', translation: 'Good morning', pronunciation: 'zǎo shang hǎo', example: '早上好,你睡得好吗?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: '请', translation: 'Please', pronunciation: 'qǐng', example: '一杯咖啡,请。', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: '谢谢', translation: 'Thank you', pronunciation: 'xiè xie', example: '谢谢你的帮助!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: '不客气', translation: 'You\'re welcome', pronunciation: 'bù kè qi', example: '不客气,这很有趣。', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: '面包', translation: 'Bread', pronunciation: 'miàn bāo', example: '我想要新鲜的面包。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: '水', translation: 'Water', pronunciation: 'shuǐ', example: '一杯水,请。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: '苹果', translation: 'Apple', pronunciation: 'píng guǒ', example: '红苹果很好吃。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: '房子', translation: 'House', pronunciation: 'fáng zi', example: '我的房子在城市里。', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: '图书馆', translation: 'Library', pronunciation: 'tú shū guǎn', example: '我去图书馆学习。', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: '朋友', translation: 'Friend', pronunciation: 'péng you', example: '我的朋友很善良。', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: '家庭', translation: 'Family', pronunciation: 'jiā tíng', example: '我的家庭很大。', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: '猫', translation: 'Cat', pronunciation: 'māo', example: '猫很漂亮。', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: '狗', translation: 'Dog', pronunciation: 'gǒu', example: '狗在公园里玩。', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: '鸟', translation: 'Bird', pronunciation: 'niǎo', example: '鸟在早上唱歌。', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: '红色', translation: 'Red', pronunciation: 'hóng sè', example: '我喜欢红色。', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: '蓝色', translation: 'Blue', pronunciation: 'lán sè', example: '天空是蓝色的。', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: '绿色', translation: 'Green', pronunciation: 'lǜ sè', example: '植物是绿色的。', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: '一', translation: 'One', pronunciation: 'yī', example: '我有一个苹果。', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: '二', translation: 'Two', pronunciation: 'èr', example: '我有两个哥哥。', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: '三', translation: 'Three', pronunciation: 'sān', example: '这里有三只猫。', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: '咖啡', translation: 'Coffee', pronunciation: 'kā fēi', example: '我每天早上喝咖啡。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: '书', translation: 'Book', pronunciation: 'shū', example: '我喜欢看这本书。', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: '学校', translation: 'School', pronunciation: 'xué xiào', example: '我的学校离家很近。', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: '爱', translation: 'Love', pronunciation: 'ài', example: '我爱我的家人。', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: '开心', translation: 'Happy', pronunciation: 'kāi xīn', example: '我今天很开心。', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // JAPANESE VOCABULARY (25+ words)
  static List<VocabularyWord> _japaneseVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'こんにちは', translation: 'Hello', pronunciation: 'kon-ni-chi-wa', example: 'こんにちは、お元気ですか?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'さようなら', translation: 'Goodbye', pronunciation: 'sa-yo-u-na-ra', example: 'さようなら、また後で!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'おはよう', translation: 'Good morning', pronunciation: 'o-ha-yo-u', example: 'おはよう、よく眠れましたか?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'ください', translation: 'Please', pronunciation: 'ku-da-sa-i', example: 'コーヒーをください。', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'ありがとう', translation: 'Thank you', pronunciation: 'a-ri-ga-to-u', example: 'ありがとうございました!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'どういたしまして', translation: 'You\'re welcome', pronunciation: 'do-u-i-ta-shi-ma-shi-te', example: 'どういたしまして、喜びです。', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'パン', translation: 'Bread', pronunciation: 'pa-n', example: '新鮮なパンが欲しいです。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: '水', translation: 'Water', pronunciation: 'mi-zu', example: 'コップ一杯の水をください。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'リンゴ', translation: 'Apple', pronunciation: 'rin-go', example: '赤いリンゴがおいしいです。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: '家', translation: 'House', pronunciation: 'ie', example: '私の家は町にあります。', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: '図書館', translation: 'Library', pronunciation: 'to-sho-kan', example: '勉強するために図書館へ行きます。', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: '友達', translation: 'Friend', pronunciation: 'to-mo-da-chi', example: '私の友達はとても親切です。', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: '家族', translation: 'Family', pronunciation: 'ka-zo-ku', example: '私の家族は大きいです。', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: '猫', translation: 'Cat', pronunciation: 'ne-ko', example: '猫はとてもかわいいです。', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: '犬', translation: 'Dog', pronunciation: 'i-nu', example: '犬は公園で遊びます。', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: '鳥', translation: 'Bird', pronunciation: 'to-ri', example: '鳥は朝に歌います。', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: '赤', translation: 'Red', pronunciation: 'a-ka', example: '赤い色が好きです。', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: '青', translation: 'Blue', pronunciation: 'a-o', example: '空は青いです。', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: '緑', translation: 'Green', pronunciation: 'mi-do-ri', example: '植物は緑色です。', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: '一', translation: 'One', pronunciation: 'i-chi', example: 'リンゴが一つあります。', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: '二', translation: 'Two', pronunciation: 'ni', example: '兄弟が二人います。', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: '三', translation: 'Three', pronunciation: 'san', example: '猫が三匹ここにいます。', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'コーヒー', translation: 'Coffee', pronunciation: 'ko-hi', example: '毎朝コーヒーを飲みます。', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: '本', translation: 'Book', pronunciation: 'ho-n', example: 'この本を読むのが好きです。', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: '学校', translation: 'School', pronunciation: 'ga-kko-u', example: '私の学校は家の近くです。', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: '愛', translation: 'Love', pronunciation: 'a-i', example: '私の家族を愛しています。', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: '幸せ', translation: 'Happy', pronunciation: 'shi-a-wa-se', example: '今日はとても幸せです。', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // KOREAN VOCABULARY (25+ words)
  static List<VocabularyWord> _koreanVocabulary() {
    return [
      VocabularyWord(id: '1', word: '안녕하세요', translation: 'Hello', pronunciation: 'an-nyeong-ha-se-yo', example: '안녕하세요, 어떻게 지내세요?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: '안녕히 가세요', translation: 'Goodbye', pronunciation: 'an-nyeong-hi ga-se-yo', example: '안녕히 가세요, 나중에 봐요!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: '좋은 아침', translation: 'Good morning', pronunciation: 'jo-eun a-chim', example: '좋은 아침, 잘 주무셨어요?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: '주세요', translation: 'Please', pronunciation: 'ju-se-yo', example: '커피 한 잔 주세요.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: '감사합니다', translation: 'Thank you', pronunciation: 'gam-sa-hap-ni-da', example: '도와주셔서 감사합니다!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: '천만에요', translation: 'You\'re welcome', pronunciation: 'cheon-man-e-yo', example: '천만에요, 기꺼이 도와드립니다.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: '빵', translation: 'Bread', pronunciation: 'bbang', example: '신선한 빵을 원합니다.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: '물', translation: 'Water', pronunciation: 'mul', example: '물 한 잔 주세요.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: '사과', translation: 'Apple', pronunciation: 'sa-gwa', example: '빨간 사과가 맛있습니다.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: '집', translation: 'House', pronunciation: 'jip', example: '제 집은 도시에 있습니다.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: '도서관', translation: 'Library', pronunciation: 'do-seo-gwan', example: '공부하러 도서관에 갑니다.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: '친구', translation: 'Friend', pronunciation: 'chin-gu', example: '제 친구는 매우 친절합니다.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: '가족', translation: 'Family', pronunciation: 'ga-jok', example: '제 가족은 큽니다.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: '고양이', translation: 'Cat', pronunciation: 'go-yang-i', example: '고양이는 매우 귀엽습니다.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: '개', translation: 'Dog', pronunciation: 'gae', example: '개는 공원에서 놉니다.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: '새', translation: 'Bird', pronunciation: 'sae', example: '새는 아침에 노래합니다.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: '빨강색', translation: 'Red', pronunciation: 'bbalgang-saek', example: '빨강색을 좋아합니다.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: '파랑색', translation: 'Blue', pronunciation: 'parangk-saek', example: '하늘은 파랑색입니다.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: '초록색', translation: 'Green', pronunciation: 'choroksaek', example: '식물은 초록색입니다.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: '하나', translation: 'One', pronunciation: 'ha-na', example: '사과가 하나 있습니다.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: '둘', translation: 'Two', pronunciation: 'dul', example: '형제가 둘 있습니다.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: '셋', translation: 'Three', pronunciation: 'set', example: '고양이가 셋 있습니다.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: '커피', translation: 'Coffee', pronunciation: 'keo-pi', example: '매일 아침 커피를 마십니다.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: '책', translation: 'Book', pronunciation: 'chaek', example: '이 책 읽는 것을 좋아합니다.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: '학교', translation: 'School', pronunciation: 'hak-gyo', example: '제 학교는 집 근처입니다.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: '사랑', translation: 'Love', pronunciation: 'sa-rang', example: '제 가족을 사랑합니다.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: '행복', translation: 'Happy', pronunciation: 'haeng-bok', example: '오늘은 매우 행복합니다.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // RUSSIAN VOCABULARY (25+ words)
  static List<VocabularyWord> _russianVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'Привет', translation: 'Hello', pronunciation: 'pri-vyet', example: 'Привет, как дела?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'До видания', translation: 'Goodbye', pronunciation: 'do vi-da-ni-ya', example: 'До видания, до скорого!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'Доброе утро', translation: 'Good morning', pronunciation: 'do-bro-ye u-tro', example: 'Доброе утро, как ты спал?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'Пожалуйста', translation: 'Please', pronunciation: 'pa-zhal-sta', example: 'Кофе, пожалуйста.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'Спасибо', translation: 'Thank you', pronunciation: 'spa-si-ba', example: 'Спасибо за помощь!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'Не за что', translation: 'You\'re welcome', pronunciation: 'nye za shto', example: 'Не за что, это удовольствие.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'Хлеб', translation: 'Bread', pronunciation: 'khleb', example: 'Я хочу свежий хлеб.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'Вода', translation: 'Water', pronunciation: 'vo-da', example: 'Стакан воды, пожалуйста.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'Яблоко', translation: 'Apple', pronunciation: 'yab-lo-ka', example: 'Красное яблоко вкусное.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'Дом', translation: 'House', pronunciation: 'dom', example: 'Мой дом в городе.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'Библиотека', translation: 'Library', pronunciation: 'bib-li-o-te-ka', example: 'Я иду в библиотеку учиться.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'Друг', translation: 'Friend', pronunciation: 'druk', example: 'Мой друг очень добрый.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'Семья', translation: 'Family', pronunciation: 'sem-ya', example: 'Моя семья большая.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'Кошка', translation: 'Cat', pronunciation: 'kosh-ka', example: 'Кошка очень красивая.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'Собака', translation: 'Dog', pronunciation: 'sa-ba-ka', example: 'Собака играет в парке.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'Птица', translation: 'Bird', pronunciation: 'pti-tsa', example: 'Птица поет по утрам.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'Красный', translation: 'Red', pronunciation: 'kras-ny', example: 'Мне нравится красный цвет.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'Синий', translation: 'Blue', pronunciation: 'si-ny', example: 'Небо синего цвета.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'Зеленый', translation: 'Green', pronunciation: 'ze-le-ny', example: 'Растения зеленые.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'Один', translation: 'One', pronunciation: 'o-din', example: 'У меня одно яблоко.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'Два', translation: 'Two', pronunciation: 'dva', example: 'У меня два брата.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'Три', translation: 'Three', pronunciation: 'tri', example: 'Здесь три кошки.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'Кофе', translation: 'Coffee', pronunciation: 'ko-fe', example: 'Я пью кофе каждое утро.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'Книга', translation: 'Book', pronunciation: 'kni-ga', example: 'Мне нравится читать эту книгу.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'Школа', translation: 'School', pronunciation: 'shko-la', example: 'Моя школа близко к дому.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'Любовь', translation: 'Love', pronunciation: 'lyu-bov', example: 'Я люблю мою семью.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'Счастлив', translation: 'Happy', pronunciation: 'scha-stliv', example: 'Я очень счастлив сегодня.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // ARABIC VOCABULARY (25+ words)
  static List<VocabularyWord> _arabicVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'مرحبا', translation: 'Hello', pronunciation: 'marhaba', example: 'مرحبا، كيف حالك؟', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'وداعا', translation: 'Goodbye', pronunciation: 'wadaaan', example: 'وداعا، إلى اللقاء!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'صباح الخير', translation: 'Good morning', pronunciation: 'sabah al-khair', example: 'صباح الخير، كيف نمت؟', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'من فضلك', translation: 'Please', pronunciation: 'min fadlak', example: 'قهوة من فضلك.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'شكرا', translation: 'Thank you', pronunciation: 'shukran', example: 'شكرا على مساعدتك!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'أهلا وسهلا', translation: 'You\'re welcome', pronunciation: 'ahlan wa sahlan', example: 'أهلا وسهلا، كان سعيدا بالمساعدة.', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'خبز', translation: 'Bread', pronunciation: 'khubz', example: 'أريد خبزا طازجا.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'ماء', translation: 'Water', pronunciation: 'maa', example: 'كأس من الماء من فضلك.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'تفاحة', translation: 'Apple', pronunciation: 'tufaha', example: 'التفاحة الحمراء لذيذة.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'بيت', translation: 'House', pronunciation: 'bayt', example: 'بيتي في المدينة.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'مكتبة', translation: 'Library', pronunciation: 'maktaba', example: 'أذهب إلى المكتبة للدراسة.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'صديق', translation: 'Friend', pronunciation: 'sadiq', example: 'صديقي طيب جدا.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'عائلة', translation: 'Family', pronunciation: 'aailah', example: 'عائلتي كبيرة.', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'قط', translation: 'Cat', pronunciation: 'qat', example: 'القط جميل جدا.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'كلب', translation: 'Dog', pronunciation: 'kalb', example: 'الكلب يلعب في الحديقة.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'طائر', translation: 'Bird', pronunciation: 'taair', example: 'الطائر يغني في الصباح.', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'أحمر', translation: 'Red', pronunciation: 'ahmar', example: 'أحب اللون الأحمر.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'أزرق', translation: 'Blue', pronunciation: 'azraq', example: 'السماء زرقاء.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'أخضر', translation: 'Green', pronunciation: 'akhdar', example: 'النباتات خضراء.', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'واحد', translation: 'One', pronunciation: 'wahid', example: 'لدي تفاحة واحدة.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'اثنان', translation: 'Two', pronunciation: 'ithnaan', example: 'لدي أخوان.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'ثلاثة', translation: 'Three', pronunciation: 'talata', example: 'هناك ثلاثة قطط هنا.', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'قهوة', translation: 'Coffee', pronunciation: 'qahwa', example: 'أشرب القهوة كل صباح.', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'كتاب', translation: 'Book', pronunciation: 'kitaab', example: 'أحب قراءة هذا الكتاب.', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'مدرسة', translation: 'School', pronunciation: 'madrasa', example: 'مدرستي قريبة من البيت.', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'حب', translation: 'Love', pronunciation: 'hubb', example: 'أحب عائلتي.', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'سعيد', translation: 'Happy', pronunciation: 'saeed', example: 'أنا سعيد جدا اليوم.', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }

  // HINDI VOCABULARY (25+ words)
  static List<VocabularyWord> _hindiVocabulary() {
    return [
      VocabularyWord(id: '1', word: 'नमस्ते', translation: 'Hello', pronunciation: 'namaste', example: 'नमस्ते, आप कैसे हैं?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '2', word: 'अलविदा', translation: 'Goodbye', pronunciation: 'alvida', example: 'अलविदा, बाद में मिलेंगे!', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '3', word: 'सुप्रभात', translation: 'Good morning', pronunciation: 'suprabhaat', example: 'सुप्रभात, आप ठीक सोए?', category: 'Greetings', addedAt: DateTime.now()),
      VocabularyWord(id: '4', word: 'कृपया', translation: 'Please', pronunciation: 'kripya', example: 'कॉफी कृपया।', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '5', word: 'धन्यवाद', translation: 'Thank you', pronunciation: 'dhanyavaad', example: 'आपकी मदद के लिए धन्यवाद!', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '6', word: 'स्वागत है', translation: 'You\'re welcome', pronunciation: 'swagat hai', example: 'स्वागत है, यह मेरी खुशी थी।', category: 'Politeness', addedAt: DateTime.now()),
      VocabularyWord(id: '7', word: 'रोटी', translation: 'Bread', pronunciation: 'roti', example: 'मुझे ताजी रोटी चाहिए।', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '8', word: 'पानी', translation: 'Water', pronunciation: 'pani', example: 'एक गिलास पानी कृपया।', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '9', word: 'सेब', translation: 'Apple', pronunciation: 'seb', example: 'लाल सेब स्वादिष्ट है।', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '10', word: 'घर', translation: 'House', pronunciation: 'ghar', example: 'मेरा घर शहर में है।', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '11', word: 'पुस्तकालय', translation: 'Library', pronunciation: 'pustkalay', example: 'मैं पुस्तकालय में पढ़ने जाता हूं।', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '12', word: 'दोस्त', translation: 'Friend', pronunciation: 'dost', example: 'मेरा दोस्त बहुत दयालु है।', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '13', word: 'परिवार', translation: 'Family', pronunciation: 'parivar', example: 'मेरा परिवार बड़ा है।', category: 'People', addedAt: DateTime.now()),
      VocabularyWord(id: '14', word: 'बिल्ली', translation: 'Cat', pronunciation: 'billi', example: 'बिल्ली बहुत सुंदर है।', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '15', word: 'कुत्ता', translation: 'Dog', pronunciation: 'kutta', example: 'कुत्ता पार्क में खेलता है।', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '16', word: 'पक्षी', translation: 'Bird', pronunciation: 'pakshi', example: 'पक्षी सुबह गाता है।', category: 'Animals', addedAt: DateTime.now()),
      VocabularyWord(id: '17', word: 'लाल', translation: 'Red', pronunciation: 'lal', example: 'मुझे लाल रंग पसंद है।', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '18', word: 'नीला', translation: 'Blue', pronunciation: 'neela', example: 'आकाश नीला है।', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '19', word: 'हरा', translation: 'Green', pronunciation: 'hara', example: 'पौधे हरे हैं।', category: 'Colors', addedAt: DateTime.now()),
      VocabularyWord(id: '20', word: 'एक', translation: 'One', pronunciation: 'ek', example: 'मेरे पास एक सेब है।', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '21', word: 'दो', translation: 'Two', pronunciation: 'do', example: 'मेरे दो भाई हैं।', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '22', word: 'तीन', translation: 'Three', pronunciation: 'teen', example: 'यहां तीन बिल्लियां हैं।', category: 'Numbers', addedAt: DateTime.now()),
      VocabularyWord(id: '23', word: 'कॉफी', translation: 'Coffee', pronunciation: 'kafi', example: 'मैं हर सुबह कॉफी पीता हूं।', category: 'Food & Drink', addedAt: DateTime.now()),
      VocabularyWord(id: '24', word: 'किताब', translation: 'Book', pronunciation: 'kitaab', example: 'मुझे यह किताब पढ़ना पसंद है।', category: 'Things', addedAt: DateTime.now()),
      VocabularyWord(id: '25', word: 'स्कूल', translation: 'School', pronunciation: 'skool', example: 'मेरा स्कूल घर के पास है।', category: 'Places', addedAt: DateTime.now()),
      VocabularyWord(id: '26', word: 'प्यार', translation: 'Love', pronunciation: 'pyar', example: 'मैं अपने परिवार से प्यार करता हूं।', category: 'Emotions', addedAt: DateTime.now()),
      VocabularyWord(id: '27', word: 'खुश', translation: 'Happy', pronunciation: 'khush', example: 'मैं आज बहुत खुश हूं।', category: 'Emotions', addedAt: DateTime.now()),
    ];
  }
}
