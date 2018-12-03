import 'dart:io';
import 'dart:async';
import 'dart:convert';

enum Counts { none, twice, thrice, both}

Counts check(String input) {
  Map<String, int> counts = new Map<String, int>();
  input.split('').toList().forEach((String char) => 
    counts.containsKey(char) ? 
    counts[char] += 1 :
    counts[char] = 1);

  if ( counts.values.toSet().containsAll([2, 3]) ) {
    return Counts.both;
  } else if ( counts.values.contains(2) ) {
    return Counts.twice;
  } else if ( counts.values.contains(3)) {
    return Counts.thrice;
  }
  return Counts.none;
}

Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day2/input.txt";
  int twice = 0;
  int thrice = 0;

  // process line by line...
  await File(path).openRead()
  .transform(Utf8Decoder())
  .transform(new LineSplitter())
  .forEach((line){
    Counts val = check(line);
    switch(val) {
      case Counts.none:
      break;
      case Counts.twice:
      twice+=1;
      break;
      case Counts.thrice:
      thrice+=1;
      break;
      case Counts.both:
      twice+=1;
      thrice+=1;
      break;
    }
  });

  print("Final: ${twice*thrice}");
}