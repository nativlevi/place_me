List<Map<String, String>> parseCsvContent(String content) {
  final lines = content
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.length < 2) throw Exception('Not enough lines in csv');

  String headerLine = lines.first;
  if (headerLine.startsWith('\uFEFF')) {
    headerLine = headerLine.substring(1); // הסרת BOM
  }

  final header = headerLine.split(',');
  final nameIdx = header.indexOf('name');
  final phoneIdx = header.indexOf('phone');
  if (nameIdx == -1 || phoneIdx == -1) throw Exception('Missing columns');

  final tmp = <Map<String, String>>[];
  for (var i = 1; i < lines.length; i++) {
    final cols = lines[i].split(',');
    if (cols.length > [nameIdx, phoneIdx].reduce((a, b) => a > b ? a : b)) {
      final name = cols[nameIdx].trim();
      final phone = cols[phoneIdx].trim();
      if (name.isNotEmpty && phone.isNotEmpty) {
        tmp.add({'name': name, 'phone': phone});
      }
    }
  }
  return tmp;
}
