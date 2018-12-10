import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';

// Result VO.
class Result {
  final String char;
  final int length;

  Result(this.char, this.length);

  String toString() {
    return "Remove ${this.char} to get chain length of ${this.length}";
  }
}

// Reducer func, processes the stream of characters
// from the chain.
String reducer(String prev, String el) {
  if (prev == null) {
    return el;
  }

  String last = prev[prev.length - 1];

  if (last.toLowerCase() == el.toLowerCase() && last != el) {
    if (prev.length == 1) {
      return null;
    }
    return prev.substring(0, prev.length - 1);
  }

  return prev + el;
}

// The solution.
Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day5/input.txt";

  String code = await File(path)
      .openRead()
      .transform(Utf8Decoder())
      .transform(LineSplitter())
      .first;

  List<String> chars = code.split("");

  String g = await Observable.fromIterable(chars).reduce(reducer);

  // Part 1.
  print(g.length);

  Result r = await Observable.fromIterable(chars)
      .asyncMap((String el) => el.toLowerCase())
      .distinctUnique()
      .flatMap((String toRemove) {
    return Observable.fromIterable(chars)
        .where((String el) =>
            el == toRemove || el.toLowerCase() == toRemove ? false : true)
        .reduce(reducer)
        .asObservable()
        .flatMap((String result) =>
            Observable.just(new Result(toRemove, result.length)));
  }).min((Result a, Result b) => a.length - b.length);

  // Part 2.
  print(r);
}