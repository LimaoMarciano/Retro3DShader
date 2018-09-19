using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine;

public class MyLightingShaderGUI : ShaderGUI {

    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;
    static GUIContent staticLabel = new GUIContent();
    static ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);

    bool shouldShowAlphaCutoff;
    enum RenderingMode { Opaque, Cutout }

	public override void OnGUI (MaterialEditor editor, MaterialProperty[] properties)
    {
        this.target = editor.target as Material;
        this.editor = editor;
        this.properties = properties;
        DoRenderingMode();
        DoMain();
        DoSpecular();
        DoEmission();
        if (shouldShowAlphaCutoff)
        {
            DoAlphaCutoff();
        }
        
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, FindProperty("_Tint"));
        editor.TextureScaleOffsetProperty(mainTex);
    }

    void DoSpecular()
    {
        MaterialProperty specularTint = FindProperty("_SpecularTint");
        editor.ColorProperty(specularTint, specularTint.displayName);

        MaterialProperty slider = FindProperty("_Smoothness");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }

    void DoEmission()
    {
        MaterialProperty map = FindProperty("_EmissionMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertyWithHDRColor(MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission"), emissionConfig, false);

        //Checks if property or map was changed and needs to update shader keywords
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_EMISSION_MAP", map.textureValue);
        }
    }

    void DoRenderingMode ()
    {
        RenderingMode mode = RenderingMode.Opaque;
        shouldShowAlphaCutoff = false;
        if (IsKeywordEnabled("_RENDERING_CUTOUT"))
        {
            mode = RenderingMode.Cutout;
            shouldShowAlphaCutoff = true;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);

        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);

            RenderQueue queue = mode == RenderingMode.Opaque ? RenderQueue.Geometry : RenderQueue.AlphaTest;
            string renderType = mode == RenderingMode.Opaque ? "" : "TransparentCutout";
            foreach (Material m in editor.targets)
            {
                m.renderQueue = (int)queue;
                m.SetOverrideTag("RenderType", renderType);
            }
        }
    }

    void DoAlphaCutoff ()
    {
        MaterialProperty slider = FindProperty("_AlphaCutoff");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }

    //Convenience methods
    void SetKeyword (string keyword, bool state)
    {
        if (state)
        {
            foreach (Material m in editor.targets)
            {
                m.EnableKeyword(keyword);
            }
            
        }
        else
        {
            foreach (Material m in editor.targets)
            {
                target.DisableKeyword(keyword);
            }
        }
    }

    bool IsKeywordEnabled(string keyword)
    {
        return target.IsKeywordEnabled(keyword);
    }

    MaterialProperty FindProperty (string name)
    {
        return FindProperty(name, properties);
    }

    void RecordAction(string label)
    {
        editor.RegisterPropertyChangeUndo(label);
    }

    static GUIContent MakeLabel (string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel (MaterialProperty property, string tooltip = null)
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
}
