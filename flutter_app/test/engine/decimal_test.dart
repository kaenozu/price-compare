import 'package:flutter_test/flutter_test.dart';
import 'package:price_compare_flutter/engine/decimal.dart';

void main() {
  group('Decimal', () {
    group('コンストラクタ', () {
      test('文字列から生成する', () {
        expect(Decimal('0').toPlainString(), '0');
        expect(Decimal('1').toPlainString(), '1');
        expect(Decimal('0.5').toPlainString(), '0.5');
        expect(Decimal('10.25').toPlainString(), '10.25');
        expect(Decimal('-1.5').toPlainString(), '-1.5');
        expect(Decimal('+3').toPlainString(), '3');
        expect(Decimal('.5').toPlainString(), '0.5');
        expect(Decimal('1.').toPlainString(), '1');
      });

      test('無効な文字列で例外を投げる', () {
        expect(() => Decimal(''), throwsFormatException);
        expect(() => Decimal('abc'), throwsFormatException);
        expect(() => Decimal('1.2.3'), throwsFormatException);
        expect(() => Decimal('.'), throwsFormatException);
      });

      test('fromIntで生成する', () {
        expect(Decimal.fromInt(42).toPlainString(), '42');
        expect(Decimal.fromInt(-5).toPlainString(), '-5');
      });
    });

    group('定数', () {
      test('zeroとoneが正しい', () {
        expect(Decimal.zero, Decimal('0'));
        expect(Decimal.one, Decimal('1'));
      });
    });

    group('比較', () {
      test('compareToが正しい順序を返す', () {
        expect(Decimal('1').compareTo(Decimal('2')), lessThan(0));
        expect(Decimal('2').compareTo(Decimal('1')), greaterThan(0));
        expect(Decimal('1').compareTo(Decimal('1')), 0);
      });

      test('演算子が正しく動作する', () {
        expect(Decimal('1') < Decimal('2'), isTrue);
        expect(Decimal('2') > Decimal('1'), isTrue);
        expect(Decimal('1') <= Decimal('1'), isTrue);
        expect(Decimal('2') >= Decimal('1'), isTrue);
      });

      test('等価性が正しい', () {
        expect(Decimal('1.00'), Decimal('1'));
        expect(Decimal('1.00') == Decimal('1'), isTrue);
        expect(Decimal('1.0'), isNot(Decimal('1.1')));
      });
    });

    group('加算', () {
      test('整数同士の加算', () {
        expect((Decimal('1') + Decimal('2')).toPlainString(), '3');
      });

      test('小数を含む加算', () {
        expect((Decimal('0.1') + Decimal('0.2')).toPlainString(), '0.3');
      });

      test('異なるスケールの加算で末尾のゼロが正規化される', () {
        expect((Decimal('1.5') + Decimal('2.50')).toPlainString(), '4');
      });

      test('負数の加算', () {
        expect((Decimal('-1') + Decimal('3')).toPlainString(), '2');
      });
    });

    group('減算', () {
      test('整数同士の減算', () {
        expect((Decimal('5') - Decimal('3')).toPlainString(), '2');
      });

      test('結果が負になる減算', () {
        expect((Decimal('3') - Decimal('5')).toPlainString(), '-2');
      });
    });

    group('乗算', () {
      test('整数同士の乗算', () {
        expect((Decimal('3') * Decimal('4')).toPlainString(), '12');
      });

      test('小数を含む乗算', () {
        expect((Decimal('0.5') * Decimal('0.5')).toPlainString(), '0.25');
      });

      test('負数を含む乗算', () {
        expect((Decimal('-3') * Decimal('4')).toPlainString(), '-12');
      });
    });

    group('除算', () {
      test('整数同士の除算', () {
        expect((Decimal('10') / Decimal('2')).toPlainString(), '5');
      });

      test('割り切れない除算はデフォルトスケールで丸める', () {
        expect((Decimal('1') / Decimal('3')).toPlainString(), '0.3333333333');
      });

      test('divideで結果スケールを指定する', () {
        expect(Decimal('1').divide(Decimal('3'), resultScale: 2).toPlainString(), '0.33');
      });

      test('0除算で例外を投げる', () {
        expect(() => Decimal('1') / Decimal('0'), throwsArgumentError);
      });
    });

    group('単項演算', () {
      test('absが絶対値を返す', () {
        expect(Decimal('-5').abs(), Decimal('5'));
        expect(Decimal('5').abs(), Decimal('5'));
      });

      test('符号反転', () {
        expect((-Decimal('5')).toPlainString(), '-5');
        expect((-Decimal('-3')).toPlainString(), '3');
      });
    });

    group('述語', () {
      test('isZeroが正しい', () {
        expect(Decimal('0').isZero, isTrue);
        expect(Decimal('1').isZero, isFalse);
      });

      test('isPositiveが正しい', () {
        expect(Decimal('1').isPositive, isTrue);
        expect(Decimal('0').isPositive, isFalse);
        expect(Decimal('-1').isPositive, isFalse);
      });

      test('isNegativeが正しい', () {
        expect(Decimal('-1').isNegative, isTrue);
        expect(Decimal('0').isNegative, isFalse);
        expect(Decimal('1').isNegative, isFalse);
      });
    });

    group('スケール正規化', () {
      test('fromUnscaledが末尾のゼロを削除する', () {
        final d = Decimal.fromUnscaled(BigInt.from(1000), 3);
        expect(d.scale, 0);
        expect(d.toPlainString(), '1');
      });

      test('ゼロのスケール正規化', () {
        final d = Decimal.fromUnscaled(BigInt.zero, 5);
        expect(d.toPlainString(), '0');
      });
    });

    group('toPlainString', () {
      test('正の整数', () {
        expect(Decimal('123').toPlainString(), '123');
      });

      test('負の小数', () {
        expect(Decimal('-3.14').toPlainString(), '-3.14');
      });
    });
  });
}
