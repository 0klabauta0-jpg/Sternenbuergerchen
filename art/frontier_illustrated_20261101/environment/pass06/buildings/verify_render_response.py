"""Image-response check only; quantitative shader response is not an art score."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
HERE=Path(__file__).resolve().parent
def main():
    q=HERE/'qa';rows=[]
    for kind in ['habitat_front','hall_front','ensemble_game']:
        def pixels(revision):return np.asarray(Image.open(q/f'native_{revision}_{kind}.png').convert('RGB'),dtype=np.float64)
        before,off,after=pixels('before'),pixels('wear_disabled'),pixels('after')
        control=float(np.abs(before-off).mean());change=np.abs(off-after)
        mean=float(change.mean());fraction=float((change.mean(axis=2)>4).mean())
        assert control<0.05,(kind,'zero-wear PBR route changed the baseline',control)
        assert mean>0.5 and fraction>0.03,(kind,'wear response absent or too localized',mean,fraction)
        rows.append({'view':kind,'standard_to_zero_wear_mean_rgb_delta_8bit':control,'zero_wear_to_enabled_mean_rgb_delta_8bit':mean,'enabled_max_channel_delta_8bit':float(change.max()),'fraction_pixels_rgb_mean_delta_above4':fraction})
    report={'passed':6,'failed':0,'scope':'Same static camera/light, whole-image deltas incl. unchanged background; tests clean PBR-route equivalence and actual nontrivial shader response, not artistic quality. Isolated probe shadow dither remains present in both states.','views':rows}
    (q/'render_response.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print('BUILDING_WEAR_RENDER_RESPONSE '+json.dumps(report))
if __name__=='__main__':main()
