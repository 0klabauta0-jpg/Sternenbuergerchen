using System;
using System.Collections.Generic;
using SternenBuergerUnitySpike.Core;
using UnityEngine;

namespace SternenBuergerUnitySpike.Presentation
{
    public sealed class CommanderFlowSpikeBehaviour : MonoBehaviour
    {
        public GameObject FriendlyInfantryPrefab;
        public GameObject SpacesuitPrefab;
        public GameObject DropshipPrefab;
        public GameObject DropshipAltPrefab;
        public GameObject EnemyRobotPrefab;
        public GameObject EnemyDronePrefab;
        public GameObject AssaultRiflePrefab;
        public GameObject SmgPrefab;
        public GameObject SniperPrefab;
        public GameObject LauncherPrefab;
        public GameObject ComputerPrefab;
        public GameObject ComputerLargePrefab;
        public GameObject TurretPrefab;
        public GameObject TankPrefab;
        public GameObject PipePrefab;
        public GameObject AntennaPrefab;
        public GameObject DomePrefab;
        public GameObject RockPrefab;

        private CommanderFlowSimulation _simulation;
        private string _selectedFireteamId;
        private string _selectedCatalogId;
        private string _selectedMissionId;
        private string _visualMissionId;
        private string _visualCatalogId;
        private bool _editorMode;
        private MissionEditorTool _editorTool;
        private int _lastPaintX = -1;
        private int _lastPaintY = -1;

        private Transform _worldRoot;
        private readonly Dictionary<string, GameObject> _unitObjects = new Dictionary<string, GameObject>();
        private readonly Dictionary<string, TextMesh> _unitLabels = new Dictionary<string, TextMesh>();
        private readonly Dictionary<string, GameObject> _enemyObjects = new Dictionary<string, GameObject>();
        private readonly List<TextMesh> _worldLabels = new List<TextMesh>();

        private Material _tileMaterial;
        private Material _tileAltMaterial;
        private Material _roadMaterial;
        private Material _coverMaterial;
        private Material _blockerMaterial;
        private Material _hazardMaterial;
        private Material _objectiveMaterial;
        private Material _lzMaterial;
        private Material _unitAlphaMaterial;
        private Material _unitBravoMaterial;
        private Material _enemyMaterial;
        private Material _enemyDownMaterial;
        private Material _dropshipMaterial;
        private Material _selectionMaterial;

        private GUIStyle _panelStyle;
        private GUIStyle _headerStyle;
        private GUIStyle _smallLabelStyle;
        private GUIStyle _missionLogStyle;
        private GUIStyle _badgeStyle;
        private Texture2D _panelTexture;
        private Texture2D _badgeTexture;

        private void Awake()
        {
            Debug.Log("CommanderFlowSpikeBehaviour Awake: building polished commander slice.");
            _simulation = CommanderFlowSimulation.CreateDefault();
            _selectedFireteamId = _simulation.Fireteams[0].Id;
            _selectedCatalogId = _simulation.MissionCatalog[0].Id;
            _editorTool = MissionEditorTool.Cover;
            SetupMaterials();
            SetupScene();
        }

        private void Update()
        {
            _simulation.Tick(Time.deltaTime);
            if (string.IsNullOrEmpty(_selectedMissionId) && _simulation.ActiveMissions.Count > 0)
            {
                _selectedMissionId = _simulation.ActiveMissions[_simulation.ActiveMissions.Count - 1].Id;
            }

            HandleEditorInput();
            SyncMissionVisuals();
            FaceLabelsToCamera();
        }

        private void OnGUI()
        {
            EnsureGuiStyles();
            DrawRosterPanel();
            DrawFireteamPanel();
            DrawMissionPanel();
            if (_editorMode)
            {
                DrawEditorPanel();
            }
            else
            {
                DrawCommandPanel();
            }
        }

        private void DrawRosterPanel()
        {
            GUILayout.BeginArea(new Rect(10, 10, 320, Screen.height - 20), _panelStyle);
            GUILayout.Label("HOMEBASE ROSTER", _headerStyle);
            GUILayout.Label("NPC-Werte treiben Fireteam-Score, ACK-Delay, Bewegung, Support und Feuerkraft.", _smallLabelStyle);

            foreach (CharacterProfile profile in _simulation.Roster)
            {
                bool assigned = _simulation.IsAssignedToAnyFireteam(profile.Id);
                GUILayout.BeginVertical(GUI.skin.box);
                GUILayout.Label(profile.DisplayName + " - " + profile.ShortLine, _smallLabelStyle);
                GUILayout.BeginHorizontal();
                GUI.enabled = !assigned;
                if (GUILayout.Button("Ins Fireteam"))
                {
                    _simulation.AddMemberToFireteam(_selectedFireteamId, profile.Id);
                }

                GUI.enabled = true;
                GUILayout.Label(assigned ? "assigned" : "available", _badgeStyle, GUILayout.Width(78));
                GUILayout.EndHorizontal();
                GUILayout.EndVertical();
            }

            GUILayout.Space(8);
            GUILayout.Label("GLOBAL LOG", _headerStyle);
            foreach (string line in _simulation.GlobalLog)
            {
                GUILayout.Label(line, _smallLabelStyle);
            }

            GUILayout.EndArea();
        }

        private void DrawFireteamPanel()
        {
            GUILayout.BeginArea(new Rect(340, 10, 430, Screen.height - 150), _panelStyle);
            GUILayout.Label("FOB / FIRETEAM / LOADOUT", _headerStyle);
            GUILayout.BeginHorizontal();
            foreach (FireteamState fireteam in _simulation.Fireteams)
            {
                bool selected = fireteam.Id == _selectedFireteamId;
                if (GUILayout.Toggle(selected, fireteam.DisplayName, GUI.skin.button))
                {
                    _selectedFireteamId = fireteam.Id;
                }
            }
            GUILayout.EndHorizontal();

            FireteamState team = _simulation.GetFireteam(_selectedFireteamId);
            if (team == null)
            {
                GUILayout.EndArea();
                return;
            }

            TeamScore score = team.ComputeScore(_simulation.RosterById);
            GUILayout.Label("Status: " + team.Status + " | " + score.Summary, _smallLabelStyle);
            string leaderId = team.GetLeaderId(_simulation.RosterById);
            GUILayout.Label("FTL: " + (leaderId != null ? _simulation.RosterById[leaderId].Callsign : "none"), _smallLabelStyle);

            if (team.MemberIds.Count == 0)
            {
                GUILayout.Label("Links NPCs waehlen, dann Dropship zuweisen und Mission starten.", _smallLabelStyle);
            }

            foreach (string memberId in team.MemberIds.ToArray())
            {
                CharacterProfile profile = _simulation.RosterById[memberId];
                LoadoutState loadout = team.Loadouts[memberId];
                GUILayout.BeginVertical(GUI.skin.box);
                GUILayout.BeginHorizontal();
                GUILayout.Label(profile.Callsign + " | " + profile.PreferredRole + " | " + loadout.Summary, _smallLabelStyle);
                GUI.enabled = team.Status != FireteamStatus.EnRoute && team.Status != FireteamStatus.Deployed;
                if (GUILayout.Button("Remove", GUILayout.Width(72)))
                {
                    _simulation.RemoveMemberFromFireteam(team.Id, memberId);
                }
                GUI.enabled = true;
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal();
                GUI.enabled = team.Status != FireteamStatus.EnRoute && team.Status != FireteamStatus.Deployed;
                if (GUILayout.Button("Primary: " + loadout.Primary))
                {
                    _simulation.CyclePrimaryWeapon(team.Id, memberId);
                }
                if (GUILayout.Button("Support: " + loadout.Support))
                {
                    _simulation.CycleSupportTool(team.Id, memberId);
                }
                if (GUILayout.Button("Armor: " + loadout.Armor))
                {
                    _simulation.CycleArmor(team.Id, memberId);
                }
                GUI.enabled = true;
                GUILayout.EndHorizontal();
                GUILayout.EndVertical();
            }

            GUILayout.Space(8);
            GUILayout.Label("DROPSHIPS", _headerStyle);
            foreach (DropshipState dropship in _simulation.Dropships)
            {
                GUILayout.BeginHorizontal(GUI.skin.box);
                GUILayout.Label(dropship.DisplayName + " | " + dropship.Status + " | cap " + dropship.Capacity, _smallLabelStyle);
                GUI.enabled = dropship.IsAvailable && team.MemberIds.Count > 0 && team.MemberIds.Count <= dropship.Capacity;
                if (GUILayout.Button("Assign", GUILayout.Width(70)))
                {
                    _simulation.AssignDropship(team.Id, dropship.Id);
                }
                GUI.enabled = true;
                GUILayout.EndHorizontal();
            }

            GUILayout.EndArea();
        }

        private void DrawMissionPanel()
        {
            GUILayout.BeginArea(new Rect(Screen.width - 360, 10, 350, Screen.height - 150), _panelStyle);
            GUILayout.Label("MISSION CONTROL", _headerStyle);
            GUILayout.Label("Missions laufen parallel weiter. Der sichtbare Auftrag bleibt Fireteam-Intent.", _smallLabelStyle);

            GUILayout.BeginHorizontal();
            if (GUILayout.Toggle(!_editorMode, "Play", GUI.skin.button))
            {
                _editorMode = false;
            }
            if (GUILayout.Toggle(_editorMode, "Editor", GUI.skin.button))
            {
                _editorMode = true;
                _selectedMissionId = null;
            }
            GUILayout.EndHorizontal();

            GUILayout.Label("Mission Brief", _headerStyle);
            foreach (MissionCatalogItem catalog in _simulation.MissionCatalog)
            {
                bool selected = catalog.Id == _selectedCatalogId;
                if (GUILayout.Toggle(selected, catalog.DisplayName, GUI.skin.button))
                {
                    _selectedCatalogId = catalog.Id;
                    _selectedMissionId = null;
                }
            }

            MissionCatalogItem selectedCatalog = _simulation.GetMissionCatalogItem(_selectedCatalogId);
            if (selectedCatalog != null)
            {
                GUILayout.Label(selectedCatalog.Briefing.Title, _headerStyle);
                GUILayout.Label(selectedCatalog.Briefing.Summary, _smallLabelStyle);
                GUILayout.Label("Loadout: " + selectedCatalog.Briefing.RecommendedLoadout, _smallLabelStyle);
                DrawBriefingList("Objectives", selectedCatalog.Briefing.Objectives);
                DrawBriefingList("Threats", selectedCatalog.Briefing.Threats);
            }

            FireteamState selectedTeam = _simulation.GetFireteam(_selectedFireteamId);
            GUI.enabled = !_editorMode && selectedTeam != null && selectedTeam.CanLaunch && (selectedTeam.Status == FireteamStatus.Assigned || selectedTeam.Status == FireteamStatus.Ready);
            if (GUILayout.Button("Launch selected Fireteam"))
            {
                MissionState mission = _simulation.LaunchMission(_selectedFireteamId, _selectedCatalogId);
                if (mission != null)
                {
                    _selectedMissionId = mission.Id;
                }
            }
            GUI.enabled = true;

            GUILayout.Space(8);
            GUILayout.Label("Active Missions", _headerStyle);
            if (_simulation.ActiveMissions.Count == 0)
            {
                GUILayout.Label(_editorMode ? "Editor malt den Missionskatalog." : "Noch keine aktive Mission.", _smallLabelStyle);
            }

            foreach (MissionState mission in _simulation.ActiveMissions)
            {
                FireteamState team = _simulation.GetFireteam(mission.FireteamId);
                string teamName = team != null ? team.DisplayName : mission.FireteamId;
                string line = mission.DisplayName + " | " + teamName + " | " + mission.Phase;
                bool selected = mission.Id == _selectedMissionId;
                if (GUILayout.Toggle(selected, line, GUI.skin.button))
                {
                    _selectedMissionId = mission.Id;
                    _editorMode = false;
                }
            }

            MissionState selectedMission = _simulation.GetMission(_selectedMissionId);
            if (selectedMission != null)
            {
                GUILayout.Space(8);
                GUILayout.Label(selectedMission.DisplayName, _headerStyle);
                GUILayout.Label("Order: " + selectedMission.CurrentOrderText, _smallLabelStyle);
                GUILayout.Label("Flight: " + (selectedMission.FlightProgress * 100f).ToString("0") + "% | Objective: " + (selectedMission.ObjectiveProgress * 100f).ToString("0") + "%", _smallLabelStyle);
                GUILayout.Label("Mission Log", _headerStyle);
                foreach (string line in selectedMission.Log)
                {
                    GUILayout.Label(line, _missionLogStyle);
                }
            }

            GUILayout.EndArea();
        }

        private void DrawBriefingList(string label, List<string> lines)
        {
            GUILayout.Label(label, _headerStyle);
            foreach (string line in lines)
            {
                GUILayout.Label("- " + line, _smallLabelStyle);
            }
        }

        private void DrawCommandPanel()
        {
            GUILayout.BeginArea(new Rect(340, Screen.height - 130, Screen.width - 710, 120), _panelStyle);
            GUILayout.Label("COMMANDS - Fireteam-Absicht, kein Einzelunit-Micro", _headerStyle);
            MissionState mission = _simulation.GetMission(_selectedMissionId);
            bool missionActive = mission != null && mission.Phase == MissionPhase.Active;
            GUI.enabled = missionActive;
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Move to Cover"))
            {
                _simulation.IssueCommand(mission.Id, CommandType.Move, "ridge");
            }
            if (GUILayout.Button("Defend Ridge"))
            {
                _simulation.IssueCommand(mission.Id, CommandType.Defend, "ridge");
            }
            if (GUILayout.Button("Take Objective"))
            {
                _simulation.IssueCommand(mission.Id, CommandType.Take, "objective");
            }
            if (GUILayout.Button("Engage Contact"))
            {
                _simulation.IssueCommand(mission.Id, CommandType.Engage, "contact");
            }
            if (GUILayout.Button("Flank Contact"))
            {
                _simulation.IssueCommand(mission.Id, CommandType.Flank, "contact");
            }
            GUILayout.EndHorizontal();
            GUI.enabled = true;

            if (!missionActive)
            {
                GUILayout.Label("Commands schalten frei, sobald das Dropship die LZ erreicht.", _smallLabelStyle);
            }

            GUILayout.EndArea();
        }

        private void DrawEditorPanel()
        {
            GUILayout.BeginArea(new Rect(340, Screen.height - 170, Screen.width - 710, 160), _panelStyle);
            GUILayout.Label("RUNTIME MISSION EDITOR", _headerStyle);
            GUILayout.Label("Tool waehlen und direkt auf die 3D-Karte klicken. Der Katalog wird geaendert; aktive Missionen bleiben unveraendert.", _smallLabelStyle);

            GUILayout.BeginHorizontal();
            DrawToolButton(MissionEditorTool.Ground, "Ground");
            DrawToolButton(MissionEditorTool.Road, "Road");
            DrawToolButton(MissionEditorTool.Cover, "Cover");
            DrawToolButton(MissionEditorTool.Blocker, "Wall");
            DrawToolButton(MissionEditorTool.Hazard, "Hazard");
            DrawToolButton(MissionEditorTool.LandingZone, "LZ");
            DrawToolButton(MissionEditorTool.Objective, "OBJ");
            DrawToolButton(MissionEditorTool.EnemySpawn, "Enemy");
            GUILayout.EndHorizontal();

            string last = _lastPaintX >= 0 ? _lastPaintX + "," + _lastPaintY : "noch kein Tile";
            GUILayout.Label("Aktiv: " + _editorTool + " | letzter Paint: " + last + " | Nach dem Editieren Play waehlen und Fireteam starten.", _smallLabelStyle);
            GUILayout.EndArea();
        }

        private void DrawToolButton(MissionEditorTool tool, string label)
        {
            bool selected = _editorTool == tool;
            if (GUILayout.Toggle(selected, label, GUI.skin.button, GUILayout.MinWidth(72)))
            {
                _editorTool = tool;
            }
        }

        private void HandleEditorInput()
        {
            if (!_editorMode || !Input.GetMouseButtonDown(0))
            {
                return;
            }

            Camera camera = Camera.main;
            if (camera == null)
            {
                return;
            }

            Ray ray = camera.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (!Physics.Raycast(ray, out hit, 500f))
            {
                return;
            }

            SpikeMapTile tile = hit.collider.GetComponentInParent<SpikeMapTile>();
            if (tile == null)
            {
                return;
            }

            MissionTileKind kind = ConvertEditorTool(_editorTool);
            if (_simulation.SetMissionTile(_selectedCatalogId, tile.X, tile.Y, kind))
            {
                _lastPaintX = tile.X;
                _lastPaintY = tile.Y;
                _visualCatalogId = null;
                _selectedMissionId = null;
            }
        }

        private MissionTileKind ConvertEditorTool(MissionEditorTool tool)
        {
            switch (tool)
            {
                case MissionEditorTool.Road:
                    return MissionTileKind.Road;
                case MissionEditorTool.Cover:
                    return MissionTileKind.Cover;
                case MissionEditorTool.Blocker:
                    return MissionTileKind.Blocker;
                case MissionEditorTool.Hazard:
                    return MissionTileKind.Hazard;
                case MissionEditorTool.LandingZone:
                    return MissionTileKind.LandingZone;
                case MissionEditorTool.Objective:
                    return MissionTileKind.Objective;
                case MissionEditorTool.EnemySpawn:
                    return MissionTileKind.EnemySpawn;
                default:
                    return MissionTileKind.Ground;
            }
        }

        private void SyncMissionVisuals()
        {
            MissionState selectedMission = _simulation.GetMission(_selectedMissionId);
            if (selectedMission != null)
            {
                if (_visualMissionId != selectedMission.Id)
                {
                    RebuildActiveMissionVisuals(selectedMission);
                    _visualMissionId = selectedMission.Id;
                    _visualCatalogId = null;
                }

                UpdateActiveMissionObjects(selectedMission);
                return;
            }

            MissionCatalogItem catalog = _simulation.GetMissionCatalogItem(_selectedCatalogId);
            if (catalog != null && _visualCatalogId != catalog.Id)
            {
                RebuildCatalogPreview(catalog);
                _visualCatalogId = catalog.Id;
                _visualMissionId = null;
            }
        }

        private void RebuildCatalogPreview(MissionCatalogItem catalog)
        {
            ClearWorld();
            BuildMap(catalog.Targets, catalog.Width, catalog.Height, catalog.GetTileKind);
            CreateLabel("preview_title", catalog.DisplayName, new GridPoint(4.0f, -0.6f), Color.white);
        }

        private void RebuildActiveMissionVisuals(MissionState mission)
        {
            ClearWorld();
            BuildMap(mission.Targets, mission.Width, mission.Height, mission.GetTileKind);

            GameObject dropship = CreateAssetObject(
                DropshipPrefab,
                "Dropship",
                _worldRoot,
                Vector3.zero,
                new Vector3(0.58f, 0.58f, 0.58f),
                new Vector3(0f, 135f, 0f),
                PrimitiveType.Cube,
                _dropshipMaterial);
            dropship.transform.localScale = Vector3.one;
            _unitObjects["dropship"] = dropship;
        }

        private void UpdateActiveMissionObjects(MissionState mission)
        {
            GridPoint lz = mission.Targets["lz"].Position;
            GameObject dropship;
            if (_unitObjects.TryGetValue("dropship", out dropship))
            {
                Vector3 start = GridToWorld(lz.Offset(-4.5f, 4.5f)) + Vector3.up * 2.4f;
                Vector3 end = GridToWorld(lz) + Vector3.up * 0.72f;
                dropship.transform.position = Vector3.Lerp(start, end, mission.FlightProgress);
            }

            FireteamState team = _simulation.GetFireteam(mission.FireteamId);
            Material unitMaterial = team != null && team.Id == "ft_bravo" ? _unitBravoMaterial : _unitAlphaMaterial;
            foreach (UnitRuntimeState unit in mission.Units.Values)
            {
                GameObject unitObject;
                if (!_unitObjects.TryGetValue(unit.CharacterId, out unitObject))
                {
                    CharacterProfile profile = _simulation.RosterById[unit.CharacterId];
                    LoadoutState loadout = team != null && team.Loadouts.ContainsKey(unit.CharacterId) ? team.Loadouts[unit.CharacterId] : null;
                    unitObject = CreateUnitObject(profile, loadout, unitMaterial);
                    _unitObjects[unit.CharacterId] = unitObject;
                    TextMesh label = CreateLabel("label_" + unit.CharacterId, profile.Callsign, unit.Position.Offset(0f, 0.25f), Color.white);
                    _unitLabels[unit.CharacterId] = label;
                }

                unitObject.transform.position = GridToWorld(unit.Position);
                TextMesh unitLabel;
                if (_unitLabels.TryGetValue(unit.CharacterId, out unitLabel) && unitLabel != null)
                {
                    unitLabel.transform.position = GridToWorld(unit.Position.Offset(0f, 0.25f)) + Vector3.up * 1.35f;
                }
            }

            foreach (EnemyRuntimeState enemy in mission.Enemies)
            {
                GameObject enemyObject;
                if (!_enemyObjects.TryGetValue(enemy.Id, out enemyObject))
                {
                    enemyObject = CreateEnemyObject(enemy.Id);
                    _enemyObjects[enemy.Id] = enemyObject;
                }

                enemyObject.transform.position = GridToWorld(enemy.Position);
                enemyObject.transform.localScale = enemy.IsActive ? Vector3.one : new Vector3(1f, 0.18f, 1f);
                SetChildMaterial(enemyObject, enemy.IsActive ? _enemyMaterial : _enemyDownMaterial, false);
            }
        }

        private GameObject CreateUnitObject(CharacterProfile profile, LoadoutState loadout, Material teamMaterial)
        {
            GameObject root = new GameObject("Unit_" + profile.Id);
            root.transform.SetParent(_worldRoot);

            GameObject baseRing = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            baseRing.name = "Selection Ring";
            baseRing.transform.SetParent(root.transform, false);
            baseRing.transform.localPosition = Vector3.up * 0.025f;
            baseRing.transform.localScale = new Vector3(0.42f, 0.025f, 0.42f);
            baseRing.GetComponent<Renderer>().sharedMaterial = teamMaterial;

            GameObject prefab = profile.PreferredRole == Role.Pilot ? SpacesuitPrefab : FriendlyInfantryPrefab;
            if (prefab != null)
            {
                GameObject model = Instantiate(prefab, root.transform);
                model.name = "Infantry Model";
                model.transform.localPosition = Vector3.zero;
                model.transform.localRotation = Quaternion.Euler(0f, 180f, 0f);
                model.transform.localScale = Vector3.one * 0.42f;
            }
            else
            {
                GameObject body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                body.name = "Procedural Infantry";
                body.transform.SetParent(root.transform, false);
                body.transform.localPosition = Vector3.up * 0.62f;
                body.transform.localScale = new Vector3(0.28f, 0.58f, 0.28f);
                body.GetComponent<Renderer>().sharedMaterial = teamMaterial;
            }

            CreateWeaponObject(root.transform, loadout);
            return root;
        }

        private void CreateWeaponObject(Transform parent, LoadoutState loadout)
        {
            GameObject weaponPrefab = null;
            if (loadout != null)
            {
                switch (loadout.Primary)
                {
                    case WeaponId.Smg:
                        weaponPrefab = SmgPrefab;
                        break;
                    case WeaponId.Rifle:
                        weaponPrefab = AssaultRiflePrefab;
                        break;
                    case WeaponId.Sniper:
                        weaponPrefab = SniperPrefab;
                        break;
                    case WeaponId.RocketLauncher:
                        weaponPrefab = LauncherPrefab;
                        break;
                }
            }

            GameObject weapon = CreateAssetObject(
                weaponPrefab,
                "Weapon",
                parent,
                new Vector3(0.23f, 0.68f, 0.2f),
                Vector3.one * 0.22f,
                new Vector3(0f, 90f, -8f),
                PrimitiveType.Cube,
                _blockerMaterial);
            weapon.transform.localScale = Vector3.one;
        }

        private GameObject CreateEnemyObject(string id)
        {
            GameObject root = new GameObject("Enemy_" + id);
            root.transform.SetParent(_worldRoot);

            GameObject baseRing = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            baseRing.name = "Enemy Base";
            baseRing.transform.SetParent(root.transform, false);
            baseRing.transform.localPosition = Vector3.up * 0.025f;
            baseRing.transform.localScale = new Vector3(0.4f, 0.025f, 0.4f);
            baseRing.GetComponent<Renderer>().sharedMaterial = _enemyMaterial;

            GameObject prefab = id.EndsWith("02", StringComparison.Ordinal) ? EnemyDronePrefab : EnemyRobotPrefab;
            CreateAssetObject(
                prefab,
                "Enemy Model",
                root.transform,
                Vector3.zero,
                Vector3.one * 0.55f,
                new Vector3(0f, -35f, 0f),
                PrimitiveType.Capsule,
                _enemyMaterial);
            return root;
        }

        private void BuildMap(
            Dictionary<string, MissionTarget> targets,
            int width,
            int height,
            Func<int, int, MissionTileKind> getTileKind)
        {
            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    MissionTileKind kind = getTileKind(x, y);
                    CreateTile(x, y, kind);
                    CreateTileDecoration(x, y, kind);
                }
            }

            foreach (MissionTarget target in targets.Values)
            {
                if (target.Id == "lz")
                {
                    CreateMarker("lz", target.Position, _lzMaterial, "LZ");
                }
                else if (target.Id == "objective")
                {
                    CreateMarker("objective", target.Position, _objectiveMaterial, "OBJ");
                    CreateAssetObject(
                        ComputerLargePrefab,
                        "Objective Console",
                        _worldRoot,
                        GridToWorld(target.Position) + Vector3.up * 0.1f,
                        Vector3.one * 0.45f,
                        new Vector3(0f, 35f, 0f),
                        PrimitiveType.Cube,
                        _objectiveMaterial);
                }
                else if (target.Id == "ridge")
                {
                    CreateMarker("ridge", target.Position, _coverMaterial, "COVER");
                }
                else
                {
                    CreateLabel("target_" + target.Id, target.DisplayName, target.Position, Color.yellow);
                }
            }
        }

        private void CreateTile(int x, int y, MissionTileKind kind)
        {
            GameObject tile = GameObject.CreatePrimitive(PrimitiveType.Cube);
            tile.name = "Tile_" + x + "_" + y;
            tile.transform.SetParent(_worldRoot);
            tile.transform.position = GridToWorld(new GridPoint(x, y)) + Vector3.down * 0.05f;
            tile.transform.localScale = new Vector3(0.96f, 0.08f, 0.96f);
            tile.GetComponent<Renderer>().sharedMaterial = GetTileMaterial(kind, x, y);

            SpikeMapTile marker = tile.AddComponent<SpikeMapTile>();
            marker.X = x;
            marker.Y = y;

            if (kind == MissionTileKind.Road)
            {
                GameObject stripe = GameObject.CreatePrimitive(PrimitiveType.Cube);
                stripe.name = "Road Stripe";
                stripe.transform.SetParent(tile.transform, false);
                stripe.transform.localPosition = Vector3.up * 0.62f;
                stripe.transform.localScale = new Vector3(0.12f, 0.08f, 0.8f);
                stripe.GetComponent<Renderer>().sharedMaterial = _selectionMaterial;
            }
        }

        private void CreateTileDecoration(int x, int y, MissionTileKind kind)
        {
            Vector3 position = GridToWorld(new GridPoint(x, y));
            switch (kind)
            {
                case MissionTileKind.Cover:
                    CreateAssetObject(
                        x % 2 == 0 ? TankPrefab : PipePrefab,
                        "Cover Prop",
                        _worldRoot,
                        position + Vector3.up * 0.1f,
                        Vector3.one * 0.42f,
                        new Vector3(0f, x % 2 == 0 ? 25f : 90f, 0f),
                        PrimitiveType.Cube,
                        _coverMaterial);
                    break;
                case MissionTileKind.Blocker:
                    CreateAssetObject(
                        RockPrefab,
                        "Blocker Prop",
                        _worldRoot,
                        position + Vector3.up * 0.1f,
                        Vector3.one * 0.55f,
                        new Vector3(0f, 45f, 0f),
                        PrimitiveType.Cube,
                        _blockerMaterial);
                    break;
                case MissionTileKind.Hazard:
                    CreateAssetObject(
                        TurretPrefab,
                        "Hazard Turret",
                        _worldRoot,
                        position + Vector3.up * 0.12f,
                        Vector3.one * 0.42f,
                        new Vector3(0f, -30f, 0f),
                        PrimitiveType.Cylinder,
                        _hazardMaterial);
                    break;
                case MissionTileKind.LandingZone:
                    CreateAssetObject(
                        DomePrefab,
                        "LZ Beacon",
                        _worldRoot,
                        position + Vector3.up * 0.05f,
                        Vector3.one * 0.28f,
                        Vector3.zero,
                        PrimitiveType.Cylinder,
                        _lzMaterial);
                    break;
                case MissionTileKind.EnemySpawn:
                    CreateMarker("enemy_spawn_" + x + "_" + y, new GridPoint(x, y), _enemyMaterial, "EN");
                    break;
            }
        }

        private Material GetTileMaterial(MissionTileKind kind, int x, int y)
        {
            switch (kind)
            {
                case MissionTileKind.Road:
                    return _roadMaterial;
                case MissionTileKind.Cover:
                    return _coverMaterial;
                case MissionTileKind.Blocker:
                    return _blockerMaterial;
                case MissionTileKind.Hazard:
                    return _hazardMaterial;
                case MissionTileKind.LandingZone:
                    return _lzMaterial;
                case MissionTileKind.Objective:
                    return _objectiveMaterial;
                case MissionTileKind.EnemySpawn:
                    return _enemyMaterial;
                default:
                    return (x + y) % 2 == 0 ? _tileMaterial : _tileAltMaterial;
            }
        }

        private GameObject CreateAssetObject(
            GameObject prefab,
            string name,
            Transform parent,
            Vector3 localOrWorldPosition,
            Vector3 localScale,
            Vector3 localEuler,
            PrimitiveType fallbackPrimitive,
            Material fallbackMaterial)
        {
            GameObject root = new GameObject(name);
            root.transform.SetParent(parent, false);
            root.transform.localPosition = localOrWorldPosition;

            GameObject model;
            if (prefab != null)
            {
                model = Instantiate(prefab, root.transform);
                model.name = name + " Model";
            }
            else
            {
                model = GameObject.CreatePrimitive(fallbackPrimitive);
                model.name = name + " Fallback";
                model.transform.SetParent(root.transform, false);
                SetChildMaterial(model, fallbackMaterial, true);
            }

            model.transform.localPosition = Vector3.zero;
            model.transform.localRotation = Quaternion.Euler(localEuler);
            model.transform.localScale = localScale;
            return root;
        }

        private void SetChildMaterial(GameObject root, Material material, bool includeImportedModels)
        {
            if (material == null)
            {
                return;
            }

            Renderer[] renderers = root.GetComponentsInChildren<Renderer>();
            foreach (Renderer renderer in renderers)
            {
                if (!includeImportedModels && renderer.gameObject.name.IndexOf("Model", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    continue;
                }

                renderer.sharedMaterial = material;
            }
        }

        private void CreateMarker(string name, GridPoint position, Material material, string label)
        {
            GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = name;
            marker.transform.SetParent(_worldRoot);
            marker.transform.position = GridToWorld(position) + Vector3.up * 0.08f;
            marker.transform.localScale = new Vector3(0.55f, 0.06f, 0.55f);
            marker.GetComponent<Renderer>().sharedMaterial = material;
            CreateLabel(name + "_label", label, position.Offset(0f, 0.15f), Color.white);
        }

        private TextMesh CreateLabel(string name, string text, GridPoint position, Color color)
        {
            GameObject labelObject = new GameObject(name);
            labelObject.transform.SetParent(_worldRoot);
            labelObject.transform.position = GridToWorld(position) + Vector3.up * 0.92f;
            TextMesh textMesh = labelObject.AddComponent<TextMesh>();
            textMesh.text = text;
            textMesh.anchor = TextAnchor.MiddleCenter;
            textMesh.alignment = TextAlignment.Center;
            textMesh.characterSize = 0.16f;
            textMesh.fontSize = 42;
            textMesh.color = color;
            _worldLabels.Add(textMesh);
            return textMesh;
        }

        private void ClearWorld()
        {
            if (_worldRoot == null)
            {
                GameObject root = new GameObject("CommanderWorldRoot");
                _worldRoot = root.transform;
            }

            for (int index = _worldRoot.childCount - 1; index >= 0; index--)
            {
                Destroy(_worldRoot.GetChild(index).gameObject);
            }

            GameObject previewRoot = GameObject.Find("EditorVisiblePreviewMap");
            if (previewRoot != null)
            {
                previewRoot.SetActive(false);
            }

            _unitObjects.Clear();
            _unitLabels.Clear();
            _enemyObjects.Clear();
            _worldLabels.Clear();
        }

        private void SetupScene()
        {
            Camera camera = Camera.main;
            if (camera == null)
            {
                GameObject cameraObject = new GameObject("Main Camera");
                camera = cameraObject.AddComponent<Camera>();
                camera.tag = "MainCamera";
            }

            camera.orthographic = true;
            camera.orthographicSize = 6.2f;
            camera.nearClipPlane = 0.1f;
            camera.farClipPlane = 200f;
            camera.transform.position = new Vector3(5.5f, 8.7f, -8.7f);
            camera.transform.rotation = Quaternion.Euler(58f, -38f, 0f);
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(0.025f, 0.032f, 0.04f);

            Light existingLight = FindAnyObjectByType<Light>();
            if (existingLight == null)
            {
                GameObject lightObject = new GameObject("Key Light");
                existingLight = lightObject.AddComponent<Light>();
            }

            existingLight.type = LightType.Directional;
            existingLight.intensity = 1.25f;
            existingLight.transform.rotation = Quaternion.Euler(48f, -35f, 0f);

            ClearWorld();
            MissionCatalogItem catalog = _simulation.GetMissionCatalogItem(_selectedCatalogId);
            if (catalog != null)
            {
                RebuildCatalogPreview(catalog);
            }
        }

        private void SetupMaterials()
        {
            _tileMaterial = CreateMaterial(new Color(0.19f, 0.24f, 0.24f));
            _tileAltMaterial = CreateMaterial(new Color(0.22f, 0.27f, 0.27f));
            _roadMaterial = CreateMaterial(new Color(0.10f, 0.14f, 0.16f));
            _coverMaterial = CreateMaterial(new Color(0.32f, 0.36f, 0.36f));
            _blockerMaterial = CreateMaterial(new Color(0.17f, 0.18f, 0.2f));
            _hazardMaterial = CreateMaterial(new Color(0.7f, 0.18f, 0.1f));
            _objectiveMaterial = CreateMaterial(new Color(0.95f, 0.67f, 0.18f));
            _lzMaterial = CreateMaterial(new Color(0.14f, 0.62f, 0.88f));
            _unitAlphaMaterial = CreateMaterial(new Color(0.15f, 0.55f, 0.95f));
            _unitBravoMaterial = CreateMaterial(new Color(0.18f, 0.82f, 0.55f));
            _enemyMaterial = CreateMaterial(new Color(0.82f, 0.16f, 0.12f));
            _enemyDownMaterial = CreateMaterial(new Color(0.22f, 0.06f, 0.05f));
            _dropshipMaterial = CreateMaterial(new Color(0.63f, 0.66f, 0.75f));
            _selectionMaterial = CreateMaterial(new Color(1f, 0.86f, 0.28f));
        }

        private Material CreateMaterial(Color color)
        {
            Shader shader = Shader.Find("Standard");
            if (shader == null)
            {
                shader = Shader.Find("Diffuse");
            }

            Material material = new Material(shader);
            material.color = color;
            return material;
        }

        private Vector3 GridToWorld(GridPoint point)
        {
            return new Vector3(point.X - 3.5f, 0f, point.Y - 3.5f);
        }

        private void FaceLabelsToCamera()
        {
            Camera camera = Camera.main;
            if (camera == null)
            {
                return;
            }

            foreach (TextMesh label in _worldLabels)
            {
                if (label != null)
                {
                    label.transform.rotation = camera.transform.rotation;
                }
            }
        }

        private void EnsureGuiStyles()
        {
            if (_panelStyle != null)
            {
                return;
            }

            _panelTexture = MakeTexture(new Color(0.045f, 0.055f, 0.065f, 0.94f));
            _badgeTexture = MakeTexture(new Color(0.12f, 0.17f, 0.19f, 1f));

            _panelStyle = new GUIStyle(GUI.skin.box);
            _panelStyle.padding = new RectOffset(10, 10, 10, 10);
            _panelStyle.normal.background = _panelTexture;

            _headerStyle = new GUIStyle(GUI.skin.label);
            _headerStyle.fontSize = 15;
            _headerStyle.fontStyle = FontStyle.Bold;
            _headerStyle.normal.textColor = Color.white;

            _smallLabelStyle = new GUIStyle(GUI.skin.label);
            _smallLabelStyle.fontSize = 12;
            _smallLabelStyle.wordWrap = true;
            _smallLabelStyle.normal.textColor = new Color(0.91f, 0.94f, 0.96f);

            _missionLogStyle = new GUIStyle(_smallLabelStyle);
            _missionLogStyle.normal.textColor = new Color(0.72f, 0.9f, 1f);

            _badgeStyle = new GUIStyle(_smallLabelStyle);
            _badgeStyle.alignment = TextAnchor.MiddleCenter;
            _badgeStyle.normal.background = _badgeTexture;
        }

        private Texture2D MakeTexture(Color color)
        {
            Texture2D texture = new Texture2D(1, 1);
            texture.SetPixel(0, 0, color);
            texture.Apply();
            return texture;
        }
    }

    public sealed class SpikeMapTile : MonoBehaviour
    {
        public int X;
        public int Y;
    }

    public enum MissionEditorTool
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
}
