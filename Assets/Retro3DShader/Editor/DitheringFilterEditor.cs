using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(DitheringFilter))]
public class DitheringFilterEditor : Editor {

	public string[] resOptions = new string[] { "240p", "300p", "480p", "Custom" };
	public string[] colorOptions = new string[] { "3-bit RGB111", "6-bit RGB222", "9-bit RGB333", "12-bit RGB444", "15-bit RGB555", "16-bit RGB565", "Custom" };
	public int resIndex = 0;
	public int colorIndex = 4;

	public override void OnInspectorGUI () {

		DitheringFilter myTarget = (DitheringFilter)target;

		myTarget.ditheringPattern = EditorGUILayout.ObjectField ("Dithering pattern", myTarget.ditheringPattern, typeof(Texture2D), false) as Texture2D;

		resIndex = EditorGUILayout.Popup ("Resolution", resIndex, resOptions);

		switch (resIndex) {
		case 0:
			myTarget.verticalResolution = 240;
			break;
		case 1:
			myTarget.verticalResolution = 300;
			break;
		case 2:
			myTarget.verticalResolution = 480;
			break;
		case 3:
			int resolution = EditorGUILayout.IntField ("Screen Height Resolution", (int)myTarget.verticalResolution);
			myTarget.verticalResolution = resolution;
			EditorGUILayout.Separator ();
			break;
		}

		colorIndex = EditorGUILayout.Popup ("Color Depth", colorIndex, colorOptions);

		switch (colorIndex) {
		case 0:
			myTarget.RColorDepth = 1;
			myTarget.GColorDepth = 1;
			myTarget.BColorDepth = 1;
			break;
		case 1:
			myTarget.RColorDepth = 2;
			myTarget.GColorDepth = 2;
			myTarget.BColorDepth = 2;
			break;
		case 2:
			myTarget.RColorDepth = 3;
			myTarget.GColorDepth = 3;
			myTarget.BColorDepth = 3;
			break;
		case 3:
			myTarget.RColorDepth = 4;
			myTarget.GColorDepth = 4;
			myTarget.BColorDepth = 4;
			break;
		case 4:
			myTarget.RColorDepth = 5;
			myTarget.GColorDepth = 5;
			myTarget.BColorDepth = 5;
			break;
		case 5:
			myTarget.RColorDepth = 5;
			myTarget.GColorDepth = 6;
			myTarget.BColorDepth = 5;
			break;
		case 6:
			EditorGUILayout.BeginHorizontal ();
			EditorGUILayout.LabelField ("R", GUILayout.MaxWidth (15));
			myTarget.RColorDepth = EditorGUILayout.IntField (myTarget.RColorDepth);
			EditorGUILayout.LabelField ("G", GUILayout.MaxWidth (15));
			myTarget.GColorDepth = EditorGUILayout.IntField (myTarget.GColorDepth);
			EditorGUILayout.LabelField ("B", GUILayout.MaxWidth (15));
			myTarget.BColorDepth = EditorGUILayout.IntField (myTarget.BColorDepth);
			EditorGUILayout.EndHorizontal ();
			break;
		}

		if (GUI.changed) 
			EditorUtility.SetDirty (target);

	}
}
