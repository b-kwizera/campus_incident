import 'package:campus_incident/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('accepts ALU student and staff emails', () {
      expect(Validators.email('a.b@alustudent.com'), isNull);
      expect(Validators.email('Staff@AluEducation.com'), isNull);
    });
    test('rejects other domains, bad format and empty', () {
      expect(Validators.email('x@gmail.com'), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
  });

  group('password', () {
    test('requires length and a digit', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('longpassword'), isNotNull);
      expect(Validators.password('longpass1'), isNull);
    });
  });

  group('incident fields', () {
    test('title', () {
      expect(Validators.title(''), isNotNull);
      expect(Validators.title('abc'), isNotNull);
      expect(Validators.title('Broken projector'), isNull);
    });
    test('description', () {
      expect(Validators.description('too short'), isNotNull);
      expect(Validators.description('The tap has been leaking all day'), isNull);
    });
  });
}
