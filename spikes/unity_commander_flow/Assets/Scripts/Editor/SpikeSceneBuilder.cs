#if UNITY_EDITOR
using SternenBuergerUnitySpike.Presentation;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace SternenBuergerUnitySpike.Editor
{
    public static class SpikeSceneBuilder
    {
        [MenuItem("SternenBuerger/Build Commander Flow Spike Scene")]
        public static void Build()
        {
            AssetDatabase.Refresh();

            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            CreateCamera();
            CreateLight();
            CreatePreviewMap();

            GameObject root = new GameObject("CommanderFlowSpike");
            CommanderFlowSpikeBehaviour behaviour = root.AddComponent<CommanderFlowSpikeBehaviour>();
            AssignImportedAssets(behaviour);

            const string scenePath = "Assets/Scenes/CommanderFlowSpike.unity";
            EditorSceneManager.SaveScene(scene, scenePath);
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(scenePath, true)
            };

            Debug.Log("Commander Flow Spike scene rebuilt at " + scenePath);
        }

        private static void AssignImportedAssets(CommanderFlowSpikeBehaviour behaviour)
        {
            behaviour.FriendlyInfantryPrefab = LoadPrefab("Assets/Imported/Quaternius/Characters/Swat.fbx");
            behaviour.SpacesuitPrefab = LoadPrefab("Assets/Imported/Quaternius/Characters/Spacesuit.fbx");
            behaviour.DropshipPrefab = LoadPrefab("Assets/Imported/Quaternius/Ships/Dropship_Rae.fbx");
            behaviour.DropshipAltPrefab = LoadPrefab("Assets/Imported/Quaternius/Ships/Dropship_Barbara.fbx");
            behaviour.EnemyRobotPrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Enemy_2Legs_Gun.fbx");
            behaviour.EnemyDronePrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Enemy_Flying_Gun.fbx");
            behaviour.AssaultRiflePrefab = LoadPrefab("Assets/Imported/Quaternius/Weapons/AR_1.fbx");
            behaviour.SmgPrefab = LoadPrefab("Assets/Imported/Quaternius/Weapons/SMG_2.fbx");
            behaviour.SniperPrefab = LoadPrefab("Assets/Imported/Quaternius/Weapons/Sniper_2.fbx");
            behaviour.LauncherPrefab = LoadPrefab("Assets/Imported/Quaternius/Weapons/Grenade_1.fbx");
            behaviour.ComputerPrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Computer.fbx");
            behaviour.ComputerLargePrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Computer_Large.fbx");
            behaviour.TurretPrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Turret_Cannon.fbx");
            behaviour.TankPrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Tank.fbx");
            behaviour.PipePrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Pipe_1.fbx");
            behaviour.AntennaPrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Antenna_1.fbx");
            behaviour.DomePrefab = LoadPrefab("Assets/Imported/Quaternius/Props/GeodesicDome.fbx");
            behaviour.RockPrefab = LoadPrefab("Assets/Imported/Quaternius/Props/Rock_Large_1.fbx");
        }

        private static GameObject LoadPrefab(string path)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            if (prefab == null)
            {
                Debug.LogWarning("Commander Flow Spike asset missing: " + path);
            }

            return prefab;
        }

        private static void CreateCamera()
        {
            GameObject cameraObject = new GameObject("Main Camera");
            Camera camera = cameraObject.AddComponent<Camera>();
            camera.tag = "MainCamera";
            camera.orthographic = true;
            camera.orthographicSize = 6.4f;
            camera.nearClipPlane = 0.1f;
            camera.farClipPlane = 200f;
            camera.backgroundColor = new Color(0.05f, 0.07f, 0.09f);
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.transform.position = new Vector3(5.5f, 8.5f, -8.5f);
            camera.transform.rotation = Quaternion.Euler(58f, -38f, 0f);
        }

        private static void CreateLight()
        {
            GameObject lightObject = new GameObject("Key Light");
            Light light = lightObject.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.2f;
            light.transform.rotation = Quaternion.Euler(48f, -35f, 0f);
        }

        private static void CreatePreviewMap()
        {
            Material tileMaterial = CreateMaterial("SpikePreviewTile", new Color(0.23f, 0.33f, 0.28f));
            Material tileAltMaterial = CreateMaterial("SpikePreviewTileAlt", new Color(0.28f, 0.38f, 0.32f));
            Material markerMaterial = CreateMaterial("SpikePreviewMarker", new Color(0.2f, 0.72f, 0.92f));
            Material objectiveMaterial = CreateMaterial("SpikePreviewObjective", new Color(0.9f, 0.74f, 0.2f));

            GameObject previewRoot = new GameObject("EditorVisiblePreviewMap");
            for (int x = 0; x < 8; x++)
            {
                for (int y = 0; y < 8; y++)
                {
                    GameObject tile = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    tile.name = "PreviewTile_" + x + "_" + y;
                    tile.transform.SetParent(previewRoot.transform);
                    tile.transform.position = new Vector3(x - 3.5f, -0.05f, y - 3.5f);
                    tile.transform.localScale = new Vector3(0.96f, 0.08f, 0.96f);
                    tile.GetComponent<Renderer>().sharedMaterial = (x + y) % 2 == 0 ? tileMaterial : tileAltMaterial;
                }
            }

            GameObject lz = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            lz.name = "Preview LZ";
            lz.transform.SetParent(previewRoot.transform);
            lz.transform.position = new Vector3(1.4f - 3.5f, 0.08f, 1.2f - 3.5f);
            lz.transform.localScale = new Vector3(0.65f, 0.08f, 0.65f);
            lz.GetComponent<Renderer>().sharedMaterial = markerMaterial;

            GameObject objective = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            objective.name = "Preview Objective";
            objective.transform.SetParent(previewRoot.transform);
            objective.transform.position = new Vector3(5.5f - 3.5f, 0.08f, 5.3f - 3.5f);
            objective.transform.localScale = new Vector3(0.65f, 0.08f, 0.65f);
            objective.GetComponent<Renderer>().sharedMaterial = objectiveMaterial;
        }

        private static Material CreateMaterial(string name, Color color)
        {
            Shader shader = Shader.Find("Standard");
            if (shader == null)
            {
                shader = Shader.Find("Diffuse");
            }

            Material material = new Material(shader);
            material.name = name;
            material.color = color;
            return material;
        }
    }
}
#endif
