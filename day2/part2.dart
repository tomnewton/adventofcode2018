import 'dart:io';
import 'dart:async';
import 'dart:convert';

/**
 * Returns the index of the only difference in two string
 * or -1 if there are no differences, or more than one difference. 
 */
int indexOfOnlyDifference(String a, String b) {
  if ( a == b ) {
    return -1;
  }
  if ( a.length != b.length ) {
    return -1;
  }

  int diffs = 0; // looking for 1 only.
  int index = 0;

  for ( var i=0; i < a.length; i++ ) {
   if ( a[i] != b[i] ) {
     if (diffs > 0) { // second difference...
       return -1;
     }
     diffs += 1;
     index = i;
   }
  }

  return index; // if we are here, we have only one difference.
}

Future<void> main() async {
  // get input file
  String dir = Directory.current.absolute.path;
  String path = "${dir}/day2/input.txt";


  // process line by line...
  List<String> lines = new List();
  await File(path).openRead()
  .transform(Utf8Decoder())
  .transform(new LineSplitter())
  .forEach((String line) => lines.add(line));

  String code = "";
  for ( var i=0; i < lines.length; i++ ) {
    for ( var j=i+1; j < lines.length; j++ ) {
      int index = indexOfOnlyDifference(lines[i], lines[j]);
      if ( index != -1 ){ 
        code = lines[i].substring(0, index) + lines[i].substring(index+1);
        print(code);
        return;
      };
    }
  }
}