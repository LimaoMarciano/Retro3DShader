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
    enum RenderingMode { Opaque, Cutout, Fade, Transparent }

    struct RenderingSettings
    {
        public RenderQueue queue;
        public string renderType;
        public BlendMode srcBlend, dstBlend;
        public bool zWrite;

        public static RenderingSettings[] modes =
        {
            new RenderingSettings()
            {
                queue = RenderQueue.Geometry,
                renderType = "",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings()
            {
                queue = RenderQueue.AlphaTest,
                renderType = "TransparentCutout",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings()
            {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.SrcAlpha,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            },
            new RenderingSettings()
            {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            }
        };
    }

	public override void OnGUI (MaterialEditor editor, MaterialProperty[] properties)
    {
        this.target = editor.target as Material;
        this.editor = editor;
        this.properties = properties;
        DoRenderingMode();
        DoMain();
        if (shouldShowAlphaCutoff)
        {
            DoAlphaCutoff();
        }
        DoSpecular();
        DoEmission();
        DoReflection();
        DoVertexSnap();
        
        
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
        else if (IsKeywordEnabled("_RENDERING_FADE"))
        {
            mode = RenderingMode.Fade;
        }
        else if (IsKeywordEnabled("_RENDERING_TRANSPARENT"))
        {
            mode = RenderingMode.Transparent;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);

        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);
            SetKeyword("_RENDERING_FADE", mode == RenderingMode.Fade);
            SetKeyword("_RENDERING_TRANSPARENT", mode == RenderingMode.Transparent);

            RenderingSettings settings = RenderingSettings.modes[(int)mode];
            foreach (Material m in editor.targets)
            {
                m.renderQueue = (int)settings.queue;
                m.SetOverrideTag("RenderType", settings.renderType);
                m.SetInt("_SrcBlend", (int)settings.srcBlend);
                m.SetInt("_DstBlend", (int)settings.dstBlend);
                m.SetInt("_ZWrite", settings.zWrite ? 1 : 0);
            }
        }

        if (mode == RenderingMode.Fade || mode == RenderingMode.Transparent)
        {
            DoSemitransparentShadows();
        }

    }

    void DoAlphaCutoff ()
    {
        MaterialProperty slider = FindProperty("_AlphaCutoff");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }

    void DoSemitransparentShadows ()
    {
        EditorGUI.BeginChangeCheck();
        bool semitransparentShadows = 
            EditorGUILayout.Toggle(
                MakeLabel("Semitransp. Shadows", "Semitransparent Shadows"), 
                IsKeywordEnabled("_SEMITRANSPARENT_SHADOWS")
            );
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_SEMITRANSPARENT_SHADOWS", semitransparentShadows);
        }

        if (!semitransparentShadows)
        {
            shouldShowAlphaCutoff = true;
        }
    }

    void DoReflection ()
    {
        MaterialProperty cubemap = FindProperty("_ReflectionMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(cubemap), cubemap, cubemap.textureValue ? FindProperty("_ReflectionTint") : null);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_REFLECTIVE", cubemap.textureValue);
        }
    }

    void DoVertexSnap ()
    {
        MaterialProperty geoRes = FindProperty("_GeoRes");
        editor.FloatProperty(geoRes, MakeLabel(geoRes).text);
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
