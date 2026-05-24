using System;
using System.Collections.Generic;

namespace SternenBuergerUnitySpike.Core
{
    public sealed class CommanderFlowSimulation
    {
        private int _missionSequence = 1;

        private CommanderFlowSimulation()
        {
            Roster = new List<CharacterProfile>();
            RosterById = new Dictionary<string, CharacterProfile>();
            Fireteams = new List<FireteamState>();
            Dropships = new List<DropshipState>();
            MissionCatalog = new List<MissionCatalogItem>();
            ActiveMissions = new List<MissionState>();
            GlobalLog = new List<string>();
        }

        public List<CharacterProfile> Roster { get; private set; }
        public Dictionary<string, CharacterProfile> RosterById { get; private set; }
        public List<FireteamState> Fireteams { get; private set; }
        public List<DropshipState> Dropships { get; private set; }
        public List<MissionCatalogItem> MissionCatalog { get; private set; }
        public List<MissionState> ActiveMissions { get; private set; }
        public List<string> GlobalLog { get; private set; }

        public static CommanderFlowSimulation CreateDefault()
        {
            CommanderFlowSimulation simulation = new CommanderFlowSimulation();
            simulation.AddRoster(new CharacterProfile("npc_roth", "Mara Roth", "Roth", Role.Leader, 82, 68, 72, 22, 44, "steady"));
            simulation.AddRoster(new CharacterProfile("npc_vega", "Ilya Vega", "Vega", Role.Rifleman, 45, 81, 78, 14, 38, "aggressive"));
            simulation.AddRoster(new CharacterProfile("npc_kade", "Jon Kade", "Kade", Role.Engineer, 50, 62, 64, 18, 84, "calm"));
            simulation.AddRoster(new CharacterProfile("npc_sato", "Nina Sato", "Sato", Role.Medic, 64, 58, 70, 88, 31, "cautious"));
            simulation.AddRoster(new CharacterProfile("npc_ozan", "Ozan Demir", "Demir", Role.Leader, 74, 72, 66, 20, 40, "bold"));
            simulation.AddRoster(new CharacterProfile("npc_lenz", "Tara Lenz", "Lenz", Role.Rifleman, 38, 76, 86, 16, 33, "reckless"));
            simulation.AddRoster(new CharacterProfile("npc_malik", "Samir Malik", "Malik", Role.Medic, 57, 54, 68, 82, 48, "steady"));
            simulation.AddRoster(new CharacterProfile("npc_kovacs", "Elena Kovacs", "Kovacs", Role.Pilot, 69, 64, 74, 20, 61, "calm"));

            simulation.Fireteams.Add(new FireteamState("ft_alpha", "Alpha Fireteam"));
            simulation.Fireteams.Add(new FireteamState("ft_bravo", "Bravo Fireteam"));

            simulation.Dropships.Add(new DropshipState("ds_falke", "Dropship Falke", 4));
            simulation.Dropships.Add(new DropshipState("ds_lanze", "Dropship Lanze", 4));

            simulation.MissionCatalog.Add(CreateOutpostMission());
            simulation.MissionCatalog.Add(CreateRelayMission());
            simulation.AddGlobalLog("Spike ready: build fireteams, assign dropships, launch missions.");
            return simulation;
        }

        public FireteamState GetFireteam(string fireteamId)
        {
            return Fireteams.Find(team => team.Id == fireteamId);
        }

        public DropshipState GetDropship(string dropshipId)
        {
            return Dropships.Find(dropship => dropship.Id == dropshipId);
        }

        public MissionCatalogItem GetMissionCatalogItem(string catalogId)
        {
            return MissionCatalog.Find(mission => mission.Id == catalogId);
        }

        public MissionState GetMission(string missionId)
        {
            return ActiveMissions.Find(mission => mission.Id == missionId);
        }

        public bool SetMissionTile(string catalogId, int x, int y, MissionTileKind kind)
        {
            MissionCatalogItem catalog = GetMissionCatalogItem(catalogId);
            if (catalog == null || x < 0 || y < 0 || x >= catalog.Width || y >= catalog.Height)
            {
                return false;
            }

            catalog.SetTileKind(x, y, kind);
            AddGlobalLog("Editor: " + catalog.DisplayName + " tile " + x + "," + y + " -> " + kind + ".");
            return true;
        }

        public bool MoveMissionTarget(string catalogId, string targetId, int x, int y)
        {
            MissionCatalogItem catalog = GetMissionCatalogItem(catalogId);
            if (catalog == null || x < 0 || y < 0 || x >= catalog.Width || y >= catalog.Height)
            {
                return false;
            }

            if (targetId == "lz")
            {
                catalog.SetTileKind(x, y, MissionTileKind.LandingZone);
            }
            else if (targetId == "objective")
            {
                catalog.SetTileKind(x, y, MissionTileKind.Objective);
            }
            else if (targetId == "contact")
            {
                catalog.SetTileKind(x, y, MissionTileKind.EnemySpawn);
            }
            else
            {
                catalog.SetTargetPosition(targetId, new GridPoint(x, y));
            }

            AddGlobalLog("Editor: " + targetId + " moved to " + x + "," + y + ".");
            return true;
        }

        public bool IsAssignedToAnyFireteam(string characterId)
        {
            foreach (FireteamState team in Fireteams)
            {
                if (team.Contains(characterId))
                {
                    return true;
                }
            }

            return false;
        }

        public bool AddMemberToFireteam(string fireteamId, string characterId)
        {
            FireteamState team = GetFireteam(fireteamId);
            CharacterProfile profile;
            if (team == null || !RosterById.TryGetValue(characterId, out profile) || team.IsFull || IsAssignedToAnyFireteam(characterId))
            {
                return false;
            }

            team.AddMember(profile);
            AddGlobalLog(profile.Callsign + " joined " + team.DisplayName + ".");
            return true;
        }

        public bool RemoveMemberFromFireteam(string fireteamId, string characterId)
        {
            FireteamState team = GetFireteam(fireteamId);
            if (team == null || team.Status == FireteamStatus.EnRoute || team.Status == FireteamStatus.Deployed)
            {
                return false;
            }

            team.RemoveMember(characterId);
            AddGlobalLog(characterId + " removed from " + team.DisplayName + ".");
            return true;
        }

        public bool AssignDropship(string fireteamId, string dropshipId)
        {
            FireteamState team = GetFireteam(fireteamId);
            DropshipState dropship = GetDropship(dropshipId);
            if (team == null || dropship == null || team.MemberIds.Count == 0 || !dropship.IsAvailable)
            {
                return false;
            }

            if (team.MemberIds.Count > dropship.Capacity)
            {
                AddGlobalLog("Cannot assign " + team.DisplayName + ": dropship capacity exceeded.");
                return false;
            }

            foreach (DropshipState other in Dropships)
            {
                if (other.AssignedFireteamId == fireteamId)
                {
                    other.AssignedFireteamId = null;
                    other.Status = DropshipStatus.Available;
                }
            }

            dropship.AssignedFireteamId = fireteamId;
            dropship.Status = DropshipStatus.Assigned;
            team.AssignedDropshipId = dropshipId;
            team.Status = team.MemberIds.Count >= 2 ? FireteamStatus.Assigned : FireteamStatus.Draft;
            AddGlobalLog(team.DisplayName + " boarded " + dropship.DisplayName + ".");
            return true;
        }

        public bool CyclePrimaryWeapon(string fireteamId, string characterId)
        {
            LoadoutState loadout = GetLoadout(fireteamId, characterId);
            if (loadout == null)
            {
                return false;
            }

            loadout.CyclePrimary();
            return true;
        }

        public bool CycleSupportTool(string fireteamId, string characterId)
        {
            LoadoutState loadout = GetLoadout(fireteamId, characterId);
            if (loadout == null)
            {
                return false;
            }

            loadout.CycleSupport();
            return true;
        }

        public bool CycleArmor(string fireteamId, string characterId)
        {
            LoadoutState loadout = GetLoadout(fireteamId, characterId);
            if (loadout == null)
            {
                return false;
            }

            loadout.CycleArmor();
            return true;
        }

        public MissionState LaunchMission(string fireteamId, string catalogId)
        {
            FireteamState team = GetFireteam(fireteamId);
            if (team == null || !team.CanLaunch)
            {
                AddGlobalLog("Launch blocked: Fireteam needs at least two members and a dropship.");
                return null;
            }

            DropshipState dropship = GetDropship(team.AssignedDropshipId);
            MissionCatalogItem catalog = GetMissionCatalogItem(catalogId);
            if (dropship == null || catalog == null || !dropship.IsAvailable)
            {
                AddGlobalLog("Launch blocked: dropship or mission unavailable.");
                return null;
            }

            string missionId = "mission_" + _missionSequence.ToString("00");
            _missionSequence++;
            MissionState mission = new MissionState(missionId, catalog, fireteamId, dropship.Id);
            if (catalog.EnemySpawnPositions.Count > 0)
            {
                for (int index = 0; index < catalog.EnemySpawnPositions.Count; index++)
                {
                    mission.Enemies.Add(new EnemyRuntimeState(missionId + "_enemy_" + (index + 1).ToString("00"), catalog.EnemySpawnPositions[index]));
                }
            }
            else
            {
                mission.Enemies.Add(new EnemyRuntimeState(missionId + "_enemy_01", catalog.ObjectivePosition.Offset(-1.5f, 0.8f)));
                mission.Enemies.Add(new EnemyRuntimeState(missionId + "_enemy_02", catalog.ObjectivePosition.Offset(1.4f, -0.6f)));
            }

            mission.AddLog("Launch approved: " + team.DisplayName + " to " + catalog.DisplayName + ".");
            ActiveMissions.Add(mission);

            team.Status = FireteamStatus.EnRoute;
            team.ActiveMissionId = missionId;
            dropship.Status = DropshipStatus.Inbound;
            dropship.ActiveMissionId = missionId;
            dropship.FlightProgress = 0f;
            AddGlobalLog(team.DisplayName + " launched on " + catalog.DisplayName + ".");
            return mission;
        }

        public bool IssueCommand(string missionId, CommandType type, string targetId)
        {
            MissionState mission = GetMission(missionId);
            if (mission == null || mission.Phase != MissionPhase.Active)
            {
                AddGlobalLog("Command blocked: mission is not active yet.");
                return false;
            }

            MissionTarget target;
            if (!mission.Targets.TryGetValue(targetId, out target))
            {
                AddGlobalLog("Command blocked: target is unknown.");
                return false;
            }

            FireteamState team = GetFireteam(mission.FireteamId);
            TeamScore score = team != null ? team.ComputeScore(RosterById) : new TeamScore(0f, 0f, 0f, 0f, 0f, 0f);
            float delay = Math.Max(0.2f, 1.8f - score.Leadership / 80f);
            MissionCommand command = new MissionCommand(type, targetId, target.Position, delay);
            mission.Commands.Add(command);
            mission.CurrentOrderText = type + " -> " + target.DisplayName + " (FTL interpreting)";
            mission.AddLog("Commander: " + type + " " + target.DisplayName + ".");
            return true;
        }

        public void Tick(float deltaSeconds)
        {
            foreach (MissionState mission in ActiveMissions)
            {
                TickMission(mission, deltaSeconds);
            }
        }

        private void TickMission(MissionState mission, float deltaSeconds)
        {
            DropshipState dropship = GetDropship(mission.DropshipId);
            FireteamState team = GetFireteam(mission.FireteamId);
            if (dropship == null || team == null)
            {
                mission.Phase = MissionPhase.Failed;
                return;
            }

            if (mission.Phase == MissionPhase.Inbound)
            {
                mission.FlightProgress = Math.Min(1f, mission.FlightProgress + deltaSeconds * 0.18f);
                dropship.FlightProgress = mission.FlightProgress;
                mission.CurrentOrderText = "Dropship inbound " + (mission.FlightProgress * 100f).ToString("0") + "%";
                if (mission.FlightProgress >= 1f)
                {
                    DeployFireteam(mission, team);
                    mission.Phase = MissionPhase.Active;
                    team.Status = FireteamStatus.Deployed;
                    dropship.Status = DropshipStatus.OnStation;
                    mission.CurrentOrderText = "Awaiting commander order";
                    mission.AddLog("LZ touched down. Fireteam deployed.");
                }

                return;
            }

            if (mission.Phase != MissionPhase.Active)
            {
                return;
            }

            MissionCommand command = mission.CurrentCommand;
            if (command == null)
            {
                PatrolIdle(mission, deltaSeconds);
                return;
            }

            if (!command.IsActive)
            {
                command.RemainingDelay -= deltaSeconds;
                mission.CurrentOrderText = command.Type + " -> " + command.TargetId + " (ACK in " + Math.Max(0f, command.RemainingDelay).ToString("0.0") + "s)";
                if (command.RemainingDelay <= 0f)
                {
                    ActivateCommand(mission, team, command);
                    mission.AddLog("FTL: executing " + command.Type + " " + command.TargetId + ".");
                }
            }

            if (command.IsActive)
            {
                TickActiveCommand(mission, team, command, deltaSeconds);
            }
        }

        private void DeployFireteam(MissionState mission, FireteamState team)
        {
            GridPoint lz = mission.Targets["lz"].Position;
            float[,] offsets =
            {
                { -0.4f, -0.3f },
                { 0.4f, -0.2f },
                { -0.2f, 0.45f },
                { 0.55f, 0.45f }
            };

            for (int index = 0; index < team.MemberIds.Count; index++)
            {
                string memberId = team.MemberIds[index];
                float x = offsets[index % 4, 0];
                float y = offsets[index % 4, 1];
                mission.Units[memberId] = new UnitRuntimeState(memberId, lz.Offset(x, y));
            }
        }

        private void ActivateCommand(MissionState mission, FireteamState team, MissionCommand command)
        {
            command.IsActive = true;
            GridPoint target = command.TargetPosition;
            if (command.Type == CommandType.Flank)
            {
                target = target.Offset(-1.8f, 1.1f);
            }

            float radius = command.Type == CommandType.Defend ? 1.25f : 0.65f;
            float[,] formation =
            {
                { -radius, -0.35f },
                { radius, -0.35f },
                { -radius * 0.45f, 0.55f },
                { radius * 0.45f, 0.55f }
            };

            for (int index = 0; index < team.MemberIds.Count; index++)
            {
                UnitRuntimeState unit;
                if (!mission.Units.TryGetValue(team.MemberIds[index], out unit))
                {
                    continue;
                }

                unit.TargetPosition = target.Offset(formation[index % 4, 0], formation[index % 4, 1]);
                unit.StatusText = command.Type.ToString().ToLowerInvariant();
            }

            mission.CurrentOrderText = command.Type + " active";
        }

        private void TickActiveCommand(MissionState mission, FireteamState team, MissionCommand command, float deltaSeconds)
        {
            TeamScore score = team.ComputeScore(RosterById);
            bool allArrived = true;
            foreach (string memberId in team.MemberIds)
            {
                UnitRuntimeState unit;
                CharacterProfile profile;
                if (!mission.Units.TryGetValue(memberId, out unit) || !RosterById.TryGetValue(memberId, out profile))
                {
                    continue;
                }

                LoadoutState loadout = GetLoadout(team.Id, memberId);
                float unitSpeed = (0.75f + profile.Movement / 100f) * (loadout != null ? loadout.SpeedMultiplier : 1f);
                unit.Position = GridPoint.MoveTowards(unit.Position, unit.TargetPosition, deltaSeconds * unitSpeed);
                if (unit.Position.DistanceTo(unit.TargetPosition) > 0.08f)
                {
                    allArrived = false;
                }
            }

            if (command.Type == CommandType.Engage || command.Type == CommandType.Flank)
            {
                ApplyFire(mission, score, deltaSeconds, command.Type == CommandType.Flank ? 1.25f : 1f);
            }

            if (command.Type == CommandType.Take && allArrived)
            {
                mission.ObjectiveProgress = Math.Min(1f, mission.ObjectiveProgress + deltaSeconds * (0.08f + score.Leadership / 900f + score.Medical / 2500f));
                mission.CurrentOrderText = "Taking objective " + (mission.ObjectiveProgress * 100f).ToString("0") + "%";
            }
            else if (command.Type == CommandType.Defend && allArrived)
            {
                mission.CurrentOrderText = "Defending sector, overwatch set";
            }
            else if (command.Type == CommandType.Move && allArrived)
            {
                mission.CurrentOrderText = "Move complete, awaiting order";
            }
            else if ((command.Type == CommandType.Engage || command.Type == CommandType.Flank) && allArrived)
            {
                mission.CurrentOrderText = "Contact engaged";
            }

            bool enemiesDown = true;
            foreach (EnemyRuntimeState enemy in mission.Enemies)
            {
                if (enemy.IsActive)
                {
                    enemiesDown = false;
                    break;
                }
            }

            if (mission.ObjectiveProgress >= 1f || enemiesDown)
            {
                mission.Phase = MissionPhase.Complete;
                mission.CurrentOrderText = "Mission complete";
                mission.AddLog("Objective resolved. Fireteam ready for extraction.");
                team.Status = FireteamStatus.Complete;
                DropshipState dropship = GetDropship(mission.DropshipId);
                if (dropship != null)
                {
                    dropship.Status = DropshipStatus.Returning;
                }
                return;
            }

            if (allArrived && command.Type != CommandType.Take)
            {
                command.IsComplete = true;
            }
        }

        private void ApplyFire(MissionState mission, TeamScore score, float deltaSeconds, float multiplier)
        {
            EnemyRuntimeState target = null;
            foreach (EnemyRuntimeState enemy in mission.Enemies)
            {
                if (enemy.IsActive)
                {
                    target = enemy;
                    break;
                }
            }

            if (target == null)
            {
                return;
            }

            float damage = deltaSeconds * multiplier * (0.025f + score.Shooting / 3500f + score.Firepower / 200f);
            target.Health = Math.Max(0f, target.Health - damage);
            if (!target.IsActive)
            {
                mission.AddLog("Enemy contact neutralized.");
            }
        }

        private void PatrolIdle(MissionState mission, float deltaSeconds)
        {
            foreach (UnitRuntimeState unit in mission.Units.Values)
            {
                unit.StatusText = "holding";
            }

            mission.CurrentOrderText = "Holding LZ, awaiting commander order";
        }

        private LoadoutState GetLoadout(string fireteamId, string characterId)
        {
            FireteamState team = GetFireteam(fireteamId);
            if (team == null || !team.Loadouts.ContainsKey(characterId))
            {
                return null;
            }

            return team.Loadouts[characterId];
        }

        private void AddRoster(CharacterProfile profile)
        {
            Roster.Add(profile);
            RosterById[profile.Id] = profile;
        }

        private void AddGlobalLog(string line)
        {
            GlobalLog.Insert(0, line);
            while (GlobalLog.Count > 8)
            {
                GlobalLog.RemoveAt(GlobalLog.Count - 1);
            }
        }

        private static MissionCatalogItem CreateOutpostMission()
        {
            MissionCatalogItem item = new MissionCatalogItem(
                "outpost",
                "Outpost Eos",
                "Secure the comms block and hold the courtyard.",
                new GridPoint(5.5f, 5.3f));
            item.Targets["lz"] = new MissionTarget("lz", "LZ Kilo", new GridPoint(1f, 1f));
            item.Targets["ridge"] = new MissionTarget("ridge", "Cover Ridge", new GridPoint(3f, 4f));
            item.Targets["objective"] = new MissionTarget("objective", "Comms Block", new GridPoint(6f, 5f));
            item.Targets["contact"] = new MissionTarget("contact", "Enemy Contact", new GridPoint(6f, 6f));
            item.SetBriefing(new MissionBriefing(
                "Outpost Eos",
                "Secure the comms block, survive initial contact and hold the courtyard for extraction.",
                new[] { "Land at LZ Kilo", "Take the Comms Block", "Defend the courtyard" },
                new[] { "Two robot patrols near the block", "Light turret overwatch" },
                "Alpha: Rifle/Medictool, one Sniper if leadership is high."));
            item.SetTileKind(1, 1, MissionTileKind.LandingZone);
            item.SetTileKind(2, 1, MissionTileKind.Road);
            item.SetTileKind(3, 1, MissionTileKind.Road);
            item.SetTileKind(3, 2, MissionTileKind.Road);
            item.SetTileKind(3, 4, MissionTileKind.Cover);
            item.SetTileKind(4, 4, MissionTileKind.Cover);
            item.SetTileKind(5, 4, MissionTileKind.Blocker);
            item.SetTileKind(6, 5, MissionTileKind.Objective);
            item.SetTileKind(6, 6, MissionTileKind.EnemySpawn);
            item.SetTileKind(5, 6, MissionTileKind.EnemySpawn);
            return item;
        }

        private static MissionCatalogItem CreateRelayMission()
        {
            MissionCatalogItem item = new MissionCatalogItem(
                "relay",
                "AA Relay Theta",
                "Disable the relay before the second dropship approach.",
                new GridPoint(6.2f, 3.8f));
            item.Targets["lz"] = new MissionTarget("lz", "Dry River LZ", new GridPoint(1f, 6f));
            item.Targets["ridge"] = new MissionTarget("ridge", "Rock Shelf", new GridPoint(3f, 5f));
            item.Targets["objective"] = new MissionTarget("objective", "AA Relay", new GridPoint(6f, 3f));
            item.Targets["contact"] = new MissionTarget("contact", "Relay Guards", new GridPoint(7f, 3f));
            item.SetBriefing(new MissionBriefing(
                "AA Relay Theta",
                "A relay threatens later dropship approaches. Bring heavy firepower, move under cover, then take the relay.",
                new[] { "Insert at Dry River LZ", "Suppress relay guards", "Take AA Relay" },
                new[] { "Anti-air relay", "Guard patrol on high rock shelf" },
                "Bravo: RocketLauncher or Sniper, Heavy armor only if movement remains above 60."));
            item.SetTileKind(1, 6, MissionTileKind.LandingZone);
            item.SetTileKind(2, 6, MissionTileKind.Road);
            item.SetTileKind(3, 5, MissionTileKind.Cover);
            item.SetTileKind(4, 5, MissionTileKind.Hazard);
            item.SetTileKind(5, 4, MissionTileKind.Cover);
            item.SetTileKind(6, 3, MissionTileKind.Objective);
            item.SetTileKind(7, 3, MissionTileKind.EnemySpawn);
            item.SetTileKind(6, 4, MissionTileKind.EnemySpawn);
            return item;
        }
    }
}
