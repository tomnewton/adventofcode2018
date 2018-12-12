import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:core';
import 'package:rxdart/rxdart.dart';

// Manhattan distance
int md(Point p1, Point p2) {
  return (p1.x - p2.x).abs() + (p1.y - p2.y).abs();
}

// Iterator for our Grid.
class GridIterator extends Iterator<GridPoint> {
  int x;
  int y;
  final Grid data;

  GridIterator(this.data);

  @override
  get current {
    if (x == null || y == null ) {
      return null;
    }

    return this.data.tile(this.x, this.y);
  }

  @override
  bool moveNext() {
    if ( this.x == null && this.y == null ) {
      this.x = 0;
      this.y = 0;
      return true;
    }

    if ( this.x < this.data._grid.length-1 ) {
      this.x += 1;
      return true;
    } 
    
    // at the end of a row...
    this.x = 0;
    this.y += 1;

    if ( this.y >= this.data._grid[0].length ) {
      this.x = null;
      this.y = null;
      return false;
    }

    return true;
  }
}

// A point on our grid.
class GridPoint {
  Point p;
  int value;
  int totalDistance = 0; // for part 2.

  GridPoint(this.p, [this.value = Grid.EQUIDISTANT]);

  get x => p.x;
  get y => p.y;

  String toString() {
    return "${this.p}: ${this.value}";
  }
}

// Grid
class Grid extends Object with IterableMixin<GridPoint>{
  static const int EQUIDISTANT = -1;
  
  final int width;
  final int height;
  List<List<GridPoint>> _grid;

  Iterator<GridPoint> _iterator;

  Grid(this.width, this.height) {  // [x][y]
    _grid = new List();
    
    for (var i = 0; i < this.width; i++) {
      List<GridPoint> column = new List<GridPoint>(this.height);
      for ( var j = 0; j < this.height; j++ ) {
        column[j] = new GridPoint(new Point(i, j));
      }
      _grid.add(column);
    }
    
    _iterator = new GridIterator(this);
  }

  GridPoint tile (int x, int y) {
    return _grid[x][y];
  }

  @override
  Iterator<GridPoint> get iterator => _iterator;

  Future<List<int>> getInifinites() async {
    List<int> vals = new List();

    for (var i = 0; i < _grid.length; i++ ) {
      vals.add(_grid[0][i].value);
      vals.add(_grid[this.height-1][i].value);
    }

    for ( var i = 1; i < _grid.length-2; i++ ) {
      vals.add(_grid[i][0].value);
      vals.add(_grid[i][_grid[i].length-1].value);
    }

    return await Observable.fromIterable(vals)
      .where((int i) 
        => i != Grid.EQUIDISTANT)
      .distinctUnique()
      .toList();
  }

  /** 
  String toString() {
    String output = "";
    for ( var x = 0; x < _grid.length; x ++) {
      String row = "";
      for ( var y = 0; y < _grid[x].length; y++ ) {
        if ( _grid[y][x].value != Grid.EQUIDISTANT ) {
          row += _grid[y][x].value.toString() + ",";
        } else {
          row += ".,";
        } 
      }
      output += row+"\n";
    }
    return output;
  }*/
}

// Basic vo to keep track as we scan the grid.
class ScanVO extends Object {
  Point p;
  int distance;
  int index;
  bool duplicate;

  ScanVO(this.p, this.distance, this.index, [this.duplicate = false]);
}



// The solution.
Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day6/input.txt";

  List<Point> points = await File(path)
      .openRead()
      .transform(Utf8Decoder())
      .transform(LineSplitter())
      .map((String line) {
        List<String> parts = line.split(", ");
        return new Point(int.parse(parts[0]), int.parse(parts[1]));
      }).toList();

  // Work out how big the grid should be.
  Point maxX = await Observable.fromIterable(points).max((Point a, Point b) => a.x-b.x);
  Point maxY = await Observable.fromIterable(points).max((Point a, Point b) => a.y-b.y);
  int size = max(maxX.x, maxY.y)+1;


  // Create the grid.
  Grid grid = new Grid(size, size);

  // Loop through all of the points on the grid, and work out 
  // which of our coordinates is closest, but not a duplicate.
  await Observable.fromIterable(grid).flatMap((GridPoint gp) 
    => Observable.fromIterable(points).scan((ScanVO acc, Point curr, int i ) {
      int distance = md(gp.p, curr);
      
      if ( acc == null ) {
        return new ScanVO(curr, distance, i);
      }
      if ( acc.distance < distance ) {
        return acc;
      }
      if ( acc.distance == distance ) {
        return new ScanVO(curr, distance, i, true);
      }
      return new ScanVO(curr, distance, i);
    
    }).map((ScanVO vo) 
      => vo.duplicate ? gp.value = Grid.EQUIDISTANT : gp.value = vo.index))
    .drain();

    /*await Observable.fromIterable(grid).withLatestFrom(
      Observable.fromIterable(points), (GridPoint gp, Point p) 
        => [gp, p])
      .map((List o) => [o, md((o[0] as GridPoint).p, o[1])])
      .map((List o) => );*/


    //Stream<int> a = new Stream.empty();

    // Empty list to track the counts...
    List<int> counts = new List.filled(points.length, 0);

    // Get areas that go to inifinity, we don't want these.
    List<int> border = await grid.getInifinites();

    // now we're going to just count the grid squares and check their values...
    // to work out which one has the biggest area
    for(GridPoint p in grid) {
      if ( p.value != Grid.EQUIDISTANT && !border.contains(p.value) ) {
        counts[p.value] += 1; // count it.
      }
    }

    // Now scan counts for the largest area...
    int largestArea = await Observable.fromIterable(counts).max((int a, int b) => a-b);

    print("Part 1: ");
    print(largestArea);


    // Part 2
    grid = new Grid(size, size);

    int sizeOfArea = await new Observable.fromIterable(grid).flatMap((GridPoint gp) {
      return new Observable.fromIterable(points)
        .map((Point p) => md(gp.p, p))
        .reduce((int acc, int curr) => acc + curr).asObservable()
        .map((int total) { gp.totalDistance = total; return gp;});
    }).where((GridPoint gp) => gp.totalDistance < 10000).length;

    print(sizeOfArea);
}

class ResultVO {
  GridPoint gp;
  
}