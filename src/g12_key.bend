# Duplicate-key format lock. Not an IGD run.
# Bend rounds each decision variable to 12 decimal places
# (round(x * 1e12) / 1e12). C# DecisionKey is ToString("G12"),
# 12 significant digits. The third component 1.234567e-8 is inside
# the unit box and is not preserved: the key prints 1.2346e-8 while
# F32.show of the same literal keeps 1.234567e-8. The key format
# stays 12 decimal places.

import Base
import ./util.bend as Util

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("g12 " ++ Util.show_f32s(Util.g12_vec([1.0, 0.5, 1.234567e-8])))
    IO.print("raw " ++ F32.show(1.234567e-8))
