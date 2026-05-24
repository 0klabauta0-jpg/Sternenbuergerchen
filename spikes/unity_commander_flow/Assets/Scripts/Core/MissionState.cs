using System.Collections.Generic;

namespace SternenBuergerUnitySpike.Core
{
    public readonly struct MissionTileRecord
    {
        public MissionTileRecord(int x, int y, MissionTileKind kind)
        {
            X = x;
            Y = y;
            Kind = kind;
        }

        public readonly int X;
        public readonly int Y;
        public readonly MissionTileKind Kind;
    }

    public sealed class MissionBriefing
    {
        public MissionBriefing(
            string title,
            string summary,
            IEnumerable<string> objectives,
            IEnumerable<string> threats,
            string recommendedLoadout)
        {
            Title = title;
            Summary = summary;
            Objectives = new List<string>(objectives);
            Threats = new List<string>(threats);
            RecommendedLoadout = recommendedLoadout;
        }

        public string Title { get; private set; }
        public string Summary { get; private set; }
        public List<string> Objectives { get; private set; }
        public List<string> Threats { get; private set; }
        public string RecommendedLoadout { get; private set; }
    }

    public sealed class MissionCatalogItem
    {
        public MissionCatalogItem(string id, string displayName, string objectiveText, GridPoint objectivePosition)
        {
            Id = id;
            DisplayName = displayName;
            ObjectiveText = objectiveText;
            ObjectivePosition = objectivePosition;
            Width = 8;
            Height = 8;
            _tiles = new MissionTileKind[Width, Height];
            Targets = new Dictionary<string, MissionTarget>();
            EnemySpawnPositions = new List<GridPoint>();
            Briefing = new MissionBriefing(
                displayName,
                objectiveText,
                new[] { objectiveText },
                new[] { "Unknown contact density." },
                "Balanced rifle loadout.");
        }

        public string Id { get; private set; }
        public string DisplayName { get; private set; }
        public string ObjectiveText { get; private set; }
        public GridPoint ObjectivePosition { get; private set; }
        public int Width { get; private set; }
        public int Height { get; private set; }
        public Dictionary<string, MissionTarget> Targets { get; private set; }
        public List<GridPoint> EnemySpawnPositions { get; private set; }
        public MissionBriefing Briefing { get; private set; }

        private readonly MissionTileKind[,] _tiles;

        public MissionTileKind GetTileKind(int x, int y)
        {
            if (!IsInside(x, y))
            {
                return MissionTileKind.Ground;
            }

            return _tiles[x, y];
        }

        public void SetTileKind(int x, int y, MissionTileKind kind)
        {
            if (!IsInside(x, y))
            {
                return;
            }

            if (kind == MissionTileKind.LandingZone)
            {
                ClearKind(MissionTileKind.LandingZone);
                SetTargetPosition("lz", new GridPoint(x, y));
            }
            else if (kind == MissionTileKind.Objective)
            {
                ClearKind(MissionTileKind.Objective);
                SetTargetPosition("objective", new GridPoint(x, y));
            }

            RemoveEnemySpawnAt(x, y);
            if (kind == MissionTileKind.EnemySpawn)
            {
                EnemySpawnPositions.Add(new GridPoint(x, y));
                SetTargetPosition("contact", new GridPoint(x, y));
            }

            _tiles[x, y] = kind;
        }

        public void SetTargetPosition(string targetId, GridPoint position)
        {
            string displayName = targetId;
            MissionTarget existing;
            if (Targets.TryGetValue(targetId, out existing))
            {
                displayName = existing.DisplayName;
            }

            Targets[targetId] = new MissionTarget(targetId, displayName, position);
            if (targetId == "objective")
            {
                ObjectivePosition = position;
            }
        }

        public MissionTileKind[,] CloneTiles()
        {
            MissionTileKind[,] clone = new MissionTileKind[Width, Height];
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    clone[x, y] = _tiles[x, y];
                }
            }

            return clone;
        }

        public List<MissionTileRecord> EnumerateTiles()
        {
            List<MissionTileRecord> records = new List<MissionTileRecord>();
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    records.Add(new MissionTileRecord(x, y, _tiles[x, y]));
                }
            }

            return records;
        }

        public void SetBriefing(MissionBriefing briefing)
        {
            Briefing = briefing;
        }

        private void ClearKind(MissionTileKind kind)
        {
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    if (_tiles[x, y] == kind)
                    {
                        _tiles[x, y] = MissionTileKind.Ground;
                    }
                }
            }
        }

        private void RemoveEnemySpawnAt(int x, int y)
        {
            for (int index = EnemySpawnPositions.Count - 1; index >= 0; index--)
            {
                GridPoint spawn = EnemySpawnPositions[index];
                if ((int)spawn.X == x && (int)spawn.Y == y)
                {
                    EnemySpawnPositions.RemoveAt(index);
                }
            }
        }

        private bool IsInside(int x, int y)
        {
            return x >= 0 && y >= 0 && x < Width && y < Height;
        }
    }

    public sealed class MissionTarget
    {
        public MissionTarget(string id, string displayName, GridPoint position)
        {
            Id = id;
            DisplayName = displayName;
            Position = position;
        }

        public string Id { get; private set; }
        public string DisplayName { get; private set; }
        public GridPoint Position { get; private set; }
    }

    public sealed class MissionCommand
    {
        public MissionCommand(CommandType type, string targetId, GridPoint targetPosition, float delaySeconds)
        {
            Type = type;
            TargetId = targetId;
            TargetPosition = targetPosition;
            RemainingDelay = delaySeconds;
            IsActive = false;
            IsComplete = false;
        }

        public CommandType Type { get; private set; }
        public string TargetId { get; private set; }
        public GridPoint TargetPosition { get; private set; }
        public float RemainingDelay { get; set; }
        public bool IsActive { get; set; }
        public bool IsComplete { get; set; }
    }

    public sealed class UnitRuntimeState
    {
        public UnitRuntimeState(string characterId, GridPoint position)
        {
            CharacterId = characterId;
            Position = position;
            TargetPosition = position;
            Health = 1f;
            StatusText = "deployed";
        }

        public string CharacterId { get; private set; }
        public GridPoint Position { get; set; }
        public GridPoint TargetPosition { get; set; }
        public float Health { get; set; }
        public string StatusText { get; set; }
    }

    public sealed class EnemyRuntimeState
    {
        public EnemyRuntimeState(string id, GridPoint position)
        {
            Id = id;
            Position = position;
            Health = 1f;
        }

        public string Id { get; private set; }
        public GridPoint Position { get; private set; }
        public float Health { get; set; }

        public bool IsActive
        {
            get { return Health > 0.01f; }
        }
    }

    public sealed class MissionState
    {
        public MissionState(
            string id,
            MissionCatalogItem catalog,
            string fireteamId,
            string dropshipId)
        {
            Id = id;
            CatalogId = catalog.Id;
            DisplayName = catalog.DisplayName;
            ObjectiveText = catalog.ObjectiveText;
            ObjectivePosition = catalog.ObjectivePosition;
            FireteamId = fireteamId;
            DropshipId = dropshipId;
            Phase = MissionPhase.Inbound;
            FlightProgress = 0f;
            ObjectiveProgress = 0f;
            CurrentOrderText = "Dropship inbound";
            Targets = new Dictionary<string, MissionTarget>(catalog.Targets);
            TileKinds = catalog.CloneTiles();
            Width = catalog.Width;
            Height = catalog.Height;
            Units = new Dictionary<string, UnitRuntimeState>();
            Enemies = new List<EnemyRuntimeState>();
            Commands = new List<MissionCommand>();
            Log = new List<string>();
        }

        public string Id { get; private set; }
        public string CatalogId { get; private set; }
        public string DisplayName { get; private set; }
        public string ObjectiveText { get; private set; }
        public GridPoint ObjectivePosition { get; private set; }
        public string FireteamId { get; private set; }
        public string DropshipId { get; private set; }
        public MissionPhase Phase { get; set; }
        public float FlightProgress { get; set; }
        public float ObjectiveProgress { get; set; }
        public string CurrentOrderText { get; set; }
        public Dictionary<string, MissionTarget> Targets { get; private set; }
        public MissionTileKind[,] TileKinds { get; private set; }
        public int Width { get; private set; }
        public int Height { get; private set; }
        public Dictionary<string, UnitRuntimeState> Units { get; private set; }
        public List<EnemyRuntimeState> Enemies { get; private set; }
        public List<MissionCommand> Commands { get; private set; }
        public List<string> Log { get; private set; }

        public MissionCommand CurrentCommand
        {
            get
            {
                for (int index = 0; index < Commands.Count; index++)
                {
                    if (!Commands[index].IsComplete)
                    {
                        return Commands[index];
                    }
                }

                return null;
            }
        }

        public MissionTileKind GetTileKind(int x, int y)
        {
            if (x < 0 || y < 0 || x >= Width || y >= Height)
            {
                return MissionTileKind.Ground;
            }

            return TileKinds[x, y];
        }

        public void AddLog(string line)
        {
            Log.Insert(0, line);
            while (Log.Count > 8)
            {
                Log.RemoveAt(Log.Count - 1);
            }
        }
    }
}
