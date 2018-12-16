import 'dart:async';
import 'dart:convert';
import 'dart:io';

class InputInstruction {
  String step;
  String prerequisite;

  InputInstruction(this.step, this.prerequisite) {}

  String toString() =>
      "Step ${this.prerequisite}  must be finished before step ${this.step} can begin.";
}

Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day7/input.txt";
  RegExp exp = new RegExp(" (.) .* (.) ");

  Map<String, List<InputInstruction>> m = new Map();
  Map<String, InputInstruction> allInstructions = new Map();

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
      allInstructions[step] = instr;
    }
    m[step].add(instr);

    if (!m.containsKey(prereq)) {
      m[prereq] = new List();
      allInstructions[prereq] = new InputInstruction(prereq, null);
    }
  });

  // Now for each step, we have a list of prerequisite instructions
  // these need to be sorted alphabetically... so let's do that...
  for (String k in m.keys) {
    m[k].sort(
        (InputInstruction a, InputInstruction b) => a.step.compareTo(b.step));
  }

  // Now  we just need to figure out where to start... and we should be able to follow this through
  // One of our keys won't have a prerequisite... that is the one we want to start with....
  String result = "";

  while (m.length > 0) {
    List<String> options = new List();
    for (String key in m.keys) {
      if (m[key].length == 0) {
        options.add(key);
      }
    }

    if (options.length == 0) {
      break;
    }

    String next;
    if (options.length > 0) {
      options.sort();
      next = options[0];
      m.remove(next);
      result += next;
    }

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

  print(result);
}
