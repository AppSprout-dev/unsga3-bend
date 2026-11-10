# Bend GPU-bang associate bench (`map_nearest.go!`). Isolated experiment, not Run.
# Default matches the small product fixture so outputs can be compared.
import Base
import ./assoc_map.bend as M

def main() -> IO(Unit):
  M.run(8n, 5n, 3n, 1n, 0n, 1n, 1n, True{})
