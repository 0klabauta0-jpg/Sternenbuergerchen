using System;

namespace SternenBuergerUnitySpike.Core
{
    public enum Role
    {
        Leader,
        Rifleman,
        Medic,
        Engineer,
        Pilot
    }

    public enum WeaponId
    {
        None,
        Smg,
        Rifle,
        Sniper,
        RocketLauncher,
        MedicTool
    }

    public enum ArmorClass
    {
        Light,
        Medium,
        Heavy
    }

    public enum FireteamStatus
    {
        Draft,
        Ready,
        Assigned,
        EnRoute,
        Deployed,
        Complete
    }

    public enum DropshipStatus
    {
        Available,
        Assigned,
        Inbound,
        OnStation,
        Returning
    }

    public enum MissionPhase
    {
        Available,
        Inbound,
        Deploying,
        Active,
        Complete,
        Failed
    }

    public enum CommandType
    {
        Move,
        Take,
        Defend,
        Engage,
        Flank
    }

    public enum MissionTileKind
    {
        Ground,
        Road,
        Cover,
        Blocker,
        Hazard,
        LandingZone,
        Objective,
        EnemySpawn
    }

    public readonly struct GridPoint
    {
        public readonly float X;
        public readonly float Y;

        public GridPoint(float x, float y)
        {
            X = x;
            Y = y;
        }

        public static GridPoint Zero
        {
            get { return new GridPoint(0f, 0f); }
        }

        public float DistanceTo(GridPoint other)
        {
            float dx = other.X - X;
            float dy = other.Y - Y;
            return (float)Math.Sqrt(dx * dx + dy * dy);
        }

        public GridPoint Offset(float x, float y)
        {
            return new GridPoint(X + x, Y + y);
        }

        public static GridPoint MoveTowards(GridPoint current, GridPoint target, float maxDistance)
        {
            float dx = target.X - current.X;
            float dy = target.Y - current.Y;
            float distance = (float)Math.Sqrt(dx * dx + dy * dy);
            if (distance <= maxDistance || distance <= 0.0001f)
            {
                return target;
            }

            float scale = maxDistance / distance;
            return new GridPoint(current.X + dx * scale, current.Y + dy * scale);
        }

        public override string ToString()
        {
            return string.Format("{0:0.0},{1:0.0}", X, Y);
        }
    }
}
