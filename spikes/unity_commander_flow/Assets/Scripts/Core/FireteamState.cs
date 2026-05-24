using System.Collections.Generic;

namespace SternenBuergerUnitySpike.Core
{
    public sealed class FireteamState
    {
        public FireteamState(string id, string displayName)
        {
            Id = id;
            DisplayName = displayName;
            MemberIds = new List<string>();
            Loadouts = new Dictionary<string, LoadoutState>();
            Status = FireteamStatus.Draft;
        }

        public string Id { get; private set; }
        public string DisplayName { get; private set; }
        public List<string> MemberIds { get; private set; }
        public Dictionary<string, LoadoutState> Loadouts { get; private set; }
        public FireteamStatus Status { get; set; }
        public string AssignedDropshipId { get; set; }
        public string ActiveMissionId { get; set; }

        public bool IsFull
        {
            get { return MemberIds.Count >= 4; }
        }

        public bool CanLaunch
        {
            get { return MemberIds.Count >= 2 && !string.IsNullOrEmpty(AssignedDropshipId); }
        }

        public bool Contains(string characterId)
        {
            return MemberIds.Contains(characterId);
        }

        public void AddMember(CharacterProfile profile)
        {
            if (IsFull || Contains(profile.Id))
            {
                return;
            }

            MemberIds.Add(profile.Id);
            if (!Loadouts.ContainsKey(profile.Id))
            {
                Loadouts[profile.Id] = LoadoutState.DefaultFor(profile.PreferredRole);
            }

            Status = MemberIds.Count >= 2 ? FireteamStatus.Ready : FireteamStatus.Draft;
        }

        public void RemoveMember(string characterId)
        {
            MemberIds.Remove(characterId);
            Loadouts.Remove(characterId);
            if (MemberIds.Count < 2)
            {
                Status = FireteamStatus.Draft;
            }
        }

        public string GetLeaderId(IReadOnlyDictionary<string, CharacterProfile> roster)
        {
            string bestId = null;
            int bestScore = -1;
            foreach (string memberId in MemberIds)
            {
                CharacterProfile profile;
                if (!roster.TryGetValue(memberId, out profile))
                {
                    continue;
                }

                int score = profile.Leadership + (profile.PreferredRole == Role.Leader ? 20 : 0);
                if (score > bestScore)
                {
                    bestScore = score;
                    bestId = memberId;
                }
            }

            return bestId;
        }

        public TeamScore ComputeScore(IReadOnlyDictionary<string, CharacterProfile> roster)
        {
            if (MemberIds.Count == 0)
            {
                return new TeamScore(0f, 0f, 0f, 0f, 0f, 0f);
            }

            float leadership = 0f;
            float shooting = 0f;
            float movement = 0f;
            float firepower = 0f;
            float speed = 0f;
            float medical = 0f;

            foreach (string memberId in MemberIds)
            {
                CharacterProfile profile;
                if (!roster.TryGetValue(memberId, out profile))
                {
                    continue;
                }

                LoadoutState loadout = Loadouts.ContainsKey(memberId)
                    ? Loadouts[memberId]
                    : LoadoutState.DefaultFor(profile.PreferredRole);
                leadership += profile.Leadership;
                shooting += profile.Shooting * loadout.Firepower;
                movement += profile.Movement * loadout.SpeedMultiplier;
                firepower += loadout.Firepower;
                speed += loadout.SpeedMultiplier;
                medical += profile.Medicine + (loadout.HasMedicTool ? 30f : 0f);
            }

            float count = MemberIds.Count;
            return new TeamScore(
                leadership / count,
                shooting / count,
                movement / count,
                firepower,
                speed / count,
                medical / count);
        }
    }

    public readonly struct TeamScore
    {
        public TeamScore(float leadership, float shooting, float movement, float firepower, float speed, float medical)
        {
            Leadership = leadership;
            Shooting = shooting;
            Movement = movement;
            Firepower = firepower;
            Speed = speed;
            Medical = medical;
        }

        public readonly float Leadership;
        public readonly float Shooting;
        public readonly float Movement;
        public readonly float Firepower;
        public readonly float Speed;
        public readonly float Medical;

        public string Summary
        {
            get
            {
                return string.Format(
                    "Lead {0:0} | Shoot {1:0} | Move {2:0} | Fire {3:0.0} | Med {4:0}",
                    Leadership,
                    Shooting,
                    Movement,
                    Firepower,
                    Medical);
            }
        }
    }
}
