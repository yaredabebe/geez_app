class GeezNumber {
  final int number;
  final String symbol;
  final String name;

  GeezNumber({required this.number, required this.symbol, required this.name});
}

class GeezNumberService {
  static final _geezOnes = ['', '፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱'];
  static final _geezTens = ['', '፲', '፳', '፴', '፵', '፶', '፷', '፸', '፹', '፺'];
  static final _geezHundred = '፻';
  static final _geezTenThousand = '፼'; // 10,000

  static final _amharicOnes = ['', 'አንድ', 'ሁለት', 'ሶስት', 'አራት', 'አምስት', 'ስድስት', 'ሰባት', 'ስምንት', 'ዘጠኝ'];
  static final _amharicTens = [
    '',
    'አስር',
    'ሃያ',
    'ሰላሳ',
    'አርባ',
    'አምሳ',
    'ስልሳ',
    'ሰባ',
    'ሰማንያ',
    'ዘጠና'
  ];

  static List<GeezNumber> generateRange(int from, int to) {
    List<GeezNumber> list = [];
    for (int i = from; i <= to; i++) {
      list.add(GeezNumber(
        number: i,
        symbol: _toGeezSymbol(i),
        name: _toAmharicName(i),
      ));
    }
    return list;
  }

  static String _toGeezSymbol(int number) {
    if (number == 0) return '';
    
    // Handle numbers >= 10,000 (using ፼)
    if (number >= 10000) {
      int tenThousands = number ~/ 10000;
      int remainder = number % 10000;
      String result = _toGeezSymbol(tenThousands) + _geezTenThousand;
      if (remainder > 0) result += _toGeezSymbol(remainder);
      return result;
    }
    
    // Handle numbers >= 1000
    if (number >= 1000) {
      int thousands = number ~/ 1000;
      int remainder = number % 1000;
      String result = '';
      
      // Handle thousands
      if (thousands == 1) {
        result = '፲፻'; // 10 hundred = 1000
      } else if (thousands > 1) {
        result = _toGeezSymbol(thousands) + _geezHundred;
      }
      
      // Handle remainder (hundreds and below)
      if (remainder > 0) {
        if (remainder >= 100) {
          result += _toGeezSymbol(remainder);
        } else {
          result += '፻' + _toGeezSymbol(remainder);
        }
      }
      
      return result;
    }

    // Handle numbers >= 100
    if (number >= 100) {
      int hundreds = number ~/ 100;
      int remainder = number % 100;
      
      // Fix: For 100, should be just ፻, not ፩፻
      if (number == 100) return _geezHundred;
      
      String result = '';
      if (hundreds > 1) {
        result = _geezOnes[hundreds];
      }
      result += _geezHundred;
      
      if (remainder > 0) {
        result += _toGeezSymbol(remainder);
      }
      return result;
    }

    // Handle numbers < 100
    int tens = number ~/ 10;
    int ones = number % 10;
    
    if (tens == 0) return _geezOnes[ones];
    if (ones == 0) return _geezTens[tens];
    return _geezTens[tens] + _geezOnes[ones];
  }

  static String _toAmharicName(int number) {
    if (number == 0) return 'ዜሮ';
    
    // Handle numbers >= 10,000
    if (number >= 10000) {
      int tenThousands = number ~/ 10000;
      int remainder = number % 10000;
      String result = _numberToAmharicWord(tenThousands) + ' አስር ሺ';
      if (remainder > 0) result += ' ' + _toAmharicName(remainder);
      return result;
    }
    
    // Handle numbers >= 1000
    if (number >= 1000) {
      int thousands = number ~/ 1000;
      int remainder = number % 1000;
      
      String result;
      if (thousands == 1) {
        result = 'አንድ ሺ';
      } else {
        result = _numberToAmharicWord(thousands) + ' ሺ';
      }
      
      if (remainder > 0) {
        if (remainder < 100) {
          result += ' ' + _toAmharicName(remainder);
        } else {
          result += ' ' + _toAmharicName(remainder);
        }
      }
      return result;
    }

    return _numberToAmharicWord(number);
  }
  
  static String _numberToAmharicWord(int number) {
    if (number >= 100) {
      int hundreds = number ~/ 100;
      int remainder = number % 100;
      
      String result;
      if (hundreds == 1) {
        result = 'አንድ መቶ';
      } else {
        result = _amharicOnes[hundreds] + ' መቶ';
      }
      
      if (remainder > 0) {
        result += ' ' + _numberToAmharicWord(remainder);
      }
      return result;
    }
    
    int tens = number ~/ 10;
    int ones = number % 10;
    
    if (tens == 0) return _amharicOnes[ones];
    if (ones == 0) return _amharicTens[tens];
    
    // Fix: Special case for numbers 11-19
    if (tens == 1) {
      return 'አስር' + (ones > 0 ? ' እና ' + _amharicOnes[ones] : '');
    }
    
    return _amharicTens[tens] + ' ' + _amharicOnes[ones];
  }
}