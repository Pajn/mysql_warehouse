library warehouse.test.mock_conformance;

import 'package:unittest/unittest.dart';
import 'package:warehouse/adapters/conformance_tests.dart';
import 'package:warehouse/sql.dart';
import 'package:mysql_warehouse/mysql_warehouse.dart';

Mysql db;

class TestConfiguration extends SimpleConfiguration {
  onTestResult(TestCase result) {
    print(formatResult(result).trim());
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
                 String uncaughtError) {
    // Show the summary.
    print('');

    if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
      print('No tests found.');
      // This is considered a failure too.
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      print('All $passed tests passed.');
    } else {
      if (uncaughtError != null) {
        print('Top-level uncaught error: $uncaughtError');
      }
      print('$passed PASSED, $failed FAILED, $errors ERRORS');
    }

    db.pool.close();
  }
}

main() async {
  unittestConfiguration = new TestConfiguration();

  var pool = new ConnectionPool(user: 'root', password: 'pass');
  await pool.prepareExecute('DROP DATABASE IF EXISTS warehouse_mysql_test', []);
  await pool.prepareExecute('CREATE DATABASE warehouse_mysql_test', []);
  pool.close();

  pool = new ConnectionPool(
      user: 'root',
      password: 'pass',
      db: 'warehouse_mysql_test'
  );
  db = new Mysql(pool);

  await registerModels(db);
  runConformanceTests(
          () => new SqlDbSession(db),
          (session, type) => new SqlRepository.withTypes(session, [type])
  );
}
