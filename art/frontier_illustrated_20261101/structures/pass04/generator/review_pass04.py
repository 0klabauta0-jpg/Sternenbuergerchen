"""Reuse the verified P03 review cameras against separate P04 source files."""
from pathlib import Path
import sys
HERE=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(HERE.parent/'pass03/generator'))
import review_cutaways as review
review.HERE=HERE;review.ROOT=HERE.parents[3];review.QA=HERE/'qa'
ASSETS=['habitat_cutaway_01','freihafen_hall_01','utility_fuel_01']
if __name__=='__main__':
    for asset in ASSETS:review.review(asset)
