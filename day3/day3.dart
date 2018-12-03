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

  // Will hold all the rects we read in from the input file.
  Map<int, Rectangle> rects = new Map();

  // process line by line...
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

  // build a bounding box for the cloth based on the rects we read in from input.txt
  Rectangle boundingBox = Rectangle.fromPoints(new Point(0,0), new Point(1,1));
  rects.values.forEach((Rectangle r) => boundingBox = boundingBox.boundingBox(r));

  // Create a two dimensional array to represent our cloth
  // built from the bounding box's dimensions. 
  // That is all the bounding box is used for.
  List<List<int>> cloth = new List(boundingBox.width); // cloth[x][y] using a top left 0,0
  for ( var i = 0; i < cloth.length; i++ ) {
    cloth[i] = new List.filled(boundingBox.height, 0);
  }

  int count = 0; // we are going to count squares that are intersected 2 or more times.

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

  print('PART 1: ${count}'); // 104126

  // START OF PART 2

  for ( var key in rects.keys ) {
    Rectangle r = rects[key];
    bool success = true;
    
    // Loop over this rect on the cloth, and see if it is 
    // the one that doesn't overlap. It will be the one that doesn't 
    // overlap if all the squares it covers == 1.
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

    if ( success ) { // if you're here, you've found it.
      print('PART 2: Rectangle ${key}');
      break;
    }
  };
}

