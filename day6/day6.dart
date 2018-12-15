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

// Iterator for our Grid, so that we can map over the
// multidimentional array.
class GridIterator extends Iterator<GridPoint> {
  int x;
  int y;
  final Grid data;

  GridIterator(this.data);

  @override
  get current {
    if (x == null || y == null) {
      return null;
    }

    return this.data.tile(this.x, this.y);
  }

  @override
  bool moveNext() {
    if (this.x == null && this.y == null) {
      this.x = 0;
      this.y = 0;
      return true;
    }

    if (this.x < this.data._grid.length - 1) {
      this.x += 1;
      return true;
    }

    // at the end of a row...
    this.x = 0;
    this.y += 1;

    if (this.y >= this.data._grid[0].length) {
      this.x = null;
      this.y = null;
      return false;
    }

    return true;
  }
}

// the input coordinates ( problem dataset )
class InputCoordinate extends Point<int> {
  final int index; // position in the input.
  bool isInfinite = false;
  int area = 0;

  InputCoordinate(int x, int y, this.index) : super(x, y);

  @override
  int get hashCode =>
      this.index ^ this.x.hashCode ^ this.y.hashCode ^ this.isInfinite.hashCode;
}

// A point on our grid.
class GridPoint extends Point<int> {
  InputCoordinate
      _closestCoordinate; // the input coordinate, closest to this point
  bool isEquidistant = false;

  int totalDistance = 0; // for part 2.

  GridPoint(int x, int y) : super(x, y);

  InputCoordinate get closestCoordinate => _closestCoordinate;

  set closestCoordinate(InputCoordinate ic) {
    _closestCoordinate = ic;
  }

  int get distanceToClosestCoordinate => _closestCoordinate == null
      ? double.maxFinite.toInt()
      : this.manhattanDistanceTo(_closestCoordinate);

  String toString() {
    return "${this.x}, ${this.y}: ${this.closestCoordinate}";
  }

  int manhattanDistanceTo(Point ic) {
    return md(this, ic);
  }
}

// Grid
// Represents our grid that contains our InputCoordinates
// We must evaluate each point on this grid for both Part 1
// and Part 2. This class makes this simpler.
class Grid extends Object with IterableMixin<GridPoint> {
  static const int EQUIDISTANT = -1;

  final int width;
  final int height;
  List<List<GridPoint>> _grid;

  Iterator<GridPoint> _iterator;

  Grid(this.width, this.height) {
    // [x][y]
    _grid = new List();

    for (var i = 0; i < this.width; i++) {
      List<GridPoint> column = new List<GridPoint>(this.height);
      for (var j = 0; j < this.height; j++) {
        column[j] = new GridPoint(i, j);
      }
      _grid.add(column);
    }

    _iterator = new GridIterator(this);
  }

  GridPoint tile(int x, int y) {
    return _grid[x][y];
  }

  @override
  Iterator<GridPoint> get iterator => _iterator;

  Future<List<int>> getInifinites() async {
    List<int> vals = new List();

    for (var i = 0; i < _grid.length; i++) {
      vals.add(_grid[0][i].closestCoordinate.index);
      vals.add(_grid[this.height - 1][i].closestCoordinate.index);
    }

    for (var i = 1; i < _grid.length - 2; i++) {
      vals.add(_grid[i][0].closestCoordinate.index);
      vals.add(_grid[i][_grid[i].length - 1].closestCoordinate.index);
    }

    return await Observable.fromIterable(vals)
        .where((int i) => i != Grid.EQUIDISTANT)
        .distinctUnique()
        .toList();
  }

  bool pointOnEdge(GridPoint p) =>
      p.x == this.width - 1 || p.y == this.height - 1 || p.x == 0 || p.y == 0
          ? true
          : false;
}

Future<int> solvePart1(Grid grid, List<InputCoordinate> points) async {
  // For each point on the grid, map over the input coordinates
  // and find the closest input coordinate to the grid point.
  await Observable.fromIterable(grid)
      .flatMap((GridPoint gp) =>
              Observable.fromIterable(points).map((InputCoordinate ic) {
                int distance = md(gp, ic);
                if (gp.distanceToClosestCoordinate == distance) {
                  gp.isEquidistant = true;
                } else if (gp.distanceToClosestCoordinate > distance) {
                  gp.closestCoordinate = ic;
                  gp.isEquidistant = false;
                }
              }) // just want one of each GridPoint.
          )
      .drain();

  List<int> counts = new List<int>.filled(points.length, 0);

  // now that the grid has been evaluated
  // eliminate the areas that are inifinite
  int largestArea = await Observable.fromIterable(grid)
      .map((GridPoint gp) {
        if (grid.pointOnEdge(gp)) {
          gp.closestCoordinate.isInfinite = true;
        }
        return gp;
      })
      .where((GridPoint gp) => // apply our filter
          !gp.isEquidistant && !gp.closestCoordinate.isInfinite)
      .map((GridPoint gp) {
        // count to get the size of the area
        counts[gp.closestCoordinate.index]++;
        return counts[gp.closestCoordinate.index];
      })
      .max((int a, int b) => a - b);

  return largestArea;
}

// Part 2
Future<int> solvePart2(Grid grid, List<InputCoordinate> points) async {
  return await new Observable.fromIterable(grid)
      .flatMap((GridPoint gp) {
        return new Observable.fromIterable(points)
            .map((Point p) => md(gp, p))
            .reduce((int acc, int curr) => acc + curr)
            .asObservable()
            .map((int total) {
          gp.totalDistance = total;
          return gp;
        });
      })
      .where((GridPoint gp) => gp.totalDistance < 10000)
      .length;
}

// The solution.
Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day6/input.txt";

  int index = -1;
  List<InputCoordinate> points = await File(path)
      .openRead()
      .transform(Utf8Decoder())
      .transform(LineSplitter())
      .map((String line) {
    List<String> parts = line.split(", ");
    index++;
    return new InputCoordinate(int.parse(parts[0]), int.parse(parts[1]), index);
  }).toList();

  // Work out how big the grid should be.
  Point maxX = await Observable.fromIterable(points)
      .max((Point a, Point b) => a.x - b.x);
  Point maxY = await Observable.fromIterable(points)
      .max((Point a, Point b) => a.y - b.y);
  int size = max(maxX.x, maxY.y) + 1;

  Grid grid;

  // Part1:
  grid = new Grid(size, size);
  int largestArea = await solvePart1(grid, points);
  print("Part 1: ${largestArea}");

  // Part 2
  grid = new Grid(size, size);
  int sizeOfArea = await solvePart2(grid, points);
  print("Part 2: ${sizeOfArea}");
}
