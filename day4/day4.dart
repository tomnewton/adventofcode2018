import 'dart:io';
import 'dart:async';
import 'dart:convert';

// The input rows in input.txt are one of three types.
enum GuardAction {wake, sleep, startDuty}

// Before we can work with the data, 
// we have to sort the raw events from the input.
// This class is a value object for the input rows 
// so that we can easily sort them. 
class RawEvent {
  DateTime dt;
  GuardAction action;
  String guardId; 

  RawEvent(String dateTime, String action, [String guardId]) {
    this.dt = DateTime.parse(dateTime);
    if ( guardId != null ) {
      this.action = GuardAction.startDuty;
      this.guardId = guardId;
    } else {
      if ( action.contains('wake')) {
        this.action = GuardAction.wake;
      } else if ( action.contains('sleep')) {
        this.action = GuardAction.sleep;
      }
    }
  }
}


// This class holds information we have about each guard 
// and their sleeping patterns.
class GuardNfo {
  String id;
  List<int> _sleepByMinute;

  GuardNfo(String id){
    this.id = id;
    _sleepByMinute = new List.filled(60, 0);
  }

  void recordSleep(RawEvent start, RawEvent end) {
    int startMin = start.dt.minute;
    int endMin = end.dt.minute;

    for ( var i = startMin; i < endMin; i++) {
      _sleepByMinute[i] += 1;
    }
  }

  int get totalMinutesAsleep {
    int total = 0;
    for ( var i=0; i < _sleepByMinute.length; i++ ) {
      total += _sleepByMinute[i];
    }
    return total;
  }

  int get mostSleepyMinute {
    int max = 0;
    int minute = 0;
    for ( var i=0; i < _sleepByMinute.length; i++ ) {
      if ( _sleepByMinute[i] > max ) {
        minute = i;
        max = _sleepByMinute[i];
      }
    }
    return minute;
  }

  int get mostSleepyMinuteFrequency {
    int m = this.mostSleepyMinute;
    return _sleepByMinute[m];
  }

  String toString() {
    return 'Guard #${this.id}';
  }
}

// The solution.
Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day4/input.txt";

  // Pattern for the input lines.
  RegExp exp = new RegExp(r"([0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+)] (Guard #([0-9]+) begins shift|falls asleep|wakes up)");

  // RawNfo to sort
  List<RawEvent> data = new List();
  
  // process line by line...
  // gather the raw events so we can sort them by date
  await File(path).openRead()
  .transform(Utf8Decoder())
  .transform(new LineSplitter())
  .forEach((String line) {
    Iterable<Match> matches = exp.allMatches(line);
    Match first = matches.first;
    
    if ( first.groupCount == 3 ) { // Guard coming on duty..
      data.add(new RawEvent(first.group(1), first.group(2), first.group(3)));
    } else {
      data.add(new RawEvent(first.group(1), first.group(2)));
    }
  });

  // Sort the events by date...
  data.sort((RawEvent a, RawEvent b) => a.dt.compareTo(b.dt));

  // Guards
  Map<String, GuardNfo> guardNfo = new Map();
  
  // Proces the events and build out our picture of each guards 
  // sleeping habits. 
  GuardNfo currentGuard;
  RawEvent sleepEvent;

  for( var i = 0; i < data.length; i++ ) { 
    RawEvent event = data[i];
    if ( event.guardId != null ) {
      if ( !guardNfo.containsKey(event.guardId)) {
        guardNfo[event.guardId] = new GuardNfo(event.guardId);
      }
      // Each time we see a raw event with a guard id, we switch the 
      // currentGuard so that we can add sleep times.
      currentGuard = guardNfo[event.guardId];
      continue;
    } 

    // if we are here, this is a sleep or awake Action.
    // record it to the guard
    switch(event.action) {
      case GuardAction.sleep:
        sleepEvent = event;
        break;
      case GuardAction.wake:
        currentGuard.recordSleep(sleepEvent, event);
        break;
      case GuardAction.startDuty:
        break;
    }
  }

  // now we have all of our guards, and their sleep times recorded.
  // sort by length of sleep
  List<GuardNfo> guardList = guardNfo.values.toList();
  guardList.sort((GuardNfo a, GuardNfo b) => b.totalMinutesAsleep.compareTo(a.totalMinutesAsleep));

  print('Part 1:');
  print('Guard with most minutes asleep total: ${guardList[0]} with ${guardList[0].totalMinutesAsleep} minutes');
  print('The sleepiest minute for this guard is: minute ${guardList[0].mostSleepyMinute}');
  print('Anser: ${guardList[0].mostSleepyMinute * int.parse(guardList[0].id)}');
  
  // Part 2
  GuardNfo g = guardList[0];
  guardList.forEach((GuardNfo guard) {
    if ( g.mostSleepyMinuteFrequency < guard.mostSleepyMinuteFrequency ) {
      g = guard;
    }
  });

  print('Part 2:');
  print('Guard with the most commonly slept through minute is ${g} with ${g.mostSleepyMinuteFrequency} during minute ${g.mostSleepyMinute}');
  print('Anser: ${int.parse(g.id) * g.mostSleepyMinute}');
}
