import 'dart:io';
import 'dart:async';
import 'dart:convert';

 
Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day1/input.txt";
  int freq = 0;

  // process line by line...
  await File(path).openRead()
  .transform(Utf8Decoder())
  .transform(new LineSplitter())
  .forEach((line) => freq += int.tryParse(line));

  print("Final: ${freq}");
}