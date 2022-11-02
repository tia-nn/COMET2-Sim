package casl2.parser;

import extype.Nullable;
import types.FilePosition;

// @:using(casl2.parser.ParseResult.ParseResultTools)
enum ParseResult<T> {
    Success(result:T, position:FilePosition);
    Error(position:FilePosition, message:String);
    Warning(tmpResult:T, position:FilePosition, message:String);
}

// enum ParseError {
//     Warning(pos:FilePosition, message:String);
//     Fail(pos:FilePosition, message:String);
// }

class ParseResultTools {
    //     public static function merge<A, B, R>(a:ParseResult<A>, b:ParseResult<B>, mergeFn:(Nullable<A>, Nullable<B>) -> R):ParseResult<R> {
    //         return switch (a) {
    //             case Success(resultA, positionA):
    //                 switch (b) {
    //                     case Success(resultB, positionB):
    //                         Success(mergeFn(resultA, resultB), mergePosition(positionA, positionB));
    //                     case Error(tmpResult, positionB, errors):
    //                         Error(mergeFn(resultA, tmpResult), mergePosition(positionA, positionB), errors);
    //                 }
    //             case Error(tmpResultA, positionA, errorsA):
    //                 switch (b) {
    //                     case Success(resultB, positionB):
    //                         Error(mergeFn(tmpResultA, resultB), mergePosition(positionA, positionB), errorsA);
    //                     case Error(tmpResultB, positionB, errorsB):
    //                         Error(mergeFn(tmpResultA, tmpResultB), mergePosition(positionA, positionB), errorsA.concat(errorsB));
    //                 }
    //         }
    //     }
    //     static function mergePosition(a:FilePosition, b:FilePosition):FilePosition {
    //         if (a.line != b.line)
    //             trace("warning: 違う行のParseResultをマージしています.");
    //         return {
    //             line: a.line,
    //             col: a.col,
    //             len: b.col - a.col + b.len.getOrElse(0)
    //         };
    //     }
    public static function getPosition<A>(pos:ParseResult<A>):FilePosition {
        return switch (pos) {
            case Success(result, position):
                position;
            case Error(position, errors):
                position;
            case Warning(tmpResult, position, message):
                position;
        }
    }
}
