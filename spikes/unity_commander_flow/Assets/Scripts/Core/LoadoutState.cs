using System;

namespace SternenBuergerUnitySpike.Core
{
    public sealed class LoadoutState
    {
        public LoadoutState(WeaponId primary, WeaponId support, ArmorClass armor)
        {
            Primary = primary;
            Support = support;
            Armor = armor;
        }

        public WeaponId Primary { get; private set; }
        public WeaponId Support { get; private set; }
        public ArmorClass Armor { get; private set; }

        public static LoadoutState DefaultFor(Role role)
        {
            if (role == Role.Medic)
            {
                return new LoadoutState(WeaponId.Smg, WeaponId.MedicTool, ArmorClass.Medium);
            }

            if (role == Role.Engineer)
            {
                return new LoadoutState(WeaponId.Rifle, WeaponId.None, ArmorClass.Medium);
            }

            if (role == Role.Leader)
            {
                return new LoadoutState(WeaponId.Rifle, WeaponId.None, ArmorClass.Medium);
            }

            return new LoadoutState(WeaponId.Smg, WeaponId.None, ArmorClass.Light);
        }

        public void CyclePrimary()
        {
            switch (Primary)
            {
                case WeaponId.Smg:
                    Primary = WeaponId.Rifle;
                    break;
                case WeaponId.Rifle:
                    Primary = WeaponId.Sniper;
                    break;
                case WeaponId.Sniper:
                    Primary = WeaponId.RocketLauncher;
                    break;
                case WeaponId.RocketLauncher:
                    Primary = WeaponId.None;
                    break;
                default:
                    Primary = WeaponId.Smg;
                    break;
            }
        }

        public void CycleSupport()
        {
            switch (Support)
            {
                case WeaponId.None:
                    Support = WeaponId.MedicTool;
                    break;
                default:
                    Support = WeaponId.None;
                    break;
            }
        }

        public void CycleArmor()
        {
            switch (Armor)
            {
                case ArmorClass.Light:
                    Armor = ArmorClass.Medium;
                    break;
                case ArmorClass.Medium:
                    Armor = ArmorClass.Heavy;
                    break;
                default:
                    Armor = ArmorClass.Light;
                    break;
            }
        }

        public float SpeedMultiplier
        {
            get
            {
                float value = 1f;
                if (Armor == ArmorClass.Medium)
                {
                    value -= 0.08f;
                }
                else if (Armor == ArmorClass.Heavy)
                {
                    value -= 0.18f;
                }

                if (Primary == WeaponId.RocketLauncher)
                {
                    value -= 0.12f;
                }
                else if (Primary == WeaponId.Sniper)
                {
                    value -= 0.05f;
                }

                return Math.Max(0.55f, value);
            }
        }

        public float Firepower
        {
            get
            {
                switch (Primary)
                {
                    case WeaponId.Smg:
                        return 0.75f;
                    case WeaponId.Rifle:
                        return 1f;
                    case WeaponId.Sniper:
                        return 1.2f;
                    case WeaponId.RocketLauncher:
                        return 1.55f;
                    default:
                        return 0.15f;
                }
            }
        }

        public float WeightScore
        {
            get
            {
                float value = Armor == ArmorClass.Light ? 0.15f : Armor == ArmorClass.Medium ? 0.35f : 0.65f;
                if (Primary == WeaponId.RocketLauncher)
                {
                    value += 0.25f;
                }

                return value;
            }
        }

        public bool HasMedicTool
        {
            get { return Primary == WeaponId.MedicTool || Support == WeaponId.MedicTool; }
        }

        public string Summary
        {
            get { return string.Format("{0} / {1} / {2}", Primary, Support, Armor); }
        }
    }
}
