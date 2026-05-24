#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;

namespace SternenBuergerUnitySpike.Editor
{
    [InitializeOnLoad]
    public static class SpikeProjectBootstrap
    {
        private const string ScenePath = "Assets/Scenes/CommanderFlowSpike.unity";

        static SpikeProjectBootstrap()
        {
            EditorApplication.delayCall += OpenSpikeSceneIfUntitled;
        }

        [MenuItem("SternenBuerger/Open Commander Flow Spike Scene")]
        public static void OpenSpikeScene()
        {
            if (EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            {
                EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            }
        }

        private static void OpenSpikeSceneIfUntitled()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
            {
                return;
            }

            Scene activeScene = EditorSceneManager.GetActiveScene();
            if (!activeScene.IsValid() || activeScene.path != ScenePath)
            {
                EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            }
        }
    }
}
#endif
