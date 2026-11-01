"""Render named source iteration with frozen R01 comparison-camera directions."""
from pathlib import Path
import sys
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[4]
sys.path.insert(0,str(ROOT/'art/frontier_illustrated_20261101/ships/pass04/generator'))
import review_ships as review
if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['1']
    review.HERE=HERE/'iterations'/('i0'+args[0]);review.QA=review.HERE/'qa';review.ROOT=ROOT
    review.review('buccaneer_01')
