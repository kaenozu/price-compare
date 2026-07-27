import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';
import 'package:price_compare_flutter/engine/money.dart';

void main() {
  group('Money', () {
    group('コンストラクタ', () {
      test('文字列から生成する', () {
        expect(Money.of('1000').amount, Decimal('1000'));
      });

      test('intから生成する', () {
        expect(Money.fromInt(500).amount, Decimal('500'));
      });

      test('zero定数が正しい', () {
        expect(Money.zero.amount, Decimal.zero);
      });
    });

    group('加算', () {
      test('同額の加算', () {
        final result = Money.of('300') + Money.of('200');
        expect(result.amount.toPlainString(), '500');
      });

      test('zeroとの加算', () {
        final result = Money.of('100') + Money.zero;
        expect(result.amount.toPlainString(), '100');
      });
    });

    group('減算', () {
      test('結果が正になる', () {
        final result = Money.of('500') - Money.of('300');
        expect(result.amount.toPlainString(), '200');
      });

      test('結果が負になる', () {
        final result = Money.of('300') - Money.of('500');
        expect(result.amount.toPlainString(), '-200');
      });
    });

    group('乗算', () {
      test('Decimal係数での乗算', () {
        final result = Money.of('1000') * Decimal('0.1');
        expect(result.amount.toPlainString(), '100');
      });
    });

    group('除算', () {
      test('Money同士の除算で比率を返す', () {
        final result = Money.of('300') / Money.of('100');
        expect(result.toPlainString(), '3');
      });
    });

    group('比較', () {
      test('compareToが正しい', () {
        expect(Money.of('100').compareTo(Money.of('200')), lessThan(0));
        expect(Money.of('200').compareTo(Money.of('100')), greaterThan(0));
        expect(Money.of('100').compareTo(Money.of('100')), 0);
      });
    });

    group('述語', () {
      test('isZero', () {
        expect(Money.zero.isZero, isTrue);
        expect(Money.of('1').isZero, isFalse);
      });

      test('isPositive', () {
        expect(Money.of('1').isPositive, isTrue);
        expect(Money.of('-1').isPositive, isFalse);
      });

      test('isNegative', () {
        expect(Money.of('-1').isNegative, isTrue);
        expect(Money.of('1').isNegative, isFalse);
      });
    });

    group('等価性', () {
      test('同じ金額は等しい', () {
        expect(Money.of('100'), Money.of('100'));
      });

      test('異なる金額は等しくない', () {
        expect(Money.of('100'), isNot(Money.of('200')));
      });
    });

    test('absが絶対値を返す', () {
      expect(Money.of('-500').abs(), Money.of('500'));
      expect(Money.of('500').abs(), Money.of('500'));
    });

    test('toStringが円を付けて表示する', () {
      expect(Money.of('1000').toString(), '1000円');
    });
  });
}
