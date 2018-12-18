import 'dart:async';
import 'dart:convert';
import 'dart:io';

const lookup = {
  "A": 1,
  "B": 2,
  "C": 3,
  "D": 4,
  "E": 5,
  "F": 6,
  "G": 7,
  "H": 8,
  "I": 9,
  "J": 10,
  "K": 11,
  "L": 12,
  "M": 13,
  "N": 14,
  "O": 15,
  "P": 16,
  "Q": 17,
  "R": 18,
  "S": 19,
  "T": 20,
  "U": 21,
  "V": 22,
  "W": 23,
  "X": 24,
  "Y": 25,
  "Z": 26
};

void partOne(Map<String, List<InputInstruction>> m) {
  String result = "";

  while (m.length > 0) {
    List<String> options = new List();

    for (String key in m.keys) {
      if (m[key].length == 0) {
        options.add(key);
      }
    }

    String next;
    if (options.length > 0) {
      options.sort();
      next = options[0];
      m.remove(next);
      result += next;

      for (String key in m.keys) {
        List<InputInstruction> prereqs = m[key];
        for (InputInstruction ii in prereqs) {
          if (ii.prerequisite == next) {
            m[key].remove(ii);
            break;
          }
        }
      }
    }
  }

  print("Part 1: ${result}");
}

// A worker.
class Worker {
  String _label = "";
  int _duration = 0;

  Worker();

  bool get isReady => _duration == 0 && _label == "";
  bool get isWorking => _duration > 0;
  String get label => _label;

  void assignWork(String work) {
    if (this.isReady) {
      _label = work;
      _duration = 60 + lookup[_label.toUpperCase()];
      return;
    }
    throw new Exception("Can't assign work to a busy worker.");
  }

  void tick() {
    if (_duration != 0) {
      _duration--;
    }
  }

  bool isDone() {
    if (_duration == 0 && _label != "") {
      return true;
    }
    return false;
  }

  // prepare to be given work again.
  void reset() {
    _label = "";
  }
}

// A pool of workers that can be assigned work.
class WorkerPool {
  final int size;
  List<Worker> _workers;

  // Create a pool of workers of a given size.
  WorkerPool(this.size) {
    _workers = new List(size);
    int index = 0;
    while (index < size) {
      _workers[index] = new Worker();
      index++;
    }
  }

  // Assign a job to a worker if one is available.
  bool assignWork(String work) {
    for (Worker worker in _workers) {
      if (worker.isReady) {
        worker.assignWork(work);
        return true;
      }
    }
    return false;
  }

  // tick each worker, and check to see if they're
  // finished.
  List<String> doWork() {
    List<String> done = new List();
    for (Worker w in _workers) {
      w.tick();
      if (w.isDone()) {
        done.add(w.label);
        w.reset();
      }
    }
    return done;
  }

  // Check if any workers are active
  bool doingWork() {
    for (Worker w in _workers) {
      if (w.isWorking) {
        return true;
      }
    }
    return false;
  }
}

// Return moves that have no prerequisities that are incomplete.
List<String> getOptions(Map<String, List<InputInstruction>> m) {
  List<String> options = new List();

  for (String key in m.keys) {
    if (m[key].length == 0) {
      options.add(key);
    }
  }

  for (String option in options) {
    m.remove(option);
  }

  options.sort();
  return options;
}

// Solution to Part Two.
void partTwo(Map<String, List<InputInstruction>> m) {
  WorkerPool pool = new WorkerPool(5);
  int seconds = 0;

  // Get the current options...
  List<String> options = getOptions(m);

  while (options.length > 0 || pool.doingWork()) {
    // try to assign work...
    // Assign them in alphabetical order to the workers...
    while (options.length > 0) {
      if (!pool.assignWork(options[0])) {
        break; // no more workers available...
      }
      options.removeAt(0);
    }

    // do work...
    List<String> done = new List();
    while (done.length == 0) {
      done = pool.doWork();
      seconds++;
    }

    for (String w in done) {
      updatePrerequisites(m, w);
    }

    // Each time a worker is finished with a piece of work,
    // see if that created more options... if it did, push them onto the options array
    List<String> newOptions = getOptions(m);
    for (String o in newOptions) {
      options.add(o);
    }
    options.sort();
  }

  print("Part 2: ${seconds}");
}

// Helper function, to loop over the instruction set, and remove prerequisites
// that are complete. if map[key].length == 0 then 'key' has no prerequisites and
// is ready to be processed by a worker.
void updatePrerequisites(Map<String, List<InputInstruction>> m, String s) {
  for (String key in m.keys) {
    List<InputInstruction> toRemove = new List();
    for (InputInstruction ii in m[key]) {
      if (ii.prerequisite == s) {
        toRemove.add(ii);
      }
    }
    for (InputInstruction ii in toRemove) {
      m[key].remove(ii);
    }
  }
}

// VO for the instructions.
class InputInstruction {
  String step;
  String prerequisite;

  InputInstruction(this.step, this.prerequisite);

  String toString() =>
      "Step ${this.prerequisite}  must be finished before step ${this.step} can begin.";
}

// Get the input instructions for the puzzle.
Future<Map<String, List<InputInstruction>>> getInput() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day7/input.txt";
  RegExp exp = new RegExp(" (.) .* (.) ");

  Map<String, List<InputInstruction>> m = new Map();

  await File(path)
      .openRead()
      .transform(Utf8Decoder())
      .transform(new LineSplitter())
      .forEach((String line) {
    Iterable<Match> matches = exp.allMatches(line);
    String step = matches.first.group(2);
    String prereq = matches.first.group(1);
    InputInstruction instr = new InputInstruction(step, prereq);
    // create a map of our InputInstructions
    // keyed on the name of the step
    if (!m.containsKey(step)) {
      m[step] = new List();
    }
    m[step].add(instr);

    if (!m.containsKey(prereq)) {
      m[prereq] = new List();
    }
  });

  for (String k in m.keys) {
    m[k].sort(
        (InputInstruction a, InputInstruction b) => a.step.compareTo(b.step));
  }

  return m;
}

Future<void> main() async {
  partOne(await getInput());

  partTwo(await getInput());
}
