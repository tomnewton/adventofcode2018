import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day3/input.txt";

  // Pattern for the input lines.
  RegExp exp = new RegExp(r"([0-9]+) \@ ([0-9]+),([0-9]+): ([0-9]+)x([0-9]+)");

  Map<int, Rectangle> rects = new Map();

  // process line by line...
  List<String> lines = new List();
  await File(path).openRead()
  .transform(Utf8Decoder())
  .transform(new LineSplitter())
  .forEach((String line) {
    Iterable<Match> matches = exp.allMatches(line);
    Match first = matches.first;

    // Create rects.
    Rectangle rect = new Rectangle(
      int.parse(first.group(2)), 
      int.parse(first.group(3)), 
      int.parse(first.group(4)), 
      int.parse(first.group(5)));

    rects[int.parse(first.group(1))] = rect;
  });

  // build a bounding box for the cloth
  Rectangle boundingBox = Rectangle.fromPoints(new Point(0,0), new Point(1,1));
  rects.values.forEach((Rectangle r) => boundingBox = boundingBox.boundingBox(r));

  List<List<int>> cloth = new List(boundingBox.width); // cloth[x][y] using a top left 0,0
  for ( var i = 0; i < cloth.length; i++ ) {
    cloth[i] = new List.filled(boundingBox.height, 0);
  }

  int count = 0;
  rects.values.forEach((Rectangle r){ 
    // fill in the cloth
    for ( var x = r.left; x < r.left + r.width; x++ ) {
      for ( var y = r.top; y < r.top + r.height; y++ ) {
        cloth[x][y] += 1;
        if ( cloth[x][y] == 2 ) { // this square is intersected 2 or more times... count it.
          count++;
        }
      }
    }
  });

  print('Count: ${count}'); // 104126


  for ( var key in rects.keys ) {
    Rectangle r = rects[key];
    bool success = true;
    for ( var x = r.left; x < r.left + r.width; x++ ) {
      for ( var y = r.top; y < r.top + r.height; y++ ) {
        // check each square on the cloth.. if they're all 1s, you're good.
        if (cloth[x][y] != 1) {
          success = false;
          break;
        } 
      }
      if ( !success ) {
        break;
      }
    }

    if ( success ) {
      print('Rectangle ${key} is ok.');
      break;
    }
  };
}

