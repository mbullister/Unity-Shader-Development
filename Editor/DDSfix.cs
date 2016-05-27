using UnityEditor;
using UnityEngine;

class DDSForceTrilinear : AssetPostprocessor
{
    void OnPostprocessTexture(Texture2D texture)
    {
        if (!assetPath.ToLower().EndsWith(".dds"))
            return;

        texture.filterMode = FilterMode.Trilinear;
    }
}