from dataclasses import dataclass


@dataclass
class Record:
    sjis: int
    unicode: int
    comment: str


tablestr = open("./sjis-0213-2004-std.txt").read()

rows = tablestr.splitlines(False)
rows = filter(lambda row: row and row[0] != '#', rows)
rows = map(lambda row: row.split('\t'), rows)
rows_256 = (next(rows) for _ in range(256))
convertible_rows = filter(lambda row: row[1], rows_256)
records = map(lambda row: Record(
    int(row[0], 16), int(row[1][2:], 16), row[2][2:]), convertible_rows)

'''// auto generated.
package;

import extype.Map;

class SjisUnicodeTable {
    public static final sjisToUnicode:Map<Int, Int> = Map.of([
        {0} => {1}, // {2}
    ]);

    public static final unicodeToSjis:Map<Int, Int> = Map.of([
        {1} => {0}, // {2}
    ]);
}
'''

records = list(records)
sjis_to_unicode_definition = [
    '        {0} => {1}, // {2}'.format(record.sjis, record.unicode, record.comment) for record in records]
sjis_to_unicode_definition_str = '\n'.join(sjis_to_unicode_definition)
unicode_to_sjis_definition = [
    '        {0} => {1}, // {2}'.format(record.unicode, record.sjis, record.comment) for record in records]
unicode_to_sjis_definition_str = '\n'.join(unicode_to_sjis_definition)


print(f'''// auto generated.
package;

import extype.Map;

class SjisUnicodeTable {{
    public static final sjisToUnicode:Map<Int, Int> = Map.of([
{sjis_to_unicode_definition_str}
    ]);

    public static final unicodeToSjis:Map<Int, Int> = Map.of([
{unicode_to_sjis_definition_str}
    ]);
}}
''')
