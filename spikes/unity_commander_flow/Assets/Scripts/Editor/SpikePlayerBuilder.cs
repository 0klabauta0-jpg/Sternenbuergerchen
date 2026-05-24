#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace SternenBuergerUnitySpike.Editor
{
    public static class SpikePlayerBuilder
    {
        private const string ScenePath = "Assets/Scenes/CommanderFlowSpike.unity";
        private const string BuildPath = "Builds/Windows/SternenBuergerchenUnitySpike.exe";

        [MenuItem("SternenBuerger/Build Windows Spike Player")]
        public static void BuildWindows()
        {
            SpikeSceneBuilder.Build();

            string buildDirectory = Path.GetDirectoryName(BuildPath);
            if (!string.IsNullOrEmpty(buildDirectory))
            {
                Directory.CreateDirectory(buildDirectory);
            }

            BuildPlayerOptions options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = BuildPath,
                target = BuildTarget.StandaloneWindows64,
                options = BuildOptions.None
            };

            BuildReport report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded)
            {
                throw new System.InvalidOperationException("Player build failed: " + report.summary.result);
            }

            Debug.Log("Commander Flow Spike Windows player built at " + BuildPath);
        }
    }
}
#endif
