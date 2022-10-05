package types;

import extype.Nullable;

typedef FilePosition = {
    final line:Int;
    final col:Int;
    final ?len:Nullable<Int>;
}
