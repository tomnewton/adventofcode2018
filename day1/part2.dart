import 'dart:io';
import 'dart:async';
import 'dart:convert';

 
Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day1/input.txt";
  int freq = 0;
  Map<int, bool> frequencies = new Map<int, bool>();

  // process line by line...
  var repeat = null;
  while( repeat == null ) {
    await File(path).openRead()
      .transform(Utf8Decoder())
      .transform(new LineSplitter())
      .forEach((line) {
        if ( frequencies.containsKey(freq) ) {
          repeat = freq;
          return;
        } else {
          frequencies[freq] = false;
          freq += int.tryParse(line);
        }
      });
  } 

  print("First repeat: ${repeat}");
}