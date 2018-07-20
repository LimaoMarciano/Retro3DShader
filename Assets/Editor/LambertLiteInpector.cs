using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class LambertLiteInpector : ShaderGUI {

    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;

    static GUIContent staticLabel = new GUIContent();
    static ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);

    public override void OnGUI (MaterialEditor editor, MaterialProperty[] properties) {

        this.target = editor.target as Material;
        this.editor = editor;
        this.properties = properties;

        DoMain();

    }

    void DoMain()
    {
        GUILayout.Label("Main maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo(RGB)"), mainTex, FindProperty("_Color"));

        DoSpecular();
        DoEmission();
        editor.TextureScaleOffsetProperty(mainTex);
    }

    void DoSpecular()
    {
        GUILayout.Label("Specular", EditorStyles.boldLabel);

        MaterialProperty map = FindProperty("_SpecularMap");
        MaterialProperty specColor = FindProperty("_SpecularTint");
        MaterialProperty smoothness = FindProperty("_Smoothness");

        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(map, "Specular (RGB), Smoothness(A)"), map, FindProperty("_SpecularTint"));
        EditorGUI.indentLevel += 2;
        //editor.ColorProperty(specColor, "Specular color");
        editor.ShaderProperty(smoothness, MakeLabel(smoothness, "Specular smoothness"));
        EditorGUI.indentLevel -= 2;

        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_SPECULAR_MAP", map.textureValue);
        }
    }

    void DoEmission()
    {
        GUILayout.Label("Emission", EditorStyles.boldLabel);
  
        MaterialProperty map = FindProperty("_EmissionMap");

        EditorGUI.BeginChangeCheck();
        editor.TexturePropertyWithHDRColor(MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission"), emissionConfig, false);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_EMISSION_MAP", map.textureValue);
        }

        foreach (Material m in editor.targets)
        {
            m.globalIlluminationFlags =
                MaterialGlobalIlluminationFlags.BakedEmissive;
        }
    }

    MaterialProperty FindProperty (string name)
    {
        return FindProperty(name, properties);
    }

    static GUIContent MakeLabel (string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    void SetKeyword (string keyword, bool state)
    {
        if (state)
        {
            target.EnableKeyword(keyword);
        }
        else
        {
            target.DisableKeyword(keyword);
        }
    }

}
