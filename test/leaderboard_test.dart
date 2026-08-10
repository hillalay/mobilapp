import 'package:flutter_test/flutter_test.dart';
import 'package:mobilapp/features/leaderboard/leaderboard_page.dart';

void main() {
  String fmt(int seconds) =>
      LeaderboardRow(username: 'x', stopwatchSeconds: seconds).formatted;

  test('süre "X sa Y dk" biçiminde gösterilir', () {
    expect(fmt(0), '0 sa 0 dk');
    expect(fmt(59), '0 sa 0 dk'); // dakikanın altı yuvarlanmaz, kırpılır
    expect(fmt(60), '0 sa 1 dk');
    expect(fmt(3600), '1 sa 0 dk');
    expect(fmt(8100), '2 sa 15 dk');
    expect(fmt(86399), '23 sa 59 dk');
  });
}
