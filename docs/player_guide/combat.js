/* Player-facing model of the normal ground-shot path. See SOURCE_NOTES.md. */
(function(root){
  'use strict';
  const weapons={pistol:{name:'Pistole',chance:.40,damage:18,range:8,band:[.10,-.15,0]},smg:{name:'Maschinenpistole',chance:.40,damage:25,range:10,band:[.15,-.10,0]},rifle:{name:'Sturmgewehr',chance:.45,damage:40,range:25,band:[0,.05,-.10]},sniper:{name:'Scharfschützengewehr',chance:.55,damage:60,range:42,band:[-.20,0,.10]},rail_gun:{name:'Schienenkanone',chance:.35,damage:70,range:20,band:[-.10,0,-.05]},rocket_launcher:{name:'Raketenwerfer',chance:.30,damage:90,range:18,band:[-.10,0,0]}};
  const NEAR_MAX=6,MID_MAX=18; // Entfernungszonen in Feldern: nah bis 6, mittel 7-18, fern ab 19 (wie WeaponData)
  const clamp=(x,a,b)=>Math.min(b,Math.max(a,x));
  const finite=(x,fallback=0)=>Number.isFinite(Number(x))?Number(x):fallback;
  function calculate(input={}){
    const weapon=weapons[input.weapon]||weapons.rifle;
    const accuracy=clamp(finite(input.accuracy,50)/100,0,1);
    const support=clamp(finite(input.support),-12,22)/100;
    const own=clamp(finite(input.ownCover)/100,0,1);
    const target=input.flank?0:clamp(finite(input.targetCover)/100,0,.8);
    const height=clamp(finite(input.height),-2,2);
    const heightBonus=height>0?height*.10:height*.05;
    const distance=Math.max(0,finite(input.distance,NEAR_MAX));
    const zone=distance<=NEAR_MAX?0:distance<=MID_MAX?1:2;
    const rangeBonus=(weapon.band||[0,0,0])[zone];
    const attack=finite(input.attack)/100,profile=finite(input.profile)/100,evasion=finite(input.evasion)/100;
    let base=weapon.chance;
    if(Math.abs(support*100)>.001)base=clamp(base+support,.02,.98);
    if(input.spotted)base=clamp(base-.15,.02,.98);
    if(input.flank)base=clamp(base+.20,.02,.98);
    const raw=base*(.5+accuracy)+attack+profile+heightBonus+rangeBonus+.05*own-evasion-.35*target;
    const standing=clamp(raw,.05,.95);
    const movement=input.moving?.65+.30*accuracy:1;
    // Decimal teaching examples must not turn equality into a hit due to binary rounding.
    const chance=Math.round(clamp(standing*movement,.05,.95)*1e12)/1e12;
    const damageFactor=Math.max(Math.max(0,finite(input.baseDamage,1))*(input.flank?1.3:1)+attack-.20*target,.10)*Math.max(0,finite(input.targetDamage,1));
    const damage=Math.max(Math.round(weapon.damage*damageFactor),0);
    const roll=clamp(finite(input.roll,.3),0,1-Number.EPSILON);
    return {base,raw,standing,movement,chance,damage,roll,hit:roll<chance,targetCover:target,heightBonus,rangeBonus,zone:['near','mid','far'][zone]};
  }
  root.GuideCombat={weapons,calculate};
  if(typeof module!=='undefined')module.exports=root.GuideCombat;
})(typeof globalThis!=='undefined'?globalThis:this);
