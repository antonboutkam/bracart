"""Build this vehicle using the shared editable procedural source."""
from pathlib import Path
import runpy,sys
HERE=Path(__file__).resolve().parent
sys.argv=['build_vehicle.py','--',HERE.parent.name]
runpy.run_path(str(HERE.parents[1]/'tools'/'build_vehicle.py'),run_name='__main__')
