library mysql_warehouse.mysql;

import 'dart:async';
import 'dart:collection';
import 'package:sqljocky/sqljocky.dart';
import 'package:warehouse/sql.dart';
import 'package:warehouse/adapters/sql.dart';

export 'package:sqljocky/sqljocky.dart' show ConnectionPool;

handleResult(Results results) async {
  var documents = {};
  for (var row in await results.toList()) {
    var document = new HashMap();
    var join = new HashMap();
    var table;

    for (var i = 0; i < results.fields.length; i++) {
      var field = results.fields[i];
      if (table == null) {
        table = field.table;
      }

      if (table != field.table) {
        if (row[i] == null) continue;

        if (!join.containsKey(field.table)) {
          join[field.table] = new HashMap();
        }
        join[field.table][field.name] = row[i];
      } else {
        document[field.name] = row[i];
      }
    }

    if (documents.containsKey(row[0])) {
      join.forEach((table, columns) {
        if (documents[row[0]][table] is! List) {
          documents[row[0]][table] = [documents[row[0]][table]];
        }
        documents[row[0]][table].add(columns);
      });
    } else {
      join.forEach((table, columns) {
        document[table] = columns;
      });

      documents[row[0]] = document;
    }
  }
  return documents.values;
}

class Mysql extends SqlDbBase {
  final ConnectionPool pool;

  Mysql(this.pool);

  @override
  Future sql(String sql, {List parameters, bool returnCreated: false}) async {
    var result = await pool.prepareExecute(sql, parameters);
    if (returnCreated) {
      return result.insertId;
    }
    return handleResult(result);
  }

  @override
  Future<SqlTransaction> startTransaction() async {
    var transaction = await pool.startTransaction();
    return new MysqlTransaction(transaction);
  }
}

class MysqlTransaction extends SqlTransaction {
  final Transaction transaction;

  MysqlTransaction(this.transaction);

  @override
  Future<List> commit() => transaction.commit();

  @override
  Future rollback() => transaction.rollback();

  @override
  Future sql(String sql, {List parameters, bool returnCreated: false}) async {
    var result = await transaction.prepareExecute(sql, parameters);
    if (returnCreated) {
      return result.insertId;
    }
    return handleResult(result);
  }
}
