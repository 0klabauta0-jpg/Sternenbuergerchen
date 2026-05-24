using SternenBuergerUnitySpike.Core;

static void Require(bool condition, string label)
{
    if (!condition)
    {
        throw new InvalidOperationException("Verifier failed: " + label);
    }
}

static void TickFor(CommanderFlowSimulation simulation, float seconds)
{
    const float step = 0.1f;
    var elapsed = 0f;
    while (elapsed < seconds)
    {
        simulation.Tick(step);
        elapsed += step;
    }
}

var simulation = CommanderFlowSimulation.CreateDefault();

Require(simulation.SetMissionTile("outpost", 2, 2, MissionTileKind.Cover), "Editor paints cover");
Require(simulation.SetMissionTile("outpost", 6, 6, MissionTileKind.EnemySpawn), "Editor paints enemy spawn");
Require(simulation.SetMissionTile("relay", 4, 4, MissionTileKind.Hazard), "Editor paints hazard");
Require(simulation.MoveMissionTarget("outpost", "objective", 6, 4), "Editor moves objective target");
var editedOutpost = simulation.GetMissionCatalogItem("outpost");
Require(editedOutpost.GetTileKind(2, 2) == MissionTileKind.Cover, "Edited cover persisted in catalog");
Require(editedOutpost.GetTileKind(6, 4) == MissionTileKind.Objective, "Edited objective persisted in catalog");

Require(simulation.AddMemberToFireteam("ft_alpha", "npc_roth"), "Roth joins Alpha");
Require(simulation.AddMemberToFireteam("ft_alpha", "npc_vega"), "Vega joins Alpha");
Require(simulation.AddMemberToFireteam("ft_alpha", "npc_sato"), "Sato joins Alpha");
Require(simulation.CyclePrimaryWeapon("ft_alpha", "npc_vega"), "Vega weapon cycles");
Require(simulation.AssignDropship("ft_alpha", "ds_falke"), "Falke assigned");

Require(simulation.AddMemberToFireteam("ft_bravo", "npc_ozan"), "Ozan joins Bravo");
Require(simulation.AddMemberToFireteam("ft_bravo", "npc_lenz"), "Lenz joins Bravo");
Require(simulation.AddMemberToFireteam("ft_bravo", "npc_malik"), "Malik joins Bravo");
Require(simulation.AssignDropship("ft_bravo", "ds_lanze"), "Lanze assigned");

var alphaMission = simulation.LaunchMission("ft_alpha", "outpost");
var bravoMission = simulation.LaunchMission("ft_bravo", "relay");
Require(alphaMission != null, "Alpha mission launched");
Require(bravoMission != null, "Bravo mission launched");
Require(simulation.ActiveMissions.Count == 2, "Two active missions run in parallel");
Require(alphaMission.GetTileKind(2, 2) == MissionTileKind.Cover, "Edited map copied into active mission");
Require(alphaMission.Enemies.Count >= 2, "Enemy spawns copied into active mission");

TickFor(simulation, 7.0f);
Require(alphaMission.Phase == MissionPhase.Active, "Alpha deployed");
Require(bravoMission.Phase == MissionPhase.Active, "Bravo deployed");

Require(simulation.IssueCommand(alphaMission.Id, CommandType.Move, "ridge"), "Move command accepted");
Require(simulation.IssueCommand(alphaMission.Id, CommandType.Take, "objective"), "Take command accepted");
Require(simulation.IssueCommand(bravoMission.Id, CommandType.Engage, "contact"), "Engage command accepted");
Require(simulation.IssueCommand(bravoMission.Id, CommandType.Flank, "contact"), "Flank command accepted");

TickFor(simulation, 22.0f);
Require(alphaMission.ObjectiveProgress > 0.05f || alphaMission.Phase == MissionPhase.Complete, "Alpha made objective progress");
Require(bravoMission.CurrentOrderText.Length > 0, "Bravo has mission order feedback");

Console.WriteLine("Unity commander flow spike verifier passed.");
Console.WriteLine("Active missions: " + simulation.ActiveMissions.Count);
Console.WriteLine("Alpha: " + alphaMission.Phase + " objective " + (alphaMission.ObjectiveProgress * 100f).ToString("0") + "%");
Console.WriteLine("Bravo: " + bravoMission.Phase + " order " + bravoMission.CurrentOrderText);
